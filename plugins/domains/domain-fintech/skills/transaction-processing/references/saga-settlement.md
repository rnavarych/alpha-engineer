# Distributed Transactions, Settlement Workflows, and Batch Processing

## When to load
Load when implementing saga pattern for cross-service financial flows, designing settlement cycles,
building idempotent batch processing, or structuring netting and clearing processes.

## Choreography vs Orchestration

- **Choreography**: services react to events (simpler, harder to monitor)
- **Orchestration**: central coordinator manages steps (more control, single point of visibility)
- Prefer orchestration for financial workflows (easier to audit and debug)

## Compensating Transactions

- Every forward action must have a defined compensating (undo) action
- Example: charge payment -> refund payment, reserve inventory -> release inventory
- Compensating transactions must also be idempotent
- Record saga state transitions for auditability

## Saga State Machine

```
INITIATED -> VALIDATING -> AUTHORIZED -> CAPTURING -> SETTLED -> COMPLETED
                |              |             |
                v              v             v
            VALIDATION_FAILED  AUTH_FAILED  CAPTURE_FAILED -> COMPENSATING -> COMPENSATED
```

## Settlement Cycles

- **T+0** (real-time): crypto, instant payments (Faster Payments, SEPA Instant)
- **T+1**: most card transactions, ACH same-day
- **T+2**: traditional securities settlement (moving to T+1)
- Track settlement date separately from transaction date

## Settlement Process

1. **Netting**: aggregate transactions between counterparties to reduce transfers
2. **Clearing**: validate and match transactions between parties
3. **Settlement**: actual movement of funds between accounts
4. **Confirmation**: notify all parties of completed settlement

## Batch Processing

- End-of-day batch runs for fee calculation, interest accrual, statement generation
- Use database-level locking or dedicated processing windows to avoid conflicts
- Implement checkpoint/restart for long-running batches
- Idempotent batch steps: re-running a batch produces the same result
