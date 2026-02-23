# Pulsar, Redpanda, and NATS / JetStream

## When to load
Load when working with Pulsar multi-tenancy, geo-replication, Functions, or SQL; Redpanda Kafka-compatible setup with tiered storage; or NATS JetStream streams, consumers, KV store, and object store.

## Apache Pulsar: Multi-Tenant Architecture

```bash
# Create tenant with allowed clusters
bin/pulsar-admin tenants create finance \
  --allowed-clusters us-east,eu-west \
  --admin-roles finance-admin

# Create namespace with policies
bin/pulsar-admin namespaces create finance/payments
bin/pulsar-admin namespaces set-retention finance/payments --size 10G --time 7d
bin/pulsar-admin namespaces set-schema-validation-enforce finance/payments --enable
bin/pulsar-admin namespaces set-backlog-quota finance/payments \
  --limit 5G --policy producer_request_hold

# Geo-replication across clusters
bin/pulsar-admin namespaces set-clusters finance/payments \
  --clusters us-east,eu-west,ap-south
```

## Pulsar: Functions and Topic Compaction

```java
// Pulsar Function: serverless stream processing
public class OrderEnricher implements Function<Order, EnrichedOrder> {
    @Override
    public EnrichedOrder process(Order order, Context context) {
        String customerData = context.getState("customer-" + order.getCustomerId());
        return EnrichedOrder.from(order, customerData);
    }
}
// Deploy:
// pulsar-admin functions create --jar order-enricher.jar
//   --classname OrderEnricher
//   --inputs persistent://finance/payments/orders
//   --output persistent://finance/payments/enriched-orders
```

```bash
# Topic compaction (keep latest value per key)
bin/pulsar-admin topics set-compaction-threshold \
  persistent://finance/payments/customer-state --threshold 100M
bin/pulsar-admin topics trigger-compaction \
  persistent://finance/payments/customer-state

# Pulsar SQL (Presto/Trino integration)
presto> SELECT * FROM pulsar."finance/payments"."orders"
        WHERE __publish_time__ > timestamp '2024-01-01'
        LIMIT 100;
```

## Redpanda: Kafka-Compatible, No JVM

```bash
# Single binary, C++/Seastar — drop-in Kafka replacement
rpk cluster config set enable_idempotence true
rpk cluster config set enable_transactions true

rpk topic create orders -p 12 -r 3 \
  --topic-config retention.ms=604800000 \
  --topic-config compression.type=zstd

# Tiered storage to S3
rpk cluster config set cloud_storage_enabled true
rpk cluster config set cloud_storage_bucket "redpanda-tiered"
rpk cluster config set cloud_storage_region "us-east-1"
rpk cluster config set cloud_storage_credentials_source aws_instance_metadata

# Built-in Schema Registry (Confluent-compatible)
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema":"{...}","schemaType":"PROTOBUF"}' \
  http://redpanda:8081/subjects/orders-value/versions

# Built-in Redpanda Console at http://localhost:8080
```

## NATS / JetStream: Subjects and Persistent Streams

```bash
# Core NATS: fire-and-forget pub/sub
nats pub orders.new '{"id":"123","total":99.99}'
nats sub "orders.>"  # wildcard subscription

# Queue groups: load-balanced consumers
nats sub orders.new --queue=order-processors

# JetStream: persistent streams with replay
nats stream add ORDERS \
  --subjects="orders.>" \
  --storage=file \
  --retention=limits \
  --max-bytes=10GB \
  --max-age=7d \
  --replicas=3 \
  --discard=old \
  --dupe-window=2m

nats consumer add ORDERS order-processor \
  --deliver=all \
  --ack=explicit \
  --max-deliver=5 \
  --filter="orders.created" \
  --pull
```

## NATS: KV Store and Object Store

```go
js, _ := nc.JetStream()

// KV Store (built on JetStream)
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

// Object Store (large binary objects)
os, _ := js.CreateObjectStore(&nats.ObjectStoreConfig{
    Bucket:   "uploads",
    Replicas: 3,
})
os.PutFile("report.pdf")
```
