# TimescaleDB and QuestDB

## When to load
Load when working with TimescaleDB (hypertables, continuous aggregates, columnar compression, hyperfunctions) or QuestDB (SAMPLE BY, LATEST ON, ASOF JOIN, ILP ingestion).

## TimescaleDB — Hypertable Setup

```sql
CREATE TABLE metrics (
    time        TIMESTAMPTZ NOT NULL,
    device_id   TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    humidity    DOUBLE PRECISION,
    battery     DOUBLE PRECISION
);

SELECT create_hypertable('metrics', by_range('time'));

-- Space partitioning for multi-node or high cardinality
SELECT add_dimension('metrics', by_hash('device_id', 4));
```

## Continuous Aggregates

```sql
CREATE MATERIALIZED VIEW metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    device_id,
    AVG(temperature) AS avg_temp,
    MAX(temperature) AS max_temp,
    MIN(temperature) AS min_temp,
    AVG(humidity) AS avg_humidity
FROM metrics
GROUP BY bucket, device_id
WITH NO DATA;

SELECT add_continuous_aggregate_policy('metrics_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');
```

## Compression and Retention Policies

```sql
-- Columnar compression on older data
ALTER TABLE metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('metrics', INTERVAL '7 days');

-- Data retention
SELECT add_retention_policy('metrics', INTERVAL '90 days');
```

## TimescaleDB Hyperfunctions

```sql
-- Time-weighted averages
SELECT time_bucket('1 hour', time) AS bucket,
       device_id,
       time_weight('LOCF', time, temperature) AS tw_avg_temp
FROM metrics
WHERE time > now() - INTERVAL '1 day'
GROUP BY bucket, device_id;

-- Approximate p99 (uddsketch)
SELECT time_bucket('1 hour', time) AS bucket,
       approx_percentile(0.99, percentile_agg(response_time)) AS p99
FROM api_metrics
GROUP BY bucket;

-- Gap filling (LOCF: Last Observation Carried Forward)
SELECT time_bucket_gapfill('1 hour', time) AS bucket,
       device_id,
       locf(avg(temperature)) AS temperature
FROM metrics
WHERE time > now() - INTERVAL '1 day'
GROUP BY bucket, device_id;
```

## QuestDB — SQL-Native Time-Series

```sql
CREATE TABLE sensors (
    timestamp TIMESTAMP,
    sensor_id SYMBOL,        -- SYMBOL: interned string for low-cardinality columns
    temperature DOUBLE,
    humidity DOUBLE
) TIMESTAMP(timestamp) PARTITION BY DAY WAL;

-- SAMPLE BY: native time-series aggregation
SELECT timestamp, sensor_id, avg(temperature), max(humidity)
FROM sensors
WHERE timestamp IN '2024-01-01'
SAMPLE BY 1h
ALIGN TO CALENDAR;

-- LATEST ON: last value per device (replaces complex subqueries)
SELECT * FROM sensors
LATEST ON timestamp PARTITION BY sensor_id;

-- ASOF JOIN: temporal join — nearest timestamp match
SELECT s.timestamp, s.sensor_id, s.temperature, p.price
FROM sensors s
ASOF JOIN prices p ON (s.sensor_id = p.symbol);

-- Window functions
SELECT timestamp, sensor_id, temperature,
       avg(temperature) OVER (PARTITION BY sensor_id ORDER BY timestamp ROWS 10 PRECEDING) AS moving_avg
FROM sensors;
```

## QuestDB Ingestion

```bash
# InfluxDB Line Protocol over TCP (highest throughput)
echo "sensors,sensor_id=s1 temperature=23.5,humidity=62.1 1704067200000000000" | nc -q 0 localhost 9009
# HTTP API
curl -X POST "http://localhost:9000/exec?query=INSERT+INTO+sensors+VALUES(now(),'s1',23.5,62.1)"
```

## HA

- TimescaleDB: PostgreSQL streaming replication + Patroni; full PG ecosystem applies
- QuestDB: Enterprise WAL shipping; OSS is single-node
