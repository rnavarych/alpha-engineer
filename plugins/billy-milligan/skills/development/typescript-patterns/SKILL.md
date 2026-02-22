---
name: typescript-patterns
description: |
  TypeScript patterns: discriminated unions (Result type), generic utilities, Zod+TypeScript
  integration, type guards, strict tsconfig, utility types cheat sheet, branded types,
  satisfies operator, const assertions. Use when writing TypeScript, fixing type errors,
  designing type-safe APIs.
allowed-tools: Read, Grep, Glob
---

# TypeScript Patterns

## When to Use This Skill
- Designing type-safe APIs and domain models
- Implementing error handling without exceptions (Result type)
- Writing reusable generic utilities
- Fixing complex TypeScript errors
- Setting up strict TypeScript configuration

## Core Principles

1. **Strict mode always** — `strict: true` catches entire classes of bugs at compile time
2. **Discriminated unions over exceptions** — `Result<T, E>` is explicit; `throw` is invisible
3. **Branded types prevent mix-ups** — `UserId` and `OrderId` should not be interchangeable
4. **Zod is the bridge** — runtime validation + TypeScript types from one source of truth
5. **`satisfies` over `as`** — `satisfies` validates without widening the type

---

## Patterns ✅

### Strict TypeScript Configuration

```json
// tsconfig.json — use strict mode, no exceptions
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,              // Enables all strict checks
    "noUncheckedIndexedAccess": true,  // arr[0] is T | undefined, not T
    "exactOptionalPropertyTypes": true, // { a?: string } !== { a: string | undefined }
    "noImplicitReturns": true,   // Function must return in all branches
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

### Result Type (No Exceptions)

```typescript
// Explicit error handling — caller cannot ignore errors

type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

// Constructor helpers
const Ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// Usage in domain functions
type DatabaseError = { code: 'DB_ERROR'; message: string };
type NotFoundError = { code: 'NOT_FOUND'; message: string };

async function findOrder(id: string): Promise<Result<Order, NotFoundError | DatabaseError>> {
  try {
    const order = await db.orders.findUnique({ where: { id } });
    if (!order) return Err({ code: 'NOT_FOUND', message: `Order ${id} not found` });
    return Ok(order);
  } catch (err) {
    return Err({ code: 'DB_ERROR', message: String(err) });
  }
}

// Caller is FORCED to handle both cases
async function handleOrderRequest(id: string) {
  const result = await findOrder(id);

  if (!result.ok) {
    // TypeScript knows result.error type here
    switch (result.error.code) {
      case 'NOT_FOUND': return res.status(404).json({ error: result.error.message });
      case 'DB_ERROR': return res.status(500).json({ error: 'Database error' });
    }
  }

  // TypeScript knows result.value is Order here
  return res.json(result.value);
}
```

### Discriminated Unions

```typescript
// Model domain states as discriminated unions
type PaymentState =
  | { status: 'pending'; initiatedAt: Date }
  | { status: 'processing'; processorId: string; startedAt: Date }
  | { status: 'succeeded'; chargeId: string; amount: number; succeededAt: Date }
  | { status: 'failed'; reason: string; failedAt: Date; retryable: boolean };

function describePayment(payment: PaymentState): string {
  switch (payment.status) {
    case 'pending':    return `Initiated at ${payment.initiatedAt}`;
    case 'processing': return `Processing with ${payment.processorId}`;
    case 'succeeded':  return `Charged ${payment.amount} (${payment.chargeId})`;
    case 'failed':     return `Failed: ${payment.reason} (retryable: ${payment.retryable})`;
    // TypeScript enforces exhaustive check — forgetting a case is a compile error
  }
}

// Exhaustive check helper
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${JSON.stringify(x)}`);
}
```

### Branded Types

```typescript
// Prevent mixing up IDs of different types
type Brand<T, B extends string> = T & { readonly __brand: B };

type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;
type TenantId = Brand<string, 'TenantId'>;

// Constructors with validation
function UserId(id: string): UserId {
  if (!id.startsWith('usr_')) throw new Error(`Invalid UserId: ${id}`);
  return id as UserId;
}

function OrderId(id: string): OrderId {
  if (!id.startsWith('ord_')) throw new Error(`Invalid OrderId: ${id}`);
  return id as OrderId;
}

// Functions with branded types — TypeScript prevents mix-ups at compile time
async function getOrder(orderId: OrderId): Promise<Order> { /* ... */ }
async function getUser(userId: UserId): Promise<User> { /* ... */ }

const userId = UserId('usr_123');
const orderId = OrderId('ord_456');

getOrder(userId);  // TypeScript error: Argument of type 'UserId' is not assignable to 'OrderId'
getUser(orderId);  // TypeScript error: same
getOrder(orderId); // OK
```

### Zod + TypeScript Integration

```typescript
import { z } from 'zod';

// Schema is the single source of truth for both validation AND type
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

// TypeScript type inferred from schema — no duplicate type definition
type CreateOrderInput = z.infer<typeof CreateOrderSchema>;

// Runtime validation
function parseCreateOrder(data: unknown): CreateOrderInput {
  return CreateOrderSchema.parse(data);  // Throws ZodError if invalid
}

// Safe parse (no throw)
function tryParseCreateOrder(data: unknown): Result<CreateOrderInput, z.ZodError> {
  const result = CreateOrderSchema.safeParse(data);
  return result.success ? Ok(result.data) : Err(result.error);
}
```

### `satisfies` Operator

```typescript
// satisfies validates without widening the type
// as would widen to the specified type, losing specificity

const config = {
  database: { host: 'localhost', port: 5432 },
  redis: { host: 'localhost', port: 6379 },
} satisfies Record<string, { host: string; port: number }>;

// config.database.port is number (not widened to string | number)
// `as` would lose the specific type information

// Use for route definitions
const routes = {
  home: '/',
  about: '/about',
  orders: '/orders/:id',
} satisfies Record<string, `/${string}`>;
// TypeScript validates all values match the pattern
```

### Utility Types Cheat Sheet

```typescript
// Built-in utility types
type ReadonlyOrder = Readonly<Order>;                          // All fields readonly
type PartialOrder = Partial<Order>;                           // All fields optional
type RequiredOrder = Required<Order>;                         // All fields required
type PickedOrder = Pick<Order, 'id' | 'status' | 'total'>;  // Only specified fields
type OmittedOrder = Omit<Order, 'internalNotes'>;            // All except specified
type RecordMap = Record<string, Order>;                       // Dictionary type

// Extract and Exclude
type Status = 'pending' | 'active' | 'cancelled' | 'completed';
type ActiveStatus = Extract<Status, 'active' | 'completed'>;   // 'active' | 'completed'
type InactiveStatus = Exclude<Status, 'active'>;               // 'pending' | 'cancelled' | 'completed'

// Function types
type AsyncFn<T> = () => Promise<T>;
type Awaited<T> = T extends Promise<infer R> ? R : T;         // Unwrap promise
type Parameters<T extends (...args: any) => any> = ...;        // Extract function params
type ReturnType<T extends (...args: any) => any> = ...;        // Extract return type
```

---

## Anti-Patterns ❌

### `any` Type Usage
**What it is**: `const data: any = await fetchSomething()`
**What breaks**: TypeScript cannot catch any type errors on `data`. Defeats the entire purpose of TypeScript. Often spreads — `any` infects everything it touches.
**Fix**: `unknown` instead of `any`. Then narrow with type guards or Zod parsing.

### Type Assertions (`as`) Without Validation
**What it is**: `const order = data as Order` — no runtime check.
**What breaks**: If `data` doesn't actually match `Order` structure, TypeScript thinks it does. Runtime errors when accessing non-existent fields.
**Fix**: Zod `.parse()` for runtime validation + type inference, or type guards.

### Ignoring Strict Null Checks
**What it is**: `strict: false` or `strictNullChecks: false` in tsconfig.
**What breaks**: Every value can be `null | undefined` without TypeScript catching it. Classic "Cannot read property 'x' of undefined" at runtime.
**Fix**: `strict: true` from the start. Retrofit is painful but worth it.

---

## Quick Reference

```
Result type: { ok: true; value: T } | { ok: false; error: E }
Discriminated union: shared literal field (status, type, kind)
Branded types: T & { __brand: 'Name' } — prevents ID mix-ups
Zod inference: type T = z.infer<typeof schema>
satisfies vs as: satisfies validates, as silences (prefer satisfies)
noUncheckedIndexedAccess: arr[0] is T | undefined — forces null check
tsconfig must-haves: strict, noUncheckedIndexedAccess, noImplicitReturns
```
