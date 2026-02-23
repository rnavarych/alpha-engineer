---
name: domain-modeling
description: |
  Domain-Driven Design: aggregates, bounded contexts, ubiquitous language, value objects,
  domain events, repository pattern, anti-corruption layer. When to use DDD vs simple CRUD.
  Entity vs value object distinction. TypeScript implementations with invariant enforcement.
  Use when designing domain model for complex business logic, bounded context mapping.
allowed-tools: Read, Grep, Glob
---

# Domain Modeling (DDD)

## When to use
- Designing domain model for complex business logic
- Identifying bounded contexts and aggregate roots
- Translating business rules into code invariants
- Deciding between entities and value objects
- Mapping existing code to DDD building blocks

## Core principles
1. **Ubiquitous language is the contract** — code names must match business terms; if business says "Invoice", your class is `Invoice`, not `Bill` or `Document`
2. **Aggregates enforce invariants** — all business rules for a cluster of objects enforced by the root
3. **Value objects are immutable** — Money, Email, Address: no identity, defined by value
4. **Domain events record facts** — `OrderCancelled` not `cancelOrder()`, past tense
5. **DDD is overkill for CRUD** — if it's just data in / data out, use simple CRUD; DDD pays off when business rules are complex

## References available
- `references/ddd-strategic.md` — bounded context mapping, context map patterns, ACL implementation
- `references/ddd-decision-guide.md` — DDD vs CRUD decision tree, subdomain classification, team topology alignment
- `references/event-driven-integration.md` — events over sync calls, transactional outbox pattern, event versioning
- `references/event-storming.md` — workshop facilitation guide, sticky note vocabulary, phases 1-7
- `references/aggregate-design.md` — command/event/rule structure, read model derivation, event storming discoveries
- `references/ubiquitous-language.md` — naming convention rules, element type table, what to avoid
- `references/domain-glossary.md` — glossary entry format, e-commerce examples, maintenance cadence
- `references/term-conflict-resolution.md` — 5-step conflict resolution protocol, cross-context disambiguation

## Assets available
- `assets/domain-model-template.md` — aggregate skeleton, value object template, repository interface template
