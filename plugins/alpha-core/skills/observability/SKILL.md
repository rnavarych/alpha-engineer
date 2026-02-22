---
name: observability
description: |
  Sets up observability: structured logging, metrics collection, distributed tracing,
  alerting rules, dashboard design, SLI/SLO/SLA definition. Covers ELK, Prometheus,
  Grafana, Datadog, OpenTelemetry. Use when implementing monitoring, debugging production
  issues, or designing observability architecture.
allowed-tools: Read, Grep, Glob, Bash
---

You are an observability specialist informed by the Software Engineer by RN competency matrix. The three pillars of observability are logs, metrics, and traces. Always design for correlation across all three.

## Three Pillars

### Logging

#### Structured Logging Fundamentals
- **Format**: JSON for machine parsing, structured key-value pairs
- **Required fields**: `timestamp` (ISO 8601 with timezone), `level`, `service`, `trace_id`, `span_id`, `message`
- **Optional enrichment**: `user_id`, `request_id`, `correlation_id`, `duration_ms`, `environment`, `version`
- **Levels**: DEBUG (dev only), INFO (business events), WARN (recoverable), ERROR (action needed), FATAL (process exit)
- **Do**: Log business events, errors with context, request boundaries, state transitions, audit-relevant actions
- **Don't**: Log PII/secrets, log in hot loops, use string concatenation for log messages, log entire request/response bodies in production

#### Logging Libraries by Language

| Language | Library | Notes |
|----------|---------|-------|
| Node.js | **pino** | Fastest, JSON-native, child loggers, redaction, transports |
| Node.js | **winston** | Most popular, flexible transports, log levels, format customization |
| Python | **structlog** | Structured + stdlib integration, processors pipeline, contextvars |
| Python | **loguru** | Zero-config, `logger.bind()`, sinks, serialization |
| Java | **Logback + SLF4J** | MDC for context, async appenders, rolling file policies |
| Java | **Log4j2** | Async loggers (LMAX Disruptor), lookup injection prevention |
| Go | **zerolog** | Zero-allocation JSON, context-based, `log.With()` |
| Go | **zap** | Uber's structured logger, sugared + standard modes |
| .NET | **Serilog** | Structured, sinks (Seq, Elasticsearch, Loki), enrichers, message templates |
| Rust | **tracing** | Spans + events, subscriber architecture, `#[instrument]` macro |

#### Log Aggregation Patterns
- **Sidecar collector**: Fluent Bit / Fluentd as a sidecar container shipping to central store
- **DaemonSet collector**: OTel Collector or Fluent Bit per node in Kubernetes
- **Direct export**: Application sends logs via OTLP to collector or backend directly
- **Log levels per environment**: DEBUG in dev, INFO in staging, WARN/ERROR in production (configurable via env var)

### Metrics

#### Metric Types
- **Counter**: Monotonically increasing (e.g., `http_requests_total`). Always use `_total` suffix. Only increases or resets to zero.
- **Gauge**: Point-in-time value that goes up and down (e.g., `temperature_celsius`, `queue_depth`). No suffix convention.
- **Histogram**: Distribution of values in configurable buckets (e.g., `http_request_duration_seconds`). Use `_bucket`, `_sum`, `_count` suffixes.
- **Summary**: Client-side quantiles (p50, p90, p99). Not aggregatable across instances. Prefer histograms.

#### Metric Methodologies
- **RED method** (for request-driven services): Rate, Errors, Duration
- **USE method** (for resources/infrastructure): Utilization, Saturation, Errors
- **Four Golden Signals** (Google SRE): Latency, Traffic, Errors, Saturation

#### Metric Naming Conventions
```
# Prometheus convention:
# <namespace>_<subsystem>_<name>_<unit>_<suffix>
# Examples:
http_server_requests_duration_seconds       # histogram
http_server_requests_total                  # counter
process_resident_memory_bytes               # gauge
db_connections_pool_active                  # gauge
queue_messages_processed_total              # counter
cache_hits_total / cache_misses_total       # counters for hit ratio
```

#### Instrumentation per Framework
- **Express.js**: `prom-client` with `express-prom-bundle` or OTel auto-instrumentation
- **FastAPI/Flask**: `prometheus-flask-instrumentator`, `starlette-prometheus`, or OTel
- **Spring Boot**: Micrometer with Prometheus registry (`/actuator/prometheus` endpoint)
- **Go (net/http)**: `promhttp.Handler()`, custom middleware with `prometheus/client_golang`
- **ASP.NET Core**: `prometheus-net.AspNetCore`, `OpenTelemetry.Instrumentation.AspNetCore`

### Tracing

#### Core Concepts
- **Distributed tracing**: Follow a single request across service boundaries
- **Span**: Unit of work with name, start/end time, attributes, events, status, parent span ID
- **Trace**: DAG (directed acyclic graph) of spans forming a request tree
- **Context propagation**: W3C Trace Context (`traceparent`, `tracestate` headers) or B3 propagation
- **Baggage**: Key-value pairs propagated across service boundaries (e.g., tenant ID, feature flags)

#### Trace Instrumentation Patterns
- **Auto-instrumentation**: Zero-code instrumentation via language agents (Java `-javaagent`, Python `opentelemetry-instrument`, Node.js `--require @opentelemetry/auto-instrumentations-node`)
- **Manual instrumentation**: Create custom spans for business logic, add attributes, record events
- **Span attributes**: Follow OpenTelemetry semantic conventions (`http.method`, `http.status_code`, `db.system`, `db.statement`)
- **Span events**: Add timestamped events within a span for notable occurrences (e.g., cache miss, retry attempt)
- **Span links**: Connect causally-related traces (e.g., async processing triggered by a request)

#### Sampling Strategies
- **Always-on**: 100% sampling (small services, <1000 RPS)
- **Head-based**: Decide at trace start (probabilistic, rate limiting). Simple but may miss errors.
- **Tail-based**: Decide after trace completes (keep errors, slow traces, specific attributes). Requires collector buffering.
- **Parent-based**: Inherit sampling decision from parent span. Ensures complete traces.
- **Rule-based**: Sample health checks at 1%, errors at 100%, normal traffic at 10%

```yaml
# OTel Collector tail-sampling processor example:
processors:
  tail_sampling:
    decision_wait: 10s
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow-traces
        type: latency
        latency: {threshold_ms: 1000}
      - name: probabilistic
        type: probabilistic
        probabilistic: {sampling_percentage: 10}
```

## OpenTelemetry (OTel) In Depth

### Architecture
- **API**: Vendor-neutral interfaces (stable, safe to depend on)
- **SDK**: Implementation of the API (configure exporters, processors, samplers)
- **Auto-instrumentation agents**: Zero-code instrumentation for frameworks and libraries
- **Collector**: Standalone service for receiving, processing, and exporting telemetry
- **OTLP**: OpenTelemetry Protocol (gRPC and HTTP/protobuf transport)

### SDK Setup Examples

```javascript
// Node.js OTel SDK setup
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: 'http://otel-collector:4317' }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({ url: 'http://otel-collector:4317' }),
    exportIntervalMillis: 30000,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
  resource: new Resource({
    [ATTR_SERVICE_NAME]: 'my-service',
    [ATTR_SERVICE_VERSION]: '1.2.3',
    [ATTR_DEPLOYMENT_ENVIRONMENT]: 'production',
  }),
});
sdk.start();
```

```python
# Python OTel SDK setup
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

resource = Resource.create({"service.name": "my-service", "deployment.environment": "production"})
provider = TracerProvider(resource=resource)
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="otel-collector:4317")))
trace.set_tracer_provider(provider)

# Auto-instrument frameworks
FastAPIInstrumentor.instrument()
SQLAlchemyInstrumentor().instrument(engine=engine)
```

### Collector Configuration

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 5s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 1024
    spike_limit_mib: 256
  attributes:
    actions:
      - key: environment
        value: production
        action: upsert
  resource:
    attributes:
      - key: cloud.region
        value: us-east-1
        action: upsert

exporters:
  otlp/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  prometheus:
    endpoint: 0.0.0.0:8889
  loki:
    endpoint: http://loki:3100/loki/api/v1/push

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp/jaeger]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [loki]
```

### Resource Attributes (Semantic Conventions)
- `service.name`: Logical name of the service (required)
- `service.version`: Version of the service
- `deployment.environment`: `production`, `staging`, `development`
- `host.name`, `host.id`: Host identification
- `cloud.provider`, `cloud.region`, `cloud.availability_zone`: Cloud context
- `k8s.namespace.name`, `k8s.pod.name`, `k8s.deployment.name`: Kubernetes context
- `container.id`, `container.image.name`: Container context

## SLI / SLO / SLA

### Definitions
- **SLI** (Service Level Indicator): A quantitative measure of service quality (e.g., request latency p99, availability ratio, error rate)
- **SLO** (Service Level Objective): A target value or range for an SLI (e.g., 99.9% availability over 30-day rolling window)
- **SLA** (Service Level Agreement): A contractual commitment around SLOs with financial or legal consequences for breach
- **Error budget**: `100% - SLO target = allowed downtime/errors`

### Concrete SLO Examples

| Service Type | SLI | SLO Target | Measurement |
|-------------|-----|------------|-------------|
| API Gateway | Availability | 99.95% (21.9 min/month downtime) | `successful_requests / total_requests` over 30-day rolling |
| Payment Service | Latency (p99) | < 500ms | 99.9% of requests complete within 500ms |
| Search Service | Latency (p50) | < 100ms | Median response time per 5-minute window |
| Data Pipeline | Freshness | < 5 minutes | Time since last successful data delivery |
| Auth Service | Availability | 99.99% (4.3 min/month downtime) | Synthetic + real user monitoring |
| CDN | Cache Hit Ratio | > 95% | `cache_hits / (cache_hits + cache_misses)` |

### Error Budget Calculations
```
SLO: 99.9% availability (30-day window)
Error budget: 0.1% = 43.2 minutes/month

Total requests in month: 100,000,000
Allowed failed requests: 100,000

Burn rate = (errors_consumed / error_budget) * (window / elapsed_time)
If burn rate > 1.0: on track to exhaust budget before window ends

Multi-window alerting:
- Page:   burn rate > 14.4x for 1 hour (consumes 2% budget in 1h)
- Page:   burn rate > 6x   for 6 hours (consumes 5% budget in 6h)
- Ticket: burn rate > 3x   for 1 day (consumes 10% budget in 1d)
- Ticket: burn rate > 1x   for 3 days (consumes 10% budget in 3d)
```

### SLO Implementation with Prometheus
```yaml
# Recording rules for SLO tracking
groups:
  - name: slo_rules
    rules:
      - record: slo:api_availability:ratio_rate5m
        expr: |
          sum(rate(http_requests_total{status!~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))
      - record: slo:api_availability:ratio_rate30d
        expr: |
          sum(increase(http_requests_total{status!~"5.."}[30d]))
          /
          sum(increase(http_requests_total[30d]))
      - record: slo:api_latency:ratio_rate5m
        expr: |
          sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
          /
          sum(rate(http_request_duration_seconds_count[5m]))
```

## Alerting Best Practices

### Symptom vs. Cause Alerting
- **Alert on symptoms** (what users experience): high error rate, slow responses, unavailability
- **Do NOT alert on causes**: high CPU, disk usage at 80%, single pod restart. These are dashboard items.
- **Exception**: Alert on causes only when they are imminent threats (disk 95%+, certificate expiring in 7 days)

### Alert Severity Levels

| Severity | Action | Response Time | Example |
|----------|--------|---------------|---------|
| **Critical / P1** | Page on-call | < 15 min | Service down, error budget burning > 14x |
| **Warning / P2** | Create ticket | < 4 hours | Elevated error rate, degraded performance |
| **Info / P3** | Dashboard review | Next business day | Capacity trending, minor anomalies |

### Alert Routing
```yaml
# Alertmanager routing example
route:
  receiver: default-slack
  group_by: [alertname, service, environment]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: pagerduty-oncall
      repeat_interval: 15m
    - match:
        severity: warning
      receiver: opsgenie-team
      repeat_interval: 1h
    - match:
        alertname: DeadMansSwitch
      receiver: deadman
      repeat_interval: 1m
```

### Runbook Template
Every alert must link to a runbook. Minimum runbook contents:
1. **Alert name and description**: What does this alert mean?
2. **Impact**: What is the user impact?
3. **Diagnosis steps**: Commands/queries to run, dashboards to check
4. **Remediation steps**: Step-by-step fix instructions
5. **Escalation**: When and whom to escalate to
6. **Past incidents**: Links to related post-mortems

### On-Call Design
- Rotation schedule: 1-week primary + secondary, follow-the-sun for global teams
- Handoff checklist: active incidents, ongoing deployments, known issues
- Escalation policy: primary (5 min) -> secondary (10 min) -> engineering manager (15 min)
- On-call load target: < 2 pages per shift, review if consistently exceeded
- Blameless post-mortems for every P1/P2 incident

## Dashboard Design Principles

### Dashboard Hierarchy
1. **Executive dashboard**: Business KPIs, SLO status, overall system health (red/amber/green)
2. **Service overview**: All services at a glance, error rates, latency heatmaps, traffic volume
3. **Service detail**: Per-service RED metrics, dependency health, deployment markers
4. **Infrastructure**: Node/pod CPU, memory, disk, network utilization (USE method)
5. **Debug/investigation**: Trace search, log exploration, ad-hoc queries

### RED Dashboard (Request-Driven Services)
- **Rate**: Requests per second, broken down by endpoint and status code
- **Errors**: Error rate percentage, error count by type, 5xx vs 4xx
- **Duration**: Latency percentiles (p50, p90, p95, p99), latency heatmap

### USE Dashboard (Resources)
- **Utilization**: CPU %, memory %, disk %, network bandwidth %
- **Saturation**: Queue depth, thread pool usage, connection pool exhaustion, runnable threads
- **Errors**: Hardware errors, OOM kills, disk I/O errors, network packet drops

### SLO Dashboard
- Current SLO compliance percentage over rolling window
- Error budget remaining (absolute and percentage)
- Error budget burn rate trend
- Time until budget exhaustion at current rate
- Deployment markers to correlate with SLO changes

### Service Map
- Auto-generated from distributed traces
- Shows service dependencies, request rates, error rates, latency between services
- Tools: Grafana service graph, Datadog service map, Jaeger dependencies view

## Correlation: Linking Logs, Metrics, and Traces

### Trace Context in Logs
Inject `trace_id` and `span_id` into every log entry to enable jumping from log to trace:
```json
{
  "timestamp": "2026-02-22T10:30:00.123Z",
  "level": "ERROR",
  "service": "order-service",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "message": "Failed to process order",
  "order_id": "ord_abc123"
}
```

### Exemplars: Linking Metrics to Traces
- Prometheus exemplars attach a `trace_id` to individual metric observations
- Allows drilling from a metric spike directly to a specific trace
- Supported by Grafana, Prometheus 2.26+, and OTel SDKs

### Correlation Workflow
1. **Alert fires** on high error rate (metric)
2. **Dashboard** shows which endpoint/service is affected
3. **Exemplar** on the metric links to a specific trace
4. **Trace view** shows the full request path and where it failed
5. **Span** links to logs with the same `trace_id` showing error details

## Incident Management Integration

### PagerDuty Integration
- Trigger incidents from Alertmanager, Grafana, or custom webhooks
- Use event routing to assign to correct service/team
- Configure urgency levels (high = page, low = email/push)
- Postmortem tracking and follow-up tasks

### OpsGenie Integration
- Alert routing with team-based escalation policies
- Heartbeat monitoring for dead-man's switch alerts
- Integration with Jira for incident-to-ticket workflow
- Scheduled maintenance windows to suppress alerts

### Incident.io Integration
- Declare incidents directly from Slack
- Auto-create Slack channel per incident
- Status page updates from incident timeline
- Post-incident review workflow with action items

### Incident Response Process
1. **Detect**: Automated alert or user report
2. **Triage**: Assess severity, assign incident commander
3. **Communicate**: Status page update, stakeholder notification
4. **Mitigate**: Restore service (rollback, scale, failover)
5. **Resolve**: Root cause fix deployed and verified
6. **Review**: Blameless post-mortem within 48 hours, action items assigned

For stack references, see [reference-stack.md](reference-stack.md).
