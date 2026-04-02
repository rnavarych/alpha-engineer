---
name: financial-data-modeling
description: "Guides financial data modeling: account structures (asset, liability, equity, revenue, expense), currency handling (ISO 4217, minor units), decimal precision (BigDecimal, integer cents), multi-currency ledgers, financial instrument representation, and temporal data patterns. Use when designing database schemas for financial applications, choosing numeric types for monetary storage, or implementing bi-temporal audit trails."
allowed-tools: Read, Grep, Glob, Bash
---

# Financial Data Modeling

## When to use
- Designing database schemas for accounting or banking applications
- Choosing the right numeric type for monetary storage
- Modeling multi-currency accounts with FX gain/loss tracking
- Representing financial instruments (bonds, equities, derivatives)
- Implementing point-in-time queries and bi-temporal history
- Enforcing data integrity rules for financial records

## Core principles
1. **Never float money** — use `DECIMAL(19,4)` or integer minor units; floating point errors compound
2. **Currency is always explicit** — every amount must carry its ISO 4217 currency code
3. **Soft-delete only** — status flags and effective dates, never DELETE financial records
4. **Bi-temporal when auditability demands it** — system time tracks inserts, business time tracks validity
5. **Cost basis per lot** — position tracking must support FIFO/LIFO/weighted average for tax reporting

## Workflow

### Step 1: Choose monetary storage type
Select the appropriate numeric representation:
```sql
-- Option A: DECIMAL with fixed precision (recommended for SQL databases)
CREATE TABLE transactions (
    amount DECIMAL(19,4) NOT NULL,
    currency CHAR(3) NOT NULL  -- ISO 4217 code
);

-- Option B: Integer minor units (recommended for application code)
-- Store $100.50 as 10050 cents
-- Eliminates rounding errors entirely
```

### Step 2: Design account structure
Map to the five-type chart of accounts:
- **1xxx** Assets (cash, receivables, investments)
- **2xxx** Liabilities (payables, loans, deferred revenue)
- **3xxx** Equity (retained earnings, capital)
- **4xxx** Revenue (sales, interest income)
- **5xxx-7xxx** Expenses (operating, interest, tax)

### Step 3: Implement temporal tracking
```sql
-- Bi-temporal pattern for auditable financial records
CREATE TABLE account_balances (
    account_id BIGINT NOT NULL,
    amount DECIMAL(19,4) NOT NULL,
    currency CHAR(3) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL,   -- business time
    valid_to TIMESTAMPTZ,              -- business time
    system_from TIMESTAMPTZ NOT NULL,  -- system time (auto)
    system_to TIMESTAMPTZ              -- system time (auto)
);
```

### Step 4: Validate data integrity
- Verify all amounts carry explicit currency codes
- Confirm no floating-point types exist for monetary columns
- Check that DELETE operations are blocked (soft-delete only)
- Run reconciliation between sub-ledger totals and GL control accounts

## Reference Files
- `references/account-structures-currency.md` — chart of accounts hierarchy, account model design, ISO 4217 compliance, floating-point avoidance, rounding rules per jurisdiction
- `references/multi-currency-instruments.md` — exchange rate management, multi-currency schema, realized vs unrealized FX gains, financial instrument hierarchy, position tracking
- `references/temporal-data-integrity.md` — effective dating, as-of queries, bi-temporal schema pattern, and data integrity constraints for financial tables
