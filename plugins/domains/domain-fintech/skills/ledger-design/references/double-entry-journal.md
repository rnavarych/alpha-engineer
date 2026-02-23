# Double-Entry Bookkeeping and Journal Entry Design

## When to load
Load when implementing double-entry journal entries, designing journal schema, or enforcing
debit/credit validation rules. Covers the golden rule, account normal balances, and SQL schema.

## The Golden Rule

- Every financial transaction produces at least two journal lines
- Total debits must exactly equal total credits in every journal entry
- Enforce with a database CHECK constraint or application-level validation
- If debits != credits, reject the entire entry — never allow an unbalanced post

## Debit and Credit Rules

| Account Type | Debit Effect | Credit Effect | Normal Balance |
|-------------|-------------|--------------|----------------|
| Asset       | Increase    | Decrease     | Debit          |
| Liability   | Decrease    | Increase     | Credit         |
| Equity      | Decrease    | Increase     | Credit         |
| Revenue     | Decrease    | Increase     | Credit         |
| Expense     | Increase    | Decrease     | Debit          |

### Example: Customer Payment
```
Journal Entry: Customer pays $500 invoice
  DR  Cash (Asset)                 $500.00
  CR  Accounts Receivable (Asset)  $500.00
```

## Journal Entry Schema

```sql
CREATE TABLE journal_entries (
    id              BIGSERIAL PRIMARY KEY,
    entry_date      DATE NOT NULL,
    posted_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description     TEXT NOT NULL,
    reference_type  VARCHAR(50),      -- 'PAYMENT', 'INVOICE', 'ADJUSTMENT'
    reference_id    VARCHAR(100),     -- external reference
    created_by      VARCHAR(100) NOT NULL,
    is_reversing    BOOLEAN DEFAULT FALSE,
    reversed_by_id  BIGINT REFERENCES journal_entries(id)
);

CREATE TABLE journal_lines (
    id              BIGSERIAL PRIMARY KEY,
    entry_id        BIGINT NOT NULL REFERENCES journal_entries(id),
    account_id      BIGINT NOT NULL REFERENCES accounts(id),
    amount          DECIMAL(19,4) NOT NULL,  -- positive = debit, negative = credit
    currency        CHAR(3) NOT NULL,
    memo            TEXT
);
```

## Entry Validation Rules

- Sum of all line amounts in an entry must equal zero (debits positive, credits negative)
- Minimum two lines per entry
- All lines must use the same entry date
- Cross-currency entries must include exchange rate reference
- Enforce with a database trigger or application-level check before INSERT
