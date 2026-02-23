# InfluxDB and Telegraf

## When to load
Load when working with InfluxDB 1.x/2.x/3.0: Flux language, SQL queries, Telegraf agent configuration, cardinality management, retention policies, and downsampling tasks.

## Architecture Versions

```
InfluxDB 1.x: Custom TSM engine, InfluxQL, retention policies, continuous queries
InfluxDB 2.x: Flux language, unified API, built-in UI, tasks, organizations/buckets
InfluxDB 3.0: SQL + InfluxQL, Apache Arrow Flight, Parquet storage, DataFusion engine
```

## Flux Language (2.x)

```flux
// Query with windowing, aggregation, transformation
from(bucket: "metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "cpu" and r.host == "web-01")
  |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
  |> yield(name: "mean_cpu")

// Join two streams
cpu = from(bucket: "metrics") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "cpu")
mem = from(bucket: "metrics") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "mem")
join(tables: {cpu: cpu, mem: mem}, on: ["_time", "host"])

// Task: continuous downsampling
option task = {name: "downsample_cpu", every: 1h}
from(bucket: "metrics")
  |> range(start: -task.every)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> aggregateWindow(every: 5m, fn: mean)
  |> to(bucket: "metrics_downsampled", org: "myorg")
```

## InfluxDB 3.0 SQL

```sql
SELECT time, host, mean(usage_idle)
FROM cpu
WHERE time >= now() - INTERVAL '1 hour'
GROUP BY time_bucket('5 minutes', time), host
ORDER BY time DESC;
```

## Telegraf Configuration

```toml
[agent]
  interval = "10s"
  flush_interval = "10s"
  metric_batch_size = 5000
  metric_buffer_limit = 100000

[[inputs.cpu]]
  percpu = true
  totalcpu = true

[[inputs.mem]]
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs"]

[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  timeout = "5s"

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "${INFLUX_TOKEN}"
  organization = "myorg"
  bucket = "metrics"
```

## Cardinality Management

```bash
# Check cardinality (series count)
influx query 'import "influxdata/influxdb"
  influxdb.cardinality(bucket: "metrics", start: -30d)'

# Identify high-cardinality tags
influx query 'import "influxdata/influxdb/schema"
  schema.tagValues(bucket: "metrics", tag: "host", start: -7d) |> count()'
```

Best practices: avoid unbounded tag values (user IDs, request IDs), use fields for high-cardinality data, set `max-series-per-database` limits, prune stale series with DELETE or retention policies.

## Retention and Downsampling

```bash
# Create buckets with tiered retention
influx bucket create --name metrics_raw --retention 7d
influx bucket create --name metrics_1h --retention 365d
influx bucket create --name metrics_1d --retention 0  # infinite
```
