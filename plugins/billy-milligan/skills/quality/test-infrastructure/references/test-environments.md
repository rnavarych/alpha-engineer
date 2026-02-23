# Test Environments

## When to load
Load when setting up test databases, Docker Compose for tests, Testcontainers, ephemeral environments.

## Testcontainers (per-test real database)

```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';

let container: StartedPostgreSqlContainer;

beforeAll(async () => {
  container = await new PostgreSqlContainer('postgres:16')
    .withDatabase('testdb')
    .withUsername('test')
    .withPassword('test')
    .start();

  process.env.DATABASE_URL = container.getConnectionUri();
  await runMigrations();  // Apply schema
}, 60_000);

afterAll(async () => {
  await container.stop();
});

// Per-test isolation: transaction rollback
beforeEach(() => db.query('BEGIN'));
afterEach(() => db.query('ROLLBACK'));
```

## Docker Compose for Integration Tests

```yaml
# docker-compose.test.yml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: testdb
      POSTGRES_PASSWORD: test
    ports: ["5433:5432"]  # Different port to avoid conflicts
    tmpfs: /var/lib/postgresql/data  # RAM disk = faster

  redis:
    image: redis:7-alpine
    ports: ["6380:6379"]

  localstack:  # AWS services mock
    image: localstack/localstack
    ports: ["4566:4566"]
    environment:
      SERVICES: s3,sqs,ses
```

```bash
# Start test dependencies
docker compose -f docker-compose.test.yml up -d

# Run tests
DATABASE_URL=postgres://test:test@localhost:5433/testdb \
REDIS_URL=redis://localhost:6380 \
npm test

# Teardown
docker compose -f docker-compose.test.yml down -v
```

## Per-Worker Schema Isolation

```typescript
// For parallel test workers sharing one DB
const workerId = process.env.VITEST_POOL_ID ?? '1';
const schema = `test_worker_${workerId}`;

beforeAll(async () => {
  await db.query(`CREATE SCHEMA IF NOT EXISTS ${schema}`);
  await db.query(`SET search_path TO ${schema}`);
  await runMigrations();
});

afterAll(async () => {
  await db.query(`DROP SCHEMA ${schema} CASCADE`);
});
```

## Anti-patterns
- Shared test database → tests interfere, order-dependent
- tmpdir without cleanup → disk fills up in CI
- No container health check → tests start before DB is ready
- Using production-like instance sizes → slow startup, expensive

## Quick reference
```
Testcontainers: real DB per test suite, auto-cleanup
Docker Compose: multi-service test stack, tmpfs for speed
Isolation: transaction rollback per test, or per-worker schemas
Health: wait for container readyness before running tests
Port conflicts: use non-standard ports (5433, 6380)
Speed: tmpfs for DB data, parallel workers with schema isolation
CI: docker compose up -d → test → down -v
```
