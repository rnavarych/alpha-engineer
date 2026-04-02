---
name: ledger-design
description: "Guides double-entry ledger design: journal entries, chart of accounts, sub-ledgers (AR, AP, GL), reconciliation between ledgers, immutable append-only audit trails, balance calculations (running vs computed), and ledger-as-event-log pattern. Use when designing accounting systems, implementing double-entry bookkeeping, or building financial record-keeping with audit trails."
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

## Workflow

### Step 1: Design the journal entry schema
```sql
CREATE TABLE journal_entries (
    id BIGSERIAL PRIMARY KEY,
    entry_date DATE NOT NULL,
    description TEXT NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    hash CHAR(64) NOT NULL,           -- SHA-256 chain
    previous_hash CHAR(64) NOT NULL   -- links to prior entry
);

CREATE TABLE journal_lines (
    id BIGSERIAL PRIMARY KEY,
    entry_id BIGINT REFERENCES journal_entries(id),
    account_id BIGINT NOT NULL,
    debit DECIMAL(19,4) DEFAULT 0,
    credit DECIMAL(19,4) DEFAULT 0,
    CONSTRAINT positive_amounts CHECK (debit >= 0 AND credit >= 0),
    CONSTRAINT single_side CHECK (debit = 0 OR credit = 0)
);
```

### Step 2: Enforce the double-entry invariant
```sql
-- Constraint: every journal entry must balance
-- Validate before insert (application layer)
SELECT SUM(debit) - SUM(credit) AS imbalance
FROM journal_lines WHERE entry_id = :new_entry_id;
-- imbalance MUST equal 0; reject if not
```

### Step 3: Implement correction via reversal
```
# Never UPDATE or DELETE — create a reversing entry instead
Original: Debit Cash $500, Credit Revenue $500 (entry #1001)
Reversal: Debit Revenue $500, Credit Cash $500 (entry #1002)
            → references entry #1001 as reversed_entry_id
Corrected: Debit Cash $450, Credit Revenue $450 (entry #1003)
```

### Step 4: Reconcile sub-ledgers to GL
- Sum all AR sub-ledger balances → must equal GL account 1200 (Accounts Receivable)
- Sum all AP sub-ledger balances → must equal GL account 2100 (Accounts Payable)
- Run reconciliation daily; any discrepancy triggers a critical alert
- Log reconciliation results with timestamp for audit evidence

## Reference Files
- `references/double-entry-journal.md` — golden rule, debit/credit rules table, example entries, journal_entries and journal_lines SQL schema, entry validation rules
- `references/chart-of-accounts-subledgers.md` — account numbering convention (1000-7999), accounts SQL schema, GL/AR/AP sub-ledger design, sub-ledger to GL reconciliation
- `references/audit-trails-balance-calculations.md` — immutable append-only design, reversal pattern, hash chain integrity, running vs computed balance, hybrid approach, ledger-as-event-log with event sourcing
