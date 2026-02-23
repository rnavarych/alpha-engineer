---
name: performance-testing
description: |
  Performance test design and execution with k6 (JavaScript, cloud execution, thresholds),
  JMeter (GUI, distributed), Gatling (Scala DSL), and Artillery (YAML config).
  Load, stress, soak, and spike testing. Baselines, bottleneck analysis, CI performance
  gates, custom metrics, and result analysis.
allowed-tools: Read, Grep, Glob, Bash
---

# Performance Testing

## When to use
- Designing a load, stress, soak, or spike test scenario for an API or service
- Selecting a performance testing tool (k6, JMeter, Gatling, Artillery)
- Establishing performance baselines before a major release
- Investigating a latency regression — bottleneck analysis workflow
- Adding performance gates to a CI/CD pipeline
- Setting up Grafana/InfluxDB dashboards for load test result visualization

## Core principles
1. **Baselines before gates** — you cannot fail a threshold you never measured; establish baselines on a stable environment first
2. **P95 and P99, never averages** — average latency hides tail pain; users experience the tail, not the mean
3. **Test types serve different questions** — load tests validate capacity, stress tests find limits, soak tests expose leaks, spike tests prove autoscaling
4. **Bottleneck order matters** — check application first, then database, then network, then infra; jumping to infra first wastes everyone's time
5. **Store results with the code** — a test run without the commit SHA and environment spec is an anecdote, not a baseline

## Reference Files
- `references/tools-and-test-types.md` — test type selection table, k6 script with stages and thresholds, custom metrics with Trend/Counter, JMeter CLI, Gatling DSL, Artillery overview
- `references/baselines-analysis-ci.md` — baseline establishment and storage, bottleneck investigation order, APM correlation, CI gate configuration, result archiving and Grafana trend analysis
