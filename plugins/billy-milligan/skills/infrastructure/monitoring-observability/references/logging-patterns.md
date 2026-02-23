# Logging Patterns

## Structured Logging with Pino

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  redact: {
    paths: ['req.headers.authorization', 'body.password', 'body.ssn'],
    censor: '[REDACTED]',
  },
  ...(process.env.NODE_ENV === 'development' && {
    transport: { target: 'pino-pretty' },
  }),
});

// Good: structured, searchable, no PII
logger.info({ orderId, amount, currency }, 'Order placed');
logger.error({ err, orderId }, 'Payment processing failed');

// Bad: unstructured, PII in message
logger.info(`User john@example.com placed order ${orderId}`);
logger.info('error occurred');  // No context
```

## Winston Alternative

```typescript
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'order-service' },
  transports: [
    new winston.transports.Console(),
  ],
});
```

## Log Levels

```
fatal  — Process cannot continue. Immediate attention required.
error  — Operation failed. Request-level failure.
warn   — Recoverable issue. Degraded but functional.
info   — State changes. Business events. Request lifecycle.
debug  — Detailed diagnostic. Development only.
trace  — Extremely verbose. Never in production.

Production level: info (default), debug (during incidents only)
Development level: debug
```

## Correlation IDs

```typescript
import { AsyncLocalStorage } from 'async_hooks';

const requestContext = new AsyncLocalStorage<{ requestId: string }>();

// Middleware: extract or generate correlation ID
app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] as string
    || crypto.randomUUID();
  res.set('X-Request-Id', requestId);

  requestContext.run({ requestId }, () => {
    req.log = logger.child({ requestId });
    next();
  });
});

// Outbound HTTP: propagate correlation ID
const response = await fetch(url, {
  headers: { 'X-Request-Id': requestContext.getStore()?.requestId },
});
```

## Log Aggregation

| Stack | Components | Best for |
|---|---|---|
| ELK | Elasticsearch + Logstash + Kibana | Full-text search, complex queries |
| Loki + Grafana | Loki (label-indexed) + Grafana | Cost-effective, k8s native |
| Datadog | SaaS, agent-based | Low-ops, unified APM |
| CloudWatch | AWS native | AWS-only, simple setup |

Loki vs Elasticsearch:
- Loki: indexes labels only, not log content. 10x cheaper storage.
- Elasticsearch: full-text indexing. Better for ad-hoc queries. Higher storage cost.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| PII in log messages | Use `redact` option; log IDs not values |
| Free-text interpolation | Use structured fields: `logger.info({ field }, 'msg')` |
| Logging at wrong level | error = failure; warn = recoverable; info = state change |
| No correlation ID | Generate at entry, propagate via `X-Request-Id` |
| `console.log` in production | Use structured logger (Pino/Winston) |
| Logging sensitive headers | Redact `authorization`, `cookie`, `x-api-key` |

## Quick Reference

- Format: **JSON** in production, pretty-print in development
- Pino throughput: **~30K logs/sec** (5x faster than Winston)
- Correlation: `X-Request-Id` header, propagated through all services
- Redaction: authorization headers, passwords, PII fields
- Retention: 30 days hot, 90 days warm, 1 year cold (adjust per compliance)
- Cost tip: Loki is **10x cheaper** than Elasticsearch for high-volume logs
