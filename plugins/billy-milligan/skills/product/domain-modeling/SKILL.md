---
name: domain-modeling
description: |
  Domain-Driven Design: aggregates, bounded contexts, ubiquitous language, value objects,
  domain events, repository pattern, anti-corruption layer. When to use DDD vs simple CRUD.
  Entity vs value object distinction. TypeScript implementations with invariant enforcement.
  Use when designing domain model for complex business logic, bounded context mapping.
allowed-tools: Read, Grep, Glob
---

# Domain Modeling (DDD)

## When to Use This Skill
- Designing domain model for complex business logic
- Identifying bounded contexts and aggregate roots
- Translating business rules into code invariants
- Deciding between entities and value objects
- Mapping existing code to DDD building blocks

## Core Principles

1. **Ubiquitous language is the contract** — code names must match business terms; if business says "Invoice", your class is `Invoice`, not `Bill` or `Document`
2. **Aggregates enforce invariants** — all business rules for a cluster of objects enforced by the root
3. **Value objects are immutable** — Money, Email, Address: no identity, defined by value
4. **Domain events record facts** — `OrderCancelled` not `cancelOrder()`, past tense
5. **DDD is overkill for CRUD** — if it's just data in / data out, use simple CRUD; DDD pays off when business rules are complex

---

## Patterns ✅

### Aggregate Root with Invariant Enforcement

```typescript
// Aggregate root: Order
// Invariant: cannot add items to a confirmed order
// Invariant: total must equal sum of item prices

export class Order {
  private readonly _items: OrderItem[] = [];
  private _status: OrderStatus = 'draft';
  private readonly _events: DomainEvent[] = [];

  private constructor(
    public readonly id: OrderId,
    public readonly customerId: CustomerId,
  ) {}

  static create(customerId: CustomerId): Order {
    const order = new Order(OrderId.generate(), customerId);
    order._events.push(new OrderCreated(order.id, customerId));
    return order;
  }

  addItem(productId: ProductId, quantity: Quantity, price: Money): void {
    // Enforce invariant
    if (this._status !== 'draft') {
      throw new DomainError('Cannot add items to a non-draft order');
    }
    if (quantity.value <= 0) {
      throw new DomainError('Quantity must be positive');
    }

    const existing = this._items.find(i => i.productId.equals(productId));
    if (existing) {
      existing.increaseQuantity(quantity);
    } else {
      this._items.push(new OrderItem(productId, quantity, price));
    }
  }

  confirm(): void {
    if (this._items.length === 0) {
      throw new DomainError('Cannot confirm empty order');
    }
    if (this._status !== 'draft') {
      throw new DomainError(`Order already ${this._status}`);
    }
    this._status = 'confirmed';
    this._events.push(new OrderConfirmed(this.id, this.total()));
  }

  cancel(reason: string): void {
    if (this._status === 'shipped') {
      throw new DomainError('Cannot cancel a shipped order');
    }
    if (this._status === 'cancelled') return;  // Idempotent

    const previousStatus = this._status;
    this._status = 'cancelled';
    this._events.push(new OrderCancelled(this.id, reason, previousStatus));
  }

  total(): Money {
    return this._items.reduce(
      (sum, item) => sum.add(item.subtotal()),
      Money.zero('USD')
    );
  }

  pullEvents(): DomainEvent[] {
    const events = [...this._events];
    this._events.length = 0;
    return events;
  }

  get status(): OrderStatus { return this._status; }
  get items(): ReadonlyArray<OrderItem> { return [...this._items]; }
}
```

### Value Objects

```typescript
// Value object: immutable, equality by value, no identity

export class Money {
  private constructor(
    private readonly _amount: number,  // in cents — never float
    private readonly _currency: string,
  ) {}

  static of(amount: number, currency: string): Money {
    if (!Number.isInteger(amount)) {
      throw new DomainError('Money amount must be in cents (integer)');
    }
    if (amount < 0) {
      throw new DomainError('Money amount cannot be negative');
    }
    return new Money(amount, currency.toUpperCase());
  }

  static zero(currency: string): Money {
    return new Money(0, currency);
  }

  add(other: Money): Money {
    if (this._currency !== other._currency) {
      throw new DomainError(`Currency mismatch: ${this._currency} + ${other._currency}`);
    }
    return new Money(this._amount + other._amount, this._currency);
  }

  subtract(other: Money): Money {
    if (this._currency !== other._currency) {
      throw new DomainError('Currency mismatch');
    }
    if (this._amount < other._amount) {
      throw new DomainError('Insufficient funds');
    }
    return new Money(this._amount - other._amount, this._currency);
  }

  equals(other: Money): boolean {
    return this._amount === other._amount && this._currency === other._currency;
  }

  get amount(): number { return this._amount; }
  get currency(): string { return this._currency; }
  toDisplay(): string { return `${(this._amount / 100).toFixed(2)} ${this._currency}`; }
}

export class Email {
  private readonly _value: string;

  constructor(value: string) {
    const normalized = value.toLowerCase().trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
      throw new DomainError(`Invalid email: ${value}`);
    }
    this._value = normalized;
  }

  equals(other: Email): boolean {
    return this._value === other._value;
  }

  get value(): string { return this._value; }
}
```

### Bounded Context Mapping

```
E-Commerce System — Bounded Contexts:

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   CATALOG BC    │     │    ORDERS BC    │     │   PAYMENTS BC   │
│                 │     │                 │     │                 │
│ Product         │     │ Order           │     │ Payment         │
│ Category        │     │ OrderItem       │     │ Charge          │
│ Inventory       │     │ Customer        │     │ Refund          │
│                 │     │                 │     │                 │
│ "Product" =     │     │ "Product" =     │     │ "Product" =     │
│ full catalog    │     │ snapshot at     │     │ not relevant    │
│ record          │     │ order time      │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         └──────── Catalog ACL ──┘       Payments ACL ───┘

ACL = Anti-Corruption Layer: translates between contexts
```

**Key insight**: "Product" means different things in different contexts.
- In Catalog: mutable, has inventory, can be updated
- In Orders: immutable snapshot (what was the price when ordered?)
- In Payments: irrelevant — just an amount and currency

```typescript
// Anti-Corruption Layer: translates Catalog Product to Order's snapshot
export class CatalogAcl {
  static toOrderProduct(catalogProduct: CatalogProduct): OrderProductSnapshot {
    return {
      productId: OrderProductId.from(catalogProduct.id),
      name: catalogProduct.name,
      price: Money.of(catalogProduct.priceInCents, catalogProduct.currency),
      // Snapshot: captured at order time — not affected by later catalog changes
    };
  }
}
```

### Repository Pattern

```typescript
// Repository: collection abstraction over persistence
// Aggregate root only — never repository for child entities

export interface OrderRepository {
  findById(id: OrderId): Promise<Order | null>;
  findByCustomer(customerId: CustomerId, options?: FindOptions): Promise<Order[]>;
  save(order: Order): Promise<void>;
  // Note: no delete — use soft delete via domain event
}

// Drizzle implementation
export class DrizzleOrderRepository implements OrderRepository {
  constructor(private db: Database) {}

  async findById(id: OrderId): Promise<Order | null> {
    const row = await this.db
      .select()
      .from(ordersTable)
      .where(eq(ordersTable.id, id.value))
      .leftJoin(orderItemsTable, eq(orderItemsTable.orderId, ordersTable.id))
      .then(rows => rows[0] ?? null);

    if (!row) return null;
    return OrderMapper.toDomain(row);
  }

  async save(order: Order): Promise<void> {
    const { orderRow, itemRows } = OrderMapper.toPersistence(order);

    await this.db.transaction(async (tx) => {
      await tx.insert(ordersTable)
        .values(orderRow)
        .onConflictDoUpdate({ target: ordersTable.id, set: orderRow });

      // Replace all items (simplest approach for small aggregates)
      await tx.delete(orderItemsTable)
        .where(eq(orderItemsTable.orderId, order.id.value));
      if (itemRows.length > 0) {
        await tx.insert(orderItemsTable).values(itemRows);
      }

      // Publish domain events after saving
      const events = order.pullEvents();
      if (events.length > 0) {
        await tx.insert(outboxEvents).values(
          events.map(e => ({ topic: e.type, payload: e, aggregateId: order.id.value }))
        );
      }
    });
  }
}
```

---

## Anti-Patterns ❌

### Anemic Domain Model
**What it is**: Domain objects are just data bags. All business logic lives in services.
```typescript
// Anemic — domain object has no behavior
class Order {
  id: string;
  status: string;
  items: OrderItem[];
  total: number;
}

// All logic in OrderService — business rules scattered, hard to find
class OrderService {
  async cancel(orderId: string) {
    const order = await this.repo.findById(orderId);
    if (order.status === 'shipped') throw new Error('...');
    order.status = 'cancelled';
    // ... 50 more lines of business logic here
  }
}
```
**What breaks**: Business rules are scattered across services. Two services can independently put the Order into an invalid state. Rules not enforced — depend on developers remembering to check.
**Fix**: Move invariants into the aggregate. `order.cancel()` enforces all rules.

### One Repository per Table
**What it is**: Creating `OrderItemRepository`, `OrderLineRepository` for child entities.
**What breaks**: Application code assembles aggregates manually. Can partially save an aggregate (order saved, items not). Invariants cannot be enforced across the aggregate boundary.
**Fix**: Repository for aggregate root only. `OrderRepository.save(order)` persists the entire aggregate.

### Primitive Obsession in Domain
```typescript
// Wrong — nothing prevents passing wrong string to wrong param
function createOrder(userId: string, productId: string) { ... }
createOrder(productId, userId);  // Swapped — no type error

// Right — branded types catch mistakes at compile time
function createOrder(userId: UserId, productId: ProductId) { ... }
```

---

## DDD Decision Guide

```
Use DDD when:
  ✓ Business rules are complex and frequently change
  ✓ Multiple teams work in the same domain
  ✓ Domain experts (non-technical) need to understand the model
  ✓ Business logic is more than CRUD

Skip DDD when:
  ✗ It's a CRUD API with simple validation
  ✗ Team has no DDD experience and no time to learn
  ✗ The domain is trivially simple (settings, preferences)

Quick Reference:
  Entity: has identity, mutable over time (Order, User)
  Value Object: no identity, immutable, equality by value (Money, Email, Address)
  Aggregate: cluster of entities with one root enforcing invariants
  Domain Event: past-tense fact (OrderPlaced, PaymentFailed)
  Repository: collection abstraction — one per aggregate root
  Anti-Corruption Layer: translates between bounded contexts
  Ubiquitous Language: business terms in code — no synonyms
```
