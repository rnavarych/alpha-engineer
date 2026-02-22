---
name: monitoring-observability
description: |
  Monitoring and observability: structured logging (pino), Prometheus RED metrics,
  OpenTelemetry distributed tracing, SLO definitions (99.9% = 43 min/month downtime),
  alert rules with burn rate, Grafana dashboards, health check endpoints.
  Use when setting up observability, defining SLOs, building dashboards, configuring alerts.
allowed-tools: Read, Grep, Glob
---

# Monitoring & Observability

## When to Use This Skill
- Setting up structured logging for a new service
- Defining SLOs and error budgets
- Configuring Prometheus metrics and alerts
- Adding OpenTelemetry distributed tracing
- Building Grafana dashboards for service health

## Core Principles

1. **Three pillars: Logs, Metrics, Traces** — use all three; they answer different questions
2. **Structured logging always** — JSON logs are searchable; free-text logs are grep archaeology
3. **RED method for services**: Rate, Errors, Duration — three metrics per service
4. **SLO over alerts** — alert on burn rate, not raw error rate
5. **Correlation ID through every hop** — logs without correlation IDs are disconnected puzzle pieces

---

## Patterns ✅

### Structured Logging with Pino

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),  // Use string level, not integer
  },
  redact: {
    paths: ['req.headers.authorization', 'body.password', 'body.cvv'],
    censor: '[REDACTED]',
  },
  // In development: pretty-print
  ...(process.env.NODE_ENV === 'development' && {
    transport: { target: 'pino-pretty' },
  }),
});

// Request context with AsyncLocalStorage
import { AsyncLocalStorage } from 'async_hooks';
const requestContext = new AsyncLocalStorage<{ requestId: string; tenantId?: string }>();

export function contextLogger() {
  const context = requestContext.getStore();
  return context ? logger.child(context) : logger;
}

// Express middleware: correlation ID
app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] as string || crypto.randomUUID();
  res.set('X-Request-Id', requestId);

  requestContext.run({ requestId, tenantId: req.user?.tenantId }, () => {
    const reqLogger = logger.child({
      requestId,
      method: req.method,
      url: req.url,
      userAgent: req.headers['user-agent'],
    });

    req.log = reqLogger;
    reqLogger.info('Request started');

    const start = Date.now();
    res.on('finish', () => {
      reqLogger.info({
        statusCode: res.statusCode,
        duration: Date.now() - start,
      }, 'Request completed');
    });

    next();
  });
});

// Good log entries
logger.info({ orderId, amount, currency }, 'Order placed');
logger.error({ err, orderId }, 'Failed to process payment');
// Bad log entries
logger.info(`Order ${orderId} placed with amount ${amount}`);  // Not searchable
logger.info('error occurred');  // No context
```

### Prometheus Metrics (RED Method)

```typescript
import { Counter, Histogram, Gauge, register } from 'prom-client';

// R — Rate: requests per second
const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

// E — Errors: error rate
// (derived from http_requests_total where status_code >= 400)

// D — Duration: response time histogram
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  // Buckets cover: 5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s
});

// Business metrics
const ordersCreated = new Counter({
  name: 'orders_created_total',
  help: 'Total orders created',
  labelNames: ['payment_method', 'plan'],
});

const activeUsers = new Gauge({
  name: 'active_users_current',
  help: 'Current number of active sessions',
});

// Express middleware
app.use((req, res, next) => {
  const route = req.route?.path || req.path;
  const end = httpRequestDuration.startTimer({ method: req.method, route });

  res.on('finish', () => {
    end();
    httpRequestsTotal.inc({ method: req.method, route, status_code: res.statusCode });
  });
  next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

### SLO Definitions and Error Budgets

```
SLO Availability Targets:
  99.9%   = 43 minutes downtime/month   (common for internal tools)
  99.95%  = 22 minutes downtime/month   (consumer APIs)
  99.99%  = 4.4 minutes downtime/month  (payments, auth)
  99.999% = 26 seconds downtime/month   (phone networks — probably overkill)

Error Budget = 1 - SLO
  99.9% SLO → 0.1% error budget → 43 min/month of allowed downtime
  If error budget is exhausted → freeze features, focus on reliability
```

```yaml
# Prometheus alerting rules — burn rate alerts
groups:
  - name: slo-alerts
    rules:
      # Fast burn: consuming 2% of monthly budget in 1 hour (14.4× rate)
      - alert: ErrorBudgetFastBurn
        expr: |
          (
            rate(http_requests_total{status_code=~"5.."}[1h]) /
            rate(http_requests_total[1h])
          ) > (14.4 * 0.001)  # 0.1% SLO → 14.4× burn rate
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Fast error budget burn — page immediately"
          description: "Error rate {{ $value | humanizePercentage }}"

      # Slow burn: consuming 5% of monthly budget in 6 hours
      - alert: ErrorBudgetSlowBurn
        expr: |
          (
            rate(http_requests_total{status_code=~"5.."}[6h]) /
            rate(http_requests_total[6h])
          ) > (6 * 0.001)
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Slow error budget burn — investigate during business hours"
```

### OpenTelemetry Distributed Tracing

```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const sdk = new NodeSDK({
  serviceName: 'order-service',
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': { enabled: true },
      '@opentelemetry/instrumentation-express': { enabled: true },
      '@opentelemetry/instrumentation-pg': { enabled: true },
      '@opentelemetry/instrumentation-redis': { enabled: true },
    }),
  ],
});

sdk.start();  // Start before anything else

// Manual span for business operations
import { trace, context } from '@opentelemetry/api';
const tracer = trace.getTracer('order-service');

async function processOrder(orderId: string) {
  return tracer.startActiveSpan('processOrder', async (span) => {
    span.setAttributes({
      'order.id': orderId,
      'order.type': 'standard',
    });
    try {
      const result = await doProcessing(orderId);
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (err) {
      span.recordException(err as Error);
      span.setStatus({ code: SpanStatusCode.ERROR, message: String(err) });
      throw err;
    } finally {
      span.end();
    }
  });
}
```

### Health Check Endpoint

```typescript
// Standard health check — orchestrators use this to decide traffic routing
app.get('/health', async (req, res) => {
  const checks = await Promise.allSettled([
    db.execute(sql`SELECT 1`),          // Database connectivity
    redis.ping(),                        // Cache connectivity
  ]);

  const dbHealthy = checks[0].status === 'fulfilled';
  const redisHealthy = checks[1].status === 'fulfilled';
  const healthy = dbHealthy && redisHealthy;

  res.status(healthy ? 200 : 503).json({
    status: healthy ? 'healthy' : 'unhealthy',
    checks: {
      database: dbHealthy ? 'ok' : 'error',
      redis: redisHealthy ? 'ok' : 'error',
    },
    version: process.env.APP_VERSION,
    uptime: process.uptime(),
  });
});

// Liveness: is the process alive? (Kubernetes kills if fails)
app.get('/health/live', (req, res) => res.json({ status: 'alive' }));

// Readiness: can the process handle traffic? (Kubernetes stops routing if fails)
app.get('/health/ready', async (req, res) => {
  // Check all dependencies
  const ready = await checkReadiness();
  res.status(ready ? 200 : 503).json({ status: ready ? 'ready' : 'not-ready' });
});
```

---

## Anti-Patterns ❌

### Free-Text Logs
**What it is**: `logger.info("User john@example.com placed order 123 for $45.00")`
**What breaks**: Can't search by `userId` field. Can't aggregate. Contains PII in plain text. Regex parsing is fragile. Expensive in log management tools.
**Fix**: `logger.info({ userId, orderId, amount }, 'Order placed')`

### Alerting on Raw Error Rate Without SLO
**What it is**: Alert: `error_rate > 1%`
**What breaks**: Brief spike at 2AM with zero traffic = 100% error rate = page. No context for whether this matters. Alert fatigue. Engineers stop trusting alerts.
**Fix**: Burn rate alerts based on SLO. Brief spikes don't consume meaningful error budget.

### No Correlation IDs
**What it is**: Each service logs independently with no shared identifier.
**What breaks**: Request fails across 4 services. You have logs for each but can't connect them. Debugging requires timestamp-guessing across services.
**Fix**: Generate `requestId` at API gateway/entry point. Propagate via HTTP header `X-Request-Id`. Log in every service.

---

## Quick Reference

```
SLO 99.9% = 43 min/month downtime
SLO 99.99% = 4.4 min/month downtime
Error budget = 1 - SLO (freeze features when exhausted)
Fast burn alert: 14.4× burn rate over 1h = page
Slow burn alert: 6× burn rate over 6h = warning
Prometheus histograms: start at 5ms, cover up to 10s
Health check: /health (full), /health/live, /health/ready
Correlation ID: generate at entry, propagate via X-Request-Id header
```
