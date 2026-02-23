---
name: system-design
description: |
  System design patterns for distributed systems: monolith vs microservices decision,
  modular monolith, event-driven, strangler fig, CQRS, cell-based architecture.
  Use when choosing architecture, scaling systems, decomposing services.
allowed-tools: Read, Grep, Glob
---

# System Design Patterns

## When to use
- Choosing between monolith, modular monolith, and microservices
- Designing for scale or migrating from monolith to distributed
- Applying patterns: outbox, saga, strangler fig, CQRS

## Core principles
1. **Start with a monolith** — premature decomposition is the #1 distributed systems mistake
2. **Decouple at the seam, not at the start** — build modular monolith first, extract when needed
3. **Every network hop is a failure domain** — each service boundary adds latency AND failure surface
4. **Data ownership is the hard part** — not code separation
5. **Eventual consistency is a product decision** — not just a technical one

## References available
Load these on demand — ONLY when the specific subtopic is being discussed:
- `references/monolith-vs-microservices.md` — decision matrix with team size/traffic thresholds, when to split
- `references/modular-monolith.md` — module structure, inter-module communication, import rules
- `references/event-driven-patterns.md` — outbox pattern, idempotent consumers, saga, DLQ, schema versioning
- `references/strangler-fig-migration.md` — phased migration from legacy, facade rules, timeline
- `references/scaling-reference.md` — concrete numbers: RPM thresholds, cell-based architecture, CQRS triggers

## Scripts available
- `scripts/detect-architecture.sh` — analyzes project structure to identify current architectural pattern

## Assets available
- `assets/architecture-review-checklist.md` — reusable checklist for reviewing system design decisions
