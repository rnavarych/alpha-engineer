# Runtime Validation

## Zod — Schema-First Validation

```typescript
import { z } from 'zod';

// Schema = single source of truth for validation AND TypeScript type
const CreateOrderSchema = z.object({
  customerId: z.string().uuid(),
  items: z.array(z.object({
    productId: z.string().uuid(),
    quantity: z.number().int().min(1).max(100),
    price: z.number().positive(),
  })).min(1, 'At least one item required'),
  couponCode: z.string().optional(),
  notes: z.string().max(500).optional(),
});

// Infer type — no duplicate type definition
type CreateOrderInput = z.infer<typeof CreateOrderSchema>;

// Parse (throws ZodError if invalid)
const input = CreateOrderSchema.parse(requestBody);

// SafeParse (returns result object)
const result = CreateOrderSchema.safeParse(requestBody);
if (!result.success) {
  console.error(result.error.flatten().fieldErrors);
  // { customerId: ["Invalid uuid"], items: ["Required"] }
} else {
  const data = result.data; // Typed as CreateOrderInput
}
```

## Zod Advanced Patterns

```typescript
// Transforms — coerce and transform during validation
const EnvSchema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535),
  DEBUG: z.string().transform((s) => s === 'true'),
  ALLOWED_ORIGINS: z.string().transform((s) => s.split(',')),
  DATABASE_URL: z.string().url(),
});

// Discriminated unions — different shapes based on type field
const NotificationSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('email'), to: z.string().email(), subject: z.string() }),
  z.object({ type: z.literal('sms'), phone: z.string(), message: z.string() }),
  z.object({ type: z.literal('push'), deviceId: z.string(), title: z.string() }),
]);

// Refine — custom validation logic
const DateRangeSchema = z.object({
  startDate: z.coerce.date(),
  endDate: z.coerce.date(),
}).refine(
  (data) => data.endDate > data.startDate,
  { message: 'End date must be after start date', path: ['endDate'] }
);

// Extend / merge schemas
const BaseUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
});
const AdminSchema = BaseUserSchema.extend({
  role: z.literal('admin'),
  permissions: z.array(z.string()),
});

// Partial / pick for update operations
const UpdateUserSchema = BaseUserSchema.partial(); // All fields optional
const LoginSchema = BaseUserSchema.pick({ email: true }); // Only email
```

## Valibot — Lightweight Alternative

```typescript
import * as v from 'valibot';

// ~5KB vs Zod ~14KB — tree-shakeable
const CreateOrderSchema = v.object({
  customerId: v.pipe(v.string(), v.uuid()),
  items: v.pipe(
    v.array(v.object({
      productId: v.pipe(v.string(), v.uuid()),
      quantity: v.pipe(v.number(), v.integer(), v.minValue(1), v.maxValue(100)),
    })),
    v.minLength(1)
  ),
  notes: v.optional(v.pipe(v.string(), v.maxLength(500))),
});

type CreateOrderInput = v.InferOutput<typeof CreateOrderSchema>;

// Parse
const result = v.safeParse(CreateOrderSchema, requestBody);
if (result.success) {
  const data = result.output;
}
```

## API Response Validation

```typescript
// Validate external API responses — don't trust third parties
const ExternalOrderSchema = z.object({
  id: z.string(),
  amount: z.number(),
  currency: z.string().length(3),
  status: z.enum(['pending', 'paid', 'refunded']),
  metadata: z.record(z.unknown()).optional(),
});

async function fetchExternalOrder(id: string) {
  const response = await fetch(`${PARTNER_API}/orders/${id}`);
  const json = await response.json();

  // Validate — catches API contract changes at runtime
  const result = ExternalOrderSchema.safeParse(json);
  if (!result.success) {
    logger.error({ errors: result.error.issues }, 'External API contract violation');
    throw new ExternalAPIError('Invalid response from partner');
  }
  return result.data;
}
```

## Anti-Patterns
- `as` type assertion without runtime check — crashes at runtime
- `any` type — defeats TypeScript, propagates to everything it touches
- Duplicate types alongside Zod schemas — they drift apart
- No validation on external API responses — contract changes silently break you

## Quick Reference
```
Zod: z.object().parse() / .safeParse() — throws or returns result
Type inference: z.infer<typeof Schema> — no duplicate types
Transforms: z.coerce.number(), .transform() — parse and convert
Discriminated: z.discriminatedUnion('type', [...]) — tagged unions
Refine: .refine(fn, msg) — custom cross-field validation
Valibot: v.object(), v.safeParse() — 5KB tree-shakeable alternative
Always validate: request bodies, env vars, external API responses
```
