# DDD, CQRS, Event Sourcing, and Event-Driven Architecture

## When to load
Load when modeling a domain with DDD, implementing CQRS or Event Sourcing, designing event-driven systems, or running an Event Storming workshop.

## Domain-Driven Design (DDD)

### Strategic Design
- **Bounded Context**: Semantic boundary where a model applies consistently; map with Context Map
- **Ubiquitous Language**: Shared vocabulary between developers and domain experts; enforced in code
- **Context Mapping Patterns**: Partnership, Shared Kernel, Customer-Supplier, Conformist,
  Anti-Corruption Layer (ACL), Open Host Service, Published Language, Separate Ways

### Tactical Design
- **Aggregate**: Cluster of domain objects with consistency boundary; only root referenced externally
- **Entity**: Identity-based objects (User, Order); identity persists through state changes
- **Value Object**: Immutable, defined by attributes (Money, Address, Email); no identity
- **Domain Event**: Something significant that happened (OrderPlaced); past tense, immutable
- **Repository**: Abstraction for aggregate persistence; hides storage details from domain
- **Application Service**: Orchestrates use cases; thin layer; no business logic

### Domain Events Pattern
```typescript
class OrderPlaced {
  readonly occurredAt = new Date();
  constructor(
    readonly orderId: string, readonly customerId: string,
    readonly items: OrderItem[], readonly totalAmount: Money,
  ) {}
}

class Order {
  private events: DomainEvent[] = [];
  place(items: OrderItem[], payment: PaymentMethod): void {
    this.validate(items);
    this.status = 'placed';
    this.events.push(new OrderPlaced(this.id, this.customerId, items, this.total));
  }
  pullEvents(): DomainEvent[] {
    const events = [...this.events];
    this.events = [];
    return events;
  }
}
```

## CQRS (Command Query Responsibility Segregation)
- Separate write model (commands) from read model (queries)
- Commands: mutate state, validate invariants, raise domain events; no return data
- Queries: return data from optimized read model; no side effects
- **When to use**: Significantly different read/write patterns; complex reporting; high read volume

```typescript
// Write side (command handler)
class PlaceOrderHandler {
  async handle(cmd: PlaceOrderCommand): Promise<void> {
    const order = Order.create(cmd);
    await this.orderRepo.save(order);
    for (const event of order.pullEvents()) { await this.eventBus.publish(event); }
  }
}
// Read side (projection updater)
class OrderSummaryProjection {
  async on(event: OrderPlaced): Promise<void> {
    await this.db.orderSummaries.upsert({
      id: event.orderId, itemCount: event.items.length,
      total: event.totalAmount.toString(), placedAt: event.occurredAt,
    });
  }
}
```

## Event Sourcing
- Store sequence of immutable events instead of current state
- Rebuild current state by replaying events (or from snapshot)
- Natural audit trail; temporal queries ("what did the order look like last Tuesday?")
- Event store: EventStoreDB, Axon Server, Kafka (with compaction), PostgreSQL events table
- **Upcasting**: Transform old event versions to current format; never mutate stored events

## Event-Driven Architecture (EDA)

### Event Types
- **Domain Events**: Business-significant (OrderPlaced) — trigger workflows
- **Integration Events**: Cross-service communication; translated from domain events at boundaries
- **CDC (Change Data Capture)**: Database-level change streaming (Debezium, DynamoDB Streams)

### Event Schema Evolution
- Forward-compatible: add optional fields; consumers ignore unknown fields
- Backward-compatible: don't remove fields; use default values for old consumers
- Schema registry: Confluent Schema Registry — enforce compatibility
- Include event version in envelope; use upcasters to transform old versions

## Event Storming Workshop
1. **Domain Events** (orange): What happened? Past tense. "Order Placed", "Payment Failed"
2. **Commands** (blue): What triggered the event? "Place Order", "Process Payment"
3. **Aggregates** (yellow): What handles the command? "Order", "Payment"
4. **Policies** (purple): Reactive logic. "When Payment Received, Then Ship Order"
5. **External Systems** (pink): Third parties. "Stripe", "Warehouse System"
6. **Hotspots** (red): Unresolved questions, complexity, disagreements
