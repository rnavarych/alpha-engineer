---
name: trading-systems
description: |
  Guides trading system design: order matching engines (price-time priority, pro-rata),
  market data feeds (WebSocket, FIX protocol), order types (market, limit, stop, stop-limit),
  position management, P&L calculation, risk limits, low-latency architecture, and
  market microstructure. Use when building or reviewing trading platforms.
allowed-tools: Read, Grep, Glob, Bash
---

You are a trading systems specialist. Performance, correctness, and risk management are non-negotiable in trading systems.

## Order Matching Engine

### Price-Time Priority (FIFO)
- Orders matched first by best price, then by arrival time at same price
- Most common matching algorithm for equity and futures exchanges
- Implementation: maintain sorted order book per instrument
- Buy side sorted descending (highest bid first), sell side sorted ascending (lowest ask first)

### Pro-Rata Matching
- At same price level, orders filled proportionally to their size
- Common in options and interest rate futures markets
- Prevents queue position gaming but adds complexity
- Hybrid models: minimum allocation threshold to avoid dust fills

### Order Book Data Structure
```
OrderBook:
  bids: SortedMap<Price, Queue<Order>>  -- descending by price
  asks: SortedMap<Price, Queue<Order>>  -- ascending by price

Match(incoming_order):
  if incoming is BUY:
    while incoming.remaining > 0 AND best_ask <= incoming.price:
      fill(incoming, best_ask_order)
  if incoming is SELL:
    while incoming.remaining > 0 AND best_bid >= incoming.price:
      fill(incoming, best_bid_order)
  if incoming.remaining > 0 AND incoming.type != MARKET:
    add_to_book(incoming)
```

### Matching Engine Requirements
- Deterministic: same input sequence always produces same output
- Single-threaded core: avoid locking overhead, maximize throughput
- Nanosecond timestamps for ordering and audit
- Sequence numbers for gap detection and replay

## Market Data Feeds

### WebSocket for Retail
- Level 1: best bid/ask (top of book), last trade price
- Level 2: full order book depth (aggregated by price level)
- Trade feed: executed trades with price, quantity, timestamp
- Heartbeat mechanism for connection health monitoring

### FIX Protocol (Financial Information eXchange)
- Industry standard for institutional trading (FIX 4.2, 4.4, 5.0)
- Session layer: logon, heartbeat, sequence number management
- Application layer: new order, execution report, market data
- Use QuickFIX/J, QuickFIX/N, or similar for implementation
- Always implement sequence number gap fill for message recovery

### Market Data Architecture
- Multicast UDP for high-frequency feeds (exchange co-location)
- Conflation: merge rapid updates to reduce downstream load
- Snapshot + incremental updates pattern for order book maintenance
- Normalize feeds from multiple exchanges into unified format

## Order Types

### Basic Orders
- **Market**: execute immediately at best available price (no price guarantee)
- **Limit**: execute at specified price or better (may not fill)
- **Stop**: becomes market order when trigger price is reached
- **Stop-Limit**: becomes limit order when trigger price is reached

### Advanced Orders
- **Iceberg**: visible portion + hidden reserve quantity
- **Fill-or-Kill (FOK)**: execute entire quantity immediately or cancel
- **Immediate-or-Cancel (IOC)**: fill what's available, cancel remainder
- **Good-Till-Cancelled (GTC)**: persist until filled or explicitly cancelled
- **Good-Till-Date (GTD)**: persist until specified date
- **Trailing Stop**: stop price adjusts as market moves favorably

### Order Validation
- Price reasonableness check: reject orders N% away from last traded price
- Quantity limits: per-order maximum, daily maximum per user
- Self-trade prevention: detect and prevent user trading against their own orders
- Fat-finger protection: configurable price and quantity guardrails

## Position Management

### Position Tracking
- Real-time position calculation per account, per instrument
- Net position: long quantity - short quantity
- Average entry price: weighted average of all fill prices
- Unrealized P&L: (current_price - avg_entry_price) * position_quantity
- Margin requirement: position_value * margin_rate

### Position Limits
- Per-instrument limits: maximum position size per user/account
- Concentration limits: maximum percentage of portfolio in one instrument
- Gross exposure limits: total long + total short positions
- Automated position reduction when limits approached (warning at 80%, block at 100%)

## P&L Calculation

### Realized P&L
- Calculated when a position is closed (fully or partially)
- FIFO: match against oldest open lot first
- LIFO: match against newest open lot first
- Weighted average: compute average cost across all lots
- Store cost basis method per account for consistency

### Unrealized P&L (Mark-to-Market)
- Recalculate continuously using real-time market prices
- End-of-day MTM for daily settlement (futures)
- Use mid-price, last trade, or settlement price per instrument type
- Account for accrued interest (bonds), dividends (equities)

### P&L Attribution
- Price P&L: change due to market price movement
- FX P&L: change due to currency rate movement
- Fee P&L: commissions, exchange fees, clearing fees
- Carry P&L: financing cost, swap points, dividend income

## Risk Limits

### Pre-Trade Risk Checks (Gatekeeper)
- Sufficient margin/buying power before order acceptance
- Position limit check: will this order breach instrument or portfolio limits?
- Order rate limit: maximum orders per second per user
- Price collar: reject orders outside configurable price range
- All checks must complete in <1ms to avoid adding latency

### Real-Time Risk Monitoring
- Portfolio VaR (Value at Risk): 1-day, 99% confidence
- Stress testing: predefined scenarios (market crash, rate spike, flash crash)
- Margin utilization: real-time margin used vs available
- Kill switch: ability to cancel all open orders and flatten positions instantly

## Low-Latency Architecture

### In-Memory Processing
- Keep order book entirely in memory (no disk I/O on critical path)
- Use memory-mapped files or shared memory for inter-process communication
- Pre-allocate objects to avoid garbage collection pauses (object pooling)
- Use primitive types and arrays over boxed types and collections

### Lock-Free Design
- Single-writer principle: one thread owns each data structure
- Mechanical sympathy: cache-line-aware data structures
- Ring buffers (Disruptor pattern) for inter-thread communication
- Avoid system calls on the critical path (pre-allocate, pre-compute)

### Network Optimization
- Kernel bypass networking (DPDK, Solarflare OpenOnload)
- Busy-polling instead of interrupt-driven I/O
- Co-location with exchange matching engines
- Binary protocols (SBE, Cap'n Proto) instead of JSON/XML

## Market Microstructure

- Bid-ask spread: cost of immediacy, varies with liquidity
- Market depth: cumulative order volume at each price level
- Price discovery: how information is incorporated into prices
- Market impact: how large orders move the price
- Slippage: difference between expected and actual execution price
- Dark pools: venues with no pre-trade transparency (institutional block trades)
