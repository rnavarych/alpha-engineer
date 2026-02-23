# Relational Database Comparison

## When to load
Load when choosing between PostgreSQL, MySQL, SQLite, or CockroachDB for relational data storage.

## Patterns

### PostgreSQL (default choice for most applications)
```sql
-- JSONB for flexible schema within relational model
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  search_vector TSVECTOR GENERATED ALWAYS AS (to_tsvector('english', name)) STORED,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_products_metadata ON products USING GIN (metadata);
CREATE INDEX idx_products_search ON products USING GIN (search_vector);

-- Full-text search built-in
SELECT * FROM products WHERE search_vector @@ plainto_tsquery('wireless headphones');

-- Partitioning for large tables
CREATE TABLE events (
  id BIGSERIAL, created_at TIMESTAMPTZ NOT NULL, data JSONB
) PARTITION BY RANGE (created_at);
CREATE TABLE events_2024_q1 PARTITION OF events
  FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
```
Strengths: JSONB, full-text search, CTEs, window functions, extensions (PostGIS, pgvector, pg_cron), row-level security, partitioning. Handles 10k+ TPS on single node.

### MySQL (InnoDB)
```sql
-- Good for: read-heavy workloads, proven replication
-- Native JSON support (less powerful than Postgres JSONB)
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  profile JSON,
  INDEX idx_email (email)
) ENGINE=InnoDB;

-- Read replicas with GTID replication
-- Group Replication for multi-primary (MySQL 8.0+)
```
Strengths: battle-tested replication, wide hosting support, good read performance, MySQL 8.0 added CTEs and window functions. Ecosystem: ProxySQL, Vitess for sharding.

### SQLite
```sql
-- Embedded, zero-config, single-file database
-- Perfect for: CLI tools, mobile apps, edge computing, tests
-- WAL mode for concurrent reads
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout=5000;
PRAGMA synchronous=NORMAL;
```
Strengths: zero setup, single file, 1TB max DB size, embedded in process. Handles ~50k reads/sec. One writer at a time. Production-viable for read-heavy apps (Litestream for replication, LiteFS for distributed).

### CockroachDB
```sql
-- Distributed SQL, automatic sharding, strong consistency
-- PostgreSQL wire-compatible
CREATE TABLE orders (
  id UUID DEFAULT gen_random_uuid(),
  region STRING NOT NULL,
  total DECIMAL(10,2),
  PRIMARY KEY (region, id)  -- geo-partitioned by region
);
ALTER TABLE orders PARTITION BY LIST (region) (
  PARTITION us VALUES IN ('us-east', 'us-west'),
  PARTITION eu VALUES IN ('eu-west', 'eu-central')
);
```
Strengths: automatic sharding, multi-region with geo-partitioning, serializable isolation by default, survives node/AZ failures. Trade-off: higher write latency (consensus overhead).

## Anti-patterns
- Choosing MySQL for complex queries with CTEs/window functions -> Postgres is stronger here
- SQLite for multi-writer concurrent workloads -> single writer bottleneck
- CockroachDB for single-region, simple apps -> unnecessary complexity and cost
- Not enabling WAL mode on SQLite -> blocks reads during writes

## Decision criteria
| Factor | PostgreSQL | MySQL | SQLite | CockroachDB |
|--------|-----------|-------|--------|-------------|
| Default choice | Yes for most apps | Legacy/existing | Embedded/edge | Multi-region |
| Max practical TPS | 10k+ (single) | 10k+ (single) | 50k reads, 1 writer | 50k+ (cluster) |
| Horizontal scale | Read replicas + Citus | Vitess/ProxySQL | Litestream | Built-in |
| JSON support | JSONB (excellent) | JSON (good) | JSON (basic) | JSONB (good) |
| Replication | Streaming + logical | GTID + Group | Litestream | Raft consensus |
| Hosting complexity | Low | Low | Zero | Medium |

## Quick reference
```
Default choice: PostgreSQL (unless specific reason not to)
Read-heavy, simple: MySQL with read replicas
Embedded/edge/mobile: SQLite with WAL mode
Multi-region distributed: CockroachDB
Connection pool formula: pool_size = CPU_cores * 2 + 1
Always use: UUIDs for distributed, BIGSERIAL for single-node
Always enable: connection pooling (PgBouncer/ProxySQL)
```
