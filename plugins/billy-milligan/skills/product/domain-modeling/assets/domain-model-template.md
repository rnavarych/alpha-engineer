# Bounded Context Canvas: [Context Name]

## Purpose
[1-2 sentences: what business capability does this context own?]

## Ubiquitous Language

| Term | Definition | Notes |
|------|-----------|-------|
| [Term] | [Definition in this context] | [Conflicts with other contexts?] |
| [Term] | [Definition] | |

## Aggregates

### [Aggregate Name]
- **Root Entity**: [Entity]
- **Value Objects**: [List]
- **Invariants**: [Business rules this aggregate enforces]
- **Commands**: [What actions can be performed]
- **Events Published**: [What events this aggregate emits]

## Domain Events

| Event | Trigger | Consumers |
|-------|---------|-----------|
| [OrderPlaced] | [Customer submits order] | [Fulfillment, Notifications] |
| [PaymentCompleted] | [Payment provider confirms] | [Orders, Analytics] |

## Context Relationships

| Related Context | Relationship | Integration |
|----------------|-------------|-------------|
| [Context] | [Upstream / Downstream / Partnership] | [API / Events / Shared Kernel] |
| [Context] | [Conformist / Anti-Corruption Layer] | [Translation layer] |

## Data Ownership
- **Owned Entities**: [List entities this context is source of truth for]
- **Referenced Entities**: [List entities owned by other contexts]

## Open Questions
- [ ] [Boundary question 1]
