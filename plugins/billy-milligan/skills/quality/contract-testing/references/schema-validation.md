# Schema Validation

## When to load
Load when validating API contracts at runtime: OpenAPI, JSON Schema, Zod.

## OpenAPI Validation Middleware

```typescript
import { middleware } from 'express-openapi-validator';

app.use(
  middleware({
    apiSpec: './openapi.yaml',
    validateRequests: true,
    validateResponses: process.env.NODE_ENV !== 'production',
    validateSecurity: { handlers: { BearerAuth: validateJWT } },
  })
);

// Requests that don't match the spec get 400 automatically
// Responses that don't match get logged (dev) or 500 (strict mode)
```

## Zod Runtime Validation

```typescript
import { z } from 'zod';

// Define schema
const OrderSchema = z.object({
  id: z.string().uuid(),
  items: z.array(z.object({
    productId: z.string().uuid(),
    quantity: z.number().int().positive(),
    price: z.number().int().nonnegative(),
  })).min(1),
  status: z.enum(['pending', 'completed', 'cancelled']),
  total: z.number().int().nonnegative(),
  createdAt: z.string().datetime(),
});

type Order = z.infer<Order>; // TypeScript type from schema

// Validate API response
const result = OrderSchema.safeParse(apiResponse);
if (!result.success) {
  logger.error({ errors: result.error.flatten() }, 'API contract violation');
}

// Validate request input
app.post('/orders', (req, res) => {
  const input = CreateOrderSchema.parse(req.body); // Throws ZodError on invalid
  // input is fully typed
});
```

## JSON Schema (language-agnostic)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["id", "items", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "items": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["productId", "quantity"],
        "properties": {
          "productId": { "type": "string" },
          "quantity": { "type": "integer", "minimum": 1 }
        }
      }
    },
    "status": { "enum": ["pending", "completed", "cancelled"] }
  }
}
```

## Anti-patterns
- Validating only requests, not responses → provider can break contract silently
- Zod in production hot path without caching → performance overhead
- JSON Schema without `additionalProperties: false` in strict mode → allows anything
- No validation at API boundary → invalid data propagates deep into system

## Quick reference
```
OpenAPI: express-openapi-validator for auto request/response validation
Zod: TypeScript-first, .parse() throws, .safeParse() returns result
JSON Schema: language-agnostic, AJV for JavaScript validation
Validate at boundary: request in, response out
Dev vs prod: strict response validation in dev, log-only in prod
Type inference: z.infer<typeof Schema> for TypeScript types
```
