---
name: domain-iot:time-series-data
description: Time-series data management for IoT including database selection (InfluxDB, TimescaleDB, Prometheus, QuestDB, ClickHouse), schema design with tags and fields, downsampling and retention policies, data compression, real-time vs batch processing, and Grafana visualization.
allowed-tools: Read, Grep, Glob, Bash
---

# Time-Series Data for IoT

## When to use
- Selecting a time-series database for IoT telemetry ingestion
- Designing InfluxDB tag/field schemas or TimescaleDB hypertables for device data
- Implementing downsampling pipelines to reduce storage costs over time
- Configuring hot/warm/cold retention tiers with automatic expiry and archival
- Choosing between stream, micro-batch, and batch processing for telemetry pipelines
- Building Grafana dashboards for fleet monitoring with query optimization

## Core principles
1. **Tags are your indexes — cardinality kills them** — device IDs as tags are fine; UUIDs as tags are a cardinality bomb; model high-cardinality values as fields
2. **Downsample early, archive always** — raw data at 10s resolution for 7 days, aggregated at 1min for 90 days, rollups at 1h forever; storage is cheap, queries on raw aren't
3. **Hot/warm/cold is not optional at IoT scale** — SSD for the last 48 hours, object storage for anything older than 90 days; InfluxDB and TimescaleDB both automate this
4. **Stream for alerts, batch for reports** — Kafka Streams or Flink for sub-second alerting; Spark or dbt for anything a human looks at once a day
5. **Grafana variables prevent dashboards from melting** — never load all devices at once; use template variables and top-N queries from the start

## Reference Files
- `references/database-selection-and-modeling.md` — comparison table (InfluxDB, TimescaleDB, Prometheus, QuestDB, ClickHouse), selection criteria, InfluxDB tag/field model, TimescaleDB hypertable setup
- `references/downsampling-and-retention.md` — InfluxDB Flux tasks, TimescaleDB continuous aggregates, downsampling tier table, hot/warm/cold architecture, compression configuration
- `references/processing-and-visualization.md` — stream vs micro-batch vs batch comparison, Grafana panel types for IoT, query optimization techniques
