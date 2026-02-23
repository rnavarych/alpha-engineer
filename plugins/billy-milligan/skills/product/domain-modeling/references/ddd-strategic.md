# DDD Strategic Patterns

## When to load
Load when designing system boundaries, mapping bounded contexts, choosing a context map pattern, or deciding how to protect a downstream model from an upstream system with an Anti-Corruption Layer.

---

## Bounded Contexts

A bounded context is a boundary within which a particular domain model applies and is internally consistent. The same word can mean different things in different contexts — that's expected and correct.

### When to define a bounded context
- Different teams own different parts of the system
- The same concept means different things to different parts of the business
- You need to prevent "big ball of mud" where everything is coupled to everything
- A subdomain has its own language, rules, and rate of change

### Bounded context identification exercise

Ask these questions about your domain:
1. What are the major **capabilities** the system provides? (not features — capabilities)
2. For each capability: who owns the business rules? (different owners → different contexts)
3. What terms does each team use? Do they agree on definitions?
4. Which parts of the system change together? (high coupling → same context)
5. Which parts can be developed and deployed independently? (low coupling → separate contexts)

### E-commerce example: bounded context map

```
┌────────────────────────────────────────────────────────────────┐
│                      E-COMMERCE SYSTEM                         │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│  CATALOG BC  │   ORDERS BC  │ PAYMENTS BC  │   SHIPPING BC     │
│              │              │              │                    │
│  Product     │  Order       │  Charge      │  Shipment         │
│  Category    │  OrderItem   │  Refund      │  TrackingNumber   │
│  Inventory   │  Customer    │  PaymentMethod│  DeliveryRoute    │
│  Variant     │              │              │                    │
│              │  "Product" = │  "Customer" =│  "Order" =        │
│  "Product" = │  snapshot at │  billing     │  delivery task    │
│  source of   │  order time  │  profile     │  (no pricing)     │
│  truth       │              │              │                    │
├──────────────┴──────────────┴──────────────┴───────────────────┤
│                    INTEGRATION LAYER                            │
│  Catalog→Orders ACL    Orders→Payments ACL    Orders→Shipping  │
└────────────────────────────────────────────────────────────────┘
```

---

## Context Mapping Patterns

Context maps describe the relationship between bounded contexts and the power dynamics of that relationship.

| Pattern | When to use | Implementation |
|---------|------------|----------------|
| **Partnership** | Two contexts evolve together; teams coordinate closely | Shared planning, synchronized releases |
| **Shared Kernel** | Two contexts share a small, stable subset of the model | Shared library; changes require joint agreement |
| **Customer/Supplier** | Upstream context (supplier) serves downstream (customer) | Downstream defines needs; upstream prioritizes them |
| **Conformist** | Downstream must conform to upstream (no negotiation power) | Use upstream model as-is; e.g., integrate with Stripe's model |
| **Anti-Corruption Layer** | Downstream protects itself from upstream's model | Translation layer that converts upstream concepts to downstream language |
| **Open Host Service** | Upstream publishes a well-defined API for multiple consumers | REST API, GraphQL, event schema — versioned and documented |
| **Published Language** | Common protocol/format that both sides agree on | JSON schema, Avro schema, OpenAPI spec |
| **Separate Ways** | No integration needed; contexts operate independently | No shared code, no shared data |

### When to use an Anti-Corruption Layer (ACL)

Use an ACL when:
- Integrating with a legacy system that has a poor domain model
- Integrating with a third-party API (Stripe, Salesforce, etc.) whose concepts don't map cleanly to your domain
- An upstream context is unstable and you need to protect downstream from breaking changes
- The upstream model would "pollute" your clean domain model

```typescript
// ACL Example: Catalog → Orders integration
// Problem: Catalog Product has 40+ fields; Order only needs 5

// Orders' domain concept (clean, minimal)
export class OrderProductSnapshot {
  private constructor(
    public readonly productId: OrderProductId,
    public readonly name: string,
    public readonly sku: string,
    public readonly unitPrice: Money,
  ) {}

  static create(productId: OrderProductId, name: string, sku: string, unitPrice: Money) {
    return new OrderProductSnapshot(productId, name, sku, unitPrice);
  }
}

// ACL: translates Catalog's model into Orders' language
export class CatalogProductAcl {
  static toOrderSnapshot(catalogProduct: CatalogProduct): OrderProductSnapshot {
    if (!catalogProduct.isActive) {
      throw new DomainError(`Product ${catalogProduct.id} is not active and cannot be ordered`);
    }

    return OrderProductSnapshot.create(
      OrderProductId.from(catalogProduct.id),
      catalogProduct.name,
      catalogProduct.sku,
      Money.of(catalogProduct.priceInCents, catalogProduct.currency),
      // Snapshot: price is locked at this moment. Catalog price changes don't affect this order.
    );
  }
}
```

---

## Anti-Patterns

### The Shared Database Anti-Pattern
Multiple bounded contexts reading and writing to the same database tables. Looks efficient short-term. In practice: schema changes affect all contexts, any context can put another context's data into an invalid state, teams block each other on migrations.

**Fix:** Each context owns its data. Cross-context data needs go through APIs or events.

### The Anemic Context
A "bounded context" with no real domain logic — just a thin wrapper around a database. If everything is CRUD and there are no business rules to enforce, the context probably isn't needed or doesn't have correct boundaries.

### The God Context
One massive "Business" or "Core" context that contains everything. This is just a monolith with extra steps. Identify natural seams along business capability lines.

### Direct Model Sharing
Putting shared domain objects in a `common` package that all contexts import. Now all contexts are coupled to that model. Changes to the shared model break all contexts simultaneously.

---

## Quick Reference

```
Bounded context: boundary where one model applies consistently
Context map patterns: Partnership, Customer/Supplier, Conformist, ACL, Open Host, Published Language
Use ACL when: integrating with legacy or third-party systems with incompatible models
One team per context — no shared ownership without explicit collaboration protocol
Shared database: anti-pattern — each context owns its data, cross-context via API or events
```
