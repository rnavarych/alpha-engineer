# Mocking Strategies

## When to load
Load when deciding what to mock, choosing test doubles, or structuring dependency injection for testing.

## Test Doubles Taxonomy

```
Dummy    → passed but never used (fills parameter list)
Stub     → returns hardcoded values (no verification)
Spy      → records calls for later verification
Mock     → pre-programmed with expectations, verifies calls
Fake     → working implementation (in-memory DB, fake API)

Rule: Use the simplest double that satisfies the test.
```

## When to Mock

```
Mock:
  ✅ External APIs (HTTP, gRPC)
  ✅ Databases (in unit tests)
  ✅ File system / network
  ✅ Time (Date.now, setTimeout)
  ✅ Random (Math.random, crypto)

Don't Mock:
  ❌ The module under test
  ❌ Data transformations (pure functions)
  ❌ Value objects / DTOs
  ❌ Standard library (Array, Map)
  ❌ Everything — if everything is mocked, you're testing the mocks
```

## Dependency Injection for Testability

```typescript
// BAD: hard to test — creates its own dependency
class OrderService {
  private db = new PostgresClient();
  async create(input: CreateOrderInput) { /* uses this.db */ }
}

// GOOD: inject dependency — easy to mock
class OrderService {
  constructor(private db: DatabaseClient) {}
  async create(input: CreateOrderInput) { /* uses this.db */ }
}

// Test
const mockDb = mock<DatabaseClient>();
const service = new OrderService(mockDb);
```

## Module Mocking

```typescript
// Mock entire module
vi.mock('./email-service', () => ({
  sendEmail: vi.fn().mockResolvedValue({ messageId: '123' }),
}));

// Partial mock — keep real implementations, override specific exports
vi.mock('./utils', async () => {
  const actual = await vi.importActual('./utils');
  return { ...actual, generateId: vi.fn(() => 'fixed-id') };
});

// Spy on method without replacing
const spy = vi.spyOn(service, 'validate');
await service.create(input);
expect(spy).toHaveBeenCalledWith(input);
```

## Anti-patterns
- Mocking what you don't own without an adapter → test couples to third-party API shape
- Over-mocking → test passes but code is broken in production
- Mock returning mock → indicates poor design, refactor instead
- Not restoring mocks → test pollution across test files

## Quick reference
```
Simplest double: stub > spy > mock > fake
Mock externals: APIs, DB, filesystem, time, random
Don't mock: pure functions, value objects, standard lib
DI: inject dependencies, don't create them internally
vi.mock(): module-level mocking
vi.spyOn(): observe without replacing
afterEach: vi.restoreAllMocks() to prevent pollution
```
