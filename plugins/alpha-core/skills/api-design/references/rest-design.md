# REST API Design

## When to load
Load when designing or reviewing REST endpoints: URL structure, HTTP methods, status codes, error format, pagination, versioning, or rate limiting.

## URL Structure and HTTP Methods

- Use nouns, not verbs: `/users` not `/getUsers`
- Plural resources: `/users`, `/orders`, `/products`
- Nested for relationships: `/users/{id}/orders`
- Max 2 levels deep for nesting; prefer filtering for deeper: `/orders?user_id={id}`
- Use kebab-case: `/order-items` not `/orderItems`
- Avoid file extensions in URLs: `/reports/123` not `/reports/123.json`
- Query params for filtering/sorting/searching: `/users?role=admin&sort=created_at&order=desc`

**HTTP Methods**
- `GET`: Read (idempotent, cacheable, no body)
- `POST`: Create, trigger actions (not idempotent)
- `PUT`: Full replace (idempotent, entire resource in body)
- `PATCH`: Partial update — JSON Patch (RFC 6902) or JSON Merge Patch (RFC 7396)
- `DELETE`: Remove (idempotent, 204 No Content on success)
- `HEAD`: Get response headers without body (check existence, get metadata)
- `OPTIONS`: CORS preflight, capability discovery

## Status Codes

- `200 OK`, `201 Created` (include Location header), `202 Accepted` (async), `204 No Content`
- `301 Moved Permanently`, `304 Not Modified` (conditional GET)
- `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`
- `405 Method Not Allowed`, `409 Conflict`, `410 Gone`, `422 Unprocessable Entity`
- `429 Too Many Requests` (include Retry-After header)
- `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable`, `504 Gateway Timeout`

## Error Format (RFC 9457 — Problem Details)

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

## Pagination

- **Cursor-based** (preferred for feeds/real-time): `?cursor=eyJpZCI6MTAwfQ&limit=20`
  - Stable across insertions/deletions; cannot jump to arbitrary page
- **Offset-based** (admin panels): `?page=2&per_page=20`
  - Simple, supports page jumping; unstable with concurrent writes
- **Keyset pagination**: `?after_id=100&limit=20` — DB-index-friendly cursor variant
- Always include navigation links: `next`, `previous`, `first`, `last` (HAL or JSON:API style)

## Versioning and Rate Limiting

**Versioning strategies**
- **URL path** (most common, highly visible): `/v1/users`, `/v2/users`
- **Header** (cleaner URLs): `Accept: application/vnd.myapi.v2+json`
- **Query param** (easy to test): `?api_version=2024-01-01` (Stripe-style date versioning)
- Never remove old versions without deprecation period + sunset header
- Use `Sunset: Sat, 01 Jan 2028 00:00:00 GMT` and `Deprecation: true` headers

**Rate limiting**
- Return standard headers: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` (IETF draft)
- Legacy headers also accepted: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Algorithms: Token bucket (bursty), sliding window (smooth), fixed window (simple)
- Differentiate by: anonymous vs authenticated, API key tier, endpoint criticality
- `429 Too Many Requests` with `Retry-After` header
