---
name: time-series-databases
description: |
  Deep operational guide for 14 time-series databases. InfluxDB (Flux, 3.0 Arrow/Parquet, Telegraf), Prometheus (PromQL, Thanos/Mimir), TimescaleDB (hypertables, continuous aggregates), QuestDB, VictoriaMetrics, TDengine, IoTDB, Graphite, KDB+, OpenTSDB, M3DB, CrateDB, Timestream, GridDB. Use when designing time-series storage for metrics, IoT, financial data, or observability.
allowed-tools: Read, Grep, Glob, Bash
---

You are a time-series database specialist informed by the Software Engineer by RN competency matrix.

## Time-Series Database Comparison

| Database | Query Language | Storage Engine | Compression | Ingestion (pts/sec) | Managed Options |
|----------|---------------|----------------|-------------|---------------------|-----------------|
| InfluxDB 3.0 | SQL + InfluxQL | Apache Arrow / Parquet | Columnar + Parquet | 1M+ | InfluxDB Cloud |
| Prometheus | PromQL | Custom TSDB (chunks) | Gorilla + delta-of-delta | 10M+ (scrape) | Grafana Cloud, AWS AMP |
| TimescaleDB | SQL (PostgreSQL) | Hypertable chunks | Native columnar compression | 1M+ | Timescale Cloud |
| QuestDB | SQL (PG wire) | Column-based, memory-mapped | LZ4 + custom | 1.4M+ | QuestDB Cloud |
| VictoriaMetrics | MetricsQL (PromQL superset) | Merge-tree variant | zstd, 10-70x | 10M+ | VictoriaMetrics Cloud |
| TDengine | TSQL (SQL-like) | Column-oriented + LSM | Compression per column | 10M+ | TDengine Cloud |
| Apache IoTDB | IOTDB-SQL | TsFile columnar | Gorilla, delta, RLE, dictionary | 5M+ | Self-hosted |
| Graphite | Graphite functions | Whisper (RRD-like) | Fixed-size archives | 100K+ | Grafana Cloud, Hosted Graphite |
| KDB+ / kdb Insights | q language | Column-oriented in-memory | On-disk: splayed + compressed | 100M+ | KX Cloud |
| OpenTSDB | HTTP API | HBase | HBase block compression | 1M+ | Self-hosted |
| M3DB | PromQL + M3 Query | Custom distributed LSM | Gorilla + M3TSZ | 10M+ | Self-hosted (Chronosphere) |
| CrateDB | SQL (PG wire) | Lucene segments | Columnar + LZ4 | 500K+ | CrateDB Cloud |
| Amazon Timestream | SQL | Magnetic + memory tiers | Automatic columnar | 1M+ | AWS Managed |
| GridDB | TQL + SQL subset | In-memory + disk hybrid | ZLIB, LZ4 | 1M+ | Self-hosted |

## InfluxDB

### Architecture and Versions

InfluxDB 3.0 represents a ground-up rewrite built on Apache Arrow, DataFusion, and Parquet:
- **InfluxDB 1.x**: Custom TSM engine, InfluxQL, retention policies, continuous queries
- **InfluxDB 2.x**: Flux language, unified API, built-in UI, tasks, organizations/buckets
- **InfluxDB 3.0**: SQL + InfluxQL, Apache Arrow Flight, Parquet storage, columnar engine via DataFusion

### Flux Language (2.x)

```flux
// Query with windowing, aggregation, and transformation
from(bucket: "metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "cpu" and r.host == "web-01")
  |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
  |> yield(name: "mean_cpu")

// Join two streams
cpu = from(bucket: "metrics") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "cpu")
mem = from(bucket: "metrics") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "mem")
join(tables: {cpu: cpu, mem: mem}, on: ["_time", "host"])

// Task (continuous query replacement in 2.x)
option task = {name: "downsample_cpu", every: 1h}
from(bucket: "metrics")
  |> range(start: -task.every)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> aggregateWindow(every: 5m, fn: mean)
  |> to(bucket: "metrics_downsampled", org: "myorg")
```

### InfluxDB 3.0 SQL Queries

```sql
-- Native SQL on time-series data via DataFusion
SELECT time, host, mean(usage_idle)
FROM cpu
WHERE time >= now() - INTERVAL '1 hour'
GROUP BY time_bucket('5 minutes', time), host
ORDER BY time DESC;
```

### Telegraf Agent Configuration

```toml
# /etc/telegraf/telegraf.conf
[agent]
  interval = "10s"
  flush_interval = "10s"
  metric_batch_size = 5000
  metric_buffer_limit = 100000

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false

[[inputs.mem]]
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs"]

[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  container_names = []
  timeout = "5s"

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "${INFLUX_TOKEN}"
  organization = "myorg"
  bucket = "metrics"
```

### Cardinality Management

```bash
# Check cardinality (series count)
influx query 'import "influxdata/influxdb" influxdb.cardinality(bucket: "metrics", start: -30d)'

# Identify high-cardinality tags
influx query 'import "influxdata/influxdb/schema" schema.tagValues(bucket: "metrics", tag: "host", start: -7d) |> count()'
```

Best practices: avoid unbounded tag values (user IDs, request IDs), use fields for high-cardinality data, set `max-series-per-database` limits, prune stale series with `DELETE` or retention policies.

### Retention and Downsampling

```bash
# InfluxDB 2.x bucket with retention
influx bucket create --name metrics_raw --retention 7d
influx bucket create --name metrics_1h --retention 365d
influx bucket create --name metrics_1d --retention 0  # infinite
```

## Prometheus

### PromQL Fundamentals

```promql
# Instant vector: current CPU usage per instance
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Range vector with rate: request rate over 5m
rate(http_requests_total{job="api-server", status=~"5.."}[5m])

# Histogram quantile: p99 request duration
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job="api"}[5m])) by (le))

# Predict disk full in 4 hours
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 4 * 3600) < 0

# Aggregation across labels
sum by (service) (rate(http_requests_total[5m]))
topk(5, sum by (endpoint) (rate(http_requests_total[5m])))

# Subquery: max over time of a rate
max_over_time(rate(http_requests_total[5m])[1h:1m])
```

### Recording and Alerting Rules

```yaml
# /etc/prometheus/rules/api_rules.yml
groups:
  - name: api_recording_rules
    interval: 30s
    rules:
      - record: job:http_requests_total:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
      - record: job:http_request_duration_seconds:p99
        expr: histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket[5m])))

  - name: api_alerting_rules
    rules:
      - alert: HighErrorRate
        expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High 5xx error rate ({{ $value | humanizePercentage }})"
          dashboard: "https://grafana.example.com/d/api-overview"

      - alert: TargetDown
        expr: up == 0
        for: 3m
        labels:
          severity: warning
```

### Federation and Remote Storage

```yaml
# prometheus.yml - Federation
scrape_configs:
  - job_name: 'federate'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets: ['prometheus-dc1:9090', 'prometheus-dc2:9090']

# Remote write to long-term storage (Thanos/Mimir/VictoriaMetrics)
remote_write:
  - url: "http://mimir:9009/api/v1/push"
    queue_config:
      max_samples_per_send: 5000
      batch_send_deadline: 5s
      max_shards: 30
```

### Long-Term Storage: Thanos vs Cortex vs Mimir

| Feature | Thanos | Cortex | Grafana Mimir |
|---------|--------|--------|---------------|
| Architecture | Sidecar + compactor | Microservices | Microservices (Cortex fork) |
| Object Storage | S3/GCS/Azure | S3/GCS/Azure/Swift | S3/GCS/Azure |
| Global View | Querier federation | Multi-tenant | Multi-tenant |
| Downsampling | Built-in (5m, 1h) | Via rules | Via rules |
| Deduplication | Yes (replica labels) | Ingester HA | Ingester HA |
| Compaction | Standalone compactor | Compactor | Compactor |

```bash
# Thanos sidecar deployment alongside Prometheus
thanos sidecar \
  --tsdb.path=/prometheus/data \
  --objstore.config-file=bucket.yml \
  --prometheus.url=http://localhost:9090
```

## TimescaleDB

### Hypertable Setup and Operations

```sql
-- Create a hypertable from a regular PostgreSQL table
CREATE TABLE metrics (
    time        TIMESTAMPTZ NOT NULL,
    device_id   TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    humidity    DOUBLE PRECISION,
    battery     DOUBLE PRECISION
);

SELECT create_hypertable('metrics', by_range('time'));

-- Add space partitioning for multi-node or high cardinality
SELECT add_dimension('metrics', by_hash('device_id', 4));

-- Create continuous aggregate (materialized view)
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

-- Refresh policy for continuous aggregate
SELECT add_continuous_aggregate_policy('metrics_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- Compression policy (columnar compression on older data)
ALTER TABLE metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('metrics', INTERVAL '7 days');

-- Data retention policy
SELECT add_retention_policy('metrics', INTERVAL '90 days');
```

### TimescaleDB Hyperfunctions

```sql
-- Time-weighted averages
SELECT time_bucket('1 hour', time) AS bucket,
       device_id,
       time_weight('LOCF', time, temperature) AS tw_avg_temp
FROM metrics
WHERE time > now() - INTERVAL '1 day'
GROUP BY bucket, device_id;

-- Approximate percentile (uddsketch)
SELECT time_bucket('1 hour', time) AS bucket,
       approx_percentile(0.99, percentile_agg(response_time)) AS p99
FROM api_metrics
GROUP BY bucket;

-- Gap filling for regular time-series output
SELECT time_bucket_gapfill('1 hour', time) AS bucket,
       device_id,
       locf(avg(temperature)) AS temperature
FROM metrics
WHERE time > now() - INTERVAL '1 day'
GROUP BY bucket, device_id;
```

## QuestDB

### SQL-Native Time-Series Queries

```sql
-- QuestDB uses standard SQL with time-series extensions
CREATE TABLE sensors (
    timestamp TIMESTAMP,
    sensor_id SYMBOL,        -- SYMBOL type: interned string for low-cardinality
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

-- ASOF JOIN: temporal join (nearest timestamp match)
SELECT s.timestamp, s.sensor_id, s.temperature, p.price
FROM sensors s
ASOF JOIN prices p ON (s.sensor_id = p.symbol);

-- Window functions
SELECT timestamp, sensor_id, temperature,
       avg(temperature) OVER (PARTITION BY sensor_id ORDER BY timestamp ROWS 10 PRECEDING) AS moving_avg
FROM sensors;
```

### QuestDB Ingestion via InfluxDB Line Protocol

```bash
# High-performance ingestion via ILP over TCP
echo "sensors,sensor_id=s1 temperature=23.5,humidity=62.1 1704067200000000000" | \
  nc -q 0 localhost 9009

# Or via HTTP API
curl -X POST "http://localhost:9000/exec?query=INSERT+INTO+sensors+VALUES(now(),'s1',23.5,62.1)"
```

## VictoriaMetrics

### MetricsQL Extensions (PromQL Superset)

```promql
# WITH templates: reusable subqueries
WITH (
  request_rate = sum(rate(http_requests_total[5m])) by (service),
  error_rate = sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
)
error_rate / request_rate

# Range functions not in standard PromQL
range_median(http_request_duration_seconds[1h])
range_quantile(0.99, http_request_duration_seconds[1h])
median_over_time(process_resident_memory_bytes[1h])

# Label manipulation
label_move(metric, "src_label", "dst_label")
label_uppercase(metric, "label_name")

# Rollup functions
rollup_rate(http_requests_total[5m])  -- combines rate + aggregation in one pass
```

### Deployment: Single-Node vs Cluster

```bash
# Single-node (handles millions of metrics/sec)
victoria-metrics \
  -storageDataPath=/var/lib/victoria-metrics \
  -retentionPeriod=12 \
  -httpListenAddr=:8428 \
  -search.maxUniqueTimeseries=10000000

# Cluster mode components
# vminsert: ingestion (stateless, horizontally scalable)
vminsert -storageNode=vmstorage-1:8400,vmstorage-2:8400

# vmstorage: storage (stateful, sharded)
vmstorage -storageDataPath=/data -retentionPeriod=12

# vmselect: query (stateless, horizontally scalable)
vmselect -storageNode=vmstorage-1:8401,vmstorage-2:8401

# vmagent: metrics collection (replaces Prometheus scraper)
vmagent -promscrape.config=prometheus.yml -remoteWrite.url=http://vminsert:8480/insert/0/prometheus/
```

## TDengine

### Super Tables and IoT Data Modeling

```sql
-- Super table: schema template for all devices
CREATE STABLE sensors (
    ts TIMESTAMP,
    temperature FLOAT,
    humidity FLOAT,
    battery INT
) TAGS (
    device_id BINARY(32),
    location BINARY(64),
    device_type BINARY(16)
);

-- Subtables created per device (inherit schema from super table)
CREATE TABLE sensor_001 USING sensors TAGS ('dev-001', 'warehouse-a', 'dht22');
CREATE TABLE sensor_002 USING sensors TAGS ('dev-002', 'warehouse-b', 'bme280');

-- Auto-create subtables on write
INSERT INTO sensor_003 USING sensors TAGS ('dev-003', 'floor-1', 'dht22')
VALUES (now(), 24.5, 62.1, 95);

-- Aggregate across super table (all devices)
SELECT device_id, AVG(temperature), MAX(humidity)
FROM sensors
WHERE ts > now() - 1h
GROUP BY device_id
INTERVAL(10m);

-- Continuous query (stream computation)
CREATE STREAM avg_temp_stream TRIGGER AT_ONCE INTO avg_temp_results AS
SELECT _wstart AS ts, device_id, AVG(temperature) AS avg_temp
FROM sensors
INTERVAL(5m);
```

## Apache IoTDB

### IoT Data Management

```sql
-- Create storage group and time-series
CREATE DATABASE root.factory1;

CREATE TIMESERIES root.factory1.line1.device1.temperature WITH DATATYPE=FLOAT, ENCODING=GORILLA, COMPRESSOR=SNAPPY;
CREATE TIMESERIES root.factory1.line1.device1.vibration WITH DATATYPE=DOUBLE, ENCODING=GORILLA;

-- Aligned time-series (same timestamps, stored together)
CREATE ALIGNED TIMESERIES root.factory1.line1.device1 (
    temperature FLOAT encoding=GORILLA compressor=SNAPPY,
    humidity FLOAT encoding=GORILLA,
    status BOOLEAN encoding=RLE
);

-- Insert and query
INSERT INTO root.factory1.line1.device1 (timestamp, temperature, humidity) VALUES (now(), 25.3, 61.2);

SELECT last_value(temperature), avg(humidity)
FROM root.factory1.line1.**
GROUP BY ([now() - 1h, now()), 10m);
```

## Graphite

### Carbon + Whisper + Graphite-Web Architecture

```ini
# storage-schemas.conf - Retention policies
[default_1min_for_1day]
pattern = .*
retentions = 10s:1d,1m:7d,5m:30d,1h:1y

[high_resolution]
pattern = ^servers\.prod\.
retentions = 1s:1h,10s:1d,1m:30d,5m:1y

# storage-aggregation.conf - Downsampling methods
[min]
pattern = \.min$
xFilesFactor = 0.1
aggregationMethod = min

[max]
pattern = \.max$
xFilesFactor = 0.1
aggregationMethod = max

[count]
pattern = \.count$
xFilesFactor = 0
aggregationMethod = sum
```

```bash
# Send metrics to Carbon (plaintext protocol)
echo "servers.web01.cpu.usage 72.5 $(date +%s)" | nc -q0 graphite 2003

# Graphite render API
curl "http://graphite/render?target=servers.web01.cpu.usage&from=-1h&format=json"
curl "http://graphite/render?target=summarize(servers.*.cpu.usage,'1h','avg')&format=json"
```

## KDB+ / kdb Insights

### Financial Time-Series with q Language

```q
/ Define trade table (tick database schema)
trade:([]time:`timestamp$(); sym:`symbol$(); price:`float$(); size:`long$(); side:`char$())

/ Load sample data and query
select avg price, sum size by 5 xbar time.minute, sym from trade where date=.z.d, sym=`AAPL

/ VWAP (volume-weighted average price)
select vwap: size wavg price by sym from trade where date=.z.d

/ Time-weighted mid-price
update mid:(bid+ask)%2 from quote

/ Moving window operations
select sym, time, price, mavg[20;price] as sma20, mdev[20;price] as vol20 from trade where sym=`AAPL

/ Asof join (temporal join for trade enrichment)
aj[`sym`time; trade; quote]
```

## OpenTSDB

### HBase-Backed Metric Storage

```bash
# Write metrics via HTTP API
curl -X POST http://opentsdb:4242/api/put -d '{
  "metric": "sys.cpu.usage",
  "timestamp": 1704067200,
  "value": 72.5,
  "tags": { "host": "web01", "dc": "us-east-1" }
}'

# Query metrics
curl "http://opentsdb:4242/api/query?start=1h-ago&m=avg:rate:sys.cpu.usage{host=web01}"
```

## M3DB

### Distributed Prometheus Storage

```yaml
# M3DB namespace configuration
namespaces:
  - name: metrics_10s_2d
    retention: 48h
    resolution: 10s
    blockSize: 2h
  - name: metrics_1m_30d
    retention: 720h
    resolution: 1m
    blockSize: 12h
  - name: metrics_10m_1y
    retention: 8760h
    resolution: 10m
    blockSize: 24h

# M3 Coordinator connects Prometheus to M3DB
coordinator:
  listenAddress: 0.0.0.0:7201
  metrics:
    scope:
      prefix: "coordinator"
    prometheus:
      handlerPath: /metrics
```

## CrateDB

### Distributed SQL on Time-Series

```sql
-- Create time-series table with sharding and partitioning
CREATE TABLE sensor_data (
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    device_id TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION,
    metadata OBJECT(DYNAMIC)
) CLUSTERED BY (device_id) INTO 6 SHARDS
PARTITIONED BY (date_trunc('month', ts));

-- Full SQL including JOINs, subqueries, window functions
SELECT device_id,
       date_trunc('hour', ts) AS hour,
       AVG(temperature) AS avg_temp,
       AVG(temperature) OVER (PARTITION BY device_id ORDER BY date_trunc('hour', ts)
           ROWS BETWEEN 24 PRECEDING AND CURRENT ROW) AS moving_avg
FROM sensor_data
WHERE ts >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY 1, 2
ORDER BY 1, 2;
```

## Amazon Timestream

### Serverless Time-Series on AWS

```sql
-- Create database and table
CREATE DATABASE iot_metrics;
CREATE TABLE iot_metrics.device_readings;

-- Write via AWS SDK (multi-measure records)
-- Records automatically tier from memory (recent) to magnetic (historical)

-- Query with scheduled queries for downsampling
CREATE SCHEDULED QUERY hourly_aggregates
SCHEDULE EXPRESSION 'cron(0 * * * ? *)'
TARGET DATABASE 'iot_metrics' TABLE 'hourly_readings'
AS SELECT device_id,
          bin(time, 1h) AS hour,
          AVG(measure_value::double) AS avg_value,
          MAX(measure_value::double) AS max_value
   FROM iot_metrics.device_readings
   WHERE measure_name = 'temperature'
     AND time BETWEEN ago(2h) AND ago(1h)
   GROUP BY device_id, bin(time, 1h);

-- Interpolation and time-series functions
SELECT device_id,
       INTERPOLATE_LINEAR(
           CREATE_TIME_SERIES(time, measure_value::double),
           SEQUENCE(ago(1h), now(), 5m)
       ) AS interpolated_temp
FROM iot_metrics.device_readings
WHERE measure_name = 'temperature';
```

## GridDB

### IoT Key-Container Model

```java
// GridDB Java client: container per device
GridStore store = GridStoreFactory.getInstance().getGridStore(properties);

ContainerInfo containerInfo = new ContainerInfo();
containerInfo.setName("sensor_001");
containerInfo.setType(ContainerType.TIME_SERIES);
containerInfo.setColumnInfoList(Arrays.asList(
    new ColumnInfo("timestamp", GSType.TIMESTAMP),
    new ColumnInfo("temperature", GSType.DOUBLE),
    new ColumnInfo("humidity", GSType.DOUBLE)
));

TimeSeries<Row> ts = store.putTimeSeries("sensor_001", containerInfo);

// Insert
Row row = ts.createRow();
row.setTimestamp(0, new Date());
row.setDouble(1, 24.5);
row.setDouble(2, 61.2);
ts.put(row);

// Time-series aggregation
AggregationResult result = ts.aggregate(
    startTime, endTime, "temperature", Aggregation.WEIGHTED_AVERAGE);
```

## Data Modeling Patterns for Time-Series

### Narrow vs Wide Table Design

```
-- Narrow model (one metric per row): flexible, higher cardinality
| time       | metric_name | value | tags          |
|------------|-------------|-------|---------------|
| 2024-01-01 | cpu_usage   | 72.5  | host=web01    |
| 2024-01-01 | mem_usage   | 85.2  | host=web01    |

-- Wide model (metrics as columns): efficient for correlated queries
| time       | host   | cpu_usage | mem_usage | disk_io |
|------------|--------|-----------|-----------|---------|
| 2024-01-01 | web01  | 72.5      | 85.2      | 1024    |
```

**When to use narrow**: dynamic metrics, unknown schema upfront, flexible tagging.
**When to use wide**: fixed set of metrics per entity, correlated analysis, lower storage overhead.

### Tag / Label Design

- Keep tag cardinality bounded (prefer `region`, `host`, `service` over `user_id`, `request_id`)
- Use fields/values for high-cardinality data (measurements, IDs)
- Avoid encoding time information in tag values
- Standardize tag naming: `snake_case`, consistent prefixes (`k8s_`, `aws_`)

## Retention and Downsampling Strategies

### Multi-Tier Retention Pattern

```
Raw data (10s resolution) --> Keep 7 days
  |
  v  [Downsample to 1m averages]
1-minute aggregates       --> Keep 30 days
  |
  v  [Downsample to 5m averages]
5-minute aggregates       --> Keep 90 days
  |
  v  [Downsample to 1h averages]
1-hour aggregates         --> Keep 2 years
  |
  v  [Downsample to 1d averages]
1-day aggregates          --> Keep indefinitely
```

### Downsampling Functions by Use Case

| Metric Type | Downsample Function | Reason |
|-------------|---------------------|--------|
| Gauge (CPU, memory) | `avg` | Representative central value |
| Counter (requests) | `sum` of rates | Preserve total throughput |
| Histogram (latency) | `max` or `p99` | Preserve worst-case |
| Availability (uptime) | `min` | Surface outages |
| Error counts | `sum` | Preserve total error count |

## Operational Best Practices

### Capacity Planning

```bash
# Estimate storage: bytes_per_point * points_per_second * retention_seconds
# InfluxDB: ~2-8 bytes/point compressed
# Prometheus: ~1-2 bytes/point compressed
# VictoriaMetrics: ~0.5-1 byte/point compressed

# Example: 100K metrics, 10s interval, 30 days retention
# Points: 100,000 * 6/min * 60 * 24 * 30 = 25.9 billion points
# At 2 bytes/point = ~48 GB compressed storage
```

### High Availability Patterns

- **Prometheus**: Run 2+ replicas scraping same targets, deduplicate at query layer (Thanos/Mimir)
- **InfluxDB**: Enterprise clustering or InfluxDB Cloud; OSS is single-node only
- **TimescaleDB**: PostgreSQL streaming replication + Patroni for failover
- **VictoriaMetrics**: Cluster mode with replicated vmstorage nodes
- **QuestDB**: Replication via WAL shipping (Enterprise), or deploy behind load balancer

### Monitoring the Monitor

- Always monitor your time-series database with an independent system
- Track: ingestion rate, query latency, storage growth, cardinality, WAL size
- Set alerts for: cardinality explosion, ingestion lag, compaction delays, disk usage >80%
- Use `prometheus_tsdb_head_series` to track active series in Prometheus
- Use `influxdb_shard_write_count` to track write volume in InfluxDB
