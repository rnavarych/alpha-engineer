# OpenTelemetry and Prometheus Ecosystem

## When to load
Load when setting up OTel SDKs, configuring the OTel Collector, writing PromQL queries, configuring Prometheus recording/alerting rules, or choosing long-term metrics storage.

## OTel Collector
- Receives, processes, and exports telemetry data
- **Receivers**: OTLP, Prometheus, Jaeger, Zipkin, Fluent Forward, syslog, filelog, hostmetrics
- **Processors**: batch, memory_limiter, attributes, resource, filter, tail_sampling, k8sattributes
- **Exporters**: OTLP, Prometheus, Jaeger, Loki, Elasticsearch, Datadog, New Relic, Splunk
- **Deployment modes**: Agent (sidecar/daemonset) or Gateway (centralized)

## OTel SDKs

| Language | Package | Auto-instrumentation |
|----------|---------|---------------------|
| Node.js | `@opentelemetry/sdk-node` | `@opentelemetry/auto-instrumentations-node` |
| Python | `opentelemetry-sdk` | `opentelemetry-instrument` CLI |
| Java | `opentelemetry-sdk` | `-javaagent:opentelemetry-javaagent.jar` |
| Go | `go.opentelemetry.io/otel` | `otelhttp`, `otelgrpc`, `otelsql`, `otelgorm` |
| .NET | `OpenTelemetry.Sdk` | `OpenTelemetry.Instrumentation.*` |
| Rust | `opentelemetry` crate | `tracing-opentelemetry` bridge |

## Semantic Conventions
- HTTP: `http.request.method`, `http.response.status_code`, `url.full`, `server.address`
- Database: `db.system`, `db.name`, `db.operation`, `db.statement`
- Messaging: `messaging.system`, `messaging.destination.name`, `messaging.operation`
- Kubernetes: `k8s.namespace.name`, `k8s.pod.name`, `k8s.deployment.name`

## OTLP Protocol
- **gRPC transport** (port 4317): Binary protobuf, preferred for high throughput
- **HTTP/protobuf transport** (port 4318): Binary protobuf over HTTP, firewall-friendly
- **HTTP/JSON transport** (port 4318): JSON encoding, debugging-friendly

## PromQL Patterns
```promql
# Request rate per second (5-minute window)
rate(http_requests_total[5m])

# Error rate percentage
sum(rate(http_requests_total{status=~"5.."}[5m]))
/ sum(rate(http_requests_total[5m])) * 100

# 99th percentile latency
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# Predict disk full in 4 hours
predict_linear(node_filesystem_avail_bytes[1h], 4*3600) < 0

# Error budget remaining (30-day SLO at 99.9%)
1 - (
  (1 - (sum(increase(http_requests_total{status!~"5.."}[30d])) / sum(increase(http_requests_total[30d]))))
  / (1 - 0.999)
)
```

## Recording and Alerting Rules
```yaml
groups:
  - name: http_recording_rules
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
      - record: job:http_latency:p99_5m
        expr: histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket[5m])))

  - name: slo_alerts
    rules:
      - alert: HighErrorRate
        expr: job:http_errors:rate5m / job:http_requests:rate5m > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          runbook_url: "https://wiki.example.com/runbooks/high-error-rate"

      - alert: ErrorBudgetBurnRate
        expr: |
          (sum(rate(http_requests_total{status=~"5.."}[1h]))
          / sum(rate(http_requests_total[1h]))) > 14.4 * 0.001
        for: 5m
        labels:
          severity: critical
```

## Long-Term Prometheus Storage
- **Thanos**: Sidecar + Store + Compactor. S3/GCS/Azure Blob. Global query view. Downsampling.
- **Grafana Mimir**: Horizontally scalable, multi-tenant, 100% Prometheus-compatible, query sharding.
- **VictoriaMetrics**: MetricsQL (PromQL superset), high compression (70x), single-node or cluster.
