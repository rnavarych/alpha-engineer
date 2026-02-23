# Contract Testing, Security, and Advanced Patterns

## When to load
Load when setting up contract testing (Pact), API mocking, implementing API-first development, OAuth scopes, idempotency, conditional requests, or bulk operations.

## Contract Testing

### Pact (Consumer-Driven Contract Testing)

```javascript
const interaction = {
  state: 'user 123 exists',
  uponReceiving: 'a request for user 123',
  withRequest: { method: 'GET', path: '/users/123', headers: { Accept: 'application/json' } },
  willRespondWith: { status: 200, body: { id: '123', name: like('Alice'), email: email() } }
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

1. Write OpenAPI / AsyncAPI spec collaboratively (product + engineering)
2. Generate mock server from spec (Prism, MockServer)
3. Frontend team develops against mock while backend implements
4. Contract tests verify implementation matches spec
5. Generate client SDKs (openapi-generator, Speakeasy, Stainless)
6. Publish to developer portal (Stoplight, ReadMe, Mintlify)

## API Security Patterns

**OAuth Scopes** — granular, colon-hierarchy: `read:users`, `write:orders:create`, `admin:payments`. Minimum viable scope per endpoint. Scopes in JWT `scope` claim.

**API Key Rotation (Zero Downtime)**
```javascript
// Phase 1: generate new key (old still valid). Phase 2: customer updates integration.
// Phase 3: deprecate old key with warning headers. Phase 4: revoke after grace period.
res.setHeader('Deprecation', 'true');
res.setHeader('Sunset', new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toUTCString());
res.setHeader('Warning', '299 - "API key rotated, please update to new key"');
```

## Idempotency

```javascript
app.post('/payments', async (req, res) => {
  const key = req.headers['idempotency-key'];
  if (!key) return res.status(400).json({ error: 'Idempotency-Key header required' });
  const cached = await redis.get(`idempotency:${key}`);
  if (cached) return res.status(200).json(JSON.parse(cached));
  const lock = await redis.set(`idempotency:lock:${key}`, '1', 'EX', 30, 'NX');
  if (!lock) return res.status(409).json({ error: 'Request in progress' });
  const result = await processPayment(req.body);
  await redis.setex(`idempotency:${key}`, 86400, JSON.stringify(result));
  res.status(201).json(result);
});
```

## Conditional Requests, Content Negotiation, Bulk Operations

```javascript
// ETag conditional request
res.setHeader('ETag', '"abc123def456"');
if (req.headers['if-none-match'] === currentETag) return res.status(304).end();
```

```http
# Content negotiation
Accept: application/json, text/csv;q=0.8
Vary: Accept  # tells CDN to cache per Accept value

# Batch request
POST /batch
{ "requests": [{ "id": "1", "method": "GET", "url": "/users/123" },
                { "id": "2", "method": "POST", "url": "/orders", "body": {...} }] }

# Bulk create → 207 Multi-Status with per-item results
POST /users/bulk
{ "users": [{ "email": "a@b.com" }, { "email": "c@d.com" }] }
```

## HTTP/2 and HTTP/3

- **HTTP/2**: Multiple concurrent requests over single TCP, HPACK header compression, stream prioritization
- **HTTP/3 / QUIC**: UDP-based, eliminates TCP head-of-line blocking, 0-RTT resumption, connection migration (mobile-friendly)
- `Alt-Svc: h3=":443"; ma=86400` header advertises HTTP/3 support

## API Documentation Tools

- **Scalar**: Modern, interactive, performant UI; **Redoc**: elegant 3-panel; **Stoplight**: design-first platform
- **ReadMe**: developer hub with metrics; **Mintlify**: MDX-based, git-backed
- SDK generation: **Speakeasy** (high-quality), **Stainless** (Rails-like), **openapi-generator** (50+ languages)
