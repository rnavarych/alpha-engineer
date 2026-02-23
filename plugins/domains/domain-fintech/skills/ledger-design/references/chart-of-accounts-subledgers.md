# Chart of Accounts and Sub-Ledgers

## When to load
Load when designing a chart of accounts numbering system, building AR/AP sub-ledgers, or
implementing GL reconciliation between sub-ledgers and control accounts.

## Account Numbering Convention

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

## Account Schema

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

## General Ledger (GL)

- The master ledger containing all account balances
- Receives postings from all sub-ledgers
- Source of truth for financial statements (balance sheet, income statement)
- Period-end closing process rolls revenue/expense into retained earnings

## Accounts Receivable (AR)

- Tracks money owed to the business by customers
- Links to customer records and invoice documents
- Aging reports: current, 30-day, 60-day, 90-day, 120-day+ buckets
- Posts summary entries to GL (total AR balance change)

## Accounts Payable (AP)

- Tracks money owed by the business to vendors
- Links to vendor records and purchase orders
- Payment scheduling with early payment discount tracking
- Posts summary entries to GL (total AP balance change)

## Sub-Ledger to GL Reconciliation

- Sub-ledger detail must sum to GL control account balance
- Run reconciliation daily as an automated process
- Any discrepancy is a critical alert requiring immediate investigation
