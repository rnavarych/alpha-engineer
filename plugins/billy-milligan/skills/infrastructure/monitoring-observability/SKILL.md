---
name: monitoring-observability
description: |
  Monitoring and observability patterns. Prometheus RED/USE metrics, structured logging with Pino/Winston, OpenTelemetry tracing, SLO-based alerting, Grafana dashboards, burn rate alerts.
allowed-tools: Read, Grep, Glob
---

# Monitoring & Observability

## When to use

Use when setting up metrics, logging, tracing, or alerting for services. Covers the three pillars of observability, SLO definition, dashboard design, and alert fatigue prevention.

## Core principles

1. Three pillars: logs, metrics, traces — each answers different questions
2. Structured logging always — JSON logs are searchable; free-text logs are archaeology
3. RED method for services — Rate, Errors, Duration per endpoint
4. SLO-based alerting — alert on burn rate, not raw error count
5. Correlation IDs through every hop — without them, distributed debugging is guesswork

## References available

- `references/metrics-patterns.md` — RED/USE methods, Prometheus counters/histograms/gauges, Grafana dashboards
- `references/logging-patterns.md` — Structured logging (Pino/Winston), levels, aggregation (ELK/Loki), correlation IDs
- `references/tracing-patterns.md` — OpenTelemetry setup, span design, sampling strategies, trace analysis
- `references/alerting-strategies.md` — SLO-based alerting, burn rate (14.4x fast, 6x slow), alert fatigue prevention

## Assets available

- `assets/grafana-dashboard-template.json` — Starter RED metrics dashboard
- `assets/alert-rules-template.yaml` — Prometheus alert rules for SLO burn rate
