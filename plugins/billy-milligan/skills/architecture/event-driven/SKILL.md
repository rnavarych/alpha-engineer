---
name: event-driven
description: |
  Event-driven architecture: outbox pattern with real TypeScript, saga patterns
  (choreography vs orchestration), idempotent consumers with Redis dedup, DLQ config,
  Kafka/RabbitMQ/SQS patterns, schema versioning, event ordering guarantees.
  Use when building async workflows, distributed transactions, microservice communication.
allowed-tools: Read, Grep, Glob
---

# Event-Driven Architecture

## When to Use This Skill
- Building async workflows between services
- Handling distributed transactions without 2PC
- Implementing reliable event delivery (outbox pattern)
- Designing Kafka topics, consumer groups, DLQ
- Schema evolution without breaking consumers

## Core Principles

1. **Events are facts, commands are intentions** — `OrderPlaced` (fact) vs `PlaceOrder` (command)
2. **At-least-once delivery is the default** — design consumers to be idempotent
3. **The outbox pattern is mandatory for transactional guarantees** — never publish events outside a transaction
4. **Events should be self-contained** — consumer should not need to call back the producer
5. **Schema versioning is not optional** — consumers break when producers change event shape

---

## Patterns ✅

### Outbox Pattern (Transaction + Event Atomicity)

```typescript
// Event table lives in same DB as domain data
// Migration:
// CREATE TABLE outbox_events (
//   id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//   topic        TEXT NOT NULL,
//   aggregate_id TEXT NOT NULL,
//   payload      JSONB NOT NULL,
//   created_at   TIMESTAMPTZ DEFAULT NOW(),
//   published_at TIMESTAMPTZ,
//   retry_count  INT DEFAULT 0
// );
// CREATE INDEX idx_outbox_unpublished ON outbox_events(created_at)
//   WHERE published_at IS NULL;

async function placeOrder(input: PlaceOrderInput, db: Database) {
  return db.transaction(async (tx) => {
    const order = await tx.insert(orders).values({
      id: generateId(),
      userId: input.userId,
      total: calculateTotal(input.items),
      status: 'pending',
    }).returning().then(r => r[0]);

    // Publish to outbox in the SAME transaction
    await tx.insert(outboxEvents).values({
      topic: 'orders.placed',
      aggregateId: order.id,
      payload: {
        orderId: order.id,
        userId: order.userId,
        total: order.total,
        items: input.items,
        version: 1,
      },
    });

    return order;
  });
}

// Relay worker — polls and publishes
async function relayOutboxEvents(kafka: Kafka, db: Database) {
  while (true) {
    const events = await db
      .select()
      .from(outboxEvents)
      .where(isNull(outboxEvents.publishedAt))
      .orderBy(asc(outboxEvents.createdAt))
      .limit(100)
      .for('update skip locked');  // Advisory lock — prevents double send

    if (events.length === 0) {
      await sleep(200);  // Poll every 200ms when idle
      continue;
    }

    for (const event of events) {
      try {
        await kafka.producer().send({
          topic: event.topic,
          messages: [{ key: event.aggregateId, value: JSON.stringify(event.payload) }],
        });
        await db.update(outboxEvents)
          .set({ publishedAt: new Date() })
          .where(eq(outboxEvents.id, event.id));
      } catch (err) {
        await db.update(outboxEvents)
          .set({ retryCount: sql`retry_count + 1` })
          .where(eq(outboxEvents.id, event.id));
        logger.error({ err, eventId: event.id }, 'Outbox relay failed');
      }
    }
  }
}
```

### Idempotent Consumer with Redis Deduplication

```typescript
// Every consumer must be idempotent — at-least-once delivery guarantees duplicates
async function handleOrderPlaced(message: KafkaMessage) {
  const event = JSON.parse(message.value!.toString()) as OrderPlacedEvent;
  const dedupeKey = `processed:${message.topic}:${event.orderId}:${message.offset}`;

  // Check if already processed
  const alreadyProcessed = await redis.set(dedupeKey, '1', 'NX', 'EX', 86400);
  if (!alreadyProcessed) {
    logger.info({ orderId: event.orderId }, 'Duplicate event, skipping');
    return;  // Idempotent — safe to skip
  }

  try {
    await fulfillmentService.createFulfillmentJob(event.orderId, event.items);
  } catch (err) {
    // Delete dedupeKey so retry can process it
    await redis.del(dedupeKey);
    throw err;  // Rethrow to trigger Kafka retry/DLQ
  }
}
```

### Saga Pattern: Choreography vs Orchestration

**Choreography** (event chain) — services react to each other's events:

```
OrderService   InventoryService   PaymentService   FulfillmentService
     |                |                 |                  |
  PlaceOrder          |                 |                  |
     |→ OrderCreated →|                 |                  |
     |                |→ StockReserved →|                  |
     |                |                |→ PaymentCaptured →|
     |                |                |                  |→ FulfillOrder
```

Good for: <4 services, simple linear flows.
Bad for: Complex rollbacks, debugging (no central view).

**Orchestration** (central coordinator) — saga orchestrator drives the flow:

```typescript
class OrderSaga {
  async run(orderId: string) {
    try {
      await this.step('reserve_inventory', () =>
        inventoryService.reserve(orderId)
      );
      await this.step('capture_payment', () =>
        paymentService.capture(orderId)
      );
      await this.step('create_fulfillment', () =>
        fulfillmentService.create(orderId)
      );
      await this.complete(orderId);
    } catch (err) {
      await this.compensate(orderId);
    }
  }

  async compensate(orderId: string) {
    const completedSteps = await this.getCompletedSteps(orderId);
    // Run compensation in reverse order
    for (const step of completedSteps.reverse()) {
      await this.compensationHandlers[step](orderId);
    }
  }
}
```

Good for: Complex flows, easy debugging, explicit rollback.
Use Temporal or AWS Step Functions for durable saga orchestration in production.

### Dead Letter Queue (DLQ) Configuration

```typescript
// KafkaJS consumer with DLQ
const consumer = kafka.consumer({ groupId: 'order-processor' });

await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    const retryCount = parseInt(message.headers?.['retry-count']?.toString() ?? '0');

    try {
      await processMessage(message);
    } catch (err) {
      if (retryCount >= 3) {
        // Send to DLQ after 3 retries
        await producer.send({
          topic: `${topic}.dlq`,
          messages: [{
            key: message.key,
            value: message.value,
            headers: {
              ...message.headers,
              'original-topic': topic,
              'original-partition': partition.toString(),
              'error-message': String(err),
              'failed-at': new Date().toISOString(),
            },
          }],
        });
        logger.error({ topic, err }, 'Message sent to DLQ');
      } else {
        // Retry with incremented counter
        await producer.send({
          topic,
          messages: [{
            key: message.key,
            value: message.value,
            headers: { ...message.headers, 'retry-count': (retryCount + 1).toString() },
          }],
        });
        await sleep(1000 * Math.pow(2, retryCount));  // Exponential backoff
      }
    }
  },
});
```

### Schema Versioning (Backward Compatibility)

```typescript
// Always include version field in event payload
interface OrderPlacedEventV1 {
  version: 1;
  orderId: string;
  userId: string;
  total: number;
}

interface OrderPlacedEventV2 {
  version: 2;
  orderId: string;
  userId: string;
  total: number;
  currency: string;  // Added in v2
  items: OrderItem[];  // Added in v2
}

// Consumer handles multiple versions
function handleOrderPlaced(event: OrderPlacedEventV1 | OrderPlacedEventV2) {
  const normalizedEvent = normalizeOrderEvent(event);
  // Process normalized event...
}

function normalizeOrderEvent(event: OrderPlacedEventV1 | OrderPlacedEventV2) {
  if (event.version === 1) {
    return { ...event, currency: 'USD', items: [] };  // Default old fields
  }
  return event;
}
```

---

## Anti-Patterns ❌

### Publishing Events Outside a Transaction
**What it is**: `await kafka.publish(event)` after `await db.save(order)` — two separate operations.
**What breaks**: DB saves, Kafka publish fails → event never sent. OR: Kafka publishes, DB write fails → event without corresponding record.
**Fix**: Outbox pattern — always transactional.

### Event Without Self-Contained Data
```typescript
// Wrong — consumer must call back producer
{ "orderId": "ord_123", "type": "OrderPlaced" }
// Consumer must GET /orders/ord_123 — extra network call, coupling

// Correct — consumer has all needed data
{
  "orderId": "ord_123",
  "type": "OrderPlaced",
  "total": 5000,
  "currency": "USD",
  "userId": "usr_456",
  "items": [...]
}
```

### Synchronous Event Chains (Choreography Hell)
**What it is**: A → B → C → D → E in a choreography saga.
**What breaks**: If E fails, compensating all the way back to A is nearly impossible to reason about. Debugging requires correlating events across 5 services.
**Fix**: Use orchestration for sagas with >3 steps.

---

## Quick Reference

```
Outbox polling: 100–500ms, FOR UPDATE SKIP LOCKED prevents double-send
Idempotency TTL: 24h (covers all reasonable redelivery windows)
DLQ after: 3 retries with exponential backoff (1s, 2s, 4s)
Choreography: good for ≤3 services, linear flows
Orchestration: use for ≥4 steps or complex compensation
Schema versioning: always include version field, consumers handle multiple versions
Events = past facts, Commands = future intentions
```
