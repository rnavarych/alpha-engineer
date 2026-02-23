# Structured Logging

## When to load
Load when implementing structured logging, choosing a logging library, setting up log aggregation pipelines, or configuring log levels per environment.

## Structured Logging Fundamentals
- **Format**: JSON for machine parsing, structured key-value pairs
- **Required fields**: `timestamp` (ISO 8601 with timezone), `level`, `service`, `trace_id`, `span_id`, `message`
- **Optional enrichment**: `user_id`, `request_id`, `correlation_id`, `duration_ms`, `environment`, `version`
- **Levels**: DEBUG (dev only), INFO (business events), WARN (recoverable), ERROR (action needed), FATAL (process exit)
- **Do**: Log business events, errors with context, request boundaries, state transitions, audit-relevant actions
- **Don't**: Log PII/secrets, log in hot loops, use string concatenation, log entire request/response bodies in production

## Logging Libraries by Language

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

## Log Aggregation Patterns
- **Sidecar collector**: Fluent Bit / Fluentd as a sidecar container shipping to central store
- **DaemonSet collector**: OTel Collector or Fluent Bit per node in Kubernetes
- **Direct export**: Application sends logs via OTLP to collector or backend directly
- **Log levels per environment**: DEBUG in dev, INFO in staging, WARN/ERROR in production (configurable via env var)

## Trace Context in Logs
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
