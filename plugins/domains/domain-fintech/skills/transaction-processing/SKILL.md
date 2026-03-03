---
name: domain-fintech:transaction-processing
description: Guides transaction processing: ACID guarantees for financial operations, idempotency (idempotency keys, deduplication), distributed transactions (saga with compensating transactions), settlement workflows, batch processing, reconciliation, and transaction lifecycle state management. Use when implementing payment flows or financial operations.
allowed-tools: Read, Grep, Glob, Bash
---

# Transaction Processing

## When to use
- Implementing atomic balance transfers with correct isolation levels
- Adding idempotency keys to payment endpoints
- Designing saga-based distributed payment flows with compensating transactions
- Modelling settlement cycles (T+0, T+1, T+2) and netting/clearing processes
- Building three-way reconciliation (internal, external, cross-system)
- Defining transaction state machines with enforced valid transitions

## Core principles
1. **SERIALIZABLE isolation for balance mutations** — REPEATABLE READ is the floor, never lower
2. **Idempotency is not optional** — every mutating payment endpoint needs a key; at-least-once delivery is a guarantee, not an edge case
3. **Orchestrated sagas over choreography** — financial workflows need a single audit trail, not distributed event soup
4. **Compensating transactions must also be idempotent** — a failed rollback is worse than a failed forward step
5. **Never delete transactions** — COMPLETED, FAILED, REVERSED are terminal; the ledger is append-only

## Reference Files
- `references/acid-idempotency.md` — transaction isolation levels, SELECT FOR UPDATE, atomic transfer SQL pattern, idempotency key schema, deduplication with request hashing, exactly-once semantics
- `references/saga-settlement.md` — choreography vs orchestration trade-offs, compensating transactions, saga state machine diagram, settlement cycles (T+0/T+1/T+2), netting and clearing process, idempotent batch processing
- `references/reconciliation-lifecycle.md` — three-way reconciliation (internal/external/cross-system), daily reconciliation process, break resolution SLAs, transaction state machine (PENDING through REVERSED), state transition enforcement
