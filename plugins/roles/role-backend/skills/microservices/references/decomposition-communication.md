# Service Decomposition and Communication Patterns

## When to load
Load when deciding whether microservices are appropriate, decomposing a monolith into services, or choosing between synchronous and asynchronous inter-service communication.

## When to Use Microservices

- Team size justifies independent deployment (2+ teams owning separate services)
- Different parts of the system have meaningfully different scaling requirements
- Different parts require different technology stacks
- Independent deployment cadence is required per component

## When NOT to Use Microservices

- Small team (fewer than 5 developers) — operational overhead exceeds benefit
- Unclear domain boundaries — start with a modular monolith, extract later
- Tight coupling between components that share data frequently
- When operational complexity outweighs organizational benefits

## Decomposition Strategies

- **By business capability**: Payment, Inventory, User Management, Notification
- **By subdomain (DDD)**: Bounded contexts map directly to services
- **Strangler fig pattern**: Incrementally extract from monolith behind a facade
- Each service owns its data — no shared databases between services

## Synchronous Communication (Request-Response)

| Protocol | Best For | Considerations |
|----------|----------|----------------|
| REST/HTTP | CRUD, public APIs, simple queries | Latency coupling, cascading failures |
| gRPC | Internal service-to-service, streaming | Requires proto management, not browser-native |

- Always set timeouts on every outbound call
- Implement retries with exponential backoff and jitter
- Use circuit breakers to prevent cascade failures
- Prefer async when the caller does not need an immediate response

## Asynchronous Communication (Event-Driven)

| Pattern | Use Case |
|---------|----------|
| Event notification | "Order placed" — consumers react independently |
| Event-carried state transfer | Event includes full data, reduces queries back to source |
| Command message | "Process payment" — directed to a specific consumer |
| CQRS | Separate read/write models for different query patterns |

- Use a message broker (Kafka, RabbitMQ, SQS) for reliable delivery
- Design events as immutable facts (past tense: `OrderPlaced`, `PaymentProcessed`)
- Include event schema versioning from day one
- Implement idempotent consumers (deduplication by event ID)

## Saga Pattern

For distributed transactions spanning multiple services:

### Choreography (Event-Based)
- Each service listens for events and publishes compensating events on failure
- Simpler for 2-3 step workflows
- Harder to trace and debug as complexity grows

### Orchestration (Command-Based)
- A central orchestrator coordinates the saga steps
- Easier to understand, test, and monitor
- Single point of coordination (not failure, if designed properly)

Always implement compensating transactions for each forward step.
