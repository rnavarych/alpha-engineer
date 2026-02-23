# Migrations, Connection Pooling, and Read Replicas

## When to load
Load when writing or reviewing database migrations, configuring connection pools, or setting up read replica routing.

## Migration Best Practices

- Every schema change requires a migration file (never alter production manually)
- Migrations must be reversible — implement both `up` and `down` operations
- Name migrations descriptively: `20240115_add_email_verification_to_users`
- Test migrations against a copy of production data before deploying
- Never modify a migration that has been applied to any shared environment
- Use a separate migration for data backfills (not in schema migration)
- Run migrations in a transaction when the database supports transactional DDL (Postgres does)
- **Zero-downtime migration pattern**: add column nullable → backfill → add NOT NULL constraint → remove old column

### Alembic (Python async setup)

```python
# alembic/env.py
from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine

async def run_migrations_online():
    engine = create_async_engine(config.get_main_option("sqlalchemy.url"))
    async with engine.begin() as conn:
        await conn.run_sync(do_run_migrations)
```

## Connection Pooling

Always use connection pooling — never open/close connections per request.

| Stack | Configuration |
|-------|---------------|
| Node.js Prisma | `connection_limit` in connection string; Prisma Accelerate for serverless |
| Node.js Drizzle | `postgres-js` with `max` option or `pg-pool` |
| Python SQLAlchemy | `pool_size=20, max_overflow=10, pool_recycle=3600, pool_pre_ping=True` |
| Go GORM / sqlx | `db.SetMaxOpenConns(25); db.SetMaxIdleConns(10); db.SetConnMaxLifetime(5 * time.Minute)` |
| Java HikariCP | `maximumPoolSize=10, minimumIdle=5, connectionTimeout=30000, idleTimeout=600000` |
| Rust SQLx | `PgPoolOptions::new().max_connections(20).connect(url).await` |

Pool sizing formula: `(core_count * 2) + effective_spindle_count`

Monitor pool utilization; alert when waiting connections exceed threshold.

## Read Replicas

- Route read queries to replicas, write queries to primary
- Handle replication lag: use primary for reads-after-writes when consistency matters

| Stack | Approach |
|-------|----------|
| Prisma | `readReplicas` extension in datasources |
| SQLAlchemy | `engines` dict with `execution_options(postgresql_readonly=True)` |
| GORM | `plugin/dbresolver` with `Replica()` and `Sources()` |
| Spring | `AbstractRoutingDataSource` for read/write splitting |

## Query Optimization Rules

- Profile all queries with `EXPLAIN ANALYZE` before and after optimization
- Avoid N+1 queries: use eager loading (`include` in Prisma, `selectinload` in SQLAlchemy, `Preload` in GORM)
- Add indexes for columns in WHERE, JOIN, ORDER BY, and GROUP BY clauses
- Use composite indexes for multi-column filter patterns (leftmost prefix rule)
- Prefer `EXISTS` over `IN` for subqueries with large result sets
- Use cursor-based pagination over offset pagination for large datasets
- Monitor slow query logs and set up alerts for queries exceeding thresholds
- Use `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` in Postgres for full execution plan

## Transaction Management

- Use explicit transaction boundaries for multi-step mutations
- Keep transactions short to avoid lock contention
- Handle deadlocks with retry logic (limited retries with backoff)
- Use `READ COMMITTED` isolation (usually sufficient); use `SERIALIZABLE` for financial operations
- Implement the Unit of Work pattern for complex business operations
- Release connections back to the pool promptly after transaction completion
- Avoid long-running transactions that hold locks across user interactions
