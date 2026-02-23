# Order Matching Engine and Market Data Feeds

## When to load
Load when building or reviewing an order matching engine, designing order book data structures,
implementing FIX protocol sessions, or architecting market data distribution.

## Price-Time Priority (FIFO)

- Orders matched first by best price, then by arrival time at same price
- Most common matching algorithm for equity and futures exchanges
- Buy side sorted descending (highest bid first), sell side sorted ascending (lowest ask first)

## Pro-Rata Matching

- At same price level, orders filled proportionally to their size
- Common in options and interest rate futures markets
- Prevents queue position gaming but adds complexity
- Hybrid models: minimum allocation threshold to avoid dust fills

## Order Book Data Structure

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

## Matching Engine Requirements

- Deterministic: same input sequence always produces same output
- Single-threaded core: avoid locking overhead, maximize throughput
- Nanosecond timestamps for ordering and audit
- Sequence numbers for gap detection and replay

## WebSocket Market Data (Retail)

- Level 1: best bid/ask (top of book), last trade price
- Level 2: full order book depth (aggregated by price level)
- Trade feed: executed trades with price, quantity, timestamp
- Heartbeat mechanism for connection health monitoring

## FIX Protocol (Institutional)

- Industry standard for institutional trading (FIX 4.2, 4.4, 5.0)
- Session layer: logon, heartbeat, sequence number management
- Application layer: new order, execution report, market data
- Use QuickFIX/J, QuickFIX/N, or similar for implementation
- Always implement sequence number gap fill for message recovery

## Market Data Architecture

- Multicast UDP for high-frequency feeds (exchange co-location)
- Conflation: merge rapid updates to reduce downstream load
- Snapshot + incremental updates pattern for order book maintenance
- Normalize feeds from multiple exchanges into unified format
