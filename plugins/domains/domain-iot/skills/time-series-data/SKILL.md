---
name: time-series-data
description: |
  Time-series data management for IoT including database selection (InfluxDB,
  TimescaleDB, Prometheus), schema design with tags and fields, downsampling
  and retention policies, data compression, real-time vs batch processing,
  and Grafana visualization.
allowed-tools: Read, Grep, Glob, Bash
---

# Time-Series Data for IoT

## Database Selection

| Database | Architecture | Best For | Query Language |
|----------|-------------|----------|----------------|
| **InfluxDB** | Purpose-built TSDB, columnar storage | High-ingest IoT telemetry, DevOps monitoring | Flux, InfluxQL |
| **TimescaleDB** | PostgreSQL extension, hypertables | Teams needing SQL compatibility, joins with relational data | SQL |
| **Prometheus** | Pull-based metrics, local storage | Infrastructure monitoring, Kubernetes metrics | PromQL |
| **QuestDB** | Column-oriented, zero-GC Java | Ultra-high ingest rates, financial tick data | SQL (PostgreSQL wire protocol) |
| **ClickHouse** | Column-oriented OLAP | Analytical queries over massive datasets | SQL |

### Selection Criteria
- **InfluxDB**: Choose when you need a managed cloud option (InfluxDB Cloud), native MQTT integration, and the ecosystem of Telegraf collectors
- **TimescaleDB**: Choose when your team knows PostgreSQL, you need JOINs with device metadata tables, or you want to add time-series to an existing PostgreSQL deployment
- **Prometheus**: Choose for pull-based monitoring of infrastructure and services; not ideal for high-cardinality IoT device telemetry

## Data Modeling: Tags vs Fields

### InfluxDB Model
```
measurement: temperature
tags:        device_id=sensor-001, location=warehouse-a, floor=2
fields:      value=23.5, battery=87.2
timestamp:   2024-01-15T10:30:00Z
```

**Tags** (indexed, low cardinality):
- Device ID, location, device type, firmware version
- Use for GROUP BY and WHERE filtering
- Keep cardinality manageable: avoid UUIDs or high-cardinality values as tags

**Fields** (not indexed, store measurement values):
- Sensor readings, counters, gauge values
- Numeric values that you aggregate (mean, max, sum)

### TimescaleDB Model
```sql
CREATE TABLE telemetry (
    time        TIMESTAMPTZ NOT NULL,
    device_id   TEXT NOT NULL,
    location    TEXT,
    temperature DOUBLE PRECISION,
    humidity    DOUBLE PRECISION,
    battery     DOUBLE PRECISION
);
SELECT create_hypertable('telemetry', 'time');
CREATE INDEX ON telemetry (device_id, time DESC);
```

- Partition by time automatically via hypertables
- Add indexes on frequently filtered columns (device_id, location)
- Use continuous aggregates for pre-computed rollups

## Downsampling Strategies

Reduce storage costs and query latency by aggregating old data:

### InfluxDB Continuous Queries / Tasks
```flux
// Downsample from raw (every 10s) to 1-minute averages
option task = {name: "downsample_1m", every: 1m}
from(bucket: "raw")
  |> range(start: -task.every)
  |> aggregateWindow(every: 1m, fn: mean)
  |> to(bucket: "downsampled_1m")
```

### TimescaleDB Continuous Aggregates
```sql
CREATE MATERIALIZED VIEW telemetry_hourly
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS bucket,
       device_id,
       AVG(temperature) AS avg_temp,
       MAX(temperature) AS max_temp,
       MIN(temperature) AS min_temp,
       COUNT(*) AS sample_count
FROM telemetry
GROUP BY bucket, device_id;
```

### Downsampling Tiers
| Tier | Resolution | Retention | Purpose |
|------|-----------|-----------|---------|
| Raw | 10s - 1min | 7-30 days | Debugging, real-time dashboards |
| Aggregated | 1min - 15min | 90 days - 1 year | Trend analysis, alerting |
| Rollup | 1 hour - 1 day | 1-5 years | Historical reporting, capacity planning |

## Retention Policies

### Hot / Warm / Cold Architecture
- **Hot** (SSD, in-memory cache): Last 24-48 hours of raw data for real-time dashboards and alerting
- **Warm** (SSD or HDD): Last 30-90 days of aggregated data for operational analysis
- **Cold** (object storage: S3, GCS): Historical data in Parquet or ORC format for compliance and long-term analytics

### Implementation
- InfluxDB: Configure retention policies per bucket; data auto-expires
- TimescaleDB: Use `add_retention_policy()` to drop chunks older than the threshold
- Archive to object storage before deletion for compliance (Parquet export, InfluxDB backup)

## Data Compression

- InfluxDB uses gorilla-style compression (delta-of-delta for timestamps, XOR for floats): 2-5 bytes per point
- TimescaleDB native compression: 90-95% compression ratio on time-series data
- Enable compression on older chunks: `ALTER TABLE telemetry SET (timescaledb.compress); SELECT add_compression_policy('telemetry', INTERVAL '7 days');`
- Reduce precision where appropriate: temperature to 1 decimal, GPS to 5 decimals

## Real-Time vs Batch Processing

| Approach | Latency | Tools | Use Case |
|----------|---------|-------|----------|
| **Stream** | Milliseconds to seconds | Kafka Streams, Apache Flink, AWS Kinesis | Real-time alerting, live dashboards, control loops |
| **Micro-batch** | Seconds to minutes | Spark Structured Streaming, Telegraf batching | Near-real-time analytics with cost efficiency |
| **Batch** | Minutes to hours | Apache Spark, dbt, SQL scheduled queries | Historical reports, model training, trend analysis |

## Grafana Visualization

### Dashboard Design for IoT
- **Overview panel**: Fleet summary with device count, online %, alert count
- **Time-series graph**: Sensor readings over time with threshold lines
- **Heatmap**: Device activity matrix (devices vs hours) to spot patterns
- **Gauge/Stat**: Current values for key metrics (average temperature, total power)
- **Table**: Device list with last-seen, firmware version, status for fleet management
- **Map panel**: Geographic distribution of devices with color-coded status

### Query Optimization
- Use variables for device selection to avoid loading all devices at once
- Set appropriate time range defaults (last 6 hours for operations, last 30 days for trends)
- Use `$__interval` for automatic resolution scaling based on the visible time window
- Limit series count: query top-N devices or aggregate by location instead of showing all
