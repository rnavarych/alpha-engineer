# Performance Baselines

## When to load
Load when establishing SLOs, defining performance budgets, or setting alerting thresholds.

## SLO Definitions

```
Availability SLO:
  99.9% = 8.76 hours downtime/year = 43.8 min/month
  99.95% = 4.38 hours/year = 21.9 min/month
  99.99% = 52.6 min/year = 4.38 min/month

Latency SLO (by endpoint type):
  API reads:   p50 < 100ms, p95 < 300ms, p99 < 500ms
  API writes:  p50 < 200ms, p95 < 500ms, p99 < 1000ms
  Search:      p50 < 200ms, p95 < 500ms, p99 < 1500ms
  Reports:     p50 < 2s,    p95 < 5s,    p99 < 10s

Error rate SLO:
  5xx errors: < 0.1% of all requests
  4xx errors: < 5% (indicates client issues, not service)
```

## Baseline Establishment Process

```
1. Measure current performance (7 days, production traffic)
   - p50, p95, p99 latency per endpoint
   - Error rate per endpoint
   - Throughput (RPM) per endpoint

2. Identify critical paths
   - Checkout flow: 3 API calls, total < 2s
   - Search: < 500ms including rendering
   - Authentication: < 300ms

3. Set thresholds at 2x current p95
   - If current p95 = 200ms → threshold = 400ms
   - Gives headroom for normal variation

4. Alert when:
   - p95 > threshold for 5 minutes (warning)
   - p99 > threshold for 2 minutes (critical)
   - Error rate > 1% for 3 minutes (critical)
```

## Load Testing Targets

```
Capacity test progression:
  1x baseline  → verify SLOs hold
  2x baseline  → normal growth headroom
  5x baseline  → marketing event / sale
  10x baseline → find breaking point

Example: 1000 RPM baseline
  1000 RPM → all p95 < 300ms ✓
  2000 RPM → all p95 < 400ms ✓
  5000 RPM → p95 at 600ms, DB CPU 80% ⚠️
  10000 RPM → timeouts, 5xx spike ✗ → breaking point
```

## Anti-patterns
- Setting SLOs without measuring current performance → arbitrary targets
- Using averages instead of percentiles → p50 hides tail latency
- No burn rate alerting → alert fires only after SLO is already violated
- Testing at 1x load only → no headroom knowledge

## Quick reference
```
Measure first: 7 days production data before setting targets
Percentiles: p50 (median), p95 (most users), p99 (worst case)
Threshold: 2x current p95 for alerting
SLO: 99.9% availability = 43.8 min downtime/month
Error budget: 0.1% = 43.8 minutes of allowed downtime
Burn rate: alert when consuming budget 10x faster than allowed
Test progression: 1x → 2x → 5x → 10x baseline RPM
```
