# Middleware Pipeline and Error Handling

## When to load
Load when wiring up middleware stacks, implementing error handling, configuring CORS, or adding rate limiting to any framework.

## Middleware Pipeline Order

Standard middleware order for HTTP APIs (sequence matters):

1. **Request ID**: Generate or propagate correlation/request ID (W3C Trace-Context or custom header)
2. **Logging**: Log incoming request method, path, and timing with structured JSON
3. **CORS**: Configure allowed origins, methods, and headers
4. **Security headers**: Helmet (Node.js), SecurityHeaders (.NET), secure defaults
5. **Rate limiting**: Per-IP or per-user throttling backed by Redis
6. **Authentication**: Verify JWT/session/API key
7. **Authorization**: Check permissions for the requested resource
8. **Body parsing**: Parse JSON/multipart with size limits (default 1-10MB cap)
9. **Validation**: Validate request against schema
10. **Handler**: Execute business logic
11. **Error handler**: Catch and format errors consistently

## Error Handling (RFC 7807)

All API errors must follow the Problem Details format:

```json
{
  "type": "https://api.example.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account balance is $10.00, but the transfer requires $25.00",
  "instance": "/transfers/abc-123",
  "correlationId": "req_01HX4K2M3N5P6Q7R8S9T"
}
```

Validation error extension:

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "errors": [
    { "field": "email", "message": "Must be a valid email address", "code": "invalid_format" },
    { "field": "items[0].quantity", "message": "Must be a positive integer", "code": "too_small" }
  ]
}
```

- Map domain exceptions to specific HTTP status codes
- Never expose stack traces, internal paths, or database errors to clients
- Include a `correlationId` for support and debugging linkage to logs

## Request Validation

- Validate all incoming data at the controller/handler level before business logic
- Use schema-based validation (Zod/Valibot/ArkType for Node.js, Pydantic v2 for Python, Bean Validation for Java, FluentValidation for .NET, Ecto changesets for Elixir)
- Return 400 Bad Request with field-level error details for invalid input
- Validate path parameters, query parameters, headers, and request body separately
- Coerce types explicitly (string to number, string to date) rather than implicitly
- Strip unknown fields from input to prevent mass assignment vulnerabilities

## Rate Limiting

- Use sliding window or token bucket algorithms
- Store counters in Redis for distributed deployments
- Apply different limits by endpoint sensitivity and user tier
- Return `429 Too Many Requests` with `Retry-After` header
- Include rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Libraries: `@fastify/rate-limit`, `express-rate-limit` + `rate-limit-redis`, `throttler` (NestJS), `slowapi` (Python/FastAPI), `rack-attack` (Rails)

## CORS Configuration

- Explicitly list allowed origins (never use `*` in production with credentials)
- Restrict allowed methods to those actually used
- Set `Access-Control-Max-Age` to cache preflight responses (86400 seconds)
- Allow only required custom headers
- Enable `credentials: true` only when cookies/auth headers are needed
- Validate `Origin` header server-side for sensitive operations even with CORS configured
