# Order Types, Position Management, and P&L Calculation

## When to load
Load when implementing order validation logic, tracking real-time positions, calculating realized
and unrealized P&L, or configuring pre-trade risk limit checks.

## Basic Order Types

- **Market**: execute immediately at best available price (no price guarantee)
- **Limit**: execute at specified price or better (may not fill)
- **Stop**: becomes market order when trigger price is reached
- **Stop-Limit**: becomes limit order when trigger price is reached

## Advanced Order Types

- **Iceberg**: visible portion + hidden reserve quantity
- **Fill-or-Kill (FOK)**: execute entire quantity immediately or cancel
- **Immediate-or-Cancel (IOC)**: fill what's available, cancel remainder
- **Good-Till-Cancelled (GTC)**: persist until filled or explicitly cancelled
- **Good-Till-Date (GTD)**: persist until specified date
- **Trailing Stop**: stop price adjusts as market moves favorably

## Order Validation

- Price reasonableness check: reject orders N% away from last traded price
- Quantity limits: per-order maximum, daily maximum per user
- Self-trade prevention: detect and prevent user trading against their own orders
- Fat-finger protection: configurable price and quantity guardrails

## Position Tracking

- Real-time position calculation per account, per instrument
- Net position: long quantity - short quantity
- Average entry price: weighted average of all fill prices
- Unrealized P&L: `(current_price - avg_entry_price) * position_quantity`
- Margin requirement: `position_value * margin_rate`

## Position Limits

- Per-instrument limits: maximum position size per user/account
- Concentration limits: maximum percentage of portfolio in one instrument
- Gross exposure limits: total long + total short positions
- Automated position reduction when limits approached (warning at 80%, block at 100%)

## Realized P&L

- Calculated when a position is closed (fully or partially)
- FIFO: match against oldest open lot first
- LIFO: match against newest open lot first
- Weighted average: compute average cost across all lots
- Store cost basis method per account for consistency

## Unrealized P&L (Mark-to-Market)

- Recalculate continuously using real-time market prices
- End-of-day MTM for daily settlement (futures)
- Use mid-price, last trade, or settlement price per instrument type
- Account for accrued interest (bonds), dividends (equities)

## P&L Attribution

- Price P&L: change due to market price movement
- FX P&L: change due to currency rate movement
- Fee P&L: commissions, exchange fees, clearing fees
- Carry P&L: financing cost, swap points, dividend income
