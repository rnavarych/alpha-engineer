# Observability Stack Reference

## OpenTelemetry (OTel) Ecosystem

### OTel Collector
- Standalone binary that receives, processes, and exports telemetry data
- **Receivers**: OTLP, Prometheus, Jaeger, Zipkin, Fluent Forward, syslog, filelog, hostmetrics
- **Processors**: batch, memory_limiter, attributes, resource, filter, tail_sampling, transform, k8sattributes
- **Exporters**: OTLP, Prometheus, Jaeger, Zipkin, Loki, Elasticsearch, Datadog, New Relic, Splunk
- **Deployment modes**: Agent (sidecar/daemonset) or Gateway (centralized)
- **Collector distributions**: Core (minimal), Contrib (all components), custom builds with OCB (OTel Collector Builder)

### OTel SDKs
| Language | Package | Auto-instrumentation |
|----------|---------|---------------------|
| Node.js | `@opentelemetry/sdk-node` | `@opentelemetry/auto-instrumentations-node` (Express, Fastify, pg, mysql, Redis, gRPC, HTTP) |
| Python | `opentelemetry-sdk` | `opentelemetry-instrument` CLI (Django, Flask, FastAPI, SQLAlchemy, psycopg2, requests, aiohttp) |
| Java | `opentelemetry-sdk` | `-javaagent:opentelemetry-javaagent.jar` (Spring, JDBC, Hibernate, gRPC, Kafka, Lettuce) |
| Go | `go.opentelemetry.io/otel` | Manual + contrib libs (`otelhttp`, `otelgrpc`, `otelsql`, `otelgorm`) |
| .NET | `OpenTelemetry.Sdk` | `OpenTelemetry.Instrumentation.*` (ASP.NET Core, HttpClient, SqlClient, EF Core, gRPC) |
| Rust | `opentelemetry` crate | `tracing-opentelemetry` bridge, `opentelemetry-otlp` |

### Semantic Conventions
- HTTP: `http.request.method`, `http.response.status_code`, `url.full`, `server.address`
- Database: `db.system`, `db.name`, `db.operation`, `db.statement`
- Messaging: `messaging.system`, `messaging.destination.name`, `messaging.operation`
- RPC: `rpc.system`, `rpc.service`, `rpc.method`
- Kubernetes: `k8s.namespace.name`, `k8s.pod.name`, `k8s.deployment.name`, `k8s.container.name`
- Cloud: `cloud.provider`, `cloud.region`, `cloud.account.id`, `cloud.platform`

### OTLP Protocol
- **gRPC transport** (port 4317): Binary protobuf, bidirectional streaming, preferred for high throughput
- **HTTP/protobuf transport** (port 4318): Binary protobuf over HTTP, firewall-friendly
- **HTTP/JSON transport** (port 4318): JSON encoding, debugging-friendly, lower performance
- Supports gzip and zstd compression
- Retry with exponential backoff built into SDK exporters

## Prometheus Ecosystem

### PromQL Patterns

```promql
# Request rate per second (5-minute window)
rate(http_requests_total[5m])

# Error rate percentage
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m])) * 100

# 99th percentile latency
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# Apdex score (satisfied < 0.5s, tolerating < 2s)
(
  sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
  +
  sum(rate(http_request_duration_seconds_bucket{le="2.0"}[5m]))
)
/
2 / sum(rate(http_request_duration_seconds_count[5m]))

# Saturation: CPU throttled percentage
sum(rate(container_cpu_cfs_throttled_periods_total[5m]))
/
sum(rate(container_cpu_cfs_periods_total[5m])) * 100

# Memory utilization percentage
container_memory_working_set_bytes / container_spec_memory_limit_bytes * 100

# Predict disk full in 4 hours
predict_linear(node_filesystem_avail_bytes[1h], 4*3600) < 0

# Top 5 endpoints by request rate
topk(5, sum by (handler) (rate(http_requests_total[5m])))

# Error budget remaining (30-day SLO at 99.9%)
1 - (
  (1 - (sum(increase(http_requests_total{status!~"5.."}[30d])) / sum(increase(http_requests_total[30d]))))
  / (1 - 0.999)
)
```

### Recording Rules
```yaml
groups:
  - name: http_recording_rules
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
      - record: job:http_errors:rate5m
        expr: sum by (job) (rate(http_requests_total{status=~"5.."}[5m]))
      - record: job:http_latency:p99_5m
        expr: histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket[5m])))
```

### Alerting Rules
```yaml
groups:
  - name: slo_alerts
    rules:
      - alert: HighErrorRate
        expr: job:http_errors:rate5m / job:http_requests:rate5m > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          description: "Error rate is {{ $value | humanizePercentage }} (> 1%)"
          runbook_url: "https://wiki.example.com/runbooks/high-error-rate"

      - alert: HighLatency
        expr: job:http_latency:p99_5m > 1.0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High p99 latency on {{ $labels.job }}"
          description: "p99 latency is {{ $value }}s (> 1s)"

      - alert: ErrorBudgetBurnRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[1h]))
            / sum(rate(http_requests_total[1h]))
          ) > 14.4 * 0.001
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error budget burning too fast on {{ $labels.job }}"
```

### Long-Term Storage
- **Thanos**: Sidecar + Store + Compactor architecture. S3/GCS/Azure Blob backend. Global query view across clusters. Downsampling (5m, 1h).
- **Grafana Mimir**: Horizontally scalable. Multi-tenant. 100% Prometheus-compatible. Blazing-fast queries via query sharding.
- **VictoriaMetrics**: MetricsQL (PromQL superset). High compression (up to 70x). Single-node or cluster. vmagent for scraping.
- **Cortex**: CNCF project. Multi-tenant. Chunk or block storage. Being succeeded by Mimir.

## Grafana Ecosystem

### Grafana Loki (Logs)
- Log aggregation system inspired by Prometheus
- Index-free: only indexes labels, stores compressed log chunks in object storage
- LogQL query language (label filtering + line filtering + parser + aggregation)
- Integrates with Grafana for log-to-trace correlation
- Agents: Promtail, Grafana Alloy, Fluent Bit, OTel Collector

```logql
# LogQL examples:
{service="api-gateway"} |= "error" | json | status >= 500
{namespace="production"} | logfmt | duration > 1s | line_format "{{.method}} {{.path}} took {{.duration}}"
sum(rate({service="payment"} |= "timeout" [5m])) by (endpoint)
```

### Grafana Tempo (Traces)
- Distributed tracing backend, cost-effective (object storage only)
- Accepts Jaeger, Zipkin, OTLP protocols
- TraceQL query language for trace-level queries
- Service graph generation from traces
- No indexing required; uses trace ID lookup + search via Parquet

### Grafana Mimir (Metrics)
- See Prometheus long-term storage section above

### Grafana OnCall
- On-call management built into Grafana
- Integrations: Slack, Telegram, MS Teams, phone calls, SMS
- Escalation chains, schedules, routing
- Alert grouping and deduplication

### Grafana k6 (Load Testing)
- JavaScript-based load testing
- Protocol support: HTTP, WebSocket, gRPC, browser
- Cloud and local execution
- Integration with Grafana dashboards for test results

### Example Grafana Dashboard JSON Panel
```json
{
  "type": "timeseries",
  "title": "Request Rate by Status Code",
  "datasource": "Prometheus",
  "targets": [
    {
      "expr": "sum by (status_code) (rate(http_requests_total[5m]))",
      "legendFormat": "{{status_code}}"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "reqps",
      "custom": {
        "drawStyle": "line",
        "fillOpacity": 10,
        "gradientMode": "scheme",
        "stacking": { "mode": "normal" }
      }
    },
    "overrides": [
      { "matcher": { "id": "byRegexp", "options": "5.." }, "properties": [{ "id": "color", "value": { "fixedColor": "red", "mode": "fixed" } }] },
      { "matcher": { "id": "byRegexp", "options": "4.." }, "properties": [{ "id": "color", "value": { "fixedColor": "orange", "mode": "fixed" } }] },
      { "matcher": { "id": "byRegexp", "options": "2.." }, "properties": [{ "id": "color", "value": { "fixedColor": "green", "mode": "fixed" } }] }
    ]
  }
}
```

## ELK / OpenSearch Stack

### Elasticsearch
- Distributed search and analytics engine based on Apache Lucene
- Inverted index for full-text search, BKD trees for numeric/geo
- Index lifecycle management (ILM): hot -> warm -> cold -> frozen -> delete
- Cross-cluster search and replication
- ES|QL: piped query language (8.11+)
- Elasticsearch Serverless (managed)

### Logstash
- Server-side data processing pipeline
- Input plugins: beats, syslog, kafka, s3, jdbc, http
- Filter plugins: grok, mutate, date, geoip, dns, ruby, dissect
- Output plugins: elasticsearch, s3, kafka, stdout, datadog

### Kibana
- Visualization and dashboard platform
- Discover: ad-hoc log exploration
- Lens: drag-and-drop visualization builder
- Canvas: pixel-perfect presentations
- SIEM: security event analysis

### OpenSearch (AWS fork)
- Fork of Elasticsearch 7.10 (Apache 2.0 license)
- OpenSearch Dashboards (Kibana fork)
- Additional features: anomaly detection, alerting, SQL, PPL (Piped Processing Language)
- Serverless mode available on AWS

## Commercial APM Comparison

| Feature | Datadog | New Relic | Dynatrace |
|---------|---------|-----------|-----------|
| **Pricing model** | Per host + ingestion | Per-user + ingestion | Per-host (full-stack) |
| **APM** | Distributed tracing, flame graphs, service maps | Distributed tracing, service maps, errors inbox | PurePath tracing, Smartscape topology |
| **Infrastructure** | 800+ integrations, live process monitoring | 450+ integrations, host maps | OneAgent auto-discovery, Smartscape |
| **Logs** | Log management, Logging without Limits | Logs in context, log patterns | Log management, log analytics |
| **RUM** | Real User Monitoring, Session Replay | Browser monitoring, Session Replay | Real User Monitoring, Session Replay |
| **Synthetics** | API + Browser tests, CI/CD integration | Scripted browser, API tests | Synthetic monitoring, HTTP monitors |
| **AI/ML** | Watchdog (anomaly detection) | Applied Intelligence, AI Ops | Davis AI (causal analysis, auto-remediation) |
| **OpenTelemetry** | Full OTLP ingest | Full OTLP ingest | Full OTLP ingest + OneAgent |
| **Best for** | DevOps teams, broad observability | Full-stack developers, cost-conscious | Enterprise, auto-discovery, AI ops |

## Distributed Tracing Backends Comparison

| Feature | Jaeger | Zipkin | Grafana Tempo |
|---------|--------|--------|---------------|
| **Origin** | Uber, CNCF graduated | Twitter | Grafana Labs |
| **Storage** | Cassandra, Elasticsearch, Kafka, Badger, ClickHouse | MySQL, Cassandra, Elasticsearch, in-memory | Object storage (S3, GCS, Azure Blob) |
| **Query language** | Tag-based search | Tag-based search | TraceQL |
| **Protocol support** | Jaeger, OTLP, Zipkin | Zipkin, OTLP | Jaeger, Zipkin, OTLP |
| **UI** | Built-in, feature-rich | Built-in, simple | Grafana (no standalone UI) |
| **Sampling** | Remote sampling, adaptive | Rate-limited | Collector-level (head/tail with OTel) |
| **Cost** | Medium (requires indexing) | Low-Medium | Low (no indexing, object storage) |
| **Best for** | Kubernetes-native, self-hosted | Simple setups, lightweight | Grafana ecosystem, cost-sensitive, high scale |

## Incident Management Integration Patterns

### PagerDuty
```yaml
# Alertmanager -> PagerDuty integration
receivers:
  - name: pagerduty-oncall
    pagerduty_configs:
      - routing_key: "<integration-key>"
        severity: "{{ .CommonLabels.severity }}"
        description: "{{ .CommonAnnotations.summary }}"
        details:
          firing: "{{ .Alerts.Firing | len }}"
          dashboard: "{{ .CommonAnnotations.dashboard_url }}"
          runbook: "{{ .CommonAnnotations.runbook_url }}"
```

### OpsGenie
```yaml
# Alertmanager -> OpsGenie integration
receivers:
  - name: opsgenie-team
    opsgenie_configs:
      - api_key: "<api-key>"
        message: "{{ .CommonAnnotations.summary }}"
        priority: '{{ if eq .CommonLabels.severity "critical" }}P1{{ else if eq .CommonLabels.severity "warning" }}P2{{ else }}P3{{ end }}'
        tags: "{{ .CommonLabels.service }},{{ .CommonLabels.environment }}"
```

### Incident.io
- Slack-native incident declaration (`/incident`)
- Auto-creates incident channel with relevant responders
- Status page integration for customer communication
- Post-incident workflow: timeline, action items, follow-ups
- API-driven: can trigger from any alerting source via webhook

## Structured Log Format Examples

### Node.js (pino)
```javascript
const pino = require('pino');
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: ['req.headers.authorization', 'body.password'],
});

// Output:
// {"level":"info","time":"2026-02-22T10:30:00.123Z","service":"api","trace_id":"abc123","msg":"Request processed","duration_ms":42}
```

### Python (structlog)
```python
import structlog
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
)
log = structlog.get_logger()

# Output:
# {"level":"info","timestamp":"2026-02-22T10:30:00.123Z","service":"api","trace_id":"abc123","event":"Request processed","duration_ms":42}
```

### Go (zerolog)
```go
import "github.com/rs/zerolog/log"

log.Info().
    Str("service", "api").
    Str("trace_id", span.SpanContext().TraceID().String()).
    Int("duration_ms", 42).
    Msg("Request processed")

// Output:
// {"level":"info","time":"2026-02-22T10:30:00.123Z","service":"api","trace_id":"abc123","duration_ms":42,"message":"Request processed"}
```

### Java (Logback + SLF4J with MDC)
```java
import org.slf4j.MDC;
import org.slf4j.LoggerFactory;

MDC.put("traceId", span.getSpanContext().getTraceId());
MDC.put("spanId", span.getSpanContext().getSpanId());
logger.info("Request processed in {}ms", durationMs);

// logback-spring.xml with JSON encoder (logstash-logback-encoder):
// {"@timestamp":"2026-02-22T10:30:00.123Z","level":"INFO","logger_name":"com.example.Api","message":"Request processed in 42ms","traceId":"abc123","spanId":"def456"}
```

### .NET (Serilog)
```csharp
Log.Logger = new LoggerConfiguration()
    .Enrich.WithProperty("Service", "api")
    .Enrich.FromLogContext()
    .WriteTo.Console(new CompactJsonFormatter())
    .CreateLogger();

using (LogContext.PushProperty("TraceId", Activity.Current?.TraceId.ToString()))
{
    Log.Information("Request processed in {DurationMs}ms", durationMs);
}

// Output:
// {"@t":"2026-02-22T10:30:00.123Z","@l":"Information","@mt":"Request processed in {DurationMs}ms","DurationMs":42,"Service":"api","TraceId":"abc123"}
```
