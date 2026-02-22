# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the project.

ADRs document significant technical decisions, the context behind them,
the options considered, and the rationale for the chosen approach.
They are a permanent record of *why* the architecture looks the way it does.

## Index

| # | Title | Status | Date |
|---|-------|--------|------|
| [001](001-database-choice.md) | Database Choice | ACCEPTED | 2025-02-19 |
| [002](002-authentication-approach.md) | Authentication Approach | ACCEPTED | 2025-02-20 |
| [003](003-frontend-styling-approach.md) | Frontend Styling Approach | ACCEPTED | 2025-02-21 |

## Process

1. **Propose:** Create a new ADR with status `PROPOSED` using `/adr:new "<title>"`
2. **Discuss:** Team reviews and provides feedback via `/adr:review <number>`
3. **Accept:** Change status to `ACCEPTED` via `/adr:status <number> ACCEPTED`
4. **Evolve:** If a decision changes, create a new ADR and mark the old one `SUPERSEDED` via `/adr:supersede <old> "<new-title>"`

## Statuses

| Status | Meaning |
|--------|---------|
| `PROPOSED` | Decision is under discussion, not yet finalized |
| `ACCEPTED` | Decision is in effect |
| `DEPRECATED` | Decision no longer applies but was not replaced |
| `SUPERSEDED by ADR-NNN` | Decision was replaced by a newer ADR |

## Numbering

ADR numbers are sequential and never reused. If ADR-003 is superseded,
the replacement is the next available number (e.g., ADR-004), never ADR-003v2.
