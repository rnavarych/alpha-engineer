# Flink, Materialize, and RisingWave

## When to load
Load when implementing stream processing with Apache Flink (DataStream API, checkpointing, SQL, CDC), Materialize incremental materialized views, or RisingWave distributed streaming SQL.

## Apache Flink: DataStream API and Checkpointing

```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

// Exactly-once with S3-backed checkpoints
env.enableCheckpointing(10000, CheckpointingMode.EXACTLY_ONCE);
env.getCheckpointConfig().setCheckpointStorage("s3://flink-checkpoints/");
env.getCheckpointConfig().setMinPauseBetweenCheckpoints(5000);
env.getCheckpointConfig().setTolerableCheckpointFailureNumber(3);

// Kafka source with watermarks for event-time processing
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

## Flink SQL: Windowed Aggregation and CDC

```sql
-- Table backed by Kafka
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
    id INT, status STRING, amount DECIMAL(12, 2),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = 'postgres', 'port' = '5432',
    'username' = 'flink', 'password' = 'secret',
    'database-name' = 'shop', 'schema-name' = 'public',
    'table-name' = 'orders', 'slot.name' = 'flink_slot'
);
```

## Materialize: Incremental Materialized Views

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

-- Incrementally maintained view (millisecond freshness)
CREATE MATERIALIZED VIEW order_dashboard AS
SELECT
    c.name AS customer_name,
    COUNT(*) AS total_orders,
    SUM(o.amount) AS total_spent,
    MAX(o.created_at) AS last_order
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.name;

SELECT * FROM order_dashboard WHERE total_spent > 1000;

-- Sink results back to Kafka
CREATE SINK dashboard_sink
  FROM order_dashboard
  INTO KAFKA CONNECTION kafka_conn (TOPIC 'order-dashboard-updates')
  FORMAT JSON ENVELOPE DEBEZIUM;
```

## RisingWave: Distributed Streaming SQL

```sql
-- Source from Kafka
CREATE SOURCE orders (
    order_id VARCHAR, customer_id VARCHAR,
    amount DECIMAL, order_time TIMESTAMPTZ
) WITH (
    connector = 'kafka',
    topic = 'orders',
    properties.bootstrap.server = 'broker:9092'
) FORMAT PLAIN ENCODE JSON;

-- Tumbling window materialized view
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
