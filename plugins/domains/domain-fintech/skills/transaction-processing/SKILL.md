---
name: transaction-processing
description: |
  Guides transaction processing: ACID guarantees for financial operations, idempotency
  (idempotency keys, deduplication), distributed transactions (saga with compensating
  transactions), settlement workflows, batch processing, reconciliation, and transaction
  lifecycle state management. Use when implementing payment flows or financial operations.
allowed-tools: Read, Grep, Glob, Bash
---

You are a transaction processing specialist. Every financial operation must be correct, idempotent, and auditable.

## ACID Guarantees for Financial Operations

### Transaction Isolation
- Use SERIALIZABLE isolation for balance-affecting operations
- Use REPEATABLE READ as the minimum for financial reads
- Implement SELECT ... FOR UPDATE to lock rows during balance checks
- Wrap debit + credit in a single database transaction — never split across requests

### Atomicity Patterns
- All-or-nothing: if any step fails, the entire operation rolls back
- Use database transactions, not application-level compensation, whenever possible
- For multi-database operations, use saga pattern with compensating transactions
- Log transaction attempts before execution for crash recovery

### Consistency Enforcement
```sql
-- Example: atomic transfer between accounts
BEGIN;
  UPDATE accounts SET balance = balance - 100.00 WHERE id = :from_id AND balance >= 100.00;
  -- Check row count: if 0, insufficient funds — ROLLBACK
  UPDATE accounts SET balance = balance + 100.00 WHERE id = :to_id;
  INSERT INTO journal_entries (...) VALUES (...);
  INSERT INTO journal_lines (...) VALUES (...), (...);
COMMIT;
```

## Idempotency

### Idempotency Key Pattern
- Require a client-generated idempotency key (UUID v4) for every mutating request
- Store the key with the request hash and response in an idempotency table
- On duplicate key: return the stored response without re-executing
- Expire idempotency records after 24-72 hours

### Deduplication Strategy
```
idempotency_keys: key (PK), request_hash, response_body, status_code,
                  created_at, expires_at
```
- Hash the request body to detect payload changes with the same key
- If key exists but hash differs, reject with 422 Unprocessable Entity
- Use database UNIQUE constraint on the key column for race condition safety
- Wrap idempotency check + operation in the same database transaction

### At-Least-Once to Exactly-Once
- Accept that network failures make exactly-once delivery impossible
- Design all operations to be safely re-executable (idempotent)
- Use idempotency keys to convert at-least-once into effectively-exactly-once

## Distributed Transactions (Saga Pattern)

### Choreography vs Orchestration
- **Choreography**: services react to events (simpler, harder to monitor)
- **Orchestration**: central coordinator manages steps (more control, single point of visibility)
- Prefer orchestration for financial workflows (easier to audit and debug)

### Compensating Transactions
- Every forward action must have a defined compensating (undo) action
- Example: charge payment -> refund payment, reserve inventory -> release inventory
- Compensating transactions must also be idempotent
- Record saga state transitions for auditability

### Saga State Machine
```
INITIATED -> VALIDATING -> AUTHORIZED -> CAPTURING -> SETTLED -> COMPLETED
                |              |             |
                v              v             v
            VALIDATION_FAILED  AUTH_FAILED  CAPTURE_FAILED -> COMPENSATING -> COMPENSATED
```

## Settlement Workflows

### Settlement Cycles
- **T+0** (real-time): crypto, instant payments (Faster Payments, SEPA Instant)
- **T+1**: most card transactions, ACH same-day
- **T+2**: traditional securities settlement (moving to T+1)
- Track settlement date separately from transaction date

### Settlement Process
1. **Netting**: aggregate transactions between counterparties to reduce transfers
2. **Clearing**: validate and match transactions between parties
3. **Settlement**: actual movement of funds between accounts
4. **Confirmation**: notify all parties of completed settlement

### Batch Processing
- End-of-day batch runs for fee calculation, interest accrual, statement generation
- Use database-level locking or dedicated processing windows to avoid conflicts
- Implement checkpoint/restart for long-running batches
- Idempotent batch steps: re-running a batch produces the same result

## Reconciliation

### Three-Way Reconciliation
1. **Internal**: ledger balances vs computed sum of journal entries
2. **External**: internal records vs bank statements / payment processor reports
3. **Cross-system**: between microservices (orders vs payments vs fulfillment)

### Reconciliation Process
- Daily automated reconciliation with exception reporting
- Match by: transaction ID, amount, date, counterparty
- Handle timing differences (transactions in flight at cutoff)
- Escalation workflow: auto-match -> manual review -> adjustment entry
- Store reconciliation results with match status and resolution notes

### Break Resolution
- Investigate unmatched items within SLA (typically 24-48 hours)
- Create adjustment entries for legitimate differences
- Flag suspicious discrepancies for fraud review
- Track break rates as a system health metric

## Transaction Lifecycle States

### Core State Machine
- **PENDING**: created, awaiting processing
- **PROCESSING**: actively being executed
- **AUTHORIZED**: funds reserved but not yet captured
- **COMPLETED**: successfully settled
- **FAILED**: processing error (retryable or terminal)
- **REVERSED**: fully reversed after completion
- **PARTIALLY_REVERSED**: partial refund applied

### State Transition Rules
- Only allow valid transitions (e.g., COMPLETED -> REVERSED, never PENDING -> REVERSED)
- Record every state transition with timestamp, actor, and reason
- Use database enum or check constraints to enforce valid states
- Implement state-specific business rules (e.g., reversal window, retry limits)
- Never delete transactions — terminal states are COMPLETED, FAILED, REVERSED
