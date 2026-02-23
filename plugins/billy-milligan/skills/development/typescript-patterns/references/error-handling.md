# Error Handling

## Result Type

```typescript
// Explicit error handling — caller CANNOT ignore errors
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

// Constructors
const Ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// Domain error types — typed, not just strings
type OrderError =
  | { code: 'NOT_FOUND'; orderId: string }
  | { code: 'INSUFFICIENT_STOCK'; productId: string; available: number }
  | { code: 'PAYMENT_FAILED'; reason: string; retryable: boolean };

async function createOrder(input: CreateOrderInput): Promise<Result<Order, OrderError>> {
  const stock = await checkStock(input.items);
  if (!stock.sufficient) {
    return Err({
      code: 'INSUFFICIENT_STOCK',
      productId: stock.failedProduct,
      available: stock.available,
    });
  }

  const payment = await chargeCard(input.paymentMethodId, input.total);
  if (!payment.success) {
    return Err({
      code: 'PAYMENT_FAILED',
      reason: payment.error,
      retryable: payment.retryable,
    });
  }

  const order = await db.orders.create({ data: input });
  return Ok(order);
}

// Caller is FORCED to handle all cases
async function handleCreateOrder(input: CreateOrderInput) {
  const result = await createOrder(input);

  if (!result.ok) {
    switch (result.error.code) {
      case 'NOT_FOUND':
        return res.status(404).json({ error: result.error });
      case 'INSUFFICIENT_STOCK':
        return res.status(409).json({
          error: `Only ${result.error.available} available for ${result.error.productId}`,
        });
      case 'PAYMENT_FAILED':
        return res.status(402).json({ error: result.error.reason });
    }
  }

  return res.status(201).json(result.value);
}
```

## neverthrow Library

```typescript
import { ok, err, Result, ResultAsync } from 'neverthrow';

// Same pattern with utilities included
function divide(a: number, b: number): Result<number, 'DIVISION_BY_ZERO'> {
  if (b === 0) return err('DIVISION_BY_ZERO');
  return ok(a / b);
}

// Chaining — like Promise, but for errors
const result = divide(10, 2)
  .map((n) => n * 100)           // Transform value if ok
  .mapErr((e) => `Error: ${e}`); // Transform error if err

// ResultAsync — async operations
function fetchUser(id: string): ResultAsync<User, ApiError> {
  return ResultAsync.fromPromise(
    fetch(`/api/users/${id}`).then((r) => r.json()),
    (error) => ({ code: 'FETCH_FAILED', cause: error })
  );
}

// Combine multiple Results
const combined = Result.combine([
  validateEmail(input.email),
  validatePassword(input.password),
  validateName(input.name),
]);
// combined is Result<[Email, Password, Name], ValidationError>
```

## Typed Error Classes

```typescript
// Base error with code and HTTP status
abstract class AppError extends Error {
  abstract readonly code: string;
  abstract readonly statusCode: number;
}

class NotFoundError extends AppError {
  readonly code = 'NOT_FOUND';
  readonly statusCode = 404;

  constructor(resource: string, id: string) {
    super(`${resource} ${id} not found`);
    this.name = 'NotFoundError';
  }
}

class ValidationError extends AppError {
  readonly code = 'VALIDATION_ERROR';
  readonly statusCode = 400;

  constructor(
    message: string,
    readonly fields: Record<string, string[]>,
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}

class ConflictError extends AppError {
  readonly code = 'CONFLICT';
  readonly statusCode = 409;

  constructor(message: string) {
    super(message);
    this.name = 'ConflictError';
  }
}

// Type-safe error handler
function handleError(err: unknown, res: Response) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: { code: err.code, message: err.message },
    });
  }
  // Unknown error — log and return 500
  logger.error({ err }, 'Unhandled error');
  res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Unexpected error' } });
}
```

## When to Use Each Pattern

```
Result type:
  - Domain operations with expected failure modes
  - When caller must handle each error type differently
  - Functional pipelines with map/flatMap

Typed error classes:
  - HTTP APIs with status code mapping
  - Error middleware that maps errors to responses
  - When you need instanceof checking

neverthrow:
  - Teams that prefer Railway-oriented programming
  - Complex chains of operations with error handling
  - When you want compile-time exhaustive error checking
```

## Anti-Patterns
- `catch (e) {}` — swallowing errors silently; at minimum log
- `throw new Error('...')` for expected conditions — use Result type
- Untyped catch: `catch (e: any)` — use `unknown` and narrow
- Returning `null` for errors — caller doesn't know what failed or why

## Quick Reference
```
Result<T,E>: { ok: true; value: T } | { ok: false; error: E }
Ok(value): create success result
Err(error): create failure result
neverthrow: ok/err + .map/.mapErr/.andThen chaining
Typed errors: extends AppError with code + statusCode
catch unknown: always catch as unknown, narrow with instanceof
Exhaustive switch: default: assertNever(x) — compile-time guarantee
```
