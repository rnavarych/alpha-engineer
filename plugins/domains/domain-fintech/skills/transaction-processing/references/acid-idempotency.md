# ACID Guarantees and Idempotency

## When to load
Load when implementing atomic financial operations, choosing transaction isolation levels, or
building idempotency key patterns to convert at-least-once delivery to effectively-exactly-once.

## Transaction Isolation

- Use SERIALIZABLE isolation for balance-affecting operations
- Use REPEATABLE READ as the minimum for financial reads
- Implement `SELECT ... FOR UPDATE` to lock rows during balance checks
- Wrap debit + credit in a single database transaction — never split across requests

## Atomicity Patterns

- All-or-nothing: if any step fails, the entire operation rolls back
- Use database transactions, not application-level compensation, whenever possible
- For multi-database operations, use saga pattern with compensating transactions
- Log transaction attempts before execution for crash recovery

## Atomic Transfer Example

```sql
BEGIN;
  UPDATE accounts SET balance = balance - 100.00 WHERE id = :from_id AND balance >= 100.00;
  -- Check row count: if 0, insufficient funds — ROLLBACK
  UPDATE accounts SET balance = balance + 100.00 WHERE id = :to_id;
  INSERT INTO journal_entries (...) VALUES (...);
  INSERT INTO journal_lines (...) VALUES (...), (...);
COMMIT;
```

## Idempotency Key Pattern

- Require a client-generated idempotency key (UUID v4) for every mutating request
- Store the key with the request hash and response in an idempotency table
- On duplicate key: return the stored response without re-executing
- Expire idempotency records after 24-72 hours

## Deduplication Strategy

```
idempotency_keys: key (PK), request_hash, response_body, status_code,
                  created_at, expires_at
```

- Hash the request body to detect payload changes with the same key
- If key exists but hash differs, reject with 422 Unprocessable Entity
- Use database UNIQUE constraint on the key column for race condition safety
- Wrap idempotency check + operation in the same database transaction

## At-Least-Once to Exactly-Once

- Accept that network failures make exactly-once delivery impossible
- Design all operations to be safely re-executable (idempotent)
- Use idempotency keys to convert at-least-once into effectively-exactly-once
