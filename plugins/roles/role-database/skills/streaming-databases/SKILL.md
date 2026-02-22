---
name: streaming-databases
description: |
  Deep operational guide for 14 streaming databases and platforms. Kafka (KRaft, Streams, Connect, Schema Registry), Pulsar (multi-tenant, geo-replication), Redpanda (Kafka-compatible, no JVM), NATS/JetStream, Flink (streaming SQL), Materialize, RisingWave, Kinesis, Event Hubs, Pub/Sub, EventStoreDB. Use when implementing event streaming, CDC, real-time analytics, or event sourcing.
allowed-tools: Read, Grep, Glob, Bash
---

You are a streaming databases specialist informed by the Software Engineer by RN competency matrix.

## Streaming Platform Comparison

| Platform | Architecture | Delivery Guarantee | Latency | Ordering | Managed Option |
|----------|-------------|-------------------|---------|----------|----------------|
| Apache Kafka | Distributed log, partitioned topics | Exactly-once (EOS) | Low (ms) | Per-partition | Confluent Cloud, MSK, Event Hubs |
| Apache Pulsar | Segment-based, BookKeeper storage | Exactly-once (txn) | Low (ms) | Per-partition | StreamNative |
| Redpanda | Single-binary, Raft per partition | Exactly-once (EOS) | Ultra-low (sub-ms) | Per-partition | Redpanda Cloud |
| NATS/JetStream | Subject-based, embedded Raft | At-least-once (JetStream) | Ultra-low | Per-stream | Synadia Cloud |
| Apache Flink | Stream processor, checkpointed | Exactly-once (checkpoint) | Low (ms) | Per-key/window | Confluent Cloud, Amazon KDA |
| Materialize | Differential dataflow | Exactly-once | Low (ms) | Total order on sources | Materialize Cloud |
| RisingWave | Distributed streaming SQL | Exactly-once | Low (ms) | Per-partition | RisingWave Cloud |
| Spark Structured Streaming | Micro-batch / continuous | Exactly-once | Medium (100ms+) | Per-partition | Databricks, EMR |
| Amazon Kinesis | Sharded stream | At-least-once | Low (ms) | Per-shard | AWS-native |
| Azure Event Hubs | Partitioned log | At-least-once | Low (ms) | Per-partition | Azure-native |
| Google Pub/Sub | Global messaging | Exactly-once | Low (ms) | Ordering keys | GCP-native |
| RabbitMQ Streams | Append-only log | At-least-once | Low (ms) | Per-stream | CloudAMQP |
| EventStoreDB | Append-only event log | Exactly-once (append) | Low (ms) | Per-stream | Event Store Cloud |
| Memphis | NATS JetStream-based | At-least-once | Low (ms) | Per-station | Memphis Cloud |

## Apache Kafka

### Topic and Partition Design

```bash
# Create topic with optimal partition count
kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic orders \
  --partitions 12 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config retention.ms=604800000 \
  --config cleanup.policy=delete \
  --config compression.type=zstd

# Partition sizing guidance:
# - Start with num_consumers * 2-3 partitions
# - Each partition handles ~10 MB/s throughput
# - Max partitions per broker: ~4000 (KRaft), ~2000 (ZooKeeper)
# - Partition key: choose field with high cardinality and even distribution
```

### KRaft Mode (No ZooKeeper)

```properties
# server.properties for KRaft
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@node1:9093,2@node2:9093,3@node3:9093
controller.listener.names=CONTROLLER
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
log.dirs=/var/kafka-logs
# Migration from ZooKeeper:
# 1. kafka-metadata.sh snapshot --cluster-id <id>
# 2. Start controllers with KRaft config
# 3. Migrate brokers one at a time
# 4. Remove ZooKeeper dependency
```

### Exactly-Once Semantics (EOS)

```java
// Producer: enable idempotence + transactions
Properties props = new Properties();
props.put("bootstrap.servers", "broker:9092");
props.put("enable.idempotence", true);
props.put("acks", "all");
props.put("transactional.id", "order-processor-1");
props.put("max.in.flight.requests.per.connection", 5); // safe with idempotence

KafkaProducer<String, Order> producer = new KafkaProducer<>(props);
producer.initTransactions();

try {
    producer.beginTransaction();
    producer.send(new ProducerRecord<>("orders", order.getId(), order));
    producer.sendOffsetsToTransaction(offsets, consumerGroupMetadata);
    producer.commitTransaction();
} catch (ProducerFencedException e) {
    producer.close(); // another instance took over
} catch (KafkaException e) {
    producer.abortTransaction();
}
```

### Consumer Group Rebalancing

```java
// Cooperative sticky rebalancing (avoid stop-the-world)
props.put("partition.assignment.strategy",
    "org.apache.kafka.clients.consumer.CooperativeStickyAssignor");

// Static group membership (reduce rebalances during rolling deploys)
props.put("group.instance.id", "consumer-host-1");
props.put("session.timeout.ms", 60000);

// Consumer with exactly-once read-process-write
consumer.subscribe(List.of("input-topic"));
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    producer.beginTransaction();
    for (ConsumerRecord<String, String> record : records) {
        // process and produce to output topic
        producer.send(new ProducerRecord<>("output-topic", process(record)));
    }
    producer.sendOffsetsToTransaction(currentOffsets(records), consumer.groupMetadata());
    producer.commitTransaction();
}
```

### Kafka Streams DSL

```java
StreamsBuilder builder = new StreamsBuilder();

// Stream-table join with windowed aggregation
KStream<String, Order> orders = builder.stream("orders");
KTable<String, Customer> customers = builder.table("customers");

orders
    .selectKey((k, v) -> v.getCustomerId())
    .join(customers, (order, customer) -> enrich(order, customer))
    .groupByKey()
    .windowedBy(TimeWindows.ofSizeWithNoGrace(Duration.ofHours(1)))
    .aggregate(
        OrderSummary::new,
        (key, order, summary) -> summary.add(order),
        Materialized.as("hourly-order-summary")
    )
    .toStream()
    .to("order-summaries");
```

### Kafka Connect Source/Sink

```json
{
  "name": "postgres-cdc-source",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "replicator",
    "database.dbname": "orders_db",
    "topic.prefix": "cdc",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_slot",
    "publication.name": "dbz_publication",
    "transforms": "route",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route.regex": "cdc\\.public\\.(.*)",
    "transforms.route.replacement": "orders.$1"
  }
}
```

### Schema Registry (Avro/Protobuf/JSON Schema)

```bash
# Register Avro schema
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema": "{\"type\":\"record\",\"name\":\"Order\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"},{\"name\":\"status\",\"type\":{\"type\":\"enum\",\"name\":\"Status\",\"symbols\":[\"PENDING\",\"CONFIRMED\",\"SHIPPED\"]}}]}"}' \
  http://schema-registry:8081/subjects/orders-value/versions

# Compatibility modes: BACKWARD (default), FORWARD, FULL, NONE
# Set compatibility level
curl -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "FULL_TRANSITIVE"}' \
  http://schema-registry:8081/config/orders-value
```

### Tiered Storage and MirrorMaker 2

```properties
# Tiered storage (Confluent Platform / KIP-405)
remote.log.storage.system.enable=true
remote.log.storage.manager.class.name=io.confluent.tier.s3.S3RemoteStorageManager
remote.log.storage.manager.impl.prefix=rsm.config.
rsm.config.s3.bucket.name=kafka-tiered-storage
rsm.config.s3.region=us-east-1
# Per-topic: local.retention.ms=86400000 (keep 1 day local, rest on S3)
```

```properties
# MirrorMaker 2 (mm2) for cross-cluster replication
clusters=source,target
source.bootstrap.servers=source-kafka:9092
target.bootstrap.servers=target-kafka:9092
source->target.enabled=true
source->target.topics=orders.*
replication.factor=3
sync.topic.configs.enabled=true
sync.group.offsets.enabled=true
emit.heartbeats.enabled=true
```

## Apache Pulsar

### Multi-Tenant Architecture

```bash
# Create tenant with allowed clusters
bin/pulsar-admin tenants create finance \
  --allowed-clusters us-east,eu-west \
  --admin-roles finance-admin

# Create namespace with policies
bin/pulsar-admin namespaces create finance/payments
bin/pulsar-admin namespaces set-retention finance/payments \
  --size 10G --time 7d
bin/pulsar-admin namespaces set-schema-validation-enforce \
  finance/payments --enable
bin/pulsar-admin namespaces set-backlog-quota finance/payments \
  --limit 5G --policy producer_request_hold

# Geo-replication
bin/pulsar-admin namespaces set-clusters finance/payments \
  --clusters us-east,eu-west,ap-south
```

### Pulsar Functions and IO

```java
// Pulsar Function: serverless stream processing
public class OrderEnricher implements Function<Order, EnrichedOrder> {
    @Override
    public EnrichedOrder process(Order order, Context context) {
        String customerData = context.getState("customer-" + order.getCustomerId());
        return EnrichedOrder.from(order, customerData);
    }
}
// Deploy: pulsar-admin functions create --jar order-enricher.jar
//   --classname OrderEnricher --inputs persistent://finance/payments/orders
//   --output persistent://finance/payments/enriched-orders
```

### Topic Compaction and Pulsar SQL

```bash
# Enable topic compaction (keep latest value per key)
bin/pulsar-admin topics set-compaction-threshold \
  persistent://finance/payments/customer-state --threshold 100M
bin/pulsar-admin topics trigger-compaction \
  persistent://finance/payments/customer-state

# Pulsar SQL (Presto/Trino integration)
# Query topic data with SQL
presto> SELECT * FROM pulsar."finance/payments"."orders"
        WHERE __publish_time__ > timestamp '2024-01-01'
        LIMIT 100;
```

## Redpanda

### Kafka-Compatible, No JVM/ZK

```bash
# Install and start Redpanda (single binary, C++/Seastar)
rpk cluster config set enable_idempotence true
rpk cluster config set enable_transactions true

# Create topic
rpk topic create orders -p 12 -r 3 \
  --topic-config retention.ms=604800000 \
  --topic-config compression.type=zstd

# Redpanda Console (built-in UI)
# Access at http://localhost:8080 for topic browsing, consumer groups, schema registry

# Tiered storage to S3
rpk cluster config set cloud_storage_enabled true
rpk cluster config set cloud_storage_bucket "redpanda-tiered"
rpk cluster config set cloud_storage_region "us-east-1"
rpk cluster config set cloud_storage_credentials_source aws_instance_metadata

# Schema Registry (built-in, Confluent-compatible)
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema":"{...}","schemaType":"PROTOBUF"}' \
  http://redpanda:8081/subjects/orders-value/versions
```

## NATS / JetStream

### Subjects, Queue Groups, JetStream

```bash
# Core NATS: fire-and-forget pub/sub
nats pub orders.new '{"id":"123","total":99.99}'
nats sub "orders.>"  # wildcard subscription

# Queue groups: load-balanced consumers
nats sub orders.new --queue=order-processors

# JetStream: persistent streams
nats stream add ORDERS \
  --subjects="orders.>" \
  --storage=file \
  --retention=limits \
  --max-msgs=-1 \
  --max-bytes=10GB \
  --max-age=7d \
  --replicas=3 \
  --discard=old \
  --dupe-window=2m

# JetStream consumers
nats consumer add ORDERS order-processor \
  --deliver=all \
  --ack=explicit \
  --max-deliver=5 \
  --filter="orders.created" \
  --pull
```

### Key-Value Store and Object Store

```go
// NATS KV Store (built on JetStream)
js, _ := nc.JetStream()
kv, _ := js.CreateKeyValue(&nats.KeyValueConfig{
    Bucket:   "sessions",
    TTL:      30 * time.Minute,
    Replicas: 3,
})
kv.Put("user:123", []byte(`{"token":"abc"}`))
entry, _ := kv.Get("user:123")

// Watch for changes
watcher, _ := kv.Watch("user.*")
for update := range watcher.Updates() {
    fmt.Printf("Key %s updated: %s\n", update.Key(), string(update.Value()))
}

// NATS Object Store (large binary objects)
os, _ := js.CreateObjectStore(&nats.ObjectStoreConfig{
    Bucket:   "uploads",
    Replicas: 3,
})
os.PutFile("report.pdf")
```

## Apache Flink

### DataStream API and Checkpointing

```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

// Exactly-once with checkpointing
env.enableCheckpointing(10000, CheckpointingMode.EXACTLY_ONCE);
env.getCheckpointConfig().setCheckpointStorage("s3://flink-checkpoints/");
env.getCheckpointConfig().setMinPauseBetweenCheckpoints(5000);
env.getCheckpointConfig().setTolerableCheckpointFailureNumber(3);

// Kafka source with watermarks
KafkaSource<Order> source = KafkaSource.<Order>builder()
    .setBootstrapServers("broker:9092")
    .setTopics("orders")
    .setGroupId("flink-order-processor")
    .setStartingOffsets(OffsetsInitializer.committedOffsets(OffsetResetStrategy.EARLIEST))
    .setDeserializer(new OrderDeserializer())
    .build();

DataStream<Order> orders = env.fromSource(source,
    WatermarkStrategy.<Order>forBoundedOutOfOrderness(Duration.ofSeconds(5))
        .withTimestampAssigner((order, ts) -> order.getTimestamp()),
    "kafka-orders");
```

### Flink SQL and CDC

```sql
-- Flink SQL: create table backed by Kafka
CREATE TABLE orders (
    order_id STRING,
    customer_id STRING,
    amount DECIMAL(12, 2),
    order_time TIMESTAMP(3),
    WATERMARK FOR order_time AS order_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'orders',
    'properties.bootstrap.servers' = 'broker:9092',
    'format' = 'json',
    'scan.startup.mode' = 'earliest-offset'
);

-- Tumbling window aggregation
SELECT
    customer_id,
    TUMBLE_START(order_time, INTERVAL '1' HOUR) AS window_start,
    COUNT(*) AS order_count,
    SUM(amount) AS total_amount
FROM orders
GROUP BY customer_id, TUMBLE(order_time, INTERVAL '1' HOUR);

-- Flink CDC: read PostgreSQL changes directly
CREATE TABLE pg_orders (
    id INT,
    status STRING,
    amount DECIMAL(12, 2),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'postgres',
    'port' = '5432',
    'username' = 'flink',
    'password' = 'secret',
    'database-name' = 'shop',
    'schema-name' = 'public',
    'table-name' = 'orders',
    'slot.name' = 'flink_slot'
);
```

## Materialize

### Streaming SQL with Incremental Materialized Views

```sql
-- Source from Kafka
CREATE SOURCE orders_source
  FROM KAFKA CONNECTION kafka_conn (TOPIC 'orders')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY CONNECTION csr_conn
  ENVELOPE DEBEZIUM;

-- Source from PostgreSQL CDC
CREATE SOURCE pg_source
  FROM POSTGRES CONNECTION pg_conn (PUBLICATION 'mz_publication')
  FOR TABLES (orders, customers, products);

-- Incrementally maintained materialized view
CREATE MATERIALIZED VIEW order_dashboard AS
SELECT
    c.name AS customer_name,
    COUNT(*) AS total_orders,
    SUM(o.amount) AS total_spent,
    MAX(o.created_at) AS last_order
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.name;

-- Query always returns up-to-date results (millisecond freshness)
SELECT * FROM order_dashboard WHERE total_spent > 1000;

-- Sink results back to Kafka
CREATE SINK dashboard_sink
  FROM order_dashboard
  INTO KAFKA CONNECTION kafka_conn (TOPIC 'order-dashboard-updates')
  FORMAT JSON
  ENVELOPE DEBEZIUM;
```

## RisingWave

### Distributed Streaming SQL

```sql
-- Create source from Kafka
CREATE SOURCE orders (
    order_id VARCHAR,
    customer_id VARCHAR,
    amount DECIMAL,
    order_time TIMESTAMPTZ
) WITH (
    connector = 'kafka',
    topic = 'orders',
    properties.bootstrap.server = 'broker:9092'
) FORMAT PLAIN ENCODE JSON;

-- Materialized view with temporal filter
CREATE MATERIALIZED VIEW recent_order_stats AS
SELECT
    customer_id,
    COUNT(*) AS order_count,
    SUM(amount) AS total_amount,
    window_start
FROM TUMBLE(orders, order_time, INTERVAL '1 HOUR')
GROUP BY customer_id, window_start;

-- Sink to PostgreSQL
CREATE SINK order_stats_sink FROM recent_order_stats
WITH (
    connector = 'jdbc',
    jdbc.url = 'jdbc:postgresql://pg:5432/analytics',
    table.name = 'order_stats',
    type = 'upsert',
    primary_key = 'customer_id,window_start'
);
```

## Apache Spark Structured Streaming

### Micro-Batch and Continuous Processing

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import window, sum, col, from_json
from pyspark.sql.types import StructType, StringType, DoubleType, TimestampType

spark = SparkSession.builder.appName("OrderStreaming").getOrCreate()

schema = StructType() \
    .add("order_id", StringType()) \
    .add("customer_id", StringType()) \
    .add("amount", DoubleType()) \
    .add("order_time", TimestampType())

# Read from Kafka
orders = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "broker:9092") \
    .option("subscribe", "orders") \
    .option("startingOffsets", "earliest") \
    .load() \
    .select(from_json(col("value").cast("string"), schema).alias("data")) \
    .select("data.*")

# Windowed aggregation
hourly_stats = orders \
    .withWatermark("order_time", "5 minutes") \
    .groupBy(window("order_time", "1 hour"), "customer_id") \
    .agg(sum("amount").alias("total_amount"))

# Write to Delta Lake with exactly-once guarantees
query = hourly_stats.writeStream \
    .format("delta") \
    .outputMode("append") \
    .option("checkpointLocation", "s3://checkpoints/hourly-stats") \
    .start("s3://data-lake/hourly-order-stats")
```

## Amazon Kinesis

### Data Streams, Firehose, and Analytics

```bash
# Create stream with on-demand capacity mode
aws kinesis create-stream \
  --stream-name orders \
  --stream-mode-details StreamMode=ON_DEMAND

# Enhanced fan-out (dedicated 2 MB/s per consumer)
aws kinesis register-stream-consumer \
  --stream-arn arn:aws:kinesis:us-east-1:123456:stream/orders \
  --consumer-name order-processor
```

```python
# KCL v2 consumer (Python)
from amazon_kclpy import kcl

class OrderProcessor(kcl.RecordProcessorBase):
    def process_records(self, process_records_input):
        for record in process_records_input.records:
            order = json.loads(record.data)
            self.process_order(order)
        process_records_input.checkpointer.checkpoint()

# Kinesis Data Firehose: auto-deliver to S3/Redshift/OpenSearch
# aws firehose create-delivery-stream --delivery-stream-name orders-to-s3 \
#   --s3-destination-configuration BucketARN=arn:aws:s3:::orders-archive
```

## Azure Event Hubs

```python
# Event Hubs with Kafka protocol (drop-in replacement)
from confluent_kafka import Producer

producer = Producer({
    'bootstrap.servers': 'mynamespace.servicebus.windows.net:9093',
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'sasl.username': '$ConnectionString',
    'sasl.password': '<connection-string>',
})
producer.produce('orders', key='order-123', value=json.dumps(order))

# Event Hubs Capture: auto-archive to Azure Blob Storage / Data Lake
# Configurable time window and size window for batching
# Output format: Avro
```

## Google Pub/Sub

```python
from google.cloud import pubsub_v1

# Publisher with ordering key (guarantees order within key)
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path('project-id', 'orders')

future = publisher.publish(
    topic_path,
    data=json.dumps(order).encode('utf-8'),
    ordering_key=order['customer_id'],  # ordered per customer
)

# Exactly-once delivery (subscriber side)
subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path('project-id', 'orders-sub')

# BigQuery subscription: direct write to BigQuery table
# gcloud pubsub subscriptions create orders-bq-sub \
#   --topic=orders \
#   --bigquery-table=project:dataset.orders_raw \
#   --use-topic-schema
```

## RabbitMQ Streams

```bash
# Enable streams plugin
rabbitmq-plugins enable rabbitmq_stream

# Declare stream with retention
rabbitmqctl declare_stream --vhost / orders \
  --max-length-bytes 10GB \
  --max-age 7D \
  --max-segment-size 500MB
```

```java
// RabbitMQ Stream client
Environment environment = Environment.builder()
    .host("rabbitmq")
    .port(5552)
    .build();

Producer producer = environment.producerBuilder()
    .stream("orders")
    .build();

// Consumer with offset tracking
Consumer consumer = environment.consumerBuilder()
    .stream("orders")
    .name("order-processor")  // enables offset tracking
    .autoTrackingStrategy()
    .builder()
    .messageHandler((context, message) -> {
        processOrder(new String(message.getBodyAsBinary()));
    })
    .build();

// Super streams: partitioned streams for horizontal scaling
environment.streamCreator().name("orders").superStream().partitions(12).creator().create();
```

## EventStoreDB

### Event Sourcing and Projections

```csharp
// Append events to a stream
var client = new EventStoreClient(EventStoreClientSettings.Create("esdb://localhost:2113?tls=false"));

var orderCreated = new OrderCreated(orderId, customerId, items, total);
var eventData = new EventData(
    Uuid.NewUuid(),
    "OrderCreated",
    JsonSerializer.SerializeToUtf8Bytes(orderCreated)
);

await client.AppendToStreamAsync(
    $"order-{orderId}",
    StreamState.NoStream,  // optimistic concurrency
    new[] { eventData }
);

// Read stream (rebuild aggregate state)
var events = client.ReadStreamAsync(Direction.Forwards, $"order-{orderId}", StreamPosition.Start);
var order = new Order();
await foreach (var resolved in events) {
    order.Apply(resolved.Event);
}

// Catch-up subscription (process all events from start, then live)
await client.SubscribeToAllAsync(
    FromAll.Start,
    async (subscription, resolved, ct) => {
        await projectionHandler.Handle(resolved.Event);
    },
    filterOptions: new SubscriptionFilterOptions(
        EventTypeFilter.ExcludeSystemEvents()
    )
);
```

### Projections

```javascript
// Built-in projection: aggregate order totals per customer
fromStream('$ce-order')
    .when({
        $init: () => ({ customers: {} }),
        OrderCreated: (state, event) => {
            const cid = event.body.customerId;
            if (!state.customers[cid]) state.customers[cid] = { total: 0, count: 0 };
            state.customers[cid].total += event.body.amount;
            state.customers[cid].count += 1;
        }
    });
```

## Memphis

### Modern Kafka Alternative

```bash
# Create station (topic equivalent)
memphis station create orders \
  --retention-type=messages \
  --retention-value=1000000 \
  --storage-type=disk \
  --replicas=3

# Schemaverse: enforce schema on station
memphis schema create order-schema \
  --type=json \
  --schema-path=./order.schema.json

memphis schema attach order-schema --station=orders
```

```python
# Memphis Python SDK
from memphis import Memphis

memphis = Memphis()
await memphis.connect(host="localhost", username="root", password="memphis")

# Producer
producer = await memphis.producer(station_name="orders", producer_name="order-service")
await producer.produce({"order_id": "123", "amount": 99.99})

# Consumer with dead-letter station (automatic poison message handling)
consumer = await memphis.consumer(
    station_name="orders",
    consumer_name="order-processor",
    consumer_group="processors",
    max_msg_deliveries=5  # after 5 failures -> dead-letter station
)
```

## Event-Driven Architecture Patterns

### Pattern 1: Event Sourcing + CQRS

```
Command -> Aggregate -> Event Store (EventStoreDB/Kafka)
                            |
                            v
                     Projection -> Read Model (PostgreSQL/Redis)
                            |
                            v
                     Query API -> Client
```

### Pattern 2: CDC Pipeline (Change Data Capture)

```
PostgreSQL -> Debezium -> Kafka -> Flink/Materialize -> Analytics DB
                           |
                           +-> Elasticsearch (search index)
                           +-> Redis (cache invalidation)
```

### Pattern 3: Saga Pattern (Distributed Transactions)

```
Order Service -> [OrderCreated] -> Payment Service
                                        |
                                   [PaymentConfirmed]
                                        |
                                   Inventory Service
                                        |
                                   [InventoryReserved]
                                        |
                                   Shipping Service
                                        |
                                   [OrderShipped]
```

### Pattern 4: Event Mesh (Multi-Region)

```
Region A (Kafka) <-- MirrorMaker 2 / Pulsar Geo-Rep --> Region B (Kafka)
       |                                                        |
       v                                                        v
  Local Consumers                                        Local Consumers
```

## Exactly-Once Semantics Comparison

| Platform | Producer Idempotence | Consumer Exactly-Once | End-to-End EOS |
|----------|--------------------|-----------------------|----------------|
| Kafka | enable.idempotence=true | Transactional consumer | Read-process-write in transaction |
| Pulsar | Dedup by sequence ID | Transaction API | Pulsar transactions |
| Redpanda | Kafka-compatible EOS | Kafka-compatible EOS | Kafka-compatible EOS |
| Flink | Checkpointing | Checkpointed offsets | Two-phase commit sinks |
| Kinesis | No native | KCL checkpointing | At-least-once + dedup |
| Pub/Sub | No native | Exactly-once delivery | Dataflow exactly-once |
| Event Hubs | No native | Checkpointing | At-least-once + dedup |

## Operational Best Practices

### Monitoring Metrics

- **Kafka**: consumer lag, under-replicated partitions, request latency, disk usage, ISR shrink rate
- **Pulsar**: backlog size, publish/dispatch rate, storage size, BookKeeper journal latency
- **Flink**: checkpoint duration, checkpoint size, back pressure, record throughput
- **General**: end-to-end latency (publish to consume), message throughput, error rate, dead-letter queue depth

### Capacity Planning

```bash
# Kafka: estimate partition count
# target_throughput / per_partition_throughput = min_partitions
# 100 MB/s / 10 MB/s = 10 partitions (minimum)
# Account for consumer parallelism: max(throughput_partitions, consumer_count)

# Kafka: estimate disk
# daily_data = messages_per_second * avg_message_size * 86400
# total_disk = daily_data * retention_days * replication_factor * 1.1 (overhead)
```

### Schema Evolution Strategy

- Use Schema Registry with FULL_TRANSITIVE compatibility
- Add fields with defaults (backward compatible)
- Never remove required fields (use deprecation)
- Use union types for optional fields (Avro) or optional keyword (Protobuf)
- Version topics when breaking changes are unavoidable: `orders.v2`
- Test schema compatibility in CI/CD pipeline

For detailed references, see the alpha-core database-advisor skill for cross-cutting database patterns.
