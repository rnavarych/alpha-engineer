---
name: ledger-design
description: |
  Guides double-entry ledger design: journal entries, chart of accounts, sub-ledgers
  (AR, AP, GL), reconciliation between ledgers, immutable append-only audit trails,
  balance calculations (running vs computed), and ledger-as-event-log pattern.
  Use when designing accounting systems or financial record-keeping.
allowed-tools: Read, Grep, Glob, Bash
---

You are a ledger design specialist. The fundamental rule: every debit must have an equal and opposite credit. No exceptions.

## Double-Entry Bookkeeping Fundamentals

### The Golden Rule
- Every financial transaction produces at least two journal lines
- Total debits must exactly equal total credits in every journal entry
- Enforce this with a database CHECK constraint or application-level validation
- If debits != credits, reject the entire entry — never allow an unbalanced post

### Debit and Credit Rules
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

## Journal Entry Design

### Journal Entry Schema
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

### Entry Validation Rules
- Sum of all line amounts in an entry must equal zero (debits positive, credits negative)
- Minimum two lines per entry
- All lines must use the same entry date
- Cross-currency entries must include exchange rate reference
- Enforce with a database trigger or application-level check before INSERT

## Chart of Accounts

### Account Numbering Convention
```
1000-1999  Assets
  1000-1099  Cash and Cash Equivalents
  1100-1199  Accounts Receivable
  1200-1299  Investments
2000-2999  Liabilities
  2000-2099  Accounts Payable
  2100-2199  Loans and Credit Lines
  2200-2299  Deferred Revenue
3000-3999  Equity
4000-4999  Revenue
5000-5999  Cost of Goods Sold
6000-6999  Operating Expenses
7000-7999  Other Income/Expense
```

### Account Schema
```sql
CREATE TABLE accounts (
    id              BIGSERIAL PRIMARY KEY,
    account_number  VARCHAR(20) UNIQUE NOT NULL,
    name            VARCHAR(200) NOT NULL,
    account_type    VARCHAR(20) NOT NULL CHECK (account_type IN
                    ('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE')),
    normal_balance  VARCHAR(6) NOT NULL CHECK (normal_balance IN ('DEBIT','CREDIT')),
    parent_id       BIGINT REFERENCES accounts(id),
    currency        CHAR(3) NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## Sub-Ledgers

### General Ledger (GL)
- The master ledger containing all account balances
- Receives postings from all sub-ledgers
- Source of truth for financial statements (balance sheet, income statement)
- Period-end closing process rolls revenue/expense into retained earnings

### Accounts Receivable (AR)
- Tracks money owed to the business by customers
- Links to customer records and invoice documents
- Aging reports: current, 30-day, 60-day, 90-day, 120-day+ buckets
- Posts summary entries to GL (total AR balance change)

### Accounts Payable (AP)
- Tracks money owed by the business to vendors
- Links to vendor records and purchase orders
- Payment scheduling with early payment discount tracking
- Posts summary entries to GL (total AP balance change)

### Sub-Ledger to GL Reconciliation
- Sub-ledger detail must sum to GL control account balance
- Run reconciliation daily as an automated process
- Any discrepancy is a critical alert requiring immediate investigation

## Audit Trails

### Immutable Append-Only Design
- Journal entries are NEVER updated or deleted after posting
- Corrections are made by posting reversing entries
- Use database permissions to REVOKE UPDATE and DELETE on journal tables
- Consider write-once storage (WORM) for regulatory compliance

### Reversal Pattern
```
Original:  DR Cash $500  /  CR Revenue $500
Reversal:  DR Revenue $500  /  CR Cash $500  (reference: original entry ID)
Correction: DR Cash $450  /  CR Revenue $450
```

### Hash Chain Integrity
- Compute SHA-256 hash of each entry including previous entry's hash
- Enables tamper detection: any modification breaks the chain
- Store hash chain checkpoints for periodic integrity verification

## Balance Calculations

### Running Balance (Materialized)
- Maintain a running balance column updated on each posting
- Faster reads (O(1) balance lookup) but requires careful concurrency control
- Must reconcile with computed balance periodically
- Use database triggers or serialized updates to prevent race conditions

### Computed Balance (Derived)
- Calculate balance as SUM of all journal lines for an account
- Always accurate but slower for accounts with many entries (use indexes)
- Suitable for reconciliation and audit verification
- `SELECT SUM(amount) FROM journal_lines WHERE account_id = :id`

### Hybrid Approach (Recommended)
- Maintain running balance for fast reads
- Compute balance from journal lines for daily reconciliation
- Alert if running balance diverges from computed balance
- Running balance is a cache; journal lines are the source of truth

## Ledger-as-Event-Log

### Event Sourcing for Financial Data
- Treat journal entries as the event log — they ARE the source of truth
- Account balances are projections (materialized views) of the event stream
- Rebuild any balance by replaying journal entries from the beginning
- Enables point-in-time balance queries by replaying up to a given date

### Benefits for Financial Systems
- Complete audit trail is inherent in the design
- Retroactive corrections via reversing entries preserve history
- Regulatory reporting can replay events for any reporting period
- Debugging financial discrepancies by examining the event sequence
