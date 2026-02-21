# Observability Stack Reference

## OpenTelemetry (OTel)
- Vendor-neutral instrumentation standard
- SDKs for all major languages
- Auto-instrumentation for popular frameworks
- OTLP protocol for data export
- Collector for routing/processing telemetry data
- Supports logs, metrics, and traces in unified API

## Prometheus + Grafana
- **Prometheus**: Pull-based metrics, PromQL, Alertmanager
- **Grafana**: Visualization, dashboards, multi-source
- **Thanos/Cortex**: Long-term storage, multi-cluster federation
- Best for: Kubernetes environments, infrastructure monitoring

## ELK Stack (Elastic)
- **Elasticsearch**: Search and analytics engine
- **Logstash**: Log processing pipeline
- **Kibana**: Visualization and exploration
- **Beats**: Lightweight data shippers (Filebeat, Metricbeat)
- Best for: Log aggregation, full-text search on logs

## Datadog
- Unified platform: metrics, traces, logs, RUM, synthetics
- APM with automatic service maps
- Infrastructure monitoring with integrations
- Best for: Teams wanting managed, all-in-one solution

## Jaeger / Zipkin
- **Jaeger**: Distributed tracing, CNCF project, Kubernetes-native
- **Zipkin**: Simpler, lightweight, Twitter-originated
- Both support OpenTelemetry as data source

## Alerting Tools
- **PagerDuty**: Incident management, on-call scheduling
- **OpsGenie**: Alert routing, escalation, runbooks
- **Alertmanager**: Prometheus-native alerting
- **Grafana Alerting**: Multi-source alert rules

## Logging Best Practices
```json
{
  "timestamp": "2026-02-21T10:30:00.123Z",
  "level": "ERROR",
  "service": "payment-service",
  "trace_id": "abc123def456",
  "span_id": "789ghi",
  "message": "Payment processing failed",
  "error": "Connection timeout to Stripe API",
  "user_id": "usr_xxx",
  "payment_id": "pay_yyy",
  "duration_ms": 30000
}
```
