# CI/CD Migrations and Database Testing

## When to load
Load when integrating schema migrations into CI/CD pipelines, running database tests in CI with Testcontainers, setting up Docker Compose for local development, or testing failover with chaos engineering tools.

## Schema Migration in CI/CD

### GitHub Actions Pipeline
```yaml
name: Database Migration
on:
  push:
    paths:
      - 'migrations/**'
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate migrations
        run: |
          flyway info -url=${{ secrets.STAGING_DB_URL }}
          flyway validate -url=${{ secrets.STAGING_DB_URL }}

      - name: Lint migrations (Atlas)
        run: |
          atlas migrate lint \
              --dir "file://migrations" \
              --dev-url "docker://postgres/16" \
              --latest 1

      - name: Apply to staging
        run: flyway migrate -url=${{ secrets.STAGING_DB_URL }}

      - name: Run integration tests
        run: pytest tests/integration/ --db-url=${{ secrets.STAGING_DB_URL }}

      - name: Apply to production
        if: github.ref == 'refs/heads/main'
        run: flyway migrate -url=${{ secrets.PROD_DB_URL }}
        environment: production
```

## Database Testing with Testcontainers

### TypeScript / Node.js
```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';

describe('Database tests', () => {
    let container;
    let connectionString;

    beforeAll(async () => {
        container = await new PostgreSqlContainer('postgres:16')
            .withDatabase('testdb')
            .withUsername('test')
            .withPassword('test')
            .start();
        connectionString = container.getConnectionUri();
        await runMigrations(connectionString);
    });

    afterAll(async () => {
        await container.stop();
    });

    it('should insert and query orders', async () => {
        const db = connectToDb(connectionString);
        await db.insert('orders', { customer_id: 1, total: 100 });
        const result = await db.query('SELECT * FROM orders');
        expect(result.length).toBe(1);
    });
});
```

### Python
```python
import testcontainers.postgres

def test_database():
    with PostgresContainer("postgres:16") as postgres:
        engine = create_engine(postgres.get_connection_url())
        # Run migrations and tests...
```

## Docker Compose for Local Development
```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: app
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d myapp"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru

volumes:
  pgdata:
```

## Chaos Engineering for Databases

### Failure Scenarios

| Scenario | Tool | What It Tests |
|----------|------|--------------|
| Kill primary | `docker stop`, `kill -9` | Failover speed, data loss (RPO) |
| Network partition | `tc`, Toxiproxy, Pumba | Split-brain handling, quorum |
| Slow I/O | `tc netem`, Toxiproxy | Query timeouts, connection handling |
| Disk full | `fallocate` | Graceful degradation, alerting |
| High latency | Toxiproxy | Application timeout handling |

### Toxiproxy
```bash
toxiproxy-cli create postgres_proxy -l 0.0.0.0:5433 -u postgres-primary:5432
toxiproxy-cli toxic add postgres_proxy -t latency -a latency=500 -a jitter=100
toxiproxy-cli toxic add postgres_proxy -t reset_peer -a timeout=5000
toxiproxy-cli toxic remove postgres_proxy -n latency_downstream
```
