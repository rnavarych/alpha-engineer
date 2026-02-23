# Multi-Currency Ledgers and Financial Instruments

## When to load
Load when designing multi-currency account schemas, handling FX gains/losses, modeling financial
instruments (bonds, equities, derivatives), or tracking positions with cost basis.

## Exchange Rate Management

- Store exchange rates with effective date/time and source
- Use a rate pair (base/quote) with bid/ask spread when applicable
- Historical rate lookup for as-of reporting and mark-to-market
- Triangulation through a base currency (typically USD or EUR) for exotic pairs

## Multi-Currency Account Schema

```
accounts:      id, account_number, account_type, base_currency
balances:      account_id, currency, amount (in minor units), as_of_date
journal_entries: id, entry_date, description, posted_at
journal_lines: entry_id, account_id, amount, currency, exchange_rate, base_amount
```

## Realized vs Unrealized FX Gains

- Track unrealized FX gains/losses for mark-to-market reporting
- Record realized FX gains/losses at settlement using original vs settlement rate
- Use FIFO, LIFO, or weighted average for cost basis of currency positions

## Financial Instrument Hierarchy

- Cash and cash equivalents
- Fixed income (bonds, notes, bills): coupon rate, maturity date, face value, yield
- Equities (stocks, ETFs): ticker, exchange, lot tracking, dividend schedule
- Derivatives (options, futures): underlying, strike, expiry, contract size
- Store common fields in a base table, instrument-specific fields in type tables

## Position Tracking

- Track positions by: account, instrument, lot (for tax purposes)
- Maintain cost basis per lot (purchase price, fees, adjustments)
- Support corporate actions: splits, mergers, dividends, spin-offs
- Mark-to-market with end-of-day pricing feeds
