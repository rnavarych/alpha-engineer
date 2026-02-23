# Cloud Streaming Platforms

## When to load
Load when working with Amazon Kinesis (Data Streams, Firehose, KCL), Azure Event Hubs (Kafka protocol, Capture), Google Pub/Sub (ordering keys, exactly-once, BigQuery subscription), or Apache Spark Structured Streaming.

## Amazon Kinesis

```bash
# Create stream with on-demand capacity mode
aws kinesis create-stream \
  --stream-name orders \
  --stream-mode-details StreamMode=ON_DEMAND

# Enhanced fan-out: dedicated 2 MB/s throughput per consumer
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
# Event Hubs with Kafka protocol (drop-in Kafka replacement)
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
# Configurable time window and size window; output format: Avro
```

## Google Pub/Sub

```python
from google.cloud import pubsub_v1

# Publisher with ordering key (order guaranteed within key)
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path('project-id', 'orders')

future = publisher.publish(
    topic_path,
    data=json.dumps(order).encode('utf-8'),
    ordering_key=order['customer_id'],
)

# Exactly-once delivery subscriber
subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path('project-id', 'orders-sub')

# BigQuery subscription: direct write to BigQuery table
# gcloud pubsub subscriptions create orders-bq-sub \
#   --topic=orders \
#   --bigquery-table=project:dataset.orders_raw \
#   --use-topic-schema
```

## Apache Spark Structured Streaming

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

orders = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "broker:9092") \
    .option("subscribe", "orders") \
    .option("startingOffsets", "earliest") \
    .load() \
    .select(from_json(col("value").cast("string"), schema).alias("data")) \
    .select("data.*")

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
