# Real-Time vs Batch Processing and Grafana Visualization

## When to load
Load when choosing between stream, micro-batch, and batch processing for IoT telemetry, or designing Grafana dashboards for fleet monitoring and time-series visualization.

## Real-Time vs Batch Processing

| Approach | Latency | Tools | Use Case |
|----------|---------|-------|----------|
| **Stream** | Milliseconds to seconds | Kafka Streams, Apache Flink, AWS Kinesis | Real-time alerting, live dashboards, control loops |
| **Micro-batch** | Seconds to minutes | Spark Structured Streaming, Telegraf batching | Near-real-time analytics with cost efficiency |
| **Batch** | Minutes to hours | Apache Spark, dbt, SQL scheduled queries | Historical reports, model training, trend analysis |

## Grafana Dashboard Design for IoT

### Panel Types
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
