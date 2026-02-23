# Custom Validators, Middleware, and Schema Composition

## When to load
Load when implementing custom validation rules, wiring validation middleware into a request pipeline, composing reusable schemas, or tuning validation performance.

## Custom Validators

### Common Custom Validations
- **Email**: RFC 5322 compliant — use a library, not a simple regex
- **Phone**: E.164 format with `libphonenumber` for full validation
- **URL**: Validate scheme, host, and optionally restrict to allowlisted domains
- **Slug**: Lowercase alphanumeric with hyphens, no leading/trailing hyphens
- **Currency**: Decimal with exactly 2 places, positive, within reasonable range
- **Password strength**: Minimum length (12+), check against common password lists

### Cross-Field Validation
- Validate field relationships: `startDate` must be before `endDate`
- Conditional required fields: `shippingAddress` required if `deliveryMethod` is `"ship"`
- Mutual exclusivity: specify `email` or `phone`, not both
- Implement at the schema level when possible, business logic layer otherwise

## Validation Middleware Pattern

```
Request → Parse Body → Validate Schema → Transform/Coerce → Handler
                              |
                              v (on failure)
                     400 Bad Request with field errors
```

- Run validation before any business logic or database access
- Return all validation errors at once (not one at a time)
- Use consistent error format with field paths for nested objects

### Error Response Format

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "errors": [
    { "field": "email", "message": "Must be a valid email address", "code": "invalid_format" },
    { "field": "age", "message": "Must be at least 18", "code": "too_small" },
    { "field": "items[0].quantity", "message": "Must be a positive integer", "code": "invalid_type" }
  ]
}
```

## Schema Composition and Reuse

- Build base schemas for common types (Address, Money, DateRange, Pagination)
- Compose complex schemas from base schemas using extend/merge/intersection
- Share validation schemas between frontend and backend (monorepo or published package)
- Use discriminated unions for polymorphic types (`type: "credit_card" | "bank_transfer"`)
- Export TypeScript types from Zod schemas (`z.infer<typeof schema>`) for compile-time safety

## Performance Considerations

- Compile/precompile schemas at startup, not per request (Ajv, Zod, Joi)
- Cache compiled validators for frequently used schemas
- Avoid deeply nested validation on high-throughput endpoints
- For large payloads, validate structure first, then validate content in streaming fashion
- Profile validation overhead for latency-sensitive endpoints
