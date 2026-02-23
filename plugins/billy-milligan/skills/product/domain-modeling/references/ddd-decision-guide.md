# DDD Decision Guide

## When to load
Load when deciding whether to apply DDD vs. simpler patterns, classifying subdomains, aligning team structure with bounded context ownership, or applying Conway's Law intentionally to get the architecture you want.

---

## Is DDD Appropriate Here?

```
Decision tree:

1. Is the business logic complex?
   NO  → Use simple CRUD (Active Record, plain SQL, REST controller → service → DB)
   YES → Continue

2. Do business rules change frequently and do experts struggle to explain them consistently?
   NO  → Lightweight domain model may suffice (just organize logic in domain objects)
   YES → Continue to full DDD

3. Are there multiple teams working on different parts of this system?
   YES → Bounded contexts are almost certainly needed
   NO  → Bounded contexts still useful for large codebases; single team can manage one context

4. Does the domain language differ across business units?
   YES → Definitely needs bounded contexts with ACLs
   NO  → May be a single context

Verdict:
  - Simple data in/out → Skip DDD, use CRUD
  - One team, moderate complexity → Tactical DDD (aggregates, value objects) without full strategic mapping
  - Multiple teams or complex language conflicts → Full strategic DDD (bounded contexts, context maps, ACLs)
```

---

## Core Domain vs. Supporting Domain vs. Generic Subdomain

| Subdomain type | Definition | Investment level | Examples |
|---------------|-----------|-----------------|---------|
| **Core Domain** | The unique business capability that provides competitive advantage | Maximum — this is why you exist | Recommendation engine for Netflix, fraud detection for Stripe |
| **Supporting Subdomain** | Important but not differentiating; specific to your business | Moderate — build it, but don't over-engineer | Order management, customer profiles |
| **Generic Subdomain** | Solved problem that isn't specific to your business | Minimal — buy or use open source | Authentication, email sending, payment processing |

**Implication:** Spend your best engineers on the Core Domain. Use Stripe for payments (Generic). Build your own order management (Supporting). Never outsource your recommendation algorithm if that's your moat.

---

## Team Topology Alignment

Bounded contexts should align with team ownership. Conway's Law: systems mirror the communication structure of the organizations that build them.

### Inverse Conway Maneuver
Design the team structure you want, then let the architecture follow.

```
Desired architecture → design team structure → architecture naturally emerges

Example:
  Want: Catalog and Orders as separate services
  Do:   Create a Catalog team and an Orders team
  Result: They'll naturally define a clean API between them
         because they have no other way to coordinate

Anti-pattern:
  One team owns both Catalog and Orders
  Result: The "boundary" leaks because it's faster to share a DB than define an API
```

### Team ownership checklist
- [ ] Each bounded context has exactly one owning team
- [ ] No bounded context is owned by multiple teams without an explicit collaboration agreement
- [ ] Integration between contexts goes through documented APIs or events, not direct DB access
- [ ] Schema changes in one context do not require code changes in another (unless intentionally coupled)

---

## Anti-Patterns

### Applying DDD to CRUD
Using aggregates, domain events, and bounded contexts for a feature that's just "store this data and display it." The overhead is real and the payoff isn't there. Reserve DDD for genuinely complex business logic.

### Ignoring Conway's Law
Designing a beautiful microservices architecture but leaving all services owned by one team. The "boundaries" will erode because there's no organizational force maintaining them.

---

## Quick Reference

```
DDD decision: complex logic + changing rules + multiple teams → full DDD; otherwise CRUD is fine
Core domain: your competitive moat — max engineering investment, build in-house
Generic subdomain: solved problem — buy or use open source (auth, payments, email)
Supporting subdomain: important but not differentiating — build it, don't over-engineer
Conway's Law: architecture reflects team structure — use Inverse Conway Maneuver intentionally
One team per context — shared ownership without explicit protocol leads to boundary erosion
```
