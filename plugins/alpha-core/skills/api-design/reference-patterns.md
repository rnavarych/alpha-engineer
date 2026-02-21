# API Design Patterns Reference

## API Gateway Patterns
- **Single entry point**: Route, authenticate, rate limit at gateway level
- **BFF (Backend for Frontend)**: Separate gateway per client type (web, mobile, IoT)
- **API Composition**: Aggregate multiple service responses into one
- Tools: Kong, AWS API Gateway, Envoy, Traefik

## Pagination Patterns

### Cursor-based
```json
{
  "data": [...],
  "meta": {
    "next_cursor": "eyJpZCI6MTAwfQ",
    "has_more": true
  }
}
```
- Stable across insertions/deletions
- Cannot jump to arbitrary page
- Best for infinite scroll, real-time feeds

### Offset-based
```json
{
  "data": [...],
  "meta": {
    "page": 2,
    "per_page": 20,
    "total": 156,
    "total_pages": 8
  }
}
```
- Simple, supports page jumping
- Unstable with concurrent writes
- Best for admin panels, dashboards

## HATEOAS
```json
{
  "id": 123,
  "name": "Order #123",
  "status": "pending",
  "_links": {
    "self": {"href": "/orders/123"},
    "cancel": {"href": "/orders/123/cancel", "method": "POST"},
    "items": {"href": "/orders/123/items"}
  }
}
```

## Idempotency
- Use `Idempotency-Key` header for POST/PATCH requests
- Store key + response for configured duration (24-48h)
- Return cached response for duplicate keys
- Critical for payment processing

## Webhooks
- Use HTTPS endpoints only
- Sign payloads with HMAC-SHA256
- Include event type, timestamp, idempotency key
- Implement retry with exponential backoff
- Provide webhook testing/replay tools

## API Documentation
- OpenAPI 3.0+ specification (YAML or JSON)
- Include request/response examples
- Document error codes and error response formats
- Provide SDKs or client library generation (openapi-generator)
