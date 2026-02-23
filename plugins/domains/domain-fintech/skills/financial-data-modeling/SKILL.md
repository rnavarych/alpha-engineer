---
name: financial-data-modeling
description: Guides financial data modeling: account structures (asset, liability, equity, revenue, expense), currency handling (ISO 4217, minor units), decimal precision (BigDecimal, integer cents), multi-currency ledgers, financial instrument representation, and temporal data patterns. Use when designing database schemas for financial applications.
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

## Reference Files
- `references/account-structures-currency.md` — chart of accounts hierarchy, account model design, ISO 4217 compliance, floating-point avoidance, rounding rules per jurisdiction
- `references/multi-currency-instruments.md` — exchange rate management, multi-currency schema, realized vs unrealized FX gains, financial instrument hierarchy, position tracking
- `references/temporal-data-integrity.md` — effective dating, as-of queries, bi-temporal schema pattern, and data integrity constraints for financial tables
