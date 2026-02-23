# Downsampling, Retention Policies, and Compression

## When to load
Load when configuring data lifecycle policies, implementing downsampling pipelines in InfluxDB or TimescaleDB, setting up hot/warm/cold storage tiers, or enabling compression to reduce storage costs.

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
