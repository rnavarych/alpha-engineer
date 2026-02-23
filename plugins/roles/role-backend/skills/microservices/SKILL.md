---
name: microservices
description: |
  Designs and implements microservices architectures including service decomposition,
  synchronous (REST/gRPC) and asynchronous (event-driven) communication, saga pattern,
  circuit breaker, service mesh (Istio), API gateway, service discovery, and distributed tracing.
  Use when decomposing monoliths, designing inter-service communication, or implementing resilience patterns.
allowed-tools: Read, Grep, Glob, Bash
---

# Microservices

## When to use
- Evaluating whether microservices are the right architectural choice
- Decomposing a monolith into independently deployable services
- Designing inter-service communication (REST, gRPC, events, commands)
- Implementing distributed transactions with the saga pattern
- Adding circuit breakers, retries, or timeouts to outbound calls
- Configuring service discovery, API gateway, or a service mesh
- Setting up distributed tracing across service boundaries

## Core principles
1. **Services own their data** — no shared databases; communicate through APIs or events
2. **Design for failure** — every remote call can and will fail; circuit breakers and retries are mandatory
3. **Events are immutable facts** — past tense names, schema-versioned from day one
4. **Async by default** — synchronous calls couple availability; use events where the caller does not need an immediate response
5. **Operational complexity is the cost** — microservices without tracing, health checks, and a deployment pipeline are just distributed monoliths

## Reference Files

- `references/decomposition-communication.md` — when to use (and not use) microservices, decomposition strategies (business capability, DDD bounded contexts, strangler fig), synchronous vs asynchronous communication patterns, and the saga pattern (choreography vs orchestration)
- `references/resilience-infrastructure.md` — circuit breaker states and library options, API gateway responsibilities, service mesh trade-offs, service discovery approaches, distributed tracing with OpenTelemetry, retry/timeout strategy, and liveness/readiness health checks
