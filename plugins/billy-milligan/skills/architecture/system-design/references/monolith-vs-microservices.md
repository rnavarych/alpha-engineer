# Monolith vs Microservices

## When to load
Load when discussing whether to use monolith or microservices, or evaluating team/scale readiness for decomposition.

## Decision matrix

| Signal | Monolith | Modular Monolith | Microservices |
|--------|----------|-----------------|---------------|
| Team size | <10 engineers | 10–50 | >50 |
| Traffic | <10k RPM | 10k–100k RPM | >100k RPM or burst |
| Deploy frequency | Weekly | Daily | Multiple/day per service |
| Domain complexity | Simple | Medium, clear bounded contexts | High, independent scaling needs |
| Org structure | 1 team | 2–5 teams | Many teams, autonomous |

**Rule**: Don't do microservices until you have **two of three**: >50 engineers, >100k RPM, independent scaling requirements.

## Patterns ✅

### Service boundary identification
| Question | Yes → Same Service | No → Consider Split |
|----------|-------------------|---------------------|
| Change together? | ✓ | × |
| Share a DB transaction? | ✓ (usually) | × |
| One team owns both? | ✓ | × |
| Scale independently? | × | ✓ |
| Different business domains? | × | ✓ |
| Different regulations? | × | ✓ |

## Anti-patterns ❌

### Distributed monolith
Services share a database or call each other synchronously in chains. Service A→B→C→D: if D is slow, A is slow. Deploy B? Must coordinate with A and C. Detection: >3 sync calls per user request, shared DB connection strings.

### Microservices too early
Splitting before understanding domain boundaries. Wrong boundaries require cross-service transactions. 3-person team spending 60% on infra instead of product.

## Quick reference
```
<50 engineers + <100k RPM → monolith or modular monolith
>50 engineers OR >100k RPM → evaluate modular monolith first
>50 engineers AND >100k RPM AND independent scaling → microservices
Historical failure rate of big bang rewrites: >70% (Standish CHAOS Report)
```
