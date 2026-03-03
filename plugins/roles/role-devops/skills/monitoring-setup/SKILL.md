---
name: role-devops:monitoring-setup
description: |
  Monitoring and observability expertise covering Prometheus/Grafana stack,
  Datadog, CloudWatch, PagerDuty integration, custom metrics, dashboard design
  using USE/RED methods, alert routing, uptime monitoring, and log aggregation.
allowed-tools: Read, Grep, Glob, Bash
---

# Monitoring Setup

## Prometheus and Grafana Stack

- Deploy Prometheus with the **kube-prometheus-stack** Helm chart for Kubernetes environments. It bundles Prometheus, Grafana, Alertmanager, and node-exporter.
- Configure `ServiceMonitor` and `PodMonitor` CRDs for automatic scrape target discovery. Avoid manual scrape config editing.
- Use **recording rules** to pre-compute expensive queries (rate calculations, aggregations) and keep dashboard load times fast.
- Set appropriate scrape intervals: 15s for application metrics, 30-60s for infrastructure metrics. Shorter intervals increase storage and CPU cost.
- Retain metrics for 15-30 days locally. Use Thanos or Cortex for long-term, highly available metric storage.

## Datadog

- Use the Datadog Agent as a DaemonSet in Kubernetes. Enable APM, log collection, and infrastructure monitoring in a single agent.
- Define monitors as code with Terraform (`datadog_monitor` resource) or the Datadog API. Version control all monitor definitions.
- Use tags consistently (`env:production`, `service:api`, `team:platform`) across metrics, logs, and traces for unified correlation.
- Leverage Datadog dashboards for executive views and notebooks for investigation workflows.

## CloudWatch

- Enable **CloudWatch Container Insights** for ECS and EKS workloads. Use the CloudWatch agent for custom metrics on EC2.
- Create CloudWatch Alarms for critical thresholds. Use composite alarms to reduce noise by combining multiple conditions.
- Use Metric Math for derived metrics (error rate = errors / total requests) without custom application code.
- Stream CloudWatch Logs to a centralized platform (OpenSearch, Datadog) for richer querying and correlation.

## Dashboard Design: USE and RED Methods

- **USE Method** (for infrastructure): Utilization, Saturation, Errors for every resource (CPU, memory, disk, network).
  - CPU utilization %, memory usage vs. limit, disk I/O queue depth, network packet drops.
- **RED Method** (for services): Rate, Errors, Duration for every service endpoint.
  - Request rate (req/s), error rate (%), latency percentiles (p50, p95, p99).
- Structure dashboards top-down: executive summary at the top, drill-down sections below.
- Use consistent time ranges and variable selectors (environment, service, cluster) across all dashboards.
- Include links to runbooks and related dashboards in panel descriptions.

## Custom Metrics

- Instrument application code with Prometheus client libraries or StatsD. Expose a `/metrics` endpoint.
- Use the four golden signals: latency, traffic, errors, saturation. These cover most monitoring needs.
- Name metrics with a clear prefix and use labels for dimensions: `http_requests_total{method="GET", status="200", handler="/api/users"}`.
- Avoid high-cardinality labels (user IDs, request IDs) in metrics. Use traces for request-level data.

## Alert Routing and Escalation

- Route alerts by severity and team ownership. Critical alerts page on-call; warnings go to Slack channels.
- Configure **PagerDuty** escalation policies: primary on-call acknowledges within 5 minutes, escalates to secondary after 15, then to engineering manager.
- Group related alerts with Alertmanager's `group_by` to prevent alert storms. Use `inhibit_rules` to suppress downstream alerts when a root cause is firing.
- Define alert thresholds based on SLOs, not arbitrary numbers. Alert when the error budget burn rate is too high.
- Every alert must have a linked runbook describing symptoms, diagnostic steps, and resolution actions.

## Uptime and Synthetic Monitoring

- Configure external uptime checks (Pingdom, UptimeRobot, or cloud-native synthetics) for public-facing endpoints.
- Run synthetic transactions that mimic user flows: login, search, checkout. Alert on failures or latency degradation.
- Monitor SSL certificate expiry with at least 30 days warning. Automate renewal with cert-manager or ACME.
- Publish uptime data to a status page for customer-facing transparency.

## Log Aggregation

- Ship logs from all services to a centralized platform: ELK (Elasticsearch, Logstash, Kibana), Loki, or a managed service (Datadog Logs, CloudWatch Logs).
- Use structured logging (JSON) with consistent fields: `timestamp`, `level`, `service`, `trace_id`, `message`.
- Define log retention policies by environment: 7 days for dev, 30 days for staging, 90+ days for production.
- Correlate logs with traces using a shared `trace_id` field for seamless debugging.

## Best Practices Checklist

1. USE metrics for infrastructure, RED metrics for services
2. Alerts linked to runbooks with actionable steps
3. Dashboards follow a consistent layout and use variables
4. PagerDuty or equivalent for on-call escalation
5. Structured JSON logging across all services
6. Log and metric retention policies documented
7. Synthetic monitors for critical user flows
8. Alert thresholds derived from SLOs
