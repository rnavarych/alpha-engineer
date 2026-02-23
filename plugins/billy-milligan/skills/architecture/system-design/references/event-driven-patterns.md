# Event-Driven Patterns

## When to load
Load when discussing async workflows, distributed transactions, outbox pattern, saga, DLQ, or event schema versioning.

## Patterns ✅

### Outbox pattern (transaction + event atomicity)
```sql
CREATE TABLE outbox_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic        TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  payload      JSONB NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  retry_count  INT DEFAULT 0
);
CREATE INDEX idx_outbox_unpublished ON outbox_events(created_at)
  WHERE published_at IS NULL;
```

```typescript
// Write domain + event in ONE transaction
async function placeOrder(input: PlaceOrderInput, db: Database) {
  return db.transaction(async (tx) => {
    const order = await tx.insert(orders).values({ ... }).returning().then(r => r[0]);
    await tx.insert(outboxEvents).values({
      topic: 'orders.placed',
      aggregateId: order.id,
      payload: { orderId: order.id, userId: order.userId, total: order.total, version: 1 },
    });
    return order;
  });
}
```
Polling interval: 100–500ms. Use `FOR UPDATE SKIP LOCKED` to prevent double-send.

### Idempotent consumer (Redis dedup)
```typescript
async function handleOrderPlaced(message: KafkaMessage) {
  const event = JSON.parse(message.value!.toString());
  const dedupeKey = `processed:${message.topic}:${event.orderId}:${message.offset}`;
  const acquired = await redis.set(dedupeKey, '1', 'NX', 'EX', 86400);
  if (!acquired) return; // Already processed
  try {
    await fulfillmentService.createJob(event.orderId, event.items);
  } catch (err) {
    await redis.del(dedupeKey); // Allow retry
    throw err;
  }
}
```

### Saga: choreography vs orchestration
- **Choreography** (event chain): services react to each other's events. Good for ≤3 services, simple linear flows.
- **Orchestration** (central coordinator): saga orchestrator drives flow with explicit compensation. Good for ≥4 steps, complex rollback. Use Temporal or AWS Step Functions in production.

### DLQ config
After 3 retries with exponential backoff (1s, 2s, 4s), send to `{topic}.dlq` with original metadata and error message.

### Schema versioning
Always include `version` field. Consumers handle multiple versions via normalizer function. New fields have defaults for backward compatibility.

## Anti-patterns ❌
- Publishing events outside a transaction → split-brain (DB saved, event lost)
- Events without self-contained data → consumer must call back producer (coupling)
- Choreography with >3 steps → compensation becomes impossible to reason about

## Quick reference
```
Outbox polling: 100–500ms, FOR UPDATE SKIP LOCKED
Idempotency TTL: 24h
DLQ: after 3 retries, exponential backoff
Choreography: ≤3 services | Orchestration: ≥4 steps
Events = past facts | Commands = future intentions
```
