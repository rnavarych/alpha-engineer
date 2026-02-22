---
name: api-design
description: |
  Designs REST, GraphQL, gRPC, tRPC, WebSocket, SSE, and AsyncAPI/event-driven APIs.
  Covers OpenAPI 3.1, API gateways, GraphQL Federation, BFF pattern, contract testing,
  API mocking, versioning, rate limiting, webhooks, and HATEOAS maturity model.
  Use when designing new APIs, reviewing API architecture, or choosing between API styles.
allowed-tools: Read, Grep, Glob, Bash
---

You are an API design specialist. Design APIs that are intuitive, consistent, evolvable, and secure.

## API Style Selection

| Style | Best For | Avoid When |
|-------|----------|------------|
| REST | CRUD, public APIs, web apps, hypermedia | Real-time, complex queries |
| GraphQL | Complex data relationships, mobile, BFF | Simple CRUD, file uploads (use multipart) |
| gRPC | Internal microservices, high performance, streaming | Browser clients (without gRPC-Web/Connect) |
| tRPC | TypeScript full-stack monorepos, type safety end-to-end | Non-TypeScript backends, public APIs |
| WebSocket | Real-time bidirectional, chat, live presence, gaming | Request-response patterns, infrequent updates |
| SSE (Server-Sent Events) | Server-push, live feeds, AI streaming responses | Bidirectional communication |
| AsyncAPI | Event-driven architectures, Kafka/NATS/MQTT integration | Synchronous request-response |

## REST API Design

### URL Structure
- Use nouns, not verbs: `/users` not `/getUsers`
- Plural resources: `/users`, `/orders`, `/products`
- Nested for relationships: `/users/{id}/orders`
- Max 2 levels deep for nesting; prefer filtering for deeper: `/orders?user_id={id}`
- Use kebab-case: `/order-items` not `/orderItems`
- Avoid file extensions in URLs: `/reports/123` not `/reports/123.json`
- Use query params for filtering/sorting/searching: `/users?role=admin&sort=created_at&order=desc`

### HTTP Methods
- `GET`: Read (idempotent, cacheable, no body)
- `POST`: Create, trigger actions (not idempotent)
- `PUT`: Full replace (idempotent, entire resource in body)
- `PATCH`: Partial update — JSON Patch (RFC 6902) or JSON Merge Patch (RFC 7396)
- `DELETE`: Remove (idempotent, 204 No Content on success)
- `HEAD`: Get response headers without body (check existence, get metadata)
- `OPTIONS`: CORS preflight, capability discovery

### Status Codes
- `200 OK`, `201 Created` (include Location header), `202 Accepted` (async), `204 No Content`
- `301 Moved Permanently`, `304 Not Modified` (conditional GET)
- `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`
- `405 Method Not Allowed`, `409 Conflict`, `410 Gone`, `422 Unprocessable Entity`
- `429 Too Many Requests` (include Retry-After header)
- `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable`, `504 Gateway Timeout`

### Error Format (RFC 9457 — Problem Details, supersedes 7807)
```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 422,
  "detail": "One or more fields failed validation",
  "instance": "/users/register",
  "errors": [
    { "field": "email", "message": "Must be a valid email address", "code": "INVALID_FORMAT" },
    { "field": "password", "message": "Must be at least 12 characters", "code": "TOO_SHORT" }
  ],
  "traceId": "01HWXM3FP4ZKY7QRGBF4S9BJKD"
}
```

### Pagination
- **Cursor-based** (preferred for feeds/real-time): `?cursor=eyJpZCI6MTAwfQ&limit=20`
  - Stable across insertions/deletions; cannot jump to arbitrary page
- **Offset-based** (admin panels): `?page=2&per_page=20`
  - Simple, supports page jumping; unstable with concurrent writes
- **Keyset pagination**: `?after_id=100&limit=20` — DB-index-friendly cursor variant
- Always include navigation links: `next`, `previous`, `first`, `last` (HAL or JSON:API style)

### Versioning Strategies
- **URL path** (most common, highly visible): `/v1/users`, `/v2/users`
- **Header** (cleaner URLs): `Accept: application/vnd.myapi.v2+json`
- **Query param** (easy to test): `?api_version=2024-01-01` (Stripe-style date versioning)
- Never remove old versions without deprecation period + sunset header
- Use `Sunset: Sat, 01 Jan 2028 00:00:00 GMT` and `Deprecation: true` headers

### Rate Limiting
- Return standard headers: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` (IETF draft)
- Legacy headers also accepted: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Algorithms: Token bucket (bursty), sliding window (smooth), fixed window (simple)
- Differentiate by: anonymous vs authenticated, API key tier, endpoint criticality
- `429 Too Many Requests` with `Retry-After` header
- Implement per-user, per-IP, per-endpoint, and global limits

## tRPC

End-to-end typesafe APIs for TypeScript full-stack applications. No code generation, no schema files.

```typescript
// server/routers/user.ts
export const userRouter = router({
  list: publicProcedure
    .input(z.object({ cursor: z.string().optional(), limit: z.number().min(1).max(100).default(20) }))
    .query(async ({ input, ctx }) => {
      const users = await ctx.db.user.findMany({
        take: input.limit + 1,
        cursor: input.cursor ? { id: input.cursor } : undefined,
      });
      return { users, nextCursor: users.length > input.limit ? users[input.limit].id : null };
    }),
  create: protectedProcedure
    .input(z.object({ email: z.string().email(), name: z.string().min(1) }))
    .mutation(async ({ input, ctx }) => ctx.db.user.create({ data: input })),
});

// client — fully typed, autocomplete works
const { data } = trpc.user.list.useQuery({ limit: 10 });
await trpc.user.create.mutate({ email: "a@b.com", name: "Alice" });
```

- Router composition: merge routers, nested routers, middleware (auth, logging, validation)
- Subscriptions via WebSocket for real-time updates
- Use with React Query (TanStack Query) adapter; SWR adapter available
- OpenAPI export: trpc-openapi for public-facing tRPC routes

## GraphQL Design

- Define clear types with descriptions (triple-quote comments become schema docs)
- Use connections pattern (Relay spec) for all paginated lists
- Implement DataLoader for N+1 prevention (batch + deduplicate DB queries)
- Limit query depth (max 10) and complexity (weighted scoring)
- Use persisted queries in production (prevent arbitrary query execution)
- Prefer nullable over non-null for fields that may be absent in partial loads
- Use Enums for known finite sets of values
- Input types for mutations; never reuse query types as mutation inputs

### GraphQL Federation (Apollo Federation 2)
```graphql
# products subgraph
type Product @key(fields: "id") {
  id: ID!
  name: String!
  price: Float!
}

# reviews subgraph — extends Product from another subgraph
type Review {
  id: ID!
  product: Product!
  rating: Int!
  body: String!
}

extend type Product @key(fields: "id") {
  id: ID! @external
  reviews: [Review!]!
}
```
- **Apollo Router** (Rust): High-performance federation gateway, supergraph composition
- **Cosmo (WunderGraph)**: Open-source Apollo Federation alternative, GraphQL CDN
- **GraphQL Mesh**: Schema stitching + transform, multiple source types (REST, gRPC, SOAP, DB)
- **Stellate**: GraphQL CDN with edge caching, persisted queries, analytics

### GraphQL Subscriptions
```graphql
subscription OnMessageAdded($channelId: ID!) {
  messageAdded(channelId: $channelId) {
    id
    text
    sender { id name }
    createdAt
  }
}
```
- Transport: WebSocket (`graphql-ws` protocol, replace deprecated `subscriptions-transport-ws`)
- Server-Sent Events: `graphql-sse` for subscriptions over HTTP (works through proxies)
- Use Redis Pub/Sub or Kafka for multi-instance subscription fan-out

## Server-Sent Events (SSE)

One-way server-to-client streaming over HTTP. Ideal for AI LLM streaming responses.

```javascript
// Server (Node.js/Express)
app.get('/events', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'X-Accel-Buffering': 'no',  // Disable nginx buffering
  });

  const send = (event, data) => {
    res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\nid: ${Date.now()}\n\n`);
  };

  // Client reconnects with Last-Event-ID header — resume from last event
  const lastId = req.headers['last-event-id'];

  const interval = setInterval(() => send('update', { ts: Date.now() }), 1000);
  req.on('close', () => clearInterval(interval));
});

// Client
const es = new EventSource('/events');
es.addEventListener('update', (e) => console.log(JSON.parse(e.data)));
```

## AsyncAPI for Event-Driven APIs

Document event-driven APIs (Kafka, NATS, MQTT, AMQP, WebSocket) with AsyncAPI spec.

```yaml
asyncapi: '3.0.0'
info:
  title: Order Events API
  version: '1.0.0'
channels:
  order/created:
    address: order.created
    messages:
      OrderCreated:
        payload:
          type: object
          properties:
            orderId: { type: string, format: uuid }
            userId: { type: string }
            totalAmount: { type: number }
            items: { type: array, items: { $ref: '#/components/schemas/OrderItem' } }
operations:
  publishOrderCreated:
    action: send
    channel: { $ref: '#/channels/order~1created' }
  subscribeOrderCreated:
    action: receive
    channel: { $ref: '#/channels/order~1created' }
```

- Bindings: Kafka (topic, partition, replication), MQTT (QoS, retain), AMQP (exchange, routing key)
- CloudEvents: standard event envelope (specversion, type, source, id, time, datacontenttype, data)
- Tools: AsyncAPI Studio (visual editor), asyncapi-generator (code gen), Microcks (mock server)

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

## API Specifications

### OpenAPI 3.1 (latest)
- Full JSON Schema 2020-12 alignment (replaces OpenAPI subset)
- Webhooks support (replaces callbacks for push events)
- Discriminator improvements for polymorphism
- `pathItem` reuse in components
- Tools: Redoc, Swagger UI, Stoplight, Scalar (modern, performant), Speakeasy (SDK gen)

### JSON:API Specification
- Standardizes resource representation, relationships, links, meta
- `type` + `id` for every resource; `attributes`, `relationships`, `links` sections
- Compound documents (included resources) eliminate N+1 fetching
- Filtering, sorting, pagination, sparse fieldsets via standard query params
- Libraries: jsonapi-serializer, Ember Data, JSONAPI::Resources (Rails)

### HAL (Hypertext Application Language)
- Minimal hypermedia: `_links` and `_embedded` in JSON/XML
- Self, next, prev, related links for navigation
- Widely used in Spring HATEOAS, .NET, Node.js APIs

## BFF (Backend for Frontend) Pattern

Create dedicated backends optimized for each client type:

```
Mobile BFF    → optimized payloads for iOS/Android, push notification integration
Web BFF       → SSR data aggregation, session management, CSRF handling
Partner API   → versioned, documented, rate limited public API
Admin BFF     → full-featured, no field stripping, audit logging
```

- Each BFF is owned by the frontend team, deployed independently
- Aggregates multiple downstream services into single request
- Handles auth token refresh, response transformation, field stripping
- Implements client-specific caching and compression strategies
- GraphQL is a natural fit for BFF (flexible querying, single endpoint)

## Contract Testing

Ensure API consumers and providers agree on the contract without integration environments.

### Pact (Consumer-Driven Contract Testing)
```javascript
// Consumer test defines expected interaction
const interaction = {
  state: 'user 123 exists',
  uponReceiving: 'a request for user 123',
  withRequest: { method: 'GET', path: '/users/123', headers: { Accept: 'application/json' } },
  willRespondWith: {
    status: 200,
    body: { id: '123', name: like('Alice'), email: email() }
  }
};
// Pact generates contract file; provider verifies against real implementation
```

- **Pact Broker**: Store, version, and share contracts across teams
- **PactFlow**: Managed Pact Broker with can-i-deploy webhook integration
- **Spring Cloud Contract**: Server-first contract testing for Java/Kotlin; generates consumer stubs

### API Mocking
- **Prism**: OpenAPI-native mock server, contract validation proxy, dynamic vs static responses
- **MockServer**: Java-based, request matching, callbacks, proxying, record & replay
- **WireMock**: HTTP mock server, request matching, response templating, stateful behavior
- **MSW (Mock Service Worker)**: Browser and Node.js, intercepts at network layer, no code changes
- **Microcks**: AsyncAPI + OpenAPI mocking, Kafka/MQTT support, Testcontainers integration

## API-First Development

Design API contract before implementation:
1. Write OpenAPI / AsyncAPI spec collaboratively (product + engineering)
2. Generate mock server from spec (Prism, MockServer)
3. Frontend team develops against mock while backend implements
4. Contract tests verify implementation matches spec
5. Generate client SDKs from spec (openapi-generator, Speakeasy, Stainless)
6. Publish to developer portal (Stoplight, ReadMe, Mintlify)

## Webhook Delivery

Reliable event delivery from your API to subscriber endpoints.

- **Svix**: Managed webhook service, retries, signature verification, portal, SDKs, filtering
- **Hookdeck**: Webhook gateway, routing, filtering, retry policies, transformations, archiving
- **Standard Webhooks**: Specification for webhook signature verification (HMAC-SHA256 with `svix-signature`)
- Payload signing: `HMAC-SHA256(secret, timestamp + "." + payload)` — include timestamp to prevent replay
- Retry with exponential backoff: immediate, 5s, 30s, 2m, 10m, 30m, 1h, 6h, 12h, 24h
- Idempotency key in payload for consumer deduplication
- Webhook portal: let consumers configure endpoints, inspect deliveries, replay events
- Dead letter queue for permanently failed deliveries
- Webhook testing: ngrok, localtunnel, Svix CLI, Hookdeck CLI for local development

For patterns reference, see [reference-patterns.md](reference-patterns.md).
