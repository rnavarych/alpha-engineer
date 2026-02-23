# Prometheus and VictoriaMetrics

## When to load
Load when working with Prometheus (PromQL, recording rules, alerting, federation, remote storage) or VictoriaMetrics (MetricsQL extensions, single-node vs cluster deployment, vmagent).

## PromQL Fundamentals

```promql
# CPU usage per instance
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 5xx error rate
rate(http_requests_total{job="api-server", status=~"5.."}[5m])

# p99 request duration (histogram)
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job="api"}[5m])) by (le))

# Predict disk full in 4 hours
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 4 * 3600) < 0

# Top 5 endpoints by request rate
topk(5, sum by (endpoint) (rate(http_requests_total[5m])))

# Subquery: max over time of a rate
max_over_time(rate(http_requests_total[5m])[1h:1m])
```

## Recording and Alerting Rules

```yaml
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
      - alert: TargetDown
        expr: up == 0
        for: 3m
        labels:
          severity: warning
```

## Federation and Remote Storage

```yaml
scrape_configs:
  - job_name: 'federate'
    honor_labels: true
    metrics_path: '/federate'
    params: { 'match[]': ['{job=~".+"}'] }
    static_configs: [{ targets: ['prometheus-dc1:9090', 'prometheus-dc2:9090'] }]

remote_write:
  - url: "http://mimir:9009/api/v1/push"
    queue_config: { max_samples_per_send: 5000, batch_send_deadline: 5s, max_shards: 30 }
```

## Long-Term Storage: Thanos / Cortex / Mimir

- **Thanos**: sidecar + compactor, built-in 5m/1h downsampling, querier federation
- **Cortex/Mimir**: microservices, multi-tenant, S3/GCS/Azure object storage

```bash
thanos sidecar --tsdb.path=/prometheus/data --objstore.config-file=bucket.yml --prometheus.url=http://localhost:9090
```

## VictoriaMetrics — MetricsQL Extensions

```promql
# WITH templates: reusable subqueries
WITH (
  request_rate = sum(rate(http_requests_total[5m])) by (service),
  error_rate = sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
)
error_rate / request_rate

# Range functions beyond standard PromQL
range_median(http_request_duration_seconds[1h])
range_quantile(0.99, http_request_duration_seconds[1h])
median_over_time(process_resident_memory_bytes[1h])
rollup_rate(http_requests_total[5m])
```

## VictoriaMetrics Deployment

```bash
# Single-node
victoria-metrics -storageDataPath=/var/lib/victoria-metrics -retentionPeriod=12 -httpListenAddr=:8428

# Cluster components (stateless vminsert/vmselect, stateful vmstorage)
vminsert -storageNode=vmstorage-1:8400,vmstorage-2:8400
vmstorage -storageDataPath=/data -retentionPeriod=12
vmselect -storageNode=vmstorage-1:8401,vmstorage-2:8401
vmagent -promscrape.config=prometheus.yml -remoteWrite.url=http://vminsert:8480/insert/0/prometheus/
```

## HA Patterns

- Prometheus: 2+ replicas + Thanos/Mimir for deduplication and long-term storage
- VictoriaMetrics: replicated vmstorage nodes in cluster mode
- Always monitor your monitoring stack with an independent system
