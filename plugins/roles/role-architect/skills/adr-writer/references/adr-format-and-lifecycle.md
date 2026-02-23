# ADR Format, Numbering, and Status Lifecycle

## When to load
Load when writing a new Architecture Decision Record, determining the right format (full vs. lightweight), numbering ADRs and maintaining the index, managing status transitions, or linking related decisions.

## ADR Format

Every Architecture Decision Record follows this structure:

### Title
- Format: `ADR-NNNN: <Short Imperative Statement>`
- The title states the decision, not the question. Use imperative mood.
- Good: `ADR-0012: Use PostgreSQL for the Order Service`
- Bad: `ADR-0012: Which database should we use?`

### Status
- One of: `Proposed`, `Accepted`, `Deprecated`, `Superseded by ADR-NNNN`
- Only one status is active at a time. Record the date of each status change.

### Context
- Describe the forces at play: technical constraints, business requirements, team capabilities, timeline pressure, and existing system landscape.
- Be specific. "We need a database" is not context. "The order service processes 500 writes/second with strict ACID requirements, and the team has 3 years of PostgreSQL experience" is context.
- Include what prompted this decision now. What changed or what is new?

### Decision
- State the decision clearly in one or two sentences.
- Follow with the rationale: why this option was chosen over the alternatives.
- List the alternatives that were considered, with a brief explanation of why each was rejected.

### Consequences
- **Positive**: What becomes easier, faster, cheaper, or more reliable as a result.
- **Negative**: What becomes harder, slower, more expensive, or riskier. Every decision has trade-offs; if the consequences section lists only positives, it is incomplete.
- **Neutral**: Changes that are neither good nor bad but worth noting (e.g., "The team will need to learn Kotlin").

## ADR Numbering and Index

- Number ADRs sequentially starting from `0001`. Never reuse a number, even if the ADR is deprecated.
- Maintain an `index.md` or `README.md` in the ADR directory that lists all ADRs with their number, title, and status.
- Format the index as a table:

```
| Number | Title | Status |
|--------|-------|--------|
| ADR-0001 | Use monorepo structure | Accepted |
| ADR-0002 | Adopt GraphQL for public API | Superseded by ADR-0015 |
```

- Store ADRs in a dedicated directory (e.g., `docs/adr/` or `architecture/decisions/`).
- Use the filename format `NNNN-short-title.md` (e.g., `0012-use-postgresql-for-order-service.md`).

## Status Lifecycle

### Proposed -> Accepted
- A new ADR starts as `Proposed`. It is a draft open for review.
- After team review and approval (at least one senior engineer or architect), change status to `Accepted` with the acceptance date.

### Accepted -> Deprecated
- When a decision is no longer relevant (the system it applies to has been decommissioned, or the constraint no longer exists), mark it `Deprecated`.
- Add a note explaining why it was deprecated and when.

### Accepted -> Superseded
- When a new decision replaces an old one, mark the old ADR as `Superseded by ADR-NNNN`.
- The new ADR should reference the old one in its Context section, explaining what changed.
- Never delete or overwrite an old ADR. The history of decisions is valuable.

## Lightweight ADRs

- Not every decision needs a full ADR. Use lightweight ADRs for smaller choices.
- A lightweight ADR can be as short as 5-10 lines: Title, Status, one-paragraph Context, one-sentence Decision, and bullet-point Consequences.
- Use lightweight ADRs for: library choices, coding conventions, CI/CD tool selection, testing strategy tweaks.
- Reserve full ADRs for: database choices, service decomposition, API design philosophy, data model changes, infrastructure platform selection.

## Linking Related ADRs

- When one ADR depends on or is influenced by another, add a `Related` section with links.
- Use bidirectional links: if ADR-0010 references ADR-0005, update ADR-0005 to reference ADR-0010.
- Common relationships:
  - **Depends on**: This decision assumes the referenced decision is in effect.
  - **Supersedes**: This decision replaces the referenced decision.
  - **Informed by**: This decision was influenced by lessons learned from the referenced decision.
  - **Enables**: This decision makes the referenced decision possible or practical.
