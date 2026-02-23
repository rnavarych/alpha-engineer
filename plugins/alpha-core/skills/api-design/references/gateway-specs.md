# API Gateways and Specifications

## When to load
Load when choosing an API gateway, working with OpenAPI 3.1, JSON:API, HAL, or designing a BFF pattern.

## API Gateways

| Gateway | Strengths | Use Case |
|---------|-----------|----------|
| Kong | Open-source core, plugin ecosystem, DB-less mode | Microservices, self-hosted |
| AWS API Gateway | Lambda integration, managed, usage plans | AWS-native, serverless |
| Apigee (GCP) | Enterprise, analytics, monetization, developer portal | Enterprise, multi-cloud |
| Tyk | Open-source, GraphQL support, self-hosted | Cost-sensitive, on-prem |
| KrakenD | Stateless, no DB, ultra-high performance | Performance-critical, Kubernetes |
| Traefik Hub | Cloud-native, Kubernetes-native, GitOps | Kubernetes-first environments |
| Envoy | Low-level, service mesh integration | Service mesh data plane, advanced routing |
| Gravitee | Open-source, event-driven gateway, AsyncAPI support | Event-driven + REST hybrid |

**Gateway patterns**
- **Single entry point**: Route, authenticate, rate limit, transform at gateway level before reaching services
- **Sidecar Proxy**: Per-service proxy (Envoy) for mTLS, retries, circuit breaking, telemetry
- **Service Mesh Gateway**: Ingress gateway (Istio, Linkerd) for north-south traffic; mesh handles east-west

## OpenAPI 3.1

- Full JSON Schema 2020-12 alignment (replaces OpenAPI subset)
- Webhooks support (replaces callbacks for push events)
- Discriminator improvements for polymorphism
- `pathItem` reuse in components
- Tools: Redoc, Swagger UI, Stoplight, Scalar (modern, performant), Speakeasy (SDK gen)

## JSON:API Specification

- Standardizes resource representation, relationships, links, meta
- `type` + `id` for every resource; `attributes`, `relationships`, `links` sections
- Compound documents (included resources) eliminate N+1 fetching
- Filtering, sorting, pagination, sparse fieldsets via standard query params
- Libraries: jsonapi-serializer, Ember Data, JSONAPI::Resources (Rails)

## HAL (Hypertext Application Language)

- Minimal hypermedia: `_links` and `_embedded` in JSON/XML
- Self, next, prev, related links for navigation
- Widely used in Spring HATEOAS, .NET, Node.js APIs

## HATEOAS (Hypermedia as the Engine of Application State)

REST maturity level 3 — clients discover available actions from response links.

```json
{
  "id": 123,
  "status": "pending",
  "total": 49.99,
  "_links": {
    "self": { "href": "/orders/123", "method": "GET" },
    "cancel": { "href": "/orders/123/cancel", "method": "POST" },
    "pay": { "href": "/orders/123/payment", "method": "POST" },
    "items": { "href": "/orders/123/items", "method": "GET" }
  }
}
```

- Available actions change based on state: `paid` order has no `pay` link; `shipped` has `track` link
- Clients don't hardcode URLs — follow links from root API response

## BFF (Backend for Frontend) Pattern

```
Mobile BFF    → optimized payloads for iOS/Android, push notification integration
Web BFF       → SSR data aggregation, session management, CSRF handling
Partner API   → versioned, documented, rate limited public API
Admin BFF     → full-featured, no field stripping, audit logging
```

```
Client Request → BFF → parallel calls to:
                         ├── User Service   → user profile
                         ├── Order Service  → recent orders
                         └── Product Service → recommended products
               ← BFF assembles, transforms, and strips fields for client
```

- Use `Promise.all` / `Promise.allSettled` for parallel downstream calls
- Implement circuit breakers (opossum, Polly) for each downstream service
- Cache aggregated responses at BFF layer (Redis, in-memory LRU)
- BFF handles auth token refresh, retry logic, error transformation
- Each BFF is owned by the frontend team, deployed independently
