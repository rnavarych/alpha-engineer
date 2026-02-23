# Risk Limits, Low-Latency Architecture, and Market Microstructure

## When to load
Load when implementing pre-trade risk checks, designing low-latency trading infrastructure,
optimizing for kernel-bypass networking, or understanding market microstructure concepts.

## Pre-Trade Risk Checks (Gatekeeper)

- Sufficient margin/buying power before order acceptance
- Position limit check: will this order breach instrument or portfolio limits?
- Order rate limit: maximum orders per second per user
- Price collar: reject orders outside configurable price range
- All checks must complete in <1ms to avoid adding latency

## Real-Time Risk Monitoring

- Portfolio VaR (Value at Risk): 1-day, 99% confidence
- Stress testing: predefined scenarios (market crash, rate spike, flash crash)
- Margin utilization: real-time margin used vs available
- Kill switch: ability to cancel all open orders and flatten positions instantly

## In-Memory Processing

- Keep order book entirely in memory (no disk I/O on critical path)
- Use memory-mapped files or shared memory for inter-process communication
- Pre-allocate objects to avoid garbage collection pauses (object pooling)
- Use primitive types and arrays over boxed types and collections

## Lock-Free Design

- Single-writer principle: one thread owns each data structure
- Mechanical sympathy: cache-line-aware data structures
- Ring buffers (Disruptor pattern) for inter-thread communication
- Avoid system calls on the critical path (pre-allocate, pre-compute)

## Network Optimization

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
