# Aggregate Design

## When to load
Load when formalizing aggregates discovered during event storming, designing command/event/rule structure for an aggregate, deriving read models from domain events, or debugging domain model discoveries like language conflicts and missing events.

---

## Command-Event-Aggregate Structure

After an event storming workshop, formalize each aggregate:

```
Aggregate: Order
─────────────────────────────────────────
Commands it handles:
  PlaceOrder(customerId, items, shippingAddress)
  AddItem(productId, quantity)
  RemoveItem(productId)
  ApplyDiscount(discountCode)
  ConfirmOrder()
  CancelOrder(reason)
  MarkShipped(trackingNumber)
  RequestReturn(itemIds, reason)

Events it produces:
  OrderCreated(orderId, customerId, createdAt)
  ItemAdded(orderId, productId, quantity, price)
  ItemRemoved(orderId, productId)
  DiscountApplied(orderId, discountCode, discountAmount)
  OrderConfirmed(orderId, total, confirmedAt)
  OrderCancelled(orderId, reason, cancelledAt)
  OrderShipped(orderId, trackingNumber, shippedAt)
  ReturnRequested(orderId, itemIds, reason, requestedAt)

Business rules enforced:
  - Cannot add items after order is confirmed
  - Cannot cancel after order is shipped
  - Discount cannot exceed order total
  - Order must have at least 1 item to confirm
  - Return can only be requested within 30 days of delivery
```

### Aggregate boundary signals from event storming
- Commands and events that cluster together and reference the same entities → same aggregate
- Commands handled by different business roles or teams → likely different aggregates
- An event in one cluster that triggers a command in another cluster → integration policy between aggregates, not shared aggregate

E-commerce aggregate boundaries discovered through event storming:
```
ORDER AGGREGATE:
  Commands: PlaceOrder, CancelOrder, MarkShipped, RequestReturn
  Events: OrderPlaced, OrderCancelled, OrderShipped, ReturnRequested
  Rules: Cannot cancel shipped order; Cannot ship cancelled order

PAYMENT AGGREGATE:
  Commands: ProcessPayment, IssueRefund, RecordChargeback
  Events: PaymentSucceeded, PaymentFailed, RefundIssued, ChargebackReceived
  Rules: Cannot refund more than charged; Cannot process payment twice

INVENTORY AGGREGATE:
  Commands: ReserveInventory, ReleaseInventory, AdjustStock
  Events: InventoryReserved, InventoryReleased, StockLow, StockOut
  Rules: Cannot reserve more than available; Low stock threshold triggers alert
```

---

## Read Model Derivation

Read models are projections of events — they serve queries and UIs, never enforce business rules.

```typescript
// Read model built from event stream
// Rebuilt by replaying events — always eventually consistent

export class OrderSummaryProjection {
  // Handles: OrderCreated, ItemAdded, OrderConfirmed, OrderShipped, OrderCancelled

  async on(event: DomainEvent): Promise<void> {
    switch (event.type) {
      case 'OrderCreated':
        await this.db.insert(orderSummaries).values({
          orderId: event.payload.orderId,
          customerId: event.payload.customerId,
          status: 'draft',
          itemCount: 0,
          totalCents: 0,
          createdAt: event.payload.createdAt,
        });
        break;

      case 'ItemAdded':
        await this.db.update(orderSummaries)
          .set({
            itemCount: sql`item_count + 1`,
            totalCents: sql`total_cents + ${event.payload.price.amount}`,
          })
          .where(eq(orderSummaries.orderId, event.payload.orderId));
        break;

      case 'OrderShipped':
        await this.db.update(orderSummaries)
          .set({
            status: 'shipped',
            trackingNumber: event.payload.trackingNumber,
            shippedAt: event.payload.shippedAt,
          })
          .where(eq(orderSummaries.orderId, event.payload.orderId));
        break;
    }
  }
}
```

---

## Common Event Storming Discoveries

Things you'll almost always find when you do this properly:

**Language conflicts:**
"Customer" in sales means someone who has paid. "Customer" in support means anyone who contacts them, paid or not. → Two concepts: `Prospect` and `Customer`.

**Missing events:**
"How does the order get shipped?" — awkward silence — "Oh, someone in the warehouse just does it." → Discovered: `PickTaskAssigned`, `ItemPicked`, `ShipmentCreated` — entire process was invisible.

**Policy hotspots:**
"When a customer is marked fraudulent, what happens to their orders?" — three different answers from three different people → Red hotspot. Requires a decision before the sprint starts.

**Aggregate boundary discovery:**
`Payment` commands and events kept appearing far from `Order` commands and events, handled by different people — strong signal they belong in separate aggregates with an integration policy between them.

---

## Anti-Patterns

### Too much detail too early
Jumping to database schemas and class hierarchies before the event timeline is complete. Let the workshop breathe — the structure emerges; don't force it.

### Read models with business logic
Read models that validate, enforce invariants, or make business decisions. Read models answer queries — they are projections of what happened. All business logic lives in the aggregate.

---

## Quick Reference

```
Aggregate: cluster of commands, events, and rules — enforces invariants for a group of objects
Aggregate boundary signal: events cluster around shared commands and rules
Read model: query-optimized projection of events — never enforces rules, never writes domain state
Boundary discovery: separate aggregates when different people or teams handle different command clusters
Policy: "Whenever [event], then [command]" — the glue between aggregates
Read model is eventually consistent — rebuilt by replaying events
```
