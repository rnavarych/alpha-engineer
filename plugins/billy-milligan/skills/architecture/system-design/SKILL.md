---
name: system-design
description: |
  System design patterns for distributed systems: monolith vs microservices decision criteria,
  outbox pattern, strangler fig, cell-based architecture, CQRS, event sourcing. Real thresholds
  with specific numbers. Anti-patterns with documented failure modes. Viktor's primary domain.
  Use when: choosing architecture for new system, scaling existing monolith, decomposing services,
  designing for reliability, SaaS/fintech/e-commerce/healthcare system decisions.
allowed-tools: Read, Grep, Glob
---

# System Design Patterns

## When to Use This Skill
- Choosing between monolith, modular monolith, and microservices
- Designing for scale: when to split, when NOT to split
- Applying patterns: outbox, saga, strangler fig, CQRS
- Cell-based architecture for multi-tenant SaaS
- Migration from monolith to distributed architecture

## Core Principles

1. **Start with a monolith** — premature decomposition is the #1 distributed systems mistake
2. **Decouple at the seam, not at the start** — build modular monolith first, extract when needed
3. **Every network hop is a failure domain** — each service boundary adds latency AND failure surface
4. **Data ownership is the hard part** — not code separation
5. **Eventual consistency is a product decision** — not just a technical one

---

## Patterns ✅

### Monolith vs Microservices Decision Matrix

| Signal | Monolith | Modular Monolith | Microservices |
|--------|----------|-----------------|---------------|
| Team size | <10 engineers | 10–50 | >50 |
| Traffic | <10k RPM | 10k–100k RPM | >100k RPM or burst |
| Deployment frequency | Weekly | Daily | Multiple/day per service |
| Domain complexity | Simple | Medium, clear bounded contexts | High, independent scaling needs |
| Org structure | 1 team | 2–5 teams | Many teams, autonomous |

**Rule**: Don't do microservices until you have **two of three**: >50 engineers, >100k RPM, independent scaling requirements.

### Modular Monolith Structure

```
src/
  modules/
    orders/
      domain/       # Entities, value objects, domain events
      application/  # Use cases, commands, queries
      infrastructure/ # DB repos, external adapters
      api/          # HTTP handlers — thin layer
    inventory/
      domain/
      application/
      infrastructure/
      api/
  shared/
    events/         # Domain event bus (in-process)
    kernel/         # Shared value objects (Money, Email)
```

**Inter-module communication**: Only via public API interfaces or domain events. Direct imports across modules = architectural violation.

```typescript
// ❌ Wrong: direct import across modules
import { OrderRepository } from '../orders/infrastructure/OrderRepository';

// ✅ Right: depend on interface in shared kernel
import { IOrderQuery } from '../shared/kernel/IOrderQuery';
```

### Outbox Pattern (Guaranteed Event Delivery)

Solves: "database updated but event not published" split-brain problem.

```sql
-- Outbox table lives in same DB as your domain data
CREATE TABLE outbox_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic       TEXT NOT NULL,
  payload     JSONB NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  retry_count  INT DEFAULT 0
);
```

```typescript
// Write to domain table + outbox in ONE transaction
async function placeOrder(order: Order): Promise<void> {
  await db.transaction(async (tx) => {
    await tx.insert(orders).values(order);
    await tx.insert(outboxEvents).values({
      topic: 'orders.placed',
      payload: { orderId: order.id, amount: order.total }
    });
  });
}

// Separate poller publishes outbox events (idempotent)
async function publishOutboxEvents(): Promise<void> {
  const events = await db
    .select()
    .from(outboxEvents)
    .where(isNull(outboxEvents.publishedAt))
    .limit(100)
    .for('update skip locked');  // Prevents double-processing

  for (const event of events) {
    await kafka.produce(event.topic, event.payload);
    await db.update(outboxEvents)
      .set({ publishedAt: new Date() })
      .where(eq(outboxEvents.id, event.id));
  }
}
```

**Polling interval**: 100–500ms. Use pg_listen/pg_notify for sub-100ms latency if needed.

### Strangler Fig Migration

Migrate from legacy monolith without big-bang rewrite. Phase over 6–18 months.

```
Phase 1: Facade in front of monolith
  Client → Facade → Legacy Monolith

Phase 2: Intercept high-value endpoints
  Client → Facade → {
    /api/orders → New Orders Service (Go)
    /api/users  → Legacy Monolith
    /* rest */  → Legacy Monolith
  }

Phase 3: Strangle incrementally, keep facade
Phase 4: Legacy monolith retired, facade = API gateway
```

**Key**: Facade must be thin (nginx/Envoy routing, not business logic). Never add logic to the façade.

### Cell-Based Architecture (Multi-Tenant SaaS)

```
Global Control Plane
├── Auth (Cognito / Clerk)
├── Tenant Registry (which cell?)
└── Router

Cell A (tenants 1–1000)     Cell B (tenants 1001–2000)
├── App servers (3×)         ├── App servers (3×)
├── PostgreSQL primary       ├── PostgreSQL primary
├── Read replicas (2×)       ├── Read replicas (2×)
└── Redis cluster            └── Redis cluster
```

**Benefits**: Blast radius limited to one cell. Each cell can be on different infra version. GDPR data residency per cell.
**Cell size**: 500–2000 tenants per cell. Rebalance by migrating tenant data, not restructuring.

### CQRS (When You Need It)

Use CQRS when: read models need denormalization, read/write scale differs by 10x+, audit trail required.

```typescript
// Command side: normalized, transactional
class PlaceOrderCommand {
  constructor(
    readonly userId: string,
    readonly items: OrderItem[]
  ) {}
}

// Query side: denormalized read model
interface OrderListView {
  id: string;
  createdAt: Date;
  totalAmount: number;
  itemCount: number;
  customerName: string;  // Denormalized from users table
  status: string;
}

// Projector: keeps read model in sync
async function onOrderPlaced(event: OrderPlacedEvent): Promise<void> {
  await db.insert(orderListViews).values({
    id: event.orderId,
    totalAmount: event.amount,
    itemCount: event.items.length,
    customerName: await getUserName(event.userId),
    status: 'pending'
  }).onConflictDoUpdate({ /* handle redelivery */ });
}
```

---

## Anti-Patterns ❌

### Distributed Monolith
**What it is**: Microservices that share a database or call each other synchronously in request chains.
**What breaks**: Service A calls B calls C calls D — if D is slow, A is slow. Deploy B? Must coordinate with A and C. One DB = no independent scaling.
**When it breaks**: First time you need to deploy "one service" and realize you need to coordinate with 4 others.
**Detection**: >3 synchronous service calls per user request, shared database connection strings across services.

### Big Bang Rewrite
**What it is**: "Let's rewrite the whole thing in [new tech] over 6 months."
**What breaks**: Business never stops during rewrite. Feature parity takes 2× estimated time. New code misses edge cases old code handled. You end up with two systems to maintain.
**Historical failure rate**: >70% of big bang rewrites either fail or significantly overrun (Standish CHAOS Report).
**Correct alternative**: Strangler Fig above. Extract one module at a time. Never freeze the old system.

### Microservices Too Early
**What it is**: Splitting before understanding domain boundaries.
**What breaks**: Wrong service boundaries require cross-service transactions. Shared data needs synchronization. Each feature change touches 5 services. 3-person team spending 60% on infrastructure.
**When it breaks**: Sprint 2 — "wait, order status needs to update inventory AND notify payments at the same time."

### Event Sourcing Everywhere
**Event sourcing is NOT a default**. Use it for: financial ledgers, audit logs, compliance-heavy domains.
**Cost**: Storage 5–10× normal, queries require projection rebuilds, debugging requires replaying events, onboarding harder.
**Right domains**: Banking transactions, healthcare records, compliance audit trails.
**Wrong domains**: User preferences, product catalog, session data.

---

## Decision Matrix: Service Boundary Identification

Good service boundaries have **high cohesion, low coupling**:

| Question | Yes → Same Service | No → Consider Split |
|----------|-------------------|---------------------|
| Do these change together? | ✓ | × |
| Do they share a database transaction? | ✓ (usually) | × |
| Does one team own both? | ✓ | × |
| Do they need to scale independently? | × | ✓ |
| Are they in different business domains? | × | ✓ |
| Do different regulations apply? | × | ✓ |

---

## Quick Reference

```
Monolith first rule: <50 engineers, <100k RPM → don't split
Outbox polling: every 100–500ms, SKIP LOCKED prevents duplicates
Strangler Fig: 6–18 months, never add logic to facade
Cell size: 500–2000 tenants, blast radius = one cell
CQRS trigger: read/write scale differs 10x+, or denormalization needed
Event sourcing: only for financial, audit, compliance domains
```
