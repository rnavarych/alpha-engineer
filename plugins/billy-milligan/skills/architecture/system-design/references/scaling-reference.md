# Scaling Reference

## When to load
Load when discussing concrete scaling thresholds, cell-based architecture, or CQRS decision criteria.

## Patterns ✅

### Traffic thresholds and actions
| RPM | Action |
|-----|--------|
| <1k | Single instance, no cache needed |
| 1k–10k | Add Redis cache, connection pooling |
| 10k–50k | Read replicas, CDN for static assets |
| 50k–100k | Horizontal scaling, load balancer, rate limiting |
| 100k–500k | Service decomposition, async processing, sharding evaluation |
| >500k | Cell-based architecture, edge computing |

### Cell-based architecture (multi-tenant SaaS)
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

- Cell size: 500–2000 tenants per cell
- Blast radius limited to one cell
- GDPR data residency per cell (EU cell, US cell)
- Rebalance by migrating tenant data, not restructuring

### CQRS triggers
Use CQRS when:
- Read/write scale differs by 10×+
- Read models need heavy denormalization
- Audit trail required (append-only write side)

```typescript
// Command side: normalized, transactional
class PlaceOrderCommand { constructor(readonly userId: string, readonly items: OrderItem[]) {} }

// Query side: denormalized read model — updated via projector
interface OrderListView {
  id: string; createdAt: Date; totalAmount: number;
  customerName: string; // Denormalized from users table
  status: string;
}
```

### Event sourcing domains
- Right: financial ledgers, audit logs, compliance, healthcare records
- Wrong: user preferences, product catalog, session data
- Cost: storage 5–10× normal, queries require projection rebuilds

## Anti-patterns ❌
- Event sourcing as default → massive storage, complex debugging, slow onboarding
- Scaling before profiling → premature optimization without data

## Quick reference
```
<10k RPM: monolith + Redis cache
10k–100k RPM: read replicas + CDN + horizontal scaling
>100k RPM: service decomposition or cell-based
Cell size: 500–2000 tenants
CQRS trigger: read/write scale 10×+ difference
Event sourcing: financial/audit/compliance only
```
