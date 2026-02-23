---
name: load-testing
description: |
  Load testing with k6: script with stages (ramp-up/hold/ramp-down), thresholds
  (p99<500ms, errors<1%), spike test for finding breaking point, k6 in CI with failure
  on thresholds, soak testing, Locust for Python teams, common bottleneck patterns.
  Use when verifying performance, finding capacity limits, load testing before launch.
allowed-tools: Read, Grep, Glob
---

# Load Testing

## When to use
- Verifying performance before a product launch
- Finding capacity limits and breaking points
- Setting up performance regression in CI
- Diagnosing under which load specific endpoints degrade
- Comparing performance before and after optimization

## Core principles

1. **Test in production-like environment** — load test results from dev are meaningless
2. **Warm up before measuring** — cold start skews results
3. **Define thresholds before running** — not after seeing results
4. **Soak testing finds leaks** — sustained load reveals memory leaks and connection exhaustion
5. **Watch the database, not just the app** — DB is usually the bottleneck

## References available
- `references/k6-script.md` — stages config, custom metrics, thresholds, setup function, think time
- `references/spike-test.md` — sudden VU spike pattern, relaxed thresholds, recovery measurement
- `references/ci-integration.md` — GitHub Actions k6-action, nightly schedule, threshold exit codes
- `references/observing-load.md` — pg_stat_statements during test, DB connection monitoring, Grafana RED
- `references/threshold-reference.md` — p95/p99 targets by endpoint type, error rate budgets by load level
