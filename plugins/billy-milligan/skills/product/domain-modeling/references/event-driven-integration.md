# Event-Driven Context Integration

## When to load
Load when designing cross-context communication, choosing between synchronous calls and domain events, implementing the transactional outbox pattern, or publishing a typed event schema as a published language between bounded contexts.

---

## Why Events Over Synchronous Calls

Prefer events over synchronous calls for cross-context integration. Events decouple contexts in time and reduce coupling.

- **Synchronous call**: Orders calls Payments directly → Orders is blocked until Payments responds; if Payments is down, Orders fails
- **Event**: Orders publishes `OrderPlaced`; Payments, Shipping, and Notifications each consume it independently → failure in one consumer doesn't affect the others

---

## Event Schema as Published Language

```typescript
// Orders context publishes events — doesn't know who consumes them
// Event schema is the "published language" between contexts

export interface OrderPlacedEvent {
  type: 'order.placed';
  version: '1.0';
  payload: {
    orderId: string;
    customerId: string;
    items: Array<{
      productId: string;
      sku: string;
      name: string;
      quantity: number;
      unitPriceCents: number;
      currency: string;
    }>;
    totalCents: number;
    currency: string;
    placedAt: string;  // ISO 8601
  };
}

// Catalog context consumes event — reserves inventory
// Shipping context consumes event — creates shipment task
// Notifications context consumes event — sends confirmation email
// Each context independently reacts; Orders doesn't know or care
```

---

## Transactional Outbox Pattern

The dual-write problem: if you update state in the DB and then publish an event to a message broker, one can succeed and the other fail — state and events go out of sync.

The transactional outbox pattern solves this by writing the event into the same DB transaction as the state change. A separate process reads the outbox and publishes to the broker.

```typescript
// Publishing with transactional outbox pattern
// Event and state change in same DB transaction — no dual write problem
await db.transaction(async (tx) => {
  await tx.update(orders).set({ status: 'placed' }).where(eq(orders.id, orderId));
  await tx.insert(outboxMessages).values({
    topic: 'order.placed',
    payload: JSON.stringify(orderPlacedEvent),
    aggregateId: orderId,
    createdAt: new Date(),
  });
});

// Separate outbox relay process:
// SELECT * FROM outbox_messages WHERE published_at IS NULL ORDER BY created_at LIMIT 100
// → publish each to message broker
// → mark as published_at = NOW()
```

---

## Event Versioning

Events are a breaking change boundary. Consumers depend on the schema. When you need to change an event:

```
v1.0 → v1.1: additive changes only (new optional fields) — backward compatible
v1.0 → v2.0: breaking change (renamed fields, removed fields, structural change)
  - Publish both v1.0 and v2.0 during migration window
  - Migrate all consumers to v2.0
  - Deprecate and stop publishing v1.0
```

---

## Anti-Patterns

### Synchronous Calls for Cross-Context Integration
Calling another context's service synchronously couples your availability to theirs. One slow downstream service degrades your entire context. Use events for non-critical paths; use synchronous calls only when you need an immediate response (e.g., payment authorization before confirming an order).

### Fat Events
Publishing an event that contains the full aggregate state ("here is the entire order object"). Consumers then depend on all fields, making the event schema a de facto shared model. Publish only the fields the event actually describes.

### Event Sourcing Without Need
Using event sourcing (storing events as the source of truth) when a simple outbox + domain events pattern would do. Event sourcing is complex. Use it only when you need full audit history or temporal queries on state.

---

## Quick Reference

```
Events vs sync calls: events decouple in time — prefer for non-critical cross-context integration
Transactional outbox: write event to DB in same transaction as state change — no dual-write risk
Published language: event schema is a contract — version it like an API
Event versioning: additive changes = backward compatible; structural changes = new major version
Fat events: anti-pattern — publish only what the event describes, not the full aggregate
```
