---
name: kafka-deep
description: |
  Kafka deep-dive: topic design (partitions, replication factor), KafkaJS producer with
  idempotent writes, consumer groups with partition assignment, consumer lag monitoring,
  exactly-once semantics, schema registry, compacted topics, DLQ patterns.
  Use when designing Kafka topics, implementing producers/consumers, monitoring consumer lag.
allowed-tools: Read, Grep, Glob
---

# Kafka Deep Dive

## When to Use This Skill
- Designing topic structure (partitions, replication)
- Implementing reliable producers with idempotent writes
- Building consumer groups with proper error handling
- Monitoring consumer lag
- Choosing between Kafka, RabbitMQ, and SQS

## Core Principles

1. **Partition count determines parallelism ceiling** — 6 partitions = max 6 consumers in a group; you cannot scale beyond partition count
2. **Replication factor 3 for production** — 1 node lost: still operational; 2 nodes lost: read-only; RF=1 = data loss risk
3. **Consumer commits must happen after processing** — committing before processing = data loss on crash
4. **At-least-once is the default** — design consumers to be idempotent; dedup with Redis
5. **Consumer lag is the key operational metric** — lag >10k messages at current throughput = alert

---

## Patterns ✅

### Topic Design

```
Naming convention: [domain].[entity].[event-type]
  orders.order.placed
  orders.order.cancelled
  payments.payment.captured
  inventory.stock.updated

Partition count guidelines:
  Low traffic (<1000 msg/sec): 3–6 partitions
  Medium (1k–50k msg/sec): 12–24 partitions
  High (>50k msg/sec): 48–96 partitions
  Rule: start with 6, increase only when consumer group is hitting parallelism limit

Replication factor:
  Development: 1
  Staging: 2
  Production: 3 (minimum for HA)
  Critical data: 3 with min.insync.replicas=2

Retention:
  Event log: 7 days (default)
  Audit log: 90 days
  Compacted topics: forever (latest value per key retained)

Partition key strategy (message routing):
  Order events → key: orderId (all events for one order → same partition → ordered)
  User events → key: userId
  Random → key: null (round-robin distribution)
  WARNING: skewed keys (one popular userId) → hot partition
```

### KafkaJS Producer with Idempotent Writes

```typescript
import { Kafka, CompressionTypes } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'order-service',
  brokers: process.env.KAFKA_BROKERS!.split(','),
  ssl: true,
  sasl: {
    mechanism: 'plain',
    username: process.env.KAFKA_USERNAME!,
    password: process.env.KAFKA_PASSWORD!,
  },
  retry: {
    initialRetryTime: 100,
    retries: 8,  // Exponential backoff: 100ms, 200ms, 400ms, ...
  },
});

// Idempotent producer: exactly-once delivery to broker (not to consumers)
const producer = kafka.producer({
  idempotent: true,         // Enable idempotent writes — prevents duplicates from retries
  maxInFlightRequests: 5,   // Required with idempotent=true
});

await producer.connect();

async function publishEvent(event: DomainEvent): Promise<void> {
  await producer.send({
    topic: `${event.domain}.${event.entity}.${event.type}`,
    messages: [{
      key: event.aggregateId,        // Partition routing key
      value: JSON.stringify(event),
      headers: {
        'event-type': event.type,
        'event-version': String(event.version),
        'correlation-id': event.correlationId,
        'produced-at': new Date().toISOString(),
      },
    }],
    compression: CompressionTypes.GZIP,  // Reduce network I/O
  });
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  await producer.disconnect();
  process.exit(0);
});
```

### Consumer Group with Error Handling and DLQ

```typescript
const consumer = kafka.consumer({
  groupId: 'order-processor-v2',     // Version in groupId when changing message format
  sessionTimeout: 30_000,            // 30s — how long before rebalance on lost heartbeat
  heartbeatInterval: 3_000,          // Send heartbeat every 3s
  maxBytesPerPartition: 1_048_576,   // 1MB per partition per fetch
});

await consumer.connect();
await consumer.subscribe({
  topics: ['orders.order.placed'],
  fromBeginning: false,  // Only new messages; true = replay from start
});

const producer = kafka.producer({ idempotent: true });
await producer.connect();

await consumer.run({
  autoCommit: false,           // Manual commit — commit only after processing
  eachMessage: async ({ topic, partition, message, heartbeat }) => {
    const retryCount = parseInt(message.headers?.['retry-count']?.toString() ?? '0');
    const eventId = message.headers?.['event-id']?.toString() ?? message.offset;

    // Deduplication with Redis — at-least-once delivery can deliver duplicates
    const dedupeKey = `kafka:processed:${topic}:${partition}:${message.offset}`;
    const isNew = await redis.set(dedupeKey, '1', 'NX', 'EX', 86400);
    if (!isNew) {
      await consumer.commitOffsets([{ topic, partition, offset: (BigInt(message.offset) + 1n).toString() }]);
      return;
    }

    try {
      const event = JSON.parse(message.value!.toString());
      await processOrderEvent(event);

      // Commit only after successful processing
      await consumer.commitOffsets([{
        topic,
        partition,
        offset: (BigInt(message.offset) + 1n).toString(),
      }]);

    } catch (err) {
      if (retryCount >= 3) {
        // Send to DLQ after 3 failures
        await producer.send({
          topic: `${topic}.dlq`,
          messages: [{
            key: message.key,
            value: message.value,
            headers: {
              ...message.headers,
              'original-topic': topic,
              'original-partition': String(partition),
              'error-message': String(err),
              'failed-at': new Date().toISOString(),
              'retry-count': String(retryCount),
            },
          }],
        });
        // Commit to move past the poisoned message
        await consumer.commitOffsets([{ topic, partition, offset: (BigInt(message.offset) + 1n).toString() }]);
      } else {
        // Retry: send back to original topic with incremented count
        await producer.send({
          topic,
          messages: [{
            key: message.key,
            value: message.value,
            headers: {
              ...message.headers,
              'retry-count': String(retryCount + 1),
            },
          }],
        });
        await consumer.commitOffsets([{ topic, partition, offset: (BigInt(message.offset) + 1n).toString() }]);
      }

      // Deliver heartbeat to prevent session timeout during slow error handling
      await heartbeat();
    }
  },
});
```

### Consumer Lag Monitoring

```typescript
// Consumer lag = how many messages behind the consumer group is
// Alert when lag is high relative to throughput

async function getConsumerLag(groupId: string, topic: string): Promise<number> {
  const admin = kafka.admin();
  await admin.connect();

  try {
    const [offsets, groupOffsets] = await Promise.all([
      admin.fetchTopicOffsets(topic),
      admin.fetchOffsets({ groupId, topics: [topic] }),
    ]);

    let totalLag = 0;
    for (const partition of offsets) {
      const committed = groupOffsets[0].partitions.find(
        p => p.partition === partition.partition
      );
      const latest = BigInt(partition.high);
      const current = BigInt(committed?.offset ?? '0');
      totalLag += Number(latest - current);
    }

    return totalLag;
  } finally {
    await admin.disconnect();
  }
}

// Alert thresholds (examples):
// orders.order.placed: alert if lag > 10,000 (at 100 msg/sec = 100s behind)
// analytics.events: alert if lag > 1,000,000 (high volume, delay acceptable)
```

---

## Kafka vs RabbitMQ vs SQS

```
Kafka:
  Use when: event log (replay), high throughput (millions/day), stream processing
  Guarantees: at-least-once; exactly-once with transactions
  Retention: configurable (hours to forever)
  Ordering: per-partition

RabbitMQ:
  Use when: task queue, routing logic (topic/direct/fanout), RPC patterns
  Guarantees: at-least-once with manual acks
  Retention: until consumed (not an event log)
  Ordering: per-queue

AWS SQS:
  Use when: serverless, AWS-native, simple queue, no ops overhead
  Guarantees: at-least-once (standard) or exactly-once (FIFO)
  Retention: 1–14 days
  Ordering: FIFO queues only (limited throughput)
  SQS FIFO: 3,000 msg/sec with batching; standard: unlimited
```

---

## Anti-Patterns ❌

### Committing Before Processing
**What it is**: Commit offset → process message → crash. Message is lost.
**Fix**: Process → commit. If you crash after processing but before commit, you reprocess. Design consumers to be idempotent.

### One Partition Per Topic
**What it is**: Creating topics with 1 partition for simplicity.
**What breaks**: No parallelism — one consumer in the group can process. 100k msg/sec on one partition = bottleneck.
**Fix**: Start with 6 partitions. Use the partition count as a knob for throughput scaling.

### groupId Without Versioning
**What it is**: Using `groupId: 'processor'` and changing message schema.
**What breaks**: Old consumers with the old schema get new messages and crash (or silently fail).
**Fix**: Version the group ID when changing message format: `processor-v2`. Route to new consumer group.

---

## Quick Reference

```
Partition count: 6 (default), increase when consumer group hits ceiling
Replication factor: 3 production, min.insync.replicas=2
Naming: [domain].[entity].[event-type] — orders.order.placed
Partition key: use aggregateId for ordering guarantees per entity
Producer: idempotent=true prevents duplicates on retry
Consumer commit: after processing (not before)
DLQ: after 3 retries, with original headers preserved
Dedup TTL: 24 hours (covers redelivery windows)
Lag alert: define per topic based on throughput (e.g., lag > 10s of throughput)
Session timeout: 30s; heartbeat interval: 3s
```
