# Test Data Isolation

## When to load
Load when dealing with test data pollution between tests, setting up database cleanup strategies,
running tests in parallel, or diagnosing inter-test state contamination.

## Database Factories (Persist to DB)

```typescript
// src/test/factories/db.factory.ts — factories that INSERT into real test DB
import { db } from '../db';
import { userFactory, orderFactory } from './';

export const createUser = async (overrides: Partial<User> = {}): Promise<User> => {
  const data = userFactory.build(overrides);
  const [user] = await db.insert(users).values(data).returning();
  return user;
};

export const createOrder = async (
  overrides: Partial<Order> = {},
  options: { userId?: string } = {}
): Promise<Order> => {
  const userId = options.userId ?? (await createUser()).id;
  const data = orderFactory.build({ ...overrides, userId });
  const [order] = await db.insert(orders).values({
    id: data.id,
    userId: data.userId,
    status: data.status,
    total: data.total,
  }).returning();

  if (data.items.length > 0) {
    await db.insert(orderItems).values(
      data.items.map(item => ({ ...item, orderId: order.id }))
    );
  }

  return order;
};

// Usage in integration test
describe('OrderService', () => {
  it('should cancel pending order and restore inventory', async () => {
    const user = await createUser();
    const order = await createOrder({ status: 'pending' }, { userId: user.id });

    await orderService.cancel(order.id);

    const updated = await db.query.orders.findFirst({ where: eq(orders.id, order.id) });
    expect(updated!.status).toBe('cancelled');
  });
});
```

## Cleanup Strategies

### Strategy 1: Truncate before each test (recommended for most cases)

```typescript
// src/test/setup.ts
beforeEach(async () => {
  // Order matters: truncate child tables before parent tables
  await db.execute(sql`
    TRUNCATE TABLE order_items, orders, products, users
    RESTART IDENTITY CASCADE
  `);
});
```

Use when:
- Tests run sequentially or in a shared schema
- You want a clean slate regardless of what previous tests inserted
- Your factories insert top-level records that other tests would collide with

### Strategy 2: Database transaction rollback (fastest, but limited)

```typescript
// Each test runs inside a transaction that's rolled back
// Works only if your code doesn't use transactions internally
let tx: Transaction;

beforeEach(async () => {
  tx = await db.transaction();
  vi.spyOn(db, 'transaction').mockReturnValue(tx);
});

afterEach(async () => {
  await tx.rollback();
});
```

Use when:
- Test suite is large and truncate is too slow
- Your production code does NOT use nested transactions
- You need sub-millisecond cleanup overhead

Limitation: breaks if your service code opens its own transaction — you can't nest a real
transaction inside the test transaction.

### Strategy 3: Per-worker isolated schema (best for parallel tests)

```typescript
// Each worker gets its own schema — no inter-test cleanup needed
// Vitest assigns a unique VITEST_WORKER_ID per parallel worker
const schema = `test_worker_${process.env.VITEST_WORKER_ID ?? 0}`;

// src/test/setup.ts — run once per worker
beforeAll(async () => {
  await db.execute(sql`CREATE SCHEMA IF NOT EXISTS ${sql.identifier(schema)}`);
  await db.execute(sql`SET search_path TO ${sql.identifier(schema)}`);
  await runMigrations(schema);
});

afterAll(async () => {
  await db.execute(sql`DROP SCHEMA ${sql.identifier(schema)} CASCADE`);
});
```

Use when:
- Tests run with `--pool=threads` or `--pool=forks` in Vitest
- Multiple workers insert conflicting IDs or unique-constrained data
- You want true parallelism without test order dependencies

## Parallel Test Isolation Rules

```
Rule 1: Never share mutable DB state between workers
  Bad:  global beforeAll that inserts shared seed data
  Good: each worker creates its own data via factories

Rule 2: Use VITEST_WORKER_ID for any shared external resource
  Bad:  all workers write to Redis key "test:queue"
  Good: key = `test:queue:${process.env.VITEST_WORKER_ID}`

Rule 3: Per-worker schema > per-test truncate for parallel suites
  Truncate serializes on the table lock. Schema isolation is fully parallel.

Rule 4: File system artifacts need worker-scoped paths
  Bad:  write to /tmp/test-upload.jpg in every test
  Good: /tmp/test-upload-${workerId}-${testId}.jpg
```

## Quick reference

```
DB cleanup order    : TRUNCATE child tables before parent tables, RESTART IDENTITY CASCADE
Transaction rollback: fast but breaks when code uses its own transactions
Parallel isolation  : per-worker schemas via VITEST_WORKER_ID — no shared state
Redis in parallel   : scope keys with worker ID to prevent cross-worker collisions
Factories           : see test-data-management.md for factory setup and Faker seeding
```
