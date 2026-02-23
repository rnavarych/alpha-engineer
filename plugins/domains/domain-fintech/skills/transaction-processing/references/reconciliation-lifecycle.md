# Reconciliation and Transaction Lifecycle States

## When to load
Load when designing three-way reconciliation processes, building break resolution workflows,
or implementing transaction state machines with valid transition enforcement.

## Three-Way Reconciliation

1. **Internal**: ledger balances vs computed sum of journal entries
2. **External**: internal records vs bank statements / payment processor reports
3. **Cross-system**: between microservices (orders vs payments vs fulfillment)

## Reconciliation Process

- Daily automated reconciliation with exception reporting
- Match by: transaction ID, amount, date, counterparty
- Handle timing differences (transactions in flight at cutoff)
- Escalation workflow: auto-match -> manual review -> adjustment entry
- Store reconciliation results with match status and resolution notes

## Break Resolution

- Investigate unmatched items within SLA (typically 24-48 hours)
- Create adjustment entries for legitimate differences
- Flag suspicious discrepancies for fraud review
- Track break rates as a system health metric

## Core Transaction States

- **PENDING**: created, awaiting processing
- **PROCESSING**: actively being executed
- **AUTHORIZED**: funds reserved but not yet captured
- **COMPLETED**: successfully settled
- **FAILED**: processing error (retryable or terminal)
- **REVERSED**: fully reversed after completion
- **PARTIALLY_REVERSED**: partial refund applied

## State Transition Rules

- Only allow valid transitions (e.g., COMPLETED -> REVERSED, never PENDING -> REVERSED)
- Record every state transition with timestamp, actor, and reason
- Use database enum or check constraints to enforce valid states
- Implement state-specific business rules (e.g., reversal window, retry limits)
- Never delete transactions — terminal states are COMPLETED, FAILED, REVERSED
