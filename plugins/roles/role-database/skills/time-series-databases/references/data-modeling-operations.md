# Time-Series Data Modeling and Operations

## When to load
Load when designing time-series schemas (narrow vs wide table, tag cardinality), planning retention/downsampling tiers, estimating capacity, or setting up high availability.

## Narrow vs Wide Table Design

```
Narrow model (one metric per row): flexible, higher cardinality
| time       | metric_name | value | tags          |
|------------|-------------|-------|---------------|
| 2024-01-01 | cpu_usage   | 72.5  | host=web01    |
| 2024-01-01 | mem_usage   | 85.2  | host=web01    |

Wide model (metrics as columns): efficient for correlated queries
| time       | host   | cpu_usage | mem_usage | disk_io |
|------------|--------|-----------|-----------|---------|
| 2024-01-01 | web01  | 72.5      | 85.2      | 1024    |
```

**Use narrow**: dynamic metrics, unknown schema upfront, flexible tagging.
**Use wide**: fixed metric set per entity, correlated analysis, lower storage overhead.

## Tag / Label Design Rules

- Keep tag cardinality bounded: prefer `region`, `host`, `service` over `user_id`, `request_id`
- Use fields/values for high-cardinality data (measurements, request IDs)
- Avoid encoding time information in tag values
- Standardize naming: `snake_case`, consistent prefixes (`k8s_`, `aws_`)

## Multi-Tier Retention Pattern

```
Raw data (10s resolution)    → Keep 7 days
  |  [Downsample to 1m avg]
1-minute aggregates          → Keep 30 days
  |  [Downsample to 5m avg]
5-minute aggregates          → Keep 90 days
  |  [Downsample to 1h avg]
1-hour aggregates            → Keep 2 years
  |  [Downsample to 1d avg]
1-day aggregates             → Keep indefinitely
```

## Downsampling Functions by Metric Type

| Metric Type | Function | Reason |
|-------------|----------|--------|
| Gauge (CPU, memory) | `avg` | Representative central value |
| Counter (requests) | `sum` of rates | Preserve total throughput |
| Histogram (latency) | `max` or `p99` | Preserve worst-case |
| Availability (uptime) | `min` | Surface any outages |
| Error counts | `sum` | Preserve total error count |

## Capacity Planning

```bash
# Storage estimate: bytes_per_point * points_per_second * retention_seconds
# InfluxDB:         ~2-8 bytes/point compressed
# Prometheus:       ~1-2 bytes/point compressed
# VictoriaMetrics:  ~0.5-1 byte/point compressed

# Example: 100K metrics, 10s interval, 30 days retention
# Points: 100,000 * 6/min * 60 * 24 * 30 = 25.9 billion points
# At 2 bytes/point → ~48 GB compressed storage
```

## High Availability Patterns

| Database | HA Strategy |
|----------|-------------|
| Prometheus | 2+ replicas scraping same targets, deduplicate at Thanos/Mimir |
| InfluxDB | Enterprise clustering or InfluxDB Cloud; OSS is single-node only |
| TimescaleDB | PostgreSQL streaming replication + Patroni |
| VictoriaMetrics | Cluster mode with replicated vmstorage nodes |
| QuestDB | Enterprise WAL shipping; deploy behind load balancer for OSS |

## Monitoring the Monitor

- Always monitor your TSDB with an independent system
- Track: ingestion rate, query latency, storage growth, cardinality, WAL size
- Set alerts for: cardinality explosion, ingestion lag, compaction delays, disk >80%
- `prometheus_tsdb_head_series` — active series count in Prometheus
- `influxdb_shard_write_count` — write volume in InfluxDB
