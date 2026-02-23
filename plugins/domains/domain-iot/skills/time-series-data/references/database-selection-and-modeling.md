# Time-Series Database Selection and Data Modeling

## When to load
Load when selecting a time-series database for IoT telemetry, designing schemas (tags vs fields in InfluxDB, hypertables in TimescaleDB), or understanding the trade-offs between purpose-built TSDBs.

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
