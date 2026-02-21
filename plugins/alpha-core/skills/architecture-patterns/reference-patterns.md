# Architecture Patterns Reference

## Saga Pattern

### Choreography
- Services emit events, other services react
- Decentralized, no single point of failure
- Hard to track overall transaction state
- Best for simple, few-step transactions

### Orchestration
- Central orchestrator coordinates steps
- Clear transaction flow, easier monitoring
- Orchestrator is a potential bottleneck
- Best for complex, multi-step transactions

### Compensation
- Each step has a compensating action (undo)
- Execute compensations in reverse order on failure
- Design compensations to be idempotent

## Circuit Breaker States
- **Closed**: Normal operation, requests pass through
- **Open**: Failure threshold exceeded, requests fail immediately
- **Half-Open**: After timeout, allow limited requests to test recovery
- Libraries: Resilience4j (Java), Polly (.NET), opossum (Node.js)

## Event-Driven Architecture

### Event Types
- **Domain Events**: Business-significant occurrences (OrderPlaced, PaymentReceived)
- **Integration Events**: Cross-service communication
- **Change Data Capture**: Database-level change streaming

### Event Bus Patterns
- **Pub/Sub**: One-to-many, loose coupling
- **Event Streaming**: Ordered log (Kafka), replay capability
- **Request/Reply**: Async request with correlation ID

## API Composition Patterns
- **API Gateway**: Single entry point, routing, auth, rate limiting
- **BFF**: Backend for Frontend, tailored per client type
- **GraphQL Federation**: Unified graph across microservices
- **Service Mesh**: Infrastructure-level communication (Istio, Linkerd)

## Data Management Patterns
- **Database per Service**: Each microservice owns its data
- **Shared Database**: Anti-pattern for microservices, acceptable for modular monolith
- **CQRS**: Separate read/write stores, materialized views
- **Event Sourcing**: Append-only event log, derived read models
- **Outbox Pattern**: Transactional event publishing

## Deployment Patterns
- **Blue-Green**: Two identical environments, instant switchover
- **Canary**: Gradual rollout to subset of users
- **Rolling**: Sequential instance updates
- **Feature Flags**: Runtime feature toggling, decoupled from deployment
