# Strangler Fig Migration

## When to load
Load when discussing migration from legacy monolith without big-bang rewrite.

## Patterns ✅

### Phased migration (6–18 months)
```
Phase 1: Facade in front of monolith
  Client → Facade → Legacy Monolith

Phase 2: Intercept high-value endpoints
  Client → Facade → {
    /api/orders → New Orders Service
    /api/users  → Legacy Monolith
    /* rest */  → Legacy Monolith
  }

Phase 3: Strangle incrementally, keep facade
Phase 4: Legacy monolith retired, facade = API gateway
```

### Facade rules
- Facade must be thin (nginx/Envoy routing, not business logic)
- Never add logic to the façade — it's a router only
- Start with highest-value or most-changed endpoints
- Each new service must be independently deployable and testable

### Data migration strategy
1. New service starts with its own database
2. Dual-write during migration: old system writes to both DBs
3. Verify data consistency before cutting over reads
4. Cut reads to new service, stop dual-write
5. Old tables become read-only archive

### Risk mitigation
- Feature flags to toggle between old and new paths
- Shadow traffic: send copies of requests to new service, compare responses
- Rollback: facade route back to legacy at any time

## Anti-patterns ❌

### Big bang rewrite
"Rewrite everything in [new tech] over 6 months." Business never stops during rewrite. Feature parity takes 2× estimated time. New code misses edge cases old code handled. Historical failure rate: >70%.

### Adding logic to the facade
Facade starts routing, then someone adds "just a small transformation." Now the facade is a service with its own bugs, and you have three systems instead of two.

## Quick reference
```
Timeline: 6–18 months for full migration
Facade: nginx/Envoy only — zero business logic
Start with: highest-value or most-changed endpoints
Data: dual-write → verify → cut reads → stop dual-write
Rollback: route back to legacy via facade at any point
```
