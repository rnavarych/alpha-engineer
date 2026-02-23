# Account Structures and Currency Handling

## When to load
Load when designing chart of accounts, modeling account hierarchies, or implementing correct
currency storage for financial applications. Covers account types, numbering systems, ISO 4217,
floating-point avoidance, and rounding rules.

## Chart of Accounts Hierarchy

- **Assets**: cash, accounts receivable, investments, prepaid expenses
- **Liabilities**: accounts payable, loans, deferred revenue, accrued expenses
- **Equity**: owner's equity, retained earnings, common stock
- **Revenue**: sales, interest income, fee income, service revenue
- **Expenses**: operating expenses, cost of goods sold, interest expense

## Account Model Design

- Use a hierarchical account numbering system (e.g., 1000-1999 for assets)
- Store account type as an enum: `ASSET`, `LIABILITY`, `EQUITY`, `REVENUE`, `EXPENSE`
- Normal balance direction: DEBIT for assets/expenses, CREDIT for liabilities/equity/revenue
- Support sub-accounts for detailed tracking (e.g., 1010 Cash in Bank, 1011 Petty Cash)
- Include metadata: currency, status (active/frozen/closed), opening date, regulatory flags

## ISO 4217 Currency Compliance

- Always store currency as a 3-letter ISO 4217 code (USD, EUR, GBP)
- Store the numeric code alongside for legacy system interoperability
- Respect minor unit exponents: USD=2 (cents), JPY=0 (yen), BHD=3 (fils)
- Maintain a currency reference table with symbol, name, exponent, and active status

## Never Use Floating Point for Money

- **NEVER** use `float`, `double`, or `real` for monetary values
- Use `DECIMAL(19,4)` or `NUMERIC(19,4)` in SQL databases
- Use `BigDecimal` in Java, `Decimal` in Python/C#, `decimal.js` in JavaScript
- Alternative: store as integer minor units (cents) and convert for display only

## Rounding Rules

- Apply banker's rounding (round half to even) per IEEE 754
- Document rounding strategy per jurisdiction (some require round-up for taxes)
- Apply rounding only at the final display step, never during intermediate calculations
- Store full precision internally, round only on output
