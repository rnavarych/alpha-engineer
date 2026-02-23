# IoT and Specialized Time-Series Databases

## When to load
Load when working with TDengine, Apache IoTDB, GridDB (IoT/industrial), KDB+/q (financial time-series), OpenTSDB (HBase-backed), M3DB (distributed Prometheus storage), CrateDB (distributed SQL), or Amazon Timestream (serverless AWS).

## TDengine — Super Tables for IoT

```sql
-- Super table: one schema template, one subtable per device
CREATE STABLE sensors (ts TIMESTAMP, temperature FLOAT, humidity FLOAT, battery INT)
TAGS (device_id BINARY(32), location BINARY(64), device_type BINARY(16));

-- Auto-create subtable on write
INSERT INTO sensor_003 USING sensors TAGS ('dev-003', 'floor-1', 'dht22') VALUES (now(), 24.5, 62.1, 95);

-- Query across all devices via super table
SELECT device_id, AVG(temperature), MAX(humidity) FROM sensors
WHERE ts > now() - 1h GROUP BY device_id INTERVAL(10m);

-- Continuous stream computation
CREATE STREAM avg_temp_stream TRIGGER AT_ONCE INTO avg_temp_results AS
SELECT _wstart AS ts, device_id, AVG(temperature) AS avg_temp FROM sensors INTERVAL(5m);
```

## Apache IoTDB

```sql
CREATE DATABASE root.factory1;
CREATE ALIGNED TIMESERIES root.factory1.line1.device1 (
    temperature FLOAT encoding=GORILLA compressor=SNAPPY,
    humidity FLOAT encoding=GORILLA,
    status BOOLEAN encoding=RLE
);

INSERT INTO root.factory1.line1.device1 (timestamp, temperature, humidity) VALUES (now(), 25.3, 61.2);

SELECT last_value(temperature), avg(humidity)
FROM root.factory1.line1.**
GROUP BY ([now() - 1h, now()), 10m);
```

## KDB+ — Financial Time-Series

```q
/ VWAP (volume-weighted average price)
select vwap: size wavg price by sym from trade where date=.z.d
/ Moving window: 20-period SMA and volatility
select sym, time, price, mavg[20;price] as sma20, mdev[20;price] as vol20 from trade where sym=`AAPL
/ ASOF join (temporal join: enrich trade with nearest quote)
aj[`sym`time; trade; quote]
```

## OpenTSDB

```bash
# Write metric
curl -X POST http://opentsdb:4242/api/put \
  -d '{"metric":"sys.cpu.usage","timestamp":1704067200,"value":72.5,"tags":{"host":"web01"}}'
# Query
curl "http://opentsdb:4242/api/query?start=1h-ago&m=avg:rate:sys.cpu.usage{host=web01}"
```

## M3DB — Distributed Prometheus Storage

```yaml
# Multi-namespace retention tiers (resolution + retention + blockSize per tier)
namespaces:
  - { name: metrics_10s_2d, retention: 48h, resolution: 10s, blockSize: 2h }
  - { name: metrics_1m_30d, retention: 720h, resolution: 1m, blockSize: 12h }
  - { name: metrics_10m_1y, retention: 8760h, resolution: 10m, blockSize: 24h }
coordinator:
  listenAddress: 0.0.0.0:7201
```

## CrateDB — Distributed SQL

```sql
CREATE TABLE sensor_data (
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    device_id TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    metadata OBJECT(DYNAMIC)
) CLUSTERED BY (device_id) INTO 6 SHARDS
PARTITIONED BY (date_trunc('month', ts));

SELECT device_id, date_trunc('hour', ts) AS hour, AVG(temperature) AS avg_temp,
       AVG(temperature) OVER (PARTITION BY device_id ORDER BY date_trunc('hour', ts)
           ROWS BETWEEN 24 PRECEDING AND CURRENT ROW) AS moving_avg
FROM sensor_data WHERE ts >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY 1, 2 ORDER BY 1, 2;
```

## Amazon Timestream

```sql
CREATE DATABASE iot_metrics;
CREATE TABLE iot_metrics.device_readings;

-- Scheduled downsampling query
CREATE SCHEDULED QUERY hourly_aggregates SCHEDULE EXPRESSION 'cron(0 * * * ? *)'
TARGET DATABASE 'iot_metrics' TABLE 'hourly_readings'
AS SELECT device_id, bin(time, 1h) AS hour, AVG(measure_value::double) AS avg_value
   FROM iot_metrics.device_readings
   WHERE measure_name = 'temperature' AND time BETWEEN ago(2h) AND ago(1h)
   GROUP BY device_id, bin(time, 1h);
```

## GridDB — IoT Key-Container Model

```java
// One TimeSeries container per device; WEIGHTED_AVERAGE aggregation built-in
ContainerInfo info = new ContainerInfo();
info.setName("sensor_001"); info.setType(ContainerType.TIME_SERIES);
info.setColumnInfoList(Arrays.asList(new ColumnInfo("timestamp", GSType.TIMESTAMP),
    new ColumnInfo("temperature", GSType.DOUBLE)));
TimeSeries<Row> ts = store.putTimeSeries("sensor_001", info);
ts.aggregate(startTime, endTime, "temperature", Aggregation.WEIGHTED_AVERAGE);
```
