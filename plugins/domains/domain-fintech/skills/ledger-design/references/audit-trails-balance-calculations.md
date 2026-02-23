# Audit Trails, Balance Calculations, and Event Sourcing

## When to load
Load when implementing immutable ledger audit trails, choosing between running vs computed balances,
enforcing hash chain integrity, or applying event sourcing patterns to financial data.

## Immutable Append-Only Design

- Journal entries are NEVER updated or deleted after posting
- Corrections are made by posting reversing entries
- Use database permissions to REVOKE UPDATE and DELETE on journal tables
- Consider write-once storage (WORM) for regulatory compliance

## Reversal Pattern

```
Original:   DR Cash $500  /  CR Revenue $500
Reversal:   DR Revenue $500  /  CR Cash $500  (reference: original entry ID)
Correction: DR Cash $450  /  CR Revenue $450
```

## Hash Chain Integrity

- Compute SHA-256 hash of each entry including previous entry's hash
- Enables tamper detection: any modification breaks the chain
- Store hash chain checkpoints for periodic integrity verification

## Running Balance (Materialized)

- Maintain a running balance column updated on each posting
- Faster reads (O(1) balance lookup) but requires careful concurrency control
- Must reconcile with computed balance periodically
- Use database triggers or serialized updates to prevent race conditions

## Computed Balance (Derived)

- Calculate balance as SUM of all journal lines for an account
- Always accurate but slower for accounts with many entries (use indexes)
- Suitable for reconciliation and audit verification
- `SELECT SUM(amount) FROM journal_lines WHERE account_id = :id`

## Hybrid Approach (Recommended)

- Maintain running balance for fast reads
- Compute balance from journal lines for daily reconciliation
- Alert if running balance diverges from computed balance
- Running balance is a cache; journal lines are the source of truth

## Ledger-as-Event-Log (Event Sourcing)

- Treat journal entries as the event log — they ARE the source of truth
- Account balances are projections (materialized views) of the event stream
- Rebuild any balance by replaying journal entries from the beginning
- Enables point-in-time balance queries by replaying up to a given date
- Complete audit trail is inherent in the design
- Retroactive corrections via reversing entries preserve history
- Regulatory reporting can replay events for any reporting period
