---
name: domain-fintech:trading-systems
description: Guides trading system design: order matching engines (price-time priority, pro-rata), market data feeds (WebSocket, FIX protocol), order types (market, limit, stop, stop-limit), position management, P&L calculation, risk limits, low-latency architecture, and market microstructure. Use when building or reviewing trading platforms.
allowed-tools: Read, Grep, Glob, Bash
---

# Trading Systems

## When to use
- Designing or reviewing an order matching engine (price-time vs pro-rata)
- Implementing FIX protocol sessions or WebSocket market data feeds
- Adding advanced order types (iceberg, FOK, IOC, trailing stop)
- Building real-time position tracking and P&L calculation (realized/unrealized)
- Implementing pre-trade risk checks with <1ms latency budget
- Optimizing for low-latency with lock-free design or kernel bypass networking

## Core principles
1. **Matching engine is single-threaded** — deterministic, no locking, nanosecond timestamps; concurrency buys nothing here
2. **Pre-trade checks are the last line of defense** — all checks under 1ms or you're adding slippage for your users
3. **Kill switch is non-negotiable** — cancel all orders and flatten positions in one operation; no exceptions
4. **Journal lines are P&L truth** — running MTM is a cache; reconcile against fills at end of day
5. **Binary protocols over JSON at co-location** — SBE/Cap'n Proto at microsecond latency; JSON is for dashboards

## Reference Files
- `references/order-matching-market-data.md` — price-time and pro-rata matching algorithms, order book data structure, matching engine requirements, WebSocket Level 1/2 feeds, FIX protocol sessions, market data architecture
- `references/orders-positions-pnl.md` — basic and advanced order types, order validation rules, real-time position tracking, position limits, realized P&L (FIFO/LIFO/weighted avg), unrealized MTM, P&L attribution
- `references/risk-latency-microstructure.md` — pre-trade risk checks, real-time VaR and stress testing, kill switch, in-memory processing, lock-free design (Disruptor), kernel bypass networking, market microstructure concepts
