# Temporal Data Patterns and Data Integrity

## When to load
Load when implementing effective dating, point-in-time queries, bi-temporal schemas, or enforcing
data integrity rules for financial records.

## Effective Dating

- Use `effective_from` and `effective_to` (NULL = current) for time-varying data
- Interest rates, fee schedules, and account terms must be effective-dated
- Prevent overlapping effective date ranges with database constraints

## As-Of Queries

- Support point-in-time queries: "what was the balance on 2024-01-15?"
- Use bi-temporal modeling when both business time and system time matter
- System time tracks when a record was inserted (audit), business time tracks when it applies

## Bi-Temporal Schema Pattern

```sql
CREATE TABLE account_balances (
    account_id     BIGINT NOT NULL,
    amount         DECIMAL(19,4) NOT NULL,
    currency       CHAR(3) NOT NULL,
    valid_from     TIMESTAMP NOT NULL,  -- business time
    valid_to       TIMESTAMP,           -- business time
    system_from    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- audit time
    system_to      TIMESTAMP            -- audit time (NULL = current version)
);
```

## Data Integrity Rules

- All monetary amounts must have an associated currency code
- Account balances must equal the sum of all journal entry lines for that account
- Cross-currency entries must include exchange rate and base currency equivalent
- Soft-delete only: use status flags or effective dates, never DELETE financial records
- Foreign key constraints for all account references in transaction tables
