# Metrics Patterns

## RED Method (Request-oriented)

For every service, track three signals:

```
Rate     — requests per second
Errors   — failed requests per second
Duration — distribution of request latency
```

```typescript
import { Counter, Histogram, register } from 'prom-client';

// Rate + Errors (single counter with status label)
const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

// Duration
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
});

// Express middleware
app.use((req, res, next) => {
  const route = req.route?.path || req.path;
  const end = httpRequestDuration.startTimer({ method: req.method, route });
  res.on('finish', () => {
    end();
    httpRequestsTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode,
    });
  });
  next();
});
```

## USE Method (Resource-oriented)

For every resource (CPU, memory, disk, network):

```
Utilization — % of resource in use
Saturation  — queued work (waiting)
Errors      — error count
```

```typescript
import { Gauge } from 'prom-client';

// Node.js process metrics (auto-collected by prom-client)
import { collectDefaultMetrics } from 'prom-client';
collectDefaultMetrics({ prefix: 'app_' });

// Custom: connection pool utilization
const dbPoolUtilization = new Gauge({
  name: 'db_pool_utilization_ratio',
  help: 'Database connection pool utilization',
});

// Custom: queue saturation
const jobQueueSize = new Gauge({
  name: 'job_queue_size',
  help: 'Number of jobs waiting in queue',
  labelNames: ['queue_name'],
});
```

## Prometheus Metric Types

| Type | Use case | Example |
|---|---|---|
| Counter | Monotonically increasing | `http_requests_total`, `errors_total` |
| Gauge | Can go up or down | `active_connections`, `temperature` |
| Histogram | Distribution with buckets | `request_duration_seconds` |
| Summary | Distribution with quantiles | `request_duration_quantile` (client-side) |

Prefer histograms over summaries: histograms are aggregatable across instances, summaries are not.

## Histogram Bucket Design

```
API latency: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
  Covers 5ms to 10s — suitable for most web APIs

Batch jobs:  [1, 5, 10, 30, 60, 120, 300, 600]
  Covers 1s to 10min — suitable for background processing

Database:    [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.5, 1]
  Covers 1ms to 1s — suitable for query latency
```

## Grafana Dashboard Essentials

```
Dashboard layout for a service:
  Row 1: Request Rate | Error Rate | P50/P95/P99 Latency
  Row 2: CPU Usage | Memory Usage | Pod Count
  Row 3: DB Query Latency | Cache Hit Rate | Queue Depth

PromQL examples:
  Request rate:     rate(http_requests_total[5m])
  Error rate:       rate(http_requests_total{status_code=~"5.."}[5m])
  P99 latency:      histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
  Error percentage: rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m])
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| High-cardinality labels (user_id) | Use bounded labels (method, route, status) |
| No `_total` suffix on counters | Follow naming conventions |
| Summary instead of histogram | Histograms aggregate across instances |
| Missing `_seconds` suffix for duration | Use base units (seconds, bytes) |
| Alerting on raw metrics | Use rate() over counters, never raw values |

## Quick Reference

- RED: Rate, Errors, Duration (per service)
- USE: Utilization, Saturation, Errors (per resource)
- Histogram buckets: design for expected latency range
- Label cardinality: keep under **10 values** per label
- Scrape interval: **15s** default, **5s** for critical paths
- Retention: **15 days** local, long-term in Thanos/Cortex
