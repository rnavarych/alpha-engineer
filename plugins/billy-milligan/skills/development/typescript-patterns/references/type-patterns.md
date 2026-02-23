# Type Patterns

## Discriminated Unions

```typescript
// Model domain states — each variant has exactly the fields it needs
type PaymentState =
  | { status: 'pending'; initiatedAt: Date }
  | { status: 'processing'; processorId: string; startedAt: Date }
  | { status: 'succeeded'; chargeId: string; amount: number; succeededAt: Date }
  | { status: 'failed'; reason: string; failedAt: Date; retryable: boolean };

function describePayment(payment: PaymentState): string {
  switch (payment.status) {
    case 'pending':    return `Initiated at ${payment.initiatedAt}`;
    case 'processing': return `Processing via ${payment.processorId}`;
    case 'succeeded':  return `Charged ${payment.amount} (${payment.chargeId})`;
    case 'failed':     return `Failed: ${payment.reason}`;
    // TypeScript enforces exhaustive check — missing case = compile error
  }
}

// Exhaustive check helper
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${JSON.stringify(x)}`);
}
```

## Branded Types

```typescript
// Prevent mixing up IDs of different entity types
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

// Compile-time safety
async function getOrder(orderId: OrderId): Promise<Order> { /* ... */ }

const userId = UserId('usr_123');
const orderId = OrderId('ord_456');
getOrder(userId);  // Compile error: UserId not assignable to OrderId
getOrder(orderId); // OK
```

## Template Literal Types

```typescript
// Type-safe event names
type Entity = 'user' | 'order' | 'product';
type Action = 'created' | 'updated' | 'deleted';
type EventName = `${Entity}.${Action}`;
// = 'user.created' | 'user.updated' | ... | 'product.deleted'

function emit(event: EventName, payload: unknown): void { /* ... */ }
emit('user.created', { id: '123' });  // OK
emit('user.moved', {});               // Compile error

// Type-safe CSS units
type CSSUnit = `${number}${'px' | 'rem' | 'em' | '%' | 'vh' | 'vw'}`;
function setWidth(width: CSSUnit): void { /* ... */ }
setWidth('100px');  // OK
setWidth('50');     // Compile error
```

## Conditional Types

```typescript
// Extract promise inner type
type Awaited<T> = T extends Promise<infer R> ? Awaited<R> : T;
type A = Awaited<Promise<Promise<string>>>;  // string

// Make specific fields required
type RequireFields<T, K extends keyof T> = T & Required<Pick<T, K>>;
type OrderWithUser = RequireFields<Order, 'userId' | 'userEmail'>;

// Infer function return type from arguments
type InferReturn<T> = T extends (...args: any[]) => infer R ? R : never;
```

## Mapped Types

```typescript
// Make all fields nullable
type Nullable<T> = { [K in keyof T]: T[K] | null };

// Create update type — all fields optional except id
type Updatable<T extends { id: string }> = Pick<T, 'id'> & Partial<Omit<T, 'id'>>;
type OrderUpdate = Updatable<Order>;
// { id: string; status?: string; total?: number; ... }

// Create readonly version
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};
```

## satisfies Operator

```typescript
// Validates type WITHOUT widening — preserves literal types
const routes = {
  home: '/',
  about: '/about',
  orders: '/orders/:id',
} satisfies Record<string, `/${string}`>;

// routes.home is '/' (literal), not string
// With `as` it would be string (widened)

const config = {
  database: { host: 'localhost', port: 5432 },
  redis: { host: 'localhost', port: 6379 },
} satisfies Record<string, { host: string; port: number }>;
// config.database.port is number, type-checked against the constraint
```

## Quick Reference
```
Discriminated union: shared literal discriminant (status, type, kind)
Branded types: T & { __brand: B } — prevents ID mix-ups at compile time
Template literals: `${A}.${B}` — type-safe string patterns
Conditional types: T extends X ? Y : Z — type-level branching
Mapped types: { [K in keyof T]: ... } — transform type shapes
satisfies: validates without widening (prefer over as)
infer: extract types from generics — infer R in T extends Promise<infer R>
assertNever: exhaustive check at compile time + runtime safety
```
