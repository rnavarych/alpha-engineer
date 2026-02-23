# Kafka Topic Design

## When to load
Load when designing Kafka topics, choosing partition strategies, or planning retention policies.

## Topic Naming Convention

```
<domain>.<entity>.<event-type>

Examples:
  orders.order.created
  orders.order.updated
  payments.payment.processed
  users.user.signup
  analytics.pageview.tracked

Avoid:
  order_created (no domain context)
  prod.orders (environment prefix — use separate clusters)
  OrderCreatedEvent (camelCase, inconsistent)
```

## Partition Strategy

```
Partitions = unit of parallelism
  1 partition = 1 consumer per consumer group
  More partitions = more parallelism = more resources

Sizing:
  Start: max(expected throughput / partition throughput, consumer count)
  Single partition: ~10 MB/s write, ~30 MB/s read (typical)

  Example: 100 MB/s throughput, 10 consumers
    → max(100/10, 10) = 10 partitions
    → Start with 12 (round up, room to grow)

Rules:
  ✅ You CAN increase partitions later
  ❌ You CANNOT decrease partitions
  ❌ Increasing partitions breaks key ordering
  → Choose partition count carefully for keyed topics
```

## Partition Key Selection

```
Key → hash(key) % partitions → partition
Same key = same partition = guaranteed order

Good keys:
  user_id     → all events for a user in order
  order_id    → all order state changes in order
  tenant_id   → all tenant data co-located
  device_id   → all device telemetry in order

Bad keys:
  timestamp   → hot partition (current time gets all traffic)
  null        → round-robin (no ordering guarantee)
  country     → skewed (US partition 10x larger)
```

```typescript
// Producer with key
await producer.send({
  topic: 'orders.order.created',
  messages: [
    {
      key: order.userId,    // partition by user
      value: JSON.stringify(order),
      headers: {
        'event-type': 'order.created',
        'correlation-id': correlationId,
        'timestamp': Date.now().toString(),
      },
    },
  ],
});
```

## Retention & Compaction

```
Retention (delete policy — default):
  retention.ms = 604800000  (7 days)
  retention.bytes = -1       (unlimited by size)
  → Old messages deleted after retention period

Compaction (compact policy):
  → Keeps latest value per key forever
  → Perfect for: user profiles, config, entity state

  cleanup.policy = compact
  min.cleanable.dirty.ratio = 0.5
  delete.retention.ms = 86400000  (tombstone retention)

Hybrid (compact,delete):
  → Compact + delete after retention period
  → Keeps latest per key but only within retention window
```

## Topic Configuration

```
# High-throughput event stream
bin/kafka-topics.sh --create \
  --topic analytics.pageview.tracked \
  --partitions 24 \
  --replication-factor 3 \
  --config retention.ms=259200000 \     # 3 days
  --config compression.type=lz4 \       # fast compression
  --config max.message.bytes=1048576    # 1MB max

# Entity state (compacted)
bin/kafka-topics.sh --create \
  --topic users.user.profile \
  --partitions 12 \
  --replication-factor 3 \
  --config cleanup.policy=compact \
  --config min.compaction.lag.ms=3600000  # 1h before compaction

# Dead letter queue
bin/kafka-topics.sh --create \
  --topic orders.order.created.dlq \
  --partitions 6 \
  --replication-factor 3 \
  --config retention.ms=2592000000      # 30 days
```

## Replication

```
replication.factor = 3 (production minimum)
min.insync.replicas = 2

Broker failure scenarios with RF=3, ISR=2:
  3 brokers alive: writes succeed (3 in-sync)
  2 brokers alive: writes succeed (2 >= min.insync)
  1 broker alive:  writes FAIL (1 < min.insync)

  acks=all: producer waits for all ISR replicas
  acks=1:   producer waits for leader only (risk of data loss)
  acks=0:   fire and forget (max throughput, may lose data)
```

## Anti-patterns
- Single partition for ordered topics with high throughput → bottleneck
- Using timestamps as partition keys → hot partitions
- No DLQ for failed messages → silent data loss
- replication.factor=1 in production → data loss on broker failure
- Huge messages (>1MB) → use claim check pattern (store in S3, send reference)

## Quick reference
```
Naming: domain.entity.event-type (lowercase, dot-separated)
Partitions: max(throughput/10MB, consumer count), can only increase
Key: entity ID for ordering guarantee, avoid skewed keys
Retention: 7 days default, compact for entity state
Replication: RF=3, min.insync=2, acks=all for durability
Compression: lz4 (fast) or zstd (better ratio) in production
DLQ: <topic>.dlq for failed messages, 30-day retention
Max message: 1MB default, use claim check for larger
```
