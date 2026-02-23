# Metrics and Distributed Tracing

## When to load
Load when instrumenting services for metrics collection, choosing metric types and methodologies, setting up distributed tracing, or configuring sampling strategies.

## Metric Types
- **Counter**: Monotonically increasing (e.g., `http_requests_total`). Always use `_total` suffix.
- **Gauge**: Point-in-time value that goes up and down (e.g., `queue_depth`, `temperature_celsius`).
- **Histogram**: Distribution of values in configurable buckets (e.g., `http_request_duration_seconds`). Use `_bucket`, `_sum`, `_count` suffixes.
- **Summary**: Client-side quantiles (p50, p90, p99). Not aggregatable across instances — prefer histograms.

## Metric Methodologies
- **RED method** (for request-driven services): Rate, Errors, Duration
- **USE method** (for resources/infrastructure): Utilization, Saturation, Errors
- **Four Golden Signals** (Google SRE): Latency, Traffic, Errors, Saturation

## Metric Naming Conventions
```
# Prometheus convention: <namespace>_<subsystem>_<name>_<unit>_<suffix>
http_server_requests_duration_seconds       # histogram
http_server_requests_total                  # counter
process_resident_memory_bytes               # gauge
db_connections_pool_active                  # gauge
cache_hits_total / cache_misses_total       # counters for hit ratio
```

## Instrumentation per Framework
- **Express.js**: `prom-client` with `express-prom-bundle` or OTel auto-instrumentation
- **FastAPI/Flask**: `prometheus-flask-instrumentator`, `starlette-prometheus`, or OTel
- **Spring Boot**: Micrometer with Prometheus registry (`/actuator/prometheus` endpoint)
- **Go (net/http)**: `promhttp.Handler()`, custom middleware with `prometheus/client_golang`
- **ASP.NET Core**: `prometheus-net.AspNetCore`, `OpenTelemetry.Instrumentation.AspNetCore`

## Distributed Tracing Core Concepts
- **Span**: Unit of work with name, start/end time, attributes, events, status, parent span ID
- **Trace**: DAG (directed acyclic graph) of spans forming a request tree
- **Context propagation**: W3C Trace Context (`traceparent`, `tracestate` headers) or B3 propagation
- **Baggage**: Key-value pairs propagated across service boundaries (tenant ID, feature flags)

## Trace Instrumentation Patterns
- **Auto-instrumentation**: Zero-code via language agents (Java `-javaagent`, Python `opentelemetry-instrument`)
- **Manual instrumentation**: Create custom spans for business logic, add attributes, record events
- **Span attributes**: Follow OTel semantic conventions (`http.method`, `db.system`, `db.statement`)
- **Span events**: Timestamped events within a span (cache miss, retry attempt)
- **Span links**: Connect causally-related traces (async processing triggered by a request)

## Sampling Strategies
- **Always-on**: 100% sampling (small services, <1000 RPS)
- **Head-based**: Decide at trace start (probabilistic, rate limiting). Simple but may miss errors.
- **Tail-based**: Decide after trace completes (keep errors, slow traces). Requires collector buffering.
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
