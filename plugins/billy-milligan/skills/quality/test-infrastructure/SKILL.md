---
name: test-infrastructure
description: |
  Test infrastructure: Testcontainers with real PostgreSQL (60s timeout), parallel test
  isolation (per-worker schema), flaky test quarantine, test data seeding patterns,
  ephemeral test databases, CI database setup. Use when setting up database testing,
  managing test isolation, improving CI test reliability.
allowed-tools: Read, Grep, Glob
---

# Test Infrastructure

## When to Use This Skill
- Setting up database tests with real PostgreSQL (not mocks)
- Isolating tests that run in parallel
- Managing test data with factories and seeds
- Handling flaky tests in CI
- Testcontainers for integration tests

## Core Principles

1. **Real database over mocks** — SQLite for tests when you use PostgreSQL in prod = false confidence
2. **Parallel isolation via schemas** — each worker gets its own schema, no shared state
3. **Deterministic test data** — use factories, not shared fixtures that accumulate side effects
4. **Flaky tests: quarantine immediately** — don't let them degrade CI trust
5. **Fast teardown** — truncate tables, not DROP/CREATE (seconds vs minutes)

---

## Patterns ✅

### Testcontainers for Integration Tests

```typescript
// src/test/database.ts — shared test database setup
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { migrate } from 'drizzle-orm/node-postgres/migrator';

let container: StartedPostgreSqlContainer;
let pool: Pool;

// Start container once for entire test file
beforeAll(async () => {
  container = await new PostgreSqlContainer('postgres:16-alpine')
    .withDatabase('testdb')
    .withUsername('test')
    .withPassword('test')
    .withStartupTimeout(60_000)  // 60s timeout — Docker pull can be slow
    .start();

  pool = new Pool({
    host: container.getHost(),
    port: container.getMappedPort(5432),
    database: container.getDatabase(),
    user: container.getUsername(),
    password: container.getPassword(),
  });

  const db = drizzle(pool);
  await migrate(db, { migrationsFolder: './drizzle' });  // Run migrations
}, 90_000);  // 90s jest timeout for container start

afterAll(async () => {
  await pool.end();
  await container.stop();
});

// Truncate between tests (faster than DROP/CREATE)
beforeEach(async () => {
  await pool.query(`
    TRUNCATE TABLE order_items, orders, users, products
    RESTART IDENTITY CASCADE
  `);
});

export { pool };
```

### Per-Worker Schema Isolation (Parallel Tests)

```typescript
// vitest.config.ts — worker-based isolation
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'threads',
    poolOptions: {
      threads: {
        maxThreads: 4,
        // Each thread gets a unique worker ID
        useAtomics: true,
      },
    },
    globalSetup: './src/test/globalSetup.ts',
  },
});

// src/test/globalSetup.ts
export async function setup() {
  // Create schemas for each worker before tests start
  const pool = new Pool({ connectionString: process.env.TEST_DATABASE_URL });
  for (let i = 0; i < 4; i++) {
    await pool.query(`
      DROP SCHEMA IF EXISTS test_worker_${i} CASCADE;
      CREATE SCHEMA test_worker_${i};
    `);
  }
  await pool.end();
}

// src/test/db.ts — worker-specific schema
import { workerData } from 'worker_threads';

const workerId = workerData?.workerId ?? 0;
const schema = `test_worker_${workerId}`;

export const testPool = new Pool({
  connectionString: process.env.TEST_DATABASE_URL,
  // Set search_path to worker's schema
  options: `-c search_path=${schema}`,
});

export const db = drizzle(testPool, { schema: testSchema });
```

### Test Data Seeding

```typescript
// src/test/seeds/standardSeed.ts
import { db } from '../db';
import { userFactory, productFactory, orderFactory } from '../factories';

export async function seedStandardData() {
  const users = await Promise.all([
    db.insert(users).values(userFactory.build({ role: 'admin' })).returning().then(r => r[0]),
    db.insert(users).values(userFactory.build({ role: 'customer' })).returning().then(r => r[0]),
  ]);

  const products = await db.insert(products)
    .values(productFactory.buildList(5))
    .returning();

  return { users, products };
}

// Use in tests
describe('OrderService', () => {
  let testData: Awaited<ReturnType<typeof seedStandardData>>;

  beforeEach(async () => {
    await truncateAll();
    testData = await seedStandardData();  // Fresh data for each test
  });

  it('should create order for customer', async () => {
    const { users, products } = testData;
    const customer = users.find(u => u.role === 'customer')!;

    const order = await orderService.create({
      userId: customer.id,
      items: [{ productId: products[0].id, quantity: 2 }],
    });

    expect(order.userId).toBe(customer.id);
  });
});
```

### Flaky Test Quarantine Process

```typescript
// Step 1: Identify flaky test — fails intermittently in CI

// Step 2: Quarantine immediately — don't let it block other developers
it.skip('should process payment with retry on timeout — QUARANTINED FLAKY TEST', async () => {
  // Original test that's intermittently failing
  // Flaky because: relies on timing, external service, or shared state
});

// Step 3: Create tracking issue — in Jira/GitHub
// Title: "[FLAKY] OrderService: should process payment with retry on timeout"
// Labels: flaky-test, p2
// Due: within 1 week

// Step 4: Fix the test or delete it
// Option A: Fix root cause (timing, isolation, cleanup)
it('should process payment with retry on timeout', async () => {
  // Deterministic: mock the timeout, don't rely on real timing
  vi.useFakeTimers();
  // ...
  vi.useRealTimers();
});

// Option B: If test is low-value and hard to fix, delete it
// Don't keep skipped tests indefinitely — they rot and mislead
```

### CI Database Setup (GitHub Actions)

```yaml
# For GitHub Actions — use service containers instead of Testcontainers
# Faster in CI (pre-pulled images), no Docker-in-Docker needed

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 10
        ports:
          - 5432:5432
      redis:
        image: redis:7
        options: --health-cmd "redis-cli ping"
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4
      - name: Setup schema
        run: |
          psql postgresql://test:test@localhost/testdb -c "
            CREATE SCHEMA IF NOT EXISTS test_worker_0;
            CREATE SCHEMA IF NOT EXISTS test_worker_1;
            CREATE SCHEMA IF NOT EXISTS test_worker_2;
            CREATE SCHEMA IF NOT EXISTS test_worker_3;
          "
      - name: Run migrations
        run: pnpm db:migrate
        env:
          DATABASE_URL: postgresql://test:test@localhost/testdb
      - name: Run tests
        run: pnpm test:integration
        env:
          TEST_DATABASE_URL: postgresql://test:test@localhost/testdb
```

---

## Anti-Patterns ❌

### Shared Mutable Database State
**What it is**: All tests using the same database rows, modifying and reading each other's data.
**What breaks**: Test A creates user → Test B expects no users → Test B fails because A's user exists. Test order matters. Parallel execution is impossible.
**Fix**: Truncate before each test, or per-worker schemas, or test-scoped transactions.

### Using SQLite for PostgreSQL Integration Tests
**What it is**: "SQLite is faster and doesn't need Docker."
**What breaks**: PostgreSQL-specific features (JSONB, arrays, CTEs, window functions, RLS) don't exist in SQLite. Tests pass against SQLite, fail in production against PostgreSQL.
**Fix**: Testcontainers with real PostgreSQL. CI service containers. No SQLite for apps that use PostgreSQL.

### Leaving Quarantined Tests for Weeks
**What it is**: `it.skip('flaky test', ...)` added and forgotten.
**What breaks**: Skipped tests don't run. Coverage decreases. Tests become dead code. Next sprint nobody remembers why it was skipped.
**Fix**: Quarantine = immediate skip + ticket with 1-week due date. At 1 week: fix or delete.

---

## Quick Reference

```
Testcontainers startup timeout: 60000ms (image pull can be slow)
Jest/Vitest timeout for Testcontainers: 90000ms (beforeAll)
Truncate vs DROP: TRUNCATE RESTART IDENTITY CASCADE — seconds, not minutes
Per-worker isolation: schema per workerId — search_path in connection options
CI: service containers are faster than Testcontainers in CI (no Docker-in-Docker)
Flaky quarantine: it.skip immediately → ticket → fix within 1 week
Test data: factories with beforeEach seed — not shared module-level fixtures
```
