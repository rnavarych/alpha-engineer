# Grafana Ecosystem, ELK/OpenSearch, and Commercial APM

## When to load
Load when setting up Grafana Loki/Tempo/Mimir, ELK/OpenSearch stack, comparing commercial APM tools (Datadog, New Relic, Dynatrace), or integrating incident management (PagerDuty, OpsGenie, Incident.io).

## Grafana Loki (Logs)
- Index-free: only indexes labels, stores compressed log chunks in object storage
- LogQL query language (label filtering + line filtering + parser + aggregation)
- Agents: Promtail, Grafana Alloy, Fluent Bit, OTel Collector

```logql
{service="api-gateway"} |= "error" | json | status >= 500
{namespace="production"} | logfmt | duration > 1s | line_format "{{.method}} {{.path}} took {{.duration}}"
sum(rate({service="payment"} |= "timeout" [5m])) by (endpoint)
```

## Grafana Tempo (Traces)
- Distributed tracing backend using object storage only (cost-effective, no indexing)
- Accepts Jaeger, Zipkin, OTLP; TraceQL query language; service graph generation

## Grafana OnCall and k6
- **OnCall**: On-call management; integrations with Slack, Teams, phone; escalation chains
- **k6**: JavaScript-based load testing; protocols: HTTP, WebSocket, gRPC, browser

## ELK / OpenSearch Stack

### Elasticsearch
- Inverted index for full-text search; BKD trees for numeric/geo
- Index lifecycle management (ILM): hot → warm → cold → frozen → delete
- ES|QL: piped query language (8.11+); Cross-cluster search and replication

### Logstash
- Input plugins: beats, syslog, kafka, s3, jdbc
- Filter plugins: grok, mutate, date, geoip, dissect
- Output plugins: elasticsearch, s3, kafka, datadog

### OpenSearch (AWS fork)
- Fork of Elasticsearch 7.10 (Apache 2.0 license)
- Additional features: anomaly detection, alerting, SQL, PPL (Piped Processing Language)
- Serverless mode available on AWS

## Commercial APM Comparison

| Feature | Datadog | New Relic | Dynatrace |
|---------|---------|-----------|-----------|
| **Pricing** | Per host + ingestion | Per-user + ingestion | Per-host (full-stack) |
| **APM** | Distributed tracing, service maps | Distributed tracing, errors inbox | PurePath tracing, Smartscape |
| **AI/ML** | Watchdog anomaly detection | Applied Intelligence | Davis AI (causal analysis, auto-remediation) |
| **OpenTelemetry** | Full OTLP ingest | Full OTLP ingest | Full OTLP + OneAgent |
| **Best for** | DevOps teams, broad observability | Full-stack, cost-conscious | Enterprise, auto-discovery |

## Incident Management Integrations

### PagerDuty
```yaml
receivers:
  - name: pagerduty-oncall
    pagerduty_configs:
      - routing_key: "<integration-key>"
        severity: "{{ .CommonLabels.severity }}"
        description: "{{ .CommonAnnotations.summary }}"
        details:
          runbook: "{{ .CommonAnnotations.runbook_url }}"
```

### OpsGenie
```yaml
receivers:
  - name: opsgenie-team
    opsgenie_configs:
      - api_key: "<api-key>"
        priority: '{{ if eq .CommonLabels.severity "critical" }}P1{{ else }}P2{{ end }}'
        tags: "{{ .CommonLabels.service }},{{ .CommonLabels.environment }}"
```

### Incident.io
- Slack-native incident declaration (`/incident`); auto-creates incident channel
- Status page integration; post-incident workflow with action items and timeline

## Structured Log Format Examples

### Node.js (pino)
```javascript
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  redact: ['req.headers.authorization', 'body.password'],
  timestamp: pino.stdTimeFunctions.isoTime,
});
```

### Python (structlog)
```python
structlog.configure(processors=[
  structlog.contextvars.merge_contextvars,
  structlog.processors.add_log_level,
  structlog.processors.TimeStamper(fmt="iso"),
  structlog.processors.JSONRenderer(),
])
```

### Go (zerolog)
```go
log.Info().Str("service", "api").Str("trace_id", traceID).Int("duration_ms", 42).Msg("Request processed")
```
