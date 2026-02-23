# REST Best Practices

## When to load
Load when designing REST APIs — naming, pagination, error responses, idempotency.

## Patterns ✅

### Resource naming
```
GET    /api/v1/orders              # List
POST   /api/v1/orders              # Create
GET    /api/v1/orders/:id          # Get one
PATCH  /api/v1/orders/:id          # Partial update
DELETE /api/v1/orders/:id          # Delete
GET    /api/v1/orders/:id/items    # Sub-resource
```
Rules: plural nouns, kebab-case, no verbs. Actions via sub-resources: `POST /orders/:id/cancel`.

### Cursor pagination
```typescript
// Response format
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ==",  // base64(JSON)
    "has_more": true,
    "limit": 20
  }
}

// Implementation: WHERE (created_at, id) < ($cursor_created_at, $cursor_id)
// ORDER BY created_at DESC, id DESC LIMIT $limit + 1
// If rows returned > limit → has_more = true, pop last row
```

### Error format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "request_id": "req_abc123",
    "details": [
      { "field": "email", "message": "Must be valid email" }
    ]
  }
}
```
Always include `request_id` for debugging. Map to HTTP status: 400 validation, 401 auth, 403 forbidden, 404 not found, 409 conflict, 429 rate limit, 500 server error.

### Idempotency keys
```typescript
// Client sends: Idempotency-Key: <uuid>
// Server: check Redis for key → if exists, return cached response
// If not: process request, cache response with 24h TTL
const cached = await redis.get(`idempotency:${key}`);
if (cached) return JSON.parse(cached); // Same response, no side effect
```

## Anti-patterns ❌
- Offset pagination at scale: `OFFSET 50000` scans 50k rows then discards them
- Returning 200 for errors: breaks client error handling
- Exposing sequential IDs: enables enumeration attacks. Use UUIDs or prefixed IDs (`ord_abc123`)
- Chatty APIs: 10 calls per page load → use compound endpoints or BFF

## Quick reference
```
Pagination: cursor > offset (always)
Idempotency TTL: 24h
Rate limit headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
Max page size: 100 (default 20)
```
