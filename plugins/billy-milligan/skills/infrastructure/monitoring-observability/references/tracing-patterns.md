# Tracing Patterns

## OpenTelemetry Setup

```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: 'order-service',
    'deployment.environment': process.env.NODE_ENV,
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
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

sdk.start();  // Must start before importing application code
```

Auto-instrumented: HTTP client/server, Express routes, PostgreSQL queries, Redis commands.

## Manual Span Design

```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('order-service');

async function processOrder(orderId: string) {
  return tracer.startActiveSpan('processOrder', async (span) => {
    span.setAttributes({
      'order.id': orderId,
      'order.type': 'standard',
    });

    try {
      // Child span for payment
      await tracer.startActiveSpan('chargePayment', async (paymentSpan) => {
        paymentSpan.setAttributes({ 'payment.method': 'card' });
        await chargePayment(orderId);
        paymentSpan.end();
      });

      // Child span for notification
      await tracer.startActiveSpan('sendConfirmation', async (notifySpan) => {
        await sendEmail(orderId);
        notifySpan.end();
      });

      span.setStatus({ code: SpanStatusCode.OK });
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

## Span Design Guidelines

```
Good span names:
  "HTTP GET /api/orders"
  "processOrder"
  "pg.query SELECT orders"
  "redis.GET session:abc"

Bad span names:
  "doing stuff"
  "step 1"
  "GET /api/orders/12345"  (high cardinality -- use attributes instead)

Span attributes for context:
  order.id, user.id, http.status_code, db.statement (parameterized)

Never put in span names:
  IDs, parameters, PII (use attributes instead)
```

## Sampling Strategies

| Strategy | Rate | Use case |
|---|---|---|
| Always On | 100% | Development, low-traffic services |
| Probability | 1-10% | High-traffic production services |
| Rate Limiting | N/sec | Consistent trace volume regardless of traffic |
| Tail-based | Dynamic | Sample errors at 100%, success at 1% |

```typescript
import { TraceIdRatioBasedSampler } from '@opentelemetry/sdk-trace-base';

// Sample 10% of traces
const sampler = new TraceIdRatioBasedSampler(0.1);
```

Tail-based sampling (collector-side): keep 100% of error traces, 1% of success traces. Requires an OpenTelemetry Collector with tail sampling processor.

## Trace Analysis Patterns

```
Debugging with traces:
  1. Find the trace ID (from logs, error reports, or X-Trace-Id header)
  2. View waterfall in Jaeger/Tempo/Datadog
  3. Identify the slow span (longest bar)
  4. Check span attributes for context
  5. Correlate with logs using trace_id field

Common findings:
  - N+1 queries: many short DB spans in sequence
  - Missing index: single long DB span
  - Upstream timeout: HTTP span near timeout value
  - Retry storm: repeated identical spans
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| High-cardinality span names | Use attributes for IDs, parameterize names |
| 100% sampling in production | Use probability or tail-based sampling |
| No span on business logic | Add manual spans for key operations |
| Missing error recording | Call `span.recordException()` on catch |
| Spans not ended | Always `span.end()` in finally block |

## Quick Reference

- Start SDK **before** application imports
- Auto-instrumentation covers: HTTP, Express, DB drivers, Redis
- Add manual spans for: business logic, external API calls, complex algorithms
- Sampling: **1-10%** for high-traffic, **100%** for errors (tail-based)
- Span naming: verb + resource, no IDs in names
- Backends: Jaeger (OSS), Grafana Tempo (OSS), Datadog (SaaS)
