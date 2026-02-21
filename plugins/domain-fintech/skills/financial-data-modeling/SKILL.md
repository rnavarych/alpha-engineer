---
name: financial-data-modeling
description: |
  Guides financial data modeling: account structures (asset, liability, equity, revenue, expense),
  currency handling (ISO 4217, minor units), decimal precision (BigDecimal, integer cents),
  multi-currency ledgers, financial instrument representation, and temporal data patterns.
  Use when designing database schemas for financial applications.
allowed-tools: Read, Grep, Glob, Bash
---

You are a financial data modeling specialist. Every schema decision must prioritize correctness and auditability over convenience.

## Account Structures

### Chart of Accounts Hierarchy
- **Assets**: cash, accounts receivable, investments, prepaid expenses
- **Liabilities**: accounts payable, loans, deferred revenue, accrued expenses
- **Equity**: owner's equity, retained earnings, common stock
- **Revenue**: sales, interest income, fee income, service revenue
- **Expenses**: operating expenses, cost of goods sold, interest expense

### Account Model Design
- Use a hierarchical account numbering system (e.g., 1000-1999 for assets)
- Store account type as an enum: ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
- Normal balance direction: DEBIT for assets/expenses, CREDIT for liabilities/equity/revenue
- Support sub-accounts for detailed tracking (e.g., 1010 Cash in Bank, 1011 Petty Cash)
- Include metadata: currency, status (active/frozen/closed), opening date, regulatory flags

## Currency Handling

### ISO 4217 Compliance
- Always store currency as a 3-letter ISO 4217 code (USD, EUR, GBP)
- Store the numeric code alongside for legacy system interoperability
- Respect minor unit exponents: USD=2 (cents), JPY=0 (yen), BHD=3 (fils)
- Maintain a currency reference table with symbol, name, exponent, and active status

### Never Use Floating Point for Money
- **NEVER** use `float`, `double`, or `real` for monetary values
- Use `DECIMAL(19,4)` or `NUMERIC(19,4)` in SQL databases
- Use `BigDecimal` in Java, `Decimal` in Python/C#, `decimal.js` in JavaScript
- Alternative: store as integer minor units (cents) and convert for display only

### Rounding Rules
- Apply banker's rounding (round half to even) per IEEE 754
- Document rounding strategy per jurisdiction (some require round-up for taxes)
- Apply rounding only at the final display step, never during intermediate calculations
- Store full precision internally, round only on output

## Multi-Currency Ledgers

### Exchange Rate Management
- Store exchange rates with effective date/time and source
- Use a rate pair (base/quote) with bid/ask spread when applicable
- Historical rate lookup for as-of reporting and mark-to-market
- Triangulation through a base currency (typically USD or EUR) for exotic pairs

### Multi-Currency Account Design
```
accounts: id, account_number, account_type, base_currency
balances: account_id, currency, amount (in minor units), as_of_date
journal_entries: id, entry_date, description, posted_at
journal_lines: entry_id, account_id, amount, currency, exchange_rate, base_amount
```

### Realized vs Unrealized Gains
- Track unrealized FX gains/losses for mark-to-market reporting
- Record realized FX gains/losses at settlement using original vs settlement rate
- Use FIFO, LIFO, or weighted average for cost basis of currency positions

## Financial Instrument Representation

### Instrument Hierarchy
- Cash and cash equivalents
- Fixed income (bonds, notes, bills): coupon rate, maturity date, face value, yield
- Equities (stocks, ETFs): ticker, exchange, lot tracking, dividend schedule
- Derivatives (options, futures): underlying, strike, expiry, contract size
- Store common fields in a base table, instrument-specific fields in type tables

### Position Tracking
- Track positions by: account, instrument, lot (for tax purposes)
- Maintain cost basis per lot (purchase price, fees, adjustments)
- Support corporate actions: splits, mergers, dividends, spin-offs
- Mark-to-market with end-of-day pricing feeds

## Temporal Data Patterns

### Effective Dating
- Use `effective_from` and `effective_to` (NULL = current) for time-varying data
- Interest rates, fee schedules, and account terms must be effective-dated
- Prevent overlapping effective date ranges with database constraints

### As-Of Queries
- Support point-in-time queries: "what was the balance on 2024-01-15?"
- Use bi-temporal modeling when both business time and system time matter
- System time tracks when a record was inserted (audit), business time tracks when it applies

### Bi-Temporal Schema Pattern
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
