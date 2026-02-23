# Performance Baselines, Bottleneck Analysis, and CI Gates

## When to load
When establishing or updating performance baselines; when analyzing bottlenecks from a failed load test; when configuring performance gates in CI/CD pipelines; when archiving results for trend analysis.

## Performance Baselines

- Measure P50, P95, P99 latency, throughput (RPS), error rate, CPU/memory utilization.
- Re-run baselines on the same environment and load profile for valid comparisons.
- Store baseline results in version control alongside the test scripts that produced them.
- Re-establish baselines after major infrastructure changes or dependency upgrades.

## Bottleneck Analysis

Investigate in this order:
1. **Application**: Slow queries, N+1 problems, missing caches, blocking I/O
2. **Database**: Missing indexes, lock contention, connection pool exhaustion
3. **Network**: DNS resolution time, TLS overhead, response payload size
4. **Infrastructure**: CPU saturation, memory pressure, container resource limits

Use APM tools (Datadog, New Relic, Jaeger) and flamegraphs to identify hot paths. Cross-reference APM traces with k6 timeline to match latency spikes to specific operations.

## CI Performance Gates

- Run smoke load tests (1-2 min, low concurrency) in PR pipelines for fast feedback.
- Run full load tests nightly or before release candidates on staging.
- Fail pipeline if P95 exceeds baseline by >20%. Treat performance regressions as bugs.
- Gate on error rate as well as latency — a 0% latency regression with 5% error rate is a failure.

## Result Analysis

- Compare each run against the stored baseline. Flag regressions above configurable thresholds.
- Correlate performance changes with recent commits. Link test run to the triggering deploy SHA.
- Generate percentile distribution reports (P50/P95/P99) — averages hide tail latency.
- Archive results for historical trend analysis across releases. Visualize in Grafana with InfluxDB backend.
