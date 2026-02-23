# Resilience Patterns and Infrastructure

## When to load
Load when implementing circuit breakers, configuring API gateways or service meshes, setting up service discovery, or adding distributed tracing.

## Circuit Breaker

States: **Closed** (normal) → **Open** (failing, reject calls) → **Half-Open** (test recovery)

- Configure failure threshold: e.g., 5 failures in 60 seconds opens the circuit
- Set open duration before transitioning to half-open: e.g., 30 seconds
- Monitor circuit state changes with metrics and alerts
- Libraries: `opossum` (Node.js), `resilience4j` (Java), `gobreaker` (Go), `pybreaker` (Python)

## API Gateway

- Single entry point for all external clients
- Responsibilities: routing, authentication, rate limiting, request transformation
- Tools: Kong, AWS API Gateway, Apigee, Traefik, NGINX
- Keep business logic out of the gateway — it is infrastructure, not application code
- Implement BFF (Backend for Frontend) pattern when different clients need different APIs

## Service Mesh (Istio / Linkerd)

- Handles mTLS, load balancing, retries, and observability at the infrastructure level
- Use when managing 10+ services with complex networking requirements
- Sidecar proxy pattern (Envoy) intercepts all network traffic transparently
- Provides traffic splitting for canary deployments and A/B testing
- Adds significant operational complexity — evaluate whether your scale justifies it

## Service Discovery

- **Client-side**: Service registry (Consul, Eureka) with client-side load balancing
- **Server-side**: DNS-based (Kubernetes Services) or load balancer-based
- Kubernetes: use Service resources and cluster DNS for internal discovery
- Register health status on startup and deregister on graceful shutdown

## Distributed Tracing

- Propagate trace context (W3C Trace Context or B3 format) across all service boundaries
- Instrument HTTP clients, message consumers, and database calls with spans
- Tools: Jaeger, Zipkin, AWS X-Ray, Datadog APM, OpenTelemetry Collector
- Use OpenTelemetry SDK for vendor-neutral instrumentation — avoid vendor lock-in at the SDK level
- Add custom spans for critical business operations (payment processing, order fulfillment)
- Set sampling rates appropriate to traffic volume: 100% in dev, 1-10% in production

## Retry and Timeout Strategy

- Every outbound HTTP call must have an explicit timeout (no infinite waits)
- Retry only on transient errors: network timeouts, 429, 503
- Never retry non-idempotent operations without an idempotency key
- Exponential backoff with jitter: `delay = min(base * 2^attempt + rand(0, base), max_delay)`
- Set a maximum retry budget per request to bound total latency

## Health Checks

- Expose `/health/live` (process is running) and `/health/ready` (dependencies healthy)
- Liveness probe: fail only on unrecoverable states — do not fail on slow dependencies
- Readiness probe: fail when the service cannot serve traffic (DB disconnected, cache unavailable)
- Service mesh and Kubernetes use these probes for routing and restart decisions
