---
name: time-series-databases
description: |
  Deep operational guide for 14 time-series databases. InfluxDB (Flux, 3.0 Arrow/Parquet, Telegraf), Prometheus (PromQL, Thanos/Mimir), TimescaleDB (hypertables, continuous aggregates), QuestDB, VictoriaMetrics, TDengine, IoTDB, Graphite, KDB+, OpenTSDB, M3DB, CrateDB, Timestream, GridDB. Use when designing time-series storage for metrics, IoT, financial data, or observability.
allowed-tools: Read, Grep, Glob, Bash
---

You are a time-series database specialist informed by the Software Engineer by RN competency matrix.

## When to Use This Skill

Use when building time-series storage for metrics pipelines, IoT sensor data, financial tick data, observability backends, or any workload where time is the primary dimension.

## Selection Matrix

| Database | Best For | Ingestion | Managed |
|----------|----------|-----------|---------|
| InfluxDB 3.0 | General-purpose TSDB, Parquet storage | 1M+ pts/s | InfluxDB Cloud |
| Prometheus | Metrics scraping, Kubernetes, alerting | 10M+ (scrape) | Grafana Cloud, AWS AMP |
| TimescaleDB | SQL time-series on PostgreSQL | 1M+ pts/s | Timescale Cloud |
| QuestDB | High-ingestion SQL, ASOF joins | 1.4M+ pts/s | QuestDB Cloud |
| VictoriaMetrics | Prometheus replacement, lower cost | 10M+ pts/s | VictoriaMetrics Cloud |
| TDengine | IoT super-table model, streaming | 10M+ pts/s | TDengine Cloud |
| KDB+ | Financial tick data, q language | 100M+ pts/s | KX Cloud |
| Timestream | Serverless AWS TSDB | 1M+ pts/s | AWS Managed |

## Core Principles

- Tag cardinality is the #1 performance killer — bound it from day one
- Design retention tiers upfront: raw → 1m → 5m → 1h aggregates
- Wide table model for correlated queries; narrow for flexible tagging
- Always run multi-tier downsampling; never store raw data indefinitely
- Monitor your monitoring system with an independent stack

## Reference Files

Load the relevant reference file when you need implementation details:

- **references/influxdb-telegraf.md** — Flux language, InfluxDB 3.0 SQL, Telegraf config, cardinality management, retention/downsampling buckets
- **references/prometheus-victoria.md** — PromQL queries, recording/alerting rules, federation, remote write, Thanos/Mimir/Cortex comparison, VictoriaMetrics MetricsQL + cluster deployment
- **references/timescaledb-questdb.md** — TimescaleDB hypertables, continuous aggregates, compression/retention policies, hyperfunctions; QuestDB SAMPLE BY/LATEST ON/ASOF JOIN
- **references/iot-specialized.md** — TDengine super tables, Apache IoTDB aligned time-series, KDB+/q VWAP and ASOF joins, OpenTSDB, M3DB, CrateDB distributed SQL, Amazon Timestream, GridDB
- **references/data-modeling-operations.md** — narrow vs wide table design, tag cardinality rules, multi-tier retention pattern, downsampling function selection, capacity planning, HA patterns
