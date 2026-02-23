# Design Patterns: Saga, Circuit Breaker, Outbox, Strangler Fig, Data Mesh

## When to load
Load when implementing distributed transaction patterns (Saga, Outbox), resilience patterns (Circuit Breaker, Bulkhead), migration patterns (Strangler Fig, ACL), or Data Mesh architecture.

## Outbox Pattern (Reliable Event Publishing)
```sql
-- Application writes to DB and outbox in same transaction
BEGIN;
  INSERT INTO orders (id, status) VALUES ('ord_123', 'placed');
  INSERT INTO outbox (id, aggregate_type, aggregate_id, event_type, payload)
    VALUES (gen_random_uuid(), 'Order', 'ord_123', 'OrderPlaced', '{"..."}');
COMMIT;
-- Outbox poller reads and publishes events (at-least-once delivery)
-- Debezium: CDC from outbox table to Kafka
```

## Saga Pattern

### Choreography Saga
- Services emit events; other services react with their own events
- Decentralized, no single coordinator; hard to track overall state
- Best for: simple linear workflows with few services

### Orchestration Saga
- Saga orchestrator coordinates steps via commands; clear transaction flow; easy to monitor
- Best for: complex multi-step workflows; workflows requiring human approval steps

### Compensation
```typescript
const bookingWorkflow: SagaStep[] = [
  {
    execute: () => reserveInventory(orderId, items),
    compensate: () => releaseInventory(orderId, items),
  },
  {
    execute: () => chargePayment(orderId, amount),
    compensate: () => refundPayment(orderId, amount),
  },
  {
    execute: () => scheduleShipment(orderId),
    compensate: () => cancelShipment(orderId),
  },
];
```

## Circuit Breaker States
- **Closed**: Normal operation; failure counter tracks errors
- **Open**: Failure threshold exceeded (e.g., >50% failure rate in 60s); requests fail immediately with fallback
- **Half-Open**: After timeout, allow limited test requests; success → Closed; failure → Open
- Libraries: Resilience4j (Java), Polly (.NET), opossum (Node.js), go-circuit (Go)

## Bulkhead Pattern
- Isolate failures to prevent cascade across the system
- **Thread pool bulkhead**: separate thread pools per downstream service (CPU-bound)
- **Semaphore bulkhead**: limit concurrent calls per dependency (I/O-bound)
- Container resource limits as bulkhead: CPU/memory limits prevent one service starving others

## Strangler Fig Pattern (Legacy Migration)
1. Put a proxy/facade in front of the legacy system
2. Implement new capability in new system; route specific calls to new system
3. Gradually migrate endpoints from legacy to new
4. When all traffic migrated, decommission legacy system
- Use feature flags to switch traffic between old and new implementations

## Anti-Corruption Layer (ACL)
- Translation layer between your bounded context and external/legacy systems
- External model changes absorbed in ACL; your domain model stays clean
- Implement as Adapter + Translator: convert external DTOs to your domain objects

## Sidecar and Ambassador Patterns
- **Sidecar**: Deploy helper containers alongside main container (logging agent, proxy, secret rotation)
- **Ambassador**: Sidecar acts as outbound proxy; handles retry, circuit breaking, service discovery

## Data Mesh

### Four Principles
1. **Domain Ownership**: Data produced by a domain is owned and maintained by that domain team
2. **Data as a Product**: Each domain exposes data products with discoverability, quality SLAs, documentation
3. **Self-Serve Data Platform**: Infrastructure enables domain teams to build/publish data products
4. **Federated Computational Governance**: Global policies (privacy, compliance) enforced at platform level

## API Composition Patterns
- **API Gateway**: Single entry point, routing, auth, rate limiting
- **BFF (Backend for Frontend)**: Tailored per client type (mobile, web, third-party)
- **GraphQL Federation**: Unified graph across microservices
- **Service Mesh**: Infrastructure-level communication (Istio, Linkerd)

## Data Management Patterns Summary
- **Database per Service**: Each microservice owns its data; no cross-service DB access
- **Shared Database**: Anti-pattern for microservices; acceptable for modular monolith
- **CQRS**: Separate read/write stores, materialized views
- **Event Sourcing**: Append-only event log, derived read models

## Deployment Patterns
- **Blue-Green**: Two identical environments, instant switchover, easy rollback
- **Canary**: Gradual rollout to subset of users; validate before full rollout
- **Rolling**: Sequential instance updates; requires backward compatibility during transition
- **Feature Flags**: Runtime feature toggling; decoupled from deployment (LaunchDarkly, Unleash, Flagsmith)
