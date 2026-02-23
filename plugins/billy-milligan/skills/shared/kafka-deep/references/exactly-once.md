# Kafka Exactly-Once Semantics

## When to load
Load when implementing transactional messaging, deduplication, or exactly-once processing guarantees.

## Delivery Guarantees Spectrum

```
At-most-once:  Fire and forget. May lose messages.
  Producer: acks=0
  Consumer: auto-commit before processing

At-least-once: No data loss, but duplicates possible.
  Producer: acks=all, retries=MAX
  Consumer: commit AFTER processing
  → Most common in practice

Exactly-once:  No loss, no duplicates.
  Producer: idempotent + transactional
  Consumer: read_committed + transactional sink
  → Highest overhead, use only when needed
```

## Idempotent Producer

```typescript
// Enable idempotent producer (deduplication at broker level)
const producer = kafka.producer({
  idempotent: true,    // enables exactly-once per partition
  maxInFlightRequests: 5, // max with idempotent=true
  // Broker assigns ProducerID + sequence number
  // Duplicates detected and discarded automatically
});

// What it prevents:
// Producer sends message → network timeout → retries → broker already received
// Without idempotent: duplicate message stored
// With idempotent: broker detects duplicate, returns success without storing
```

## Transactional Producer

```typescript
// Transactions: atomic writes across multiple partitions/topics
const producer = kafka.producer({
  idempotent: true,
  transactionalId: 'order-processor-tx-1', // unique per producer instance
  maxInFlightRequests: 1,
});

await producer.connect();

// Read-process-write pattern (consume-transform-produce)
const transaction = await producer.transaction();

try {
  // Send to multiple topics atomically
  await transaction.send({
    topic: 'orders.order.confirmed',
    messages: [{ key: orderId, value: JSON.stringify(confirmedOrder) }],
  });

  await transaction.send({
    topic: 'payments.payment.initiated',
    messages: [{ key: orderId, value: JSON.stringify(payment) }],
  });

  // Commit consumer offset as part of transaction
  await transaction.sendOffsets({
    consumerGroupId: 'order-processor',
    topics: [{
      topic: 'orders.order.created',
      partitions: [{ partition: 0, offset: (Number(lastOffset) + 1).toString() }],
    }],
  });

  await transaction.commit();
} catch (error) {
  await transaction.abort();
  throw error;
}
```

## Consumer with Read-Committed Isolation

```typescript
// Consumer that only reads committed transactional messages
const consumer = kafka.consumer({
  groupId: 'downstream-service',
  readUncommitted: false,  // default: only read committed
  // Messages from aborted transactions are skipped
  // Non-transactional messages are read normally
});
```

## Application-Level Exactly-Once (Outbox Pattern)

```typescript
// When exactly-once spans Kafka + external system (e.g., database)
// Use Transactional Outbox pattern

// Step 1: Write to DB + outbox in same DB transaction
async function createOrder(order: Order) {
  await db.transaction(async (tx) => {
    // Business write
    await tx.orders.create(order);

    // Outbox entry (same DB transaction)
    await tx.outbox.create({
      id: randomUUID(),
      aggregateType: 'order',
      aggregateId: order.id,
      eventType: 'order.created',
      payload: JSON.stringify(order),
      createdAt: new Date(),
      published: false,
    });
  });
}

// Step 2: Outbox relay publishes to Kafka
async function outboxRelay() {
  const unpublished = await db.outbox.findMany({
    where: { published: false },
    orderBy: { createdAt: 'asc' },
    take: 100,
  });

  for (const event of unpublished) {
    await producer.send({
      topic: `${event.aggregateType}.${event.aggregateType}.${event.eventType}`,
      messages: [{
        key: event.aggregateId,
        value: event.payload,
        headers: { 'idempotency-key': event.id },
      }],
    });

    await db.outbox.update({
      where: { id: event.id },
      data: { published: true },
    });
  }
}

// Alternative: Use Debezium CDC to capture outbox changes automatically
```

## Consumer-Side Deduplication

```typescript
// When broker-level exactly-once isn't sufficient
async function processWithDedup(message: KafkaMessage) {
  const idempotencyKey = message.headers['idempotency-key']?.toString()
    || `${message.topic}-${message.partition}-${message.offset}`;

  // Check if already processed (Redis or DB)
  const processed = await redis.set(
    `processed:${idempotencyKey}`, '1', 'NX', 'EX', 86400
  );

  if (!processed) {
    // Already processed — skip
    return;
  }

  try {
    await processOrder(JSON.parse(message.value.toString()));
  } catch (error) {
    // Remove dedup key on failure so retry can succeed
    await redis.del(`processed:${idempotencyKey}`);
    throw error;
  }
}
```

## Anti-patterns
- Using transactions for every message → 30-50% throughput overhead, often unnecessary
- Relying solely on Kafka transactions for external systems → only works within Kafka
- No timeout on transactions → holds resources, blocks other producers
- Using same transactionalId across instances → fencing, only one active at a time

## Quick reference
```
At-least-once: acks=all + manual commit (sufficient for most cases)
Idempotent producer: dedup retries per partition (free, always enable)
Transactions: atomic writes across partitions/topics + offset commit
Read-committed: consumer skips aborted transaction messages
Outbox pattern: DB transaction + outbox table → relay to Kafka
Consumer dedup: idempotency key in Redis/DB, NX for atomic check
Throughput cost: transactions ~30-50% overhead vs non-transactional
Design principle: prefer idempotent consumers over exactly-once infra
```
