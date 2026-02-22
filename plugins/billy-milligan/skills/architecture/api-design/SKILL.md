---
name: api-design
description: |
  REST API design: resource naming, versioning strategies, cursor pagination (offset scan
  failure at 10M rows), idempotency keys, consistent error format, rate limiting headers,
  OpenAPI contracts, GraphQL vs REST decision. Real HTTP examples with status codes.
  Use when designing new APIs, reviewing API contracts, pagination at scale.
allowed-tools: Read, Grep, Glob
---

# API Design Patterns

## When to Use This Skill
- Designing REST or GraphQL APIs from scratch
- Reviewing existing API contracts for consistency
- Implementing pagination for large datasets
- Adding idempotency to payment/mutation endpoints
- Versioning strategy for breaking changes

## Core Principles

1. **Resources are nouns, actions are HTTP verbs** — `POST /orders`, not `POST /createOrder`
2. **Consistent error format across all endpoints** — clients cannot parse 5 different error shapes
3. **Cursor pagination after 10k rows** — offset becomes a full table scan
4. **Idempotency keys on all mutations that matter** — payments, order creation, email sends
5. **Version in URL, not header** — `/v1/` is discoverable; `Accept: application/vnd.api+json;version=1` is not

---

## Patterns ✅

### Resource Naming

```
# Collections
GET    /orders          → list orders
POST   /orders          → create order
GET    /orders/{id}     → get order
PATCH  /orders/{id}     → partial update
PUT    /orders/{id}     → full replace
DELETE /orders/{id}     → delete

# Nested resources (max 2 levels)
GET  /orders/{id}/items        → list items in order
POST /orders/{id}/items        → add item to order

# Actions (when CRUD does not fit)
POST /orders/{id}/cancel       → cancel order
POST /orders/{id}/refund       → process refund
POST /payments/{id}/capture    → capture auth

# Avoid
POST /createOrder
GET  /getOrderById
POST /orders/{id}/items/{itemId}/updateQuantity  # Too deep
```

### Consistent Error Format

Every error response: same shape, always.

```typescript
interface ApiError {
  error: {
    code: string;       // machine-readable: "VALIDATION_ERROR", "NOT_FOUND"
    message: string;    // human-readable: "Order not found"
    details?: Array<{   // optional field-level errors
      field: string;
      message: string;
    }>;
    requestId: string;  // correlate with logs
  };
}

// 400 response body
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      { "field": "amount", "message": "Must be greater than 0" },
      { "field": "currency", "message": "Must be ISO 4217 code" }
    ],
    "requestId": "req_01HX..."
  }
}

// 404 response body
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Order not found",
    "requestId": "req_01HX..."
  }
}
```

```typescript
// Express global error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const requestId = req.headers['x-request-id'] as string || generateId();

  if (err instanceof ValidationError) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: err.message, details: err.details, requestId }
    });
  }
  if (err instanceof NotFoundError) {
    return res.status(404).json({
      error: { code: 'NOT_FOUND', message: err.message, requestId }
    });
  }
  // Don't leak internals
  logger.error({ err, requestId }, 'Unhandled error');
  return res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', requestId }
  });
});
```

### Cursor Pagination (Not Offset)

**Why offset fails**: `SELECT * FROM orders OFFSET 50000 LIMIT 20` — the DB scans and discards 50,000 rows. At 10M rows with a heavy query, this is 2–10 seconds.

```typescript
// Offset pagination — breaks at scale
GET /orders?page=2500&limit=20
// DB: scans 50,000 rows, returns 20

// Cursor pagination — constant time
GET /orders?after=cursor_01HX...&limit=20

// Response includes next cursor
{
  "data": [...],
  "pagination": {
    "hasNextPage": true,
    "nextCursor": "cursor_01HX...",  // opaque — base64url(id + timestamp)
    "total": null  // do not compute COUNT(*) on large tables
  }
}
```

```typescript
// Cursor implementation (PostgreSQL + Drizzle)
async function listOrders(cursor?: string, limit = 20) {
  const decoded = cursor ? decodeCursor(cursor) : null;

  const orders = await db
    .select()
    .from(ordersTable)
    .where(
      decoded
        ? or(
            gt(ordersTable.createdAt, decoded.createdAt),
            and(
              eq(ordersTable.createdAt, decoded.createdAt),
              gt(ordersTable.id, decoded.id)
            )
          )
        : undefined
    )
    .orderBy(asc(ordersTable.createdAt), asc(ordersTable.id))
    .limit(limit + 1);  // Fetch one extra to detect hasNextPage

  const hasNextPage = orders.length > limit;
  const items = orders.slice(0, limit);
  const nextCursor = hasNextPage
    ? encodeCursor({ id: items.at(-1)!.id, createdAt: items.at(-1)!.createdAt })
    : null;

  return { data: items, pagination: { hasNextPage, nextCursor } };
}

function encodeCursor(data: object): string {
  return Buffer.from(JSON.stringify(data)).toString('base64url');
}
function decodeCursor(cursor: string) {
  return JSON.parse(Buffer.from(cursor, 'base64url').toString());
}
```

### Idempotency Keys

For payments, order creation, email triggers — any operation that must not run twice.

```
# Client sends idempotency key in header
POST /payments
Idempotency-Key: idem_01HX...
Content-Type: application/json

# Server stores result keyed on (idempotencyKey + endpoint)
# Same key + same endpoint → return stored result, do not re-execute
```

```typescript
// Express middleware for idempotency
async function idempotencyMiddleware(req: Request, res: Response, next: NextFunction) {
  const key = req.headers['idempotency-key'];
  if (!key) return next();  // Optional per endpoint

  const cached = await redis.get(`idem:${key}:${req.path}`);
  if (cached) {
    const { status, body } = JSON.parse(cached);
    res.set('Idempotency-Replayed', 'true');
    return res.status(status).json(body);
  }

  // Intercept response to cache it
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    if (res.statusCode < 500) {
      redis.setex(
        `idem:${key}:${req.path}`,
        86400,  // 24h TTL
        JSON.stringify({ status: res.statusCode, body })
      );
    }
    return originalJson(body);
  };

  next();
}
```

### Rate Limiting Headers

```
# Response headers clients must receive
X-RateLimit-Limit: 1000       # requests per window
X-RateLimit-Remaining: 847    # remaining in current window
X-RateLimit-Reset: 1708956000 # Unix timestamp when window resets
Retry-After: 30               # seconds to wait (only on 429)
```

```typescript
// Sliding window rate limiter with Redis sorted sets
async function checkRateLimit(userId: string, endpoint: string) {
  const key = `rl:${userId}:${endpoint}`;
  const limit = RATE_LIMITS[endpoint] ?? 1000;
  const now = Date.now();
  const windowMs = 3600_000;  // 1 hour

  // Atomic operation using a Lua script or pipeline
  await redis.zremrangebyscore(key, 0, now - windowMs);
  await redis.zadd(key, now, `${now}-${Math.random()}`);
  const count = await redis.zcard(key);
  await redis.expire(key, 3600);

  return {
    allowed: count <= limit,
    remaining: Math.max(0, limit - count),
    reset: Math.ceil((now + windowMs) / 1000),
    limit,
  };
}
```

### API Versioning

```
# URL versioning — preferred
/v1/orders
/v2/orders  # breaking change

# Breaking changes (require new version)
- Removing a field
- Renaming a field
- Changing a field type
- Removing an endpoint

# Non-breaking (no version bump needed)
- Adding new optional fields
- Adding new endpoints
- Adding new optional query params
```

---

## Anti-Patterns ❌

### Chatty APIs
**What it is**: Endpoints that return minimal data, forcing clients to make N calls.
**What breaks**: Mobile app on 3G makes 50 requests to render one screen. Latency × 50.
**Fix**: Design for the consumer. One endpoint returns all data for one screen.

### Offset Pagination at Scale
**When it breaks**: Table > 100k rows, users paginating to page 500+. Query time is O(offset). At 1M rows, `OFFSET 999980` scans 999,980 rows.
**Fix**: Cursor pagination. If you must use offset, cap at page 100 with explicit 400 error.

### Returning 200 for Errors

```json
// Wrong
HTTP 200
{ "success": false, "error": "User not found" }

// Correct
HTTP 404
{ "error": { "code": "NOT_FOUND", "message": "User not found" } }
```

**Why it matters**: Monitoring, alerting, and client error handling all depend on HTTP status codes. 200 errors are invisible to standard tooling.

### Exposing Sequential Integer IDs

```
# Sequential IDs leak business info
GET /orders/1, GET /orders/2  # competitor enumerates your orders

# Use UUIDs or prefixed IDs
GET /orders/ord_01HX...       # Stripe-style prefixed IDs
```

---

## Quick Reference

```
Pagination switch: use cursor after 10k rows
Idempotency key TTL: 24h
Rate limit headers: X-RateLimit-Limit / Remaining / Reset
Error format: { error: { code, message, details?, requestId } }
Versioning: /v1/ in URL, not Accept headers
Breaking change = new major version; additive = no version bump
Sequential IDs: never expose — use UUID or prefixed IDs
```
