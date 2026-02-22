# API Design Patterns Reference

## API Gateway Patterns

- **Single entry point**: Route, authenticate, rate limit, transform at gateway level before reaching services
- **BFF (Backend for Frontend)**: Separate gateway per client type (web, mobile, IoT, partner) — each owned by the frontend team
- **API Composition**: Aggregate multiple service responses into one client request; reduces chattiness
- **Sidecar Proxy**: Per-service proxy (Envoy) for mTLS, retries, circuit breaking, telemetry
- **Service Mesh Gateway**: Ingress gateway (Istio, Linkerd) for north-south traffic; mesh handles east-west
- Tools: Kong (plugin ecosystem), AWS API Gateway (Lambda), Apigee (enterprise analytics), Tyk (open-source), KrakenD (stateless, performance), Traefik Hub (Kubernetes-native), Gravitee (event-driven)

## Pagination Patterns

### Cursor-based (Recommended for Feeds)
```json
{
  "data": [...],
  "meta": {
    "next_cursor": "eyJpZCI6MTAwLCJjcmVhdGVkX2F0IjoiMjAyNi0wMSJ9",
    "prev_cursor": "eyJpZCI6ODEsImNyZWF0ZWRfYXQiOiIyMDI2LTAxIn0",
    "has_next": true,
    "has_prev": true,
    "count": 20
  }
}
```
- Cursor encodes sort column values (base64 JSON), not page number
- Stable across insertions/deletions — no phantom/duplicate items
- Cannot jump to arbitrary page
- Best for: infinite scroll, social feeds, real-time data, Relay-based GraphQL

### Offset-based (Simple Admin Panels)
```json
{
  "data": [...],
  "meta": {
    "page": 2,
    "per_page": 20,
    "total": 156,
    "total_pages": 8
  },
  "_links": {
    "self": "/users?page=2&per_page=20",
    "first": "/users?page=1&per_page=20",
    "last": "/users?page=8&per_page=20",
    "next": "/users?page=3&per_page=20",
    "prev": "/users?page=1&per_page=20"
  }
}
```
- Simple, supports page jumping, easy for reporting
- Unstable with concurrent writes (items can shift between pages)
- COUNT(*) can be expensive on large tables — consider approximation

### Keyset Pagination (DB Index Optimized)
```
GET /events?after_id=8f3a2c&after_created_at=2026-01-15T10:30:00Z&limit=20
```
- Uses indexed columns as cursor components
- Extremely fast for large datasets (no OFFSET scan)
- Requires consistent sort order; combine multiple columns for stability

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
- Formats: HAL (`_links`, `_embedded`), JSON:API (`links`, `relationships`), Siren, JSON-LD

## tRPC Patterns

### Router Composition
```typescript
// Middleware for authentication
const protectedProcedure = publicProcedure.use(async ({ ctx, next }) => {
  if (!ctx.session?.user) throw new TRPCError({ code: 'UNAUTHORIZED' });
  return next({ ctx: { ...ctx, user: ctx.session.user } });
});

// Nested routers
const appRouter = router({
  user: userRouter,
  post: postRouter,
  admin: router({
    dashboard: adminProcedure.query(async ({ ctx }) => getDashboardStats(ctx)),
    deleteUser: adminProcedure
      .input(z.object({ userId: z.string() }))
      .mutation(async ({ input, ctx }) => deleteUser(input.userId)),
  }),
});

// tRPC Subscriptions (WebSocket)
export const postRouter = router({
  onAdd: publicProcedure
    .input(z.object({ channelId: z.string() }))
    .subscription(({ input }) => {
      return observable<Post>((emit) => {
        const unsub = eventEmitter.on(`post.add.${input.channelId}`, emit.next);
        return () => unsub();
      });
    }),
});
```

### OpenAPI Export (trpc-openapi)
```typescript
export const appRouter = router({
  getUser: publicProcedure
    .meta({ openapi: { method: 'GET', path: '/users/{id}', tags: ['users'] } })
    .input(z.object({ id: z.string() }))
    .output(UserSchema)
    .query(({ input }) => db.user.findUnique({ where: { id: input.id } })),
});
```

## GraphQL Patterns

### DataLoader (N+1 Prevention)
```javascript
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.user.findMany({ where: { id: { in: userIds } } });
  const userMap = new Map(users.map(u => [u.id, u]));
  return userIds.map(id => userMap.get(id) ?? new Error(`User ${id} not found`));
});

// In resolver — batched automatically
const Post = { author: (post) => userLoader.load(post.authorId) };
```

### Query Complexity Analysis
```javascript
const depthLimit = require('graphql-depth-limit');
const { createComplexityRule } = require('graphql-query-complexity');

const server = new ApolloServer({
  validationRules: [
    depthLimit(10),
    createComplexityRule({
      maximumComplexity: 1000,
      estimators: [
        fieldExtensionsEstimator(),
        simpleEstimator({ defaultComplexity: 1 }),
      ],
    }),
  ],
});
```

### Persisted Queries (APQ)
```javascript
// Client sends hash first; server returns 404 if unknown; client resends full query
// Reduces bandwidth; prevents arbitrary query execution in production
const link = createPersistedQueryLink({ sha256 }) // Apollo Client
// Automatic Persisted Queries (APQ) or pre-registered trusted document IDs
```

### Subscriptions with Redis Pub/Sub (Multi-instance)
```javascript
const pubsub = new RedisPubSub({
  publisher: new Redis({ host: process.env.REDIS_HOST }),
  subscriber: new Redis({ host: process.env.REDIS_HOST }),
});

const resolvers = {
  Subscription: {
    messageAdded: {
      subscribe: withFilter(
        () => pubsub.asyncIterator(['MESSAGE_ADDED']),
        (payload, variables) => payload.messageAdded.channelId === variables.channelId
      ),
    },
  },
  Mutation: {
    addMessage: async (_, args, ctx) => {
      const message = await ctx.db.message.create({ data: args });
      pubsub.publish('MESSAGE_ADDED', { messageAdded: message });
      return message;
    },
  },
};
```

## Apollo Federation Patterns

### Entity Resolution
```graphql
# Gateway merges subgraph schemas automatically
# Product subgraph
type Product @key(fields: "id") {
  id: ID!
  name: String!
  price: Float!
}

# Inventory subgraph — extends Product without importing full type
type Product @key(fields: "id") {
  id: ID! @external
  inStock: Boolean!
  quantity: Int!
}

# Query resolves across subgraphs in single response:
# { product(id: "1") { name price inStock quantity } }
```

### Shareable and Interface Objects
```graphql
type User @key(fields: "id") @shareable {
  id: ID!
  email: String! @shareable
}
# @interfaceObject for abstract types spanning subgraphs (Federation 2.3+)
```

## API Composition with BFF

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
- BFF is the right place for response shaping — never expose raw microservice contracts

## Webhook Delivery Patterns

### Reliable Webhook Architecture
```
Producer → Event Store (DB outbox) → Webhook Dispatcher → HTTP delivery with retries
                                    ↓ (on permanent failure)
                                Dead Letter Queue → Alerting + manual replay
```

### Payload Signing (Standard Webhooks Spec)
```javascript
// Sender
const timestamp = Math.floor(Date.now() / 1000).toString();
const toSign = `${timestamp}.${JSON.stringify(payload)}`;
const signature = crypto.createHmac('sha256', secret).update(toSign).digest('hex');
headers['webhook-id'] = eventId;
headers['webhook-timestamp'] = timestamp;
headers['webhook-signature'] = `v1,${signature}`;

// Receiver verification
function verifyWebhook(payload, headers, secret) {
  const timestamp = headers['webhook-timestamp'];
  const signatures = headers['webhook-signature'].split(' ');
  const toVerify = `${headers['webhook-id']}.${timestamp}.${payload}`;
  const expected = `v1,${crypto.createHmac('sha256', secret).update(toVerify).digest('hex')}`;
  const age = Math.abs(Date.now() / 1000 - parseInt(timestamp));
  if (age > 300) throw new Error('Timestamp too old — potential replay attack');
  if (!signatures.some(sig => crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected)))) {
    throw new Error('Invalid signature');
  }
}
```

### Retry Strategy
```
Attempt 1: immediate
Attempt 2: 5 seconds
Attempt 3: 30 seconds
Attempt 4: 2 minutes
Attempt 5: 10 minutes
Attempt 6: 30 minutes
Attempt 7: 1 hour
Attempt 8: 6 hours
Attempt 9: 12 hours
Attempt 10: 24 hours
→ Move to dead letter queue, alert, allow manual replay
```

## Event-Driven API Patterns (AsyncAPI / CloudEvents)

### CloudEvents Standard Envelope
```json
{
  "specversion": "1.0",
  "type": "com.example.order.created",
  "source": "https://api.example.com/orders",
  "id": "01HWXM3FP4ZKY7QRGBF4S9BJKD",
  "time": "2026-02-21T10:30:00Z",
  "datacontenttype": "application/json",
  "dataschema": "https://api.example.com/schemas/order-created.json",
  "data": {
    "orderId": "ord_123",
    "userId": "usr_456",
    "total": 49.99
  }
}
```

### AsyncAPI with Kafka Bindings
```yaml
channels:
  order.created:
    bindings:
      kafka:
        topic: order-created-events
        partitions: 12
        replicas: 3
        topicConfiguration:
          retention.ms: 2592000000  # 30 days
          cleanup.policy: delete
    messages:
      OrderCreated:
        bindings:
          kafka:
            key:
              type: string
              description: Order ID used as partition key
```

## Long Polling Pattern

```javascript
// Server — hold request open until event or timeout
app.get('/api/updates', async (req, res) => {
  const since = req.query.since || Date.now();
  const timeout = 30000; // 30 second max hold

  const result = await Promise.race([
    waitForUpdate(since),           // Resolve when new data available
    sleep(timeout).then(() => null) // Timeout fallback
  ]);

  if (result) {
    res.json({ data: result, timestamp: Date.now() });
  } else {
    res.json({ data: null, timestamp: Date.now() }); // Client reconnects immediately
  }
});

// Client
async function poll(since = 0) {
  const res = await fetch(`/api/updates?since=${since}`);
  const { data, timestamp } = await res.json();
  if (data) handleUpdate(data);
  poll(timestamp); // Reconnect immediately after response
}
```

## HTTP/2 and HTTP/3 Patterns

### HTTP/2 Multiplexing Benefits
- Multiple concurrent requests over single TCP connection (eliminates head-of-line blocking at HTTP level)
- Server Push: proactively send resources client will need (use sparingly — `103 Early Hints` preferred)
- Header compression (HPACK): reduces overhead on repeated requests
- Stream prioritization: critical resources get bandwidth preference

### HTTP/3 / QUIC
- UDP-based transport: eliminates TCP head-of-line blocking entirely
- 0-RTT connection resumption: faster reconnects (careful — replay attack surface)
- Built-in TLS 1.3 encryption; no cleartext QUIC
- Connection migration: switch networks without reconnecting (mobile-friendly)
- Enable on: Cloudflare, Fastly, nginx (with quiche), Caddy, LiteSpeed
- `Alt-Svc: h3=":443"; ma=86400` header advertises HTTP/3 support

## API Security Patterns

### OAuth Scopes Design
```
# Granular scopes (preferred over broad read/write)
read:users          write:users:profile    admin:users
read:orders         write:orders:create    write:orders:cancel
read:payments       write:payments:refund  admin:payments

# Scope hierarchy using colon notation
# Minimum viable scope for each endpoint
# Scopes in JWT access token claim: "scope": "read:users write:orders:create"
```

### API Key Rotation (Zero Downtime)
```javascript
// Support multiple valid API keys during rotation
// Phase 1: Generate new key, mark old key as "rotating" (still valid)
// Phase 2: Customer updates their integration to use new key
// Phase 3: Deprecate old key (still valid, warning in response headers)
// Phase 4: Revoke old key after grace period

// Response header warning during grace period
res.setHeader('Deprecation', 'true');
res.setHeader('Sunset', new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toUTCString());
res.setHeader('Warning', '299 - "API key rotated, please update to new key"');
```

## Content Negotiation

```http
# Client requests specific format
GET /reports/monthly
Accept: application/json, text/csv;q=0.8, application/pdf;q=0.5

# Server responds with best match
Content-Type: application/json
Vary: Accept  # Critical: tells CDN to cache per Accept value
```

## Conditional Requests (Efficient Caching)

```javascript
// Server sends ETag with response
res.setHeader('ETag', '"abc123def456"');
res.setHeader('Last-Modified', resource.updatedAt.toUTCString());
res.setHeader('Cache-Control', 'private, max-age=0, must-revalidate');

// Client sends conditional GET
// If-None-Match: "abc123def456"  → server returns 304 if unchanged
// If-Modified-Since: <date>      → server returns 304 if not modified

if (req.headers['if-none-match'] === currentETag) {
  return res.status(304).end(); // Client uses cached version
}
```

## Bulk and Batch API Patterns

### Batch Request (JSON:API / custom)
```http
POST /batch
Content-Type: application/json

{
  "requests": [
    { "id": "1", "method": "GET", "url": "/users/123" },
    { "id": "2", "method": "POST", "url": "/orders", "body": { "items": [...] } },
    { "id": "3", "method": "DELETE", "url": "/cart/items/456", "dependsOn": ["2"] }
  ]
}
```

### Bulk Operations
```http
# Bulk create
POST /users/bulk
{ "users": [{ "email": "a@b.com" }, { "email": "c@d.com" }] }
→ 207 Multi-Status with per-item results

# Bulk update (JSON Patch)
PATCH /users
[
  { "op": "replace", "path": "/users/123/status", "value": "active" },
  { "op": "replace", "path": "/users/124/status", "value": "inactive" }
]
```

## Idempotency

```javascript
// Idempotency-Key header for POST/PATCH (critical for payments)
app.post('/payments', async (req, res) => {
  const idempotencyKey = req.headers['idempotency-key'];
  if (!idempotencyKey) return res.status(400).json({ error: 'Idempotency-Key header required' });

  // Check cache (Redis with 24h TTL)
  const cached = await redis.get(`idempotency:${idempotencyKey}`);
  if (cached) return res.status(200).json(JSON.parse(cached)); // Return same response

  // Lock to prevent concurrent duplicate processing
  const lock = await redis.set(`idempotency:lock:${idempotencyKey}`, '1', 'EX', 30, 'NX');
  if (!lock) return res.status(409).json({ error: 'Request in progress' });

  const result = await processPayment(req.body);
  await redis.setex(`idempotency:${idempotencyKey}`, 86400, JSON.stringify(result));
  res.status(201).json(result);
});
```

## API Documentation

- **OpenAPI 3.1**: YAML or JSON spec, source of truth for contract
- **Redoc**: Elegant 3-panel documentation, SEO-friendly, customizable
- **Scalar**: Modern, interactive, performant documentation UI
- **Stoplight**: Design-first platform, mock server, governance, style guides
- **ReadMe**: Developer hub, metrics, changelogs, personalized docs
- **Mintlify**: MDX-based, git-backed, component library for rich docs
- SDK generation: **Speakeasy** (high-quality, customizable), **Stainless** (Rails-like), **openapi-generator** (community, 50+ languages)
- Always include: request/response examples, error codes, authentication guide, rate limit details, changelog
