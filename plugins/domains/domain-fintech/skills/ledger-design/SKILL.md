---
name: domain-fintech:ledger-design
description: Guides double-entry ledger design: journal entries, chart of accounts, sub-ledgers (AR, AP, GL), reconciliation between ledgers, immutable append-only audit trails, balance calculations (running vs computed), and ledger-as-event-log pattern. Use when designing accounting systems or financial record-keeping.
allowed-tools: Read, Grep, Glob, Bash
---

# Ledger Design

## When to use
- Designing a double-entry bookkeeping system from scratch
- Choosing a chart of accounts numbering convention
- Building AR, AP, or GL sub-ledgers with reconciliation
- Implementing immutable audit trails with reversal patterns
- Deciding between running balance vs computed balance strategies
- Applying event sourcing to financial record-keeping

## Core principles
1. **Debits always equal credits** — enforce with DB constraint; reject unbalanced entries at the boundary
2. **Never UPDATE or DELETE journal entries** — corrections via reversing entries only; history is sacred
3. **Running balance is a cache** — journal lines are the source of truth; reconcile daily
4. **Hash chain for tamper detection** — SHA-256 chained hashes make unauthorized edits detectable
5. **Sub-ledger detail must reconcile to GL control account** — any gap is a critical alert, not a warning

## Reference Files
- `references/double-entry-journal.md` — golden rule, debit/credit rules table, example entries, journal_entries and journal_lines SQL schema, entry validation rules
- `references/chart-of-accounts-subledgers.md` — account numbering convention (1000-7999), accounts SQL schema, GL/AR/AP sub-ledger design, sub-ledger to GL reconciliation
- `references/audit-trails-balance-calculations.md` — immutable append-only design, reversal pattern, hash chain integrity, running vs computed balance, hybrid approach, ledger-as-event-log with event sourcing
