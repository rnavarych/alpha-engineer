# SOLID Principles and Architectural Styles

## When to load
Load when evaluating which architectural style fits a project, making modular monolith vs. microservices decisions, or applying SOLID principles to class/module design.

## SOLID Principles

- **S**: Single Responsibility — one reason to change per class/module; cohesion over cleverness
- **O**: Open/Closed — extend behavior without modifying existing code (strategy, decorator patterns)
- **L**: Liskov Substitution — subtypes must be substitutable for base types; honor contracts
- **I**: Interface Segregation — prefer small, focused interfaces over fat interfaces
- **D**: Dependency Inversion — depend on abstractions; inject dependencies; invert control

## Modular Monolith
- **When**: Small-to-medium teams, early product, complex domain requiring transactional integrity
- **Structure**: Bounded contexts as modules within single deployable unit; enforced module boundaries
- **Pros**: Simple deployment, easy debugging, no network overhead, single ACID transaction
- **Cons**: Scaling bottlenecks (scale all-or-nothing), deployment coupling, module boundary erosion
- **Pattern**: Strict module APIs; no direct cross-module DB access; events for cross-module side effects
- **Tools**: ArchUnit (Java), dependency-cruiser (JS/TS), NDepend (.NET) for boundary enforcement

## Microservices
- **When**: Large teams, independent scaling needs, polyglot requirements, organizational scaling
- **Pros**: Independent deployment, team autonomy, fault isolation, technology heterogeneity
- **Cons**: Network complexity, distributed transactions, operational overhead, testing complexity
- **Team topology**: Align services to Conway's Law — one team per bounded context
- **Rule**: Start modular monolith; extract services when pain points emerge (scaling, team autonomy)
- **Anti-patterns**: Nano-services (too chatty), distributed monolith (tight coupling across services)

## Serverless
- **When**: Event-driven workloads, variable/spiky traffic, rapid prototyping, edge functions
- **Pros**: No server management, auto-scaling, pay-per-use, fast deployment
- **Cons**: Cold starts, vendor lock-in, debugging complexity, statelessness, execution time limits
- **Platforms**: Lambda, Cloud Functions, Durable Functions, Cloudflare Workers, Vercel Edge

## Cell-Based Architecture
- **When**: Global scale requiring blast radius control and independent failure domains
- **Pattern**: Divide infrastructure into isolated "cells" (per-region, per-tenant cluster)
  - Each cell is self-contained: compute, data store, messaging, cache
  - Router service directs traffic to appropriate cell
  - Cell failure is isolated — no cross-cell dependencies in request path
  - Cells are identical but independent (replicated, not shared)
- **Examples**: Amazon's cell-based deployment, Slack's sharding architecture
- **Benefits**: Predictable blast radius, independent deployments, regulatory data residency
