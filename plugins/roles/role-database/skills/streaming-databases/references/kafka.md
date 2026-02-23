# Apache Kafka

## When to load
Load when configuring Kafka topics/partitions, KRaft mode, exactly-once semantics, consumer group rebalancing, Kafka Streams DSL, Connect/Debezium CDC, Schema Registry, tiered storage, or MirrorMaker 2.

## Topic and Partition Design

```bash
kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic orders \
  --partitions 12 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config retention.ms=604800000 \
  --config cleanup.policy=delete \
  --config compression.type=zstd

# Sizing guidance:
# - Start with num_consumers * 2-3 partitions
# - Each partition handles ~10 MB/s throughput
# - Max partitions per broker: ~4000 (KRaft), ~2000 (ZooKeeper)
# - Partition key: high cardinality, even distribution
```

## KRaft Mode (No ZooKeeper)

```properties
# server.properties for KRaft
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@node1:9093,2@node2:9093,3@node3:9093
controller.listener.names=CONTROLLER
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
log.dirs=/var/kafka-logs
# Migration: snapshot -> start controllers -> migrate brokers -> remove ZK
```

## Exactly-Once Semantics (EOS)

```java
Properties props = new Properties();
props.put("bootstrap.servers", "broker:9092");
props.put("enable.idempotence", true);
props.put("acks", "all");
props.put("transactional.id", "order-processor-1");
props.put("max.in.flight.requests.per.connection", 5);

KafkaProducer<String, Order> producer = new KafkaProducer<>(props);
producer.initTransactions();

try {
    producer.beginTransaction();
    producer.send(new ProducerRecord<>("orders", order.getId(), order));
    producer.sendOffsetsToTransaction(offsets, consumerGroupMetadata);
    producer.commitTransaction();
} catch (ProducerFencedException e) {
    producer.close();
} catch (KafkaException e) {
    producer.abortTransaction();
}
```

## Consumer Group Rebalancing

```java
// Cooperative sticky: avoid stop-the-world rebalances
props.put("partition.assignment.strategy",
    "org.apache.kafka.clients.consumer.CooperativeStickyAssignor");
// Static membership: reduce rebalances during rolling deploys
props.put("group.instance.id", "consumer-host-1");
props.put("session.timeout.ms", 60000);

// Exactly-once read-process-write loop
consumer.subscribe(List.of("input-topic"));
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    producer.beginTransaction();
    for (ConsumerRecord<String, String> record : records) {
        producer.send(new ProducerRecord<>("output-topic", process(record)));
    }
    producer.sendOffsetsToTransaction(currentOffsets(records), consumer.groupMetadata());
    producer.commitTransaction();
}
```

## Kafka Streams DSL

```java
StreamsBuilder builder = new StreamsBuilder();

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

## Kafka Connect (Debezium CDC Source)

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

## Schema Registry and Cross-Cluster Replication

```bash
# Register Avro schema (FULL_TRANSITIVE compatibility recommended)
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema": "{\"type\":\"record\",\"name\":\"Order\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}"}' \
  http://schema-registry:8081/subjects/orders-value/versions

curl -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "FULL_TRANSITIVE"}' \
  http://schema-registry:8081/config/orders-value
```

```properties
# MirrorMaker 2 cross-cluster replication
clusters=source,target
source.bootstrap.servers=source-kafka:9092
target.bootstrap.servers=target-kafka:9092
source->target.enabled=true
source->target.topics=orders.*
replication.factor=3
sync.topic.configs.enabled=true
sync.group.offsets.enabled=true
```
