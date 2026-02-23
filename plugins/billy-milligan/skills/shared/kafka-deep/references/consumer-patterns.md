# Kafka Consumer Patterns

## When to load
Load when implementing Kafka consumers, handling offsets, or designing consumer group strategies.

## Consumer Group Fundamentals

```
Topic: orders.order.created (6 partitions)
Consumer Group: order-processor

  Partition 0 ──→ Consumer A
  Partition 1 ──→ Consumer A
  Partition 2 ──→ Consumer B
  Partition 3 ──→ Consumer B
  Partition 4 ──→ Consumer C
  Partition 5 ──→ Consumer C

Rules:
  - Each partition → exactly 1 consumer in the group
  - Each consumer → 1 or more partitions
  - More consumers than partitions → idle consumers
  - Consumer dies → partitions rebalanced to remaining
```

## KafkaJS Consumer (Node.js)

```typescript
import { Kafka } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'order-service',
  brokers: ['kafka-1:9092', 'kafka-2:9092', 'kafka-3:9092'],
});

const consumer = kafka.consumer({
  groupId: 'order-processor',
  sessionTimeout: 30000,       // 30s heartbeat timeout
  heartbeatInterval: 3000,     // heartbeat every 3s
  maxBytesPerPartition: 1048576, // 1MB per partition per fetch
  retry: { retries: 5 },
});

await consumer.connect();
await consumer.subscribe({ topic: 'orders.order.created', fromBeginning: false });

await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    const order = JSON.parse(message.value.toString());
    const eventType = message.headers['event-type']?.toString();

    try {
      await processOrder(order);
      // Auto-commit (default) — offset committed after processing
    } catch (error) {
      // Failed processing — message will be redelivered
      // Consider: DLQ, retry topic, or skip with logging
      await sendToDLQ(topic, message, error);
    }
  },
});
```

## Offset Management

```typescript
// Manual commit (recommended for exactly-once semantics)
const consumer = kafka.consumer({
  groupId: 'order-processor',
  autoCommit: false,  // disable auto-commit
});

await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    await processOrder(JSON.parse(message.value.toString()));

    // Commit after successful processing
    await consumer.commitOffsets([{
      topic,
      partition,
      offset: (Number(message.offset) + 1).toString(),
    }]);
  },
});

// Batch commit (better performance)
await consumer.run({
  eachBatch: async ({ batch, resolveOffset, commitOffsetsIfNecessary }) => {
    for (const message of batch.messages) {
      await processOrder(JSON.parse(message.value.toString()));
      resolveOffset(message.offset);
    }
    await commitOffsetsIfNecessary();
  },
});
```

## Error Handling & DLQ

```typescript
async function processWithRetry(
  message: KafkaMessage,
  topic: string,
  maxRetries: number = 3
) {
  const retryCount = Number(message.headers['retry-count'] || '0');

  try {
    await processOrder(JSON.parse(message.value.toString()));
  } catch (error) {
    if (retryCount < maxRetries) {
      // Send to retry topic with delay
      await producer.send({
        topic: `${topic}.retry`,
        messages: [{
          key: message.key,
          value: message.value,
          headers: {
            ...message.headers,
            'retry-count': (retryCount + 1).toString(),
            'original-topic': topic,
            'error-message': error.message,
          },
        }],
      });
    } else {
      // Max retries exceeded → DLQ
      await producer.send({
        topic: `${topic}.dlq`,
        messages: [{
          key: message.key,
          value: message.value,
          headers: {
            ...message.headers,
            'original-topic': topic,
            'error-message': error.message,
            'failed-at': new Date().toISOString(),
          },
        }],
      });
    }
  }
}
```

## Consumer Patterns

```
1. Competing Consumers (default)
   Same group, multiple consumers → each message processed once
   Use for: work distribution, parallel processing

2. Fan-out
   Different groups on same topic → each group gets all messages
   Use for: analytics + notification + audit on same events

3. Event Sourcing Consumer
   Read from beginning, build state from events
   Consumer stores: last processed offset + built state

4. Polling Consumer
   consumer.run() with eachBatch for high throughput
   Process batches, commit per batch (not per message)
```

## Rebalancing Strategy

```
Strategies:
  RangeAssignor: contiguous partitions per consumer (default)
  RoundRobinAssignor: even distribution across consumers
  CooperativeStickyAssignor: incremental rebalance, no stop-the-world

Problem: rebalancing pauses ALL consumers in group
Solution: CooperativeStickyAssignor
  - Only reassigns partitions that moved
  - Other partitions keep processing
  - Set: partition.assignment.strategy=CooperativeStickyAssignor
```

## Anti-patterns
- Auto-commit with slow processing → offset committed before processing completes → data loss
- No DLQ → poison messages block partition forever
- Processing order dependency across partitions → use single partition or saga
- Consumer doing HTTP calls in message handler → slow, back-pressure issues
- Not handling rebalancing → duplicate processing during rebalance

## Quick reference
```
Consumer groups: each partition → 1 consumer, auto-rebalance on failure
Manual commit: commit AFTER successful processing for at-least-once
Auto-commit: simpler but risk of processing gap on crash
DLQ: retry 3x then dead-letter, include error context in headers
Batch processing: eachBatch for throughput, eachMessage for simplicity
Rebalancing: use CooperativeStickyAssignor to avoid stop-the-world
Idempotency: design consumers to handle duplicate messages safely
Lag monitoring: track consumer lag per partition (Burrow, Kafka UI)
```
