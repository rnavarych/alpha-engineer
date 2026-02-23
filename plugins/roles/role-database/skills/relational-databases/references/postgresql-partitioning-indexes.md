# PostgreSQL Partitioning and Indexes

## When to load
Load when designing table partitioning, choosing index types, using pgvector or GIN/GiST, or setting up extensions like pg_partman, pgAudit, pg_stat_statements.

## Declarative Partitioning

```sql
-- Range partitioning (time-based)
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMPTZ NOT NULL,
    customer_id BIGINT NOT NULL,
    total NUMERIC(12,2),
    status TEXT
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2024_q1 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE orders_default PARTITION OF orders DEFAULT;

-- List partitioning
CREATE TABLE events (id BIGINT, region TEXT, payload JSONB)
PARTITION BY LIST (region);
CREATE TABLE events_us PARTITION OF events FOR VALUES IN ('us-east', 'us-west');
CREATE TABLE events_eu PARTITION OF events FOR VALUES IN ('eu-west', 'eu-central');

-- Hash partitioning
CREATE TABLE sessions (id UUID, user_id BIGINT, data JSONB)
PARTITION BY HASH (user_id);
CREATE TABLE sessions_0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
```

## pg_partman Automation

```sql
CREATE EXTENSION pg_partman;
SELECT partman.create_parent(
    p_parent_table := 'public.orders',
    p_control := 'created_at',
    p_type := 'range',
    p_interval := '1 month',
    p_premake := 3
);
SELECT partman.run_maintenance();
```

## Index Types

| Index Type | Use Case | Example |
|------------|----------|---------|
| B-tree | Equality, range, sorting (default) | `CREATE INDEX idx ON t(col)` |
| Hash | Equality only | `CREATE INDEX idx ON t USING hash(col)` |
| GIN | JSONB, arrays, full-text search | `CREATE INDEX idx ON t USING gin(payload jsonb_path_ops)` |
| GiST | Geometric, range types, FTS ranking | `CREATE INDEX idx ON t USING gist(location)` |
| SP-GiST | Trie, quad-tree (IP, phone prefixes) | `CREATE INDEX idx ON t USING spgist(ip inet_ops)` |
| BRIN | Large sequential/append-only data | `CREATE INDEX idx ON t USING brin(created_at)` |

## Advanced Index Techniques

```sql
-- Partial index (only active orders)
CREATE INDEX idx_orders_active ON orders(customer_id) WHERE status = 'active';

-- Covering index (index-only scan)
CREATE INDEX idx_orders_covering ON orders(customer_id) INCLUDE (total, status);

-- Expression index
CREATE INDEX idx_users_email_lower ON users(LOWER(email));

-- GIN for JSONB containment
CREATE INDEX idx_meta_gin ON documents USING gin(metadata jsonb_path_ops);

-- GIN for array contains
CREATE INDEX idx_tags_gin ON articles USING gin(tags);

-- BRIN for time-series (~1000x smaller than B-tree)
CREATE INDEX idx_logs_brin ON logs USING brin(created_at) WITH (pages_per_range = 32);
```

## pgvector Usage

```sql
CREATE EXTENSION vector;
CREATE TABLE embeddings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content TEXT,
    embedding vector(1536)
);

-- HNSW index
CREATE INDEX idx_embedding_hnsw ON embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Nearest neighbor query
SELECT id, content, embedding <=> $1::vector AS distance
FROM embeddings
ORDER BY embedding <=> $1::vector
LIMIT 10;
```

## Essential Extensions

| Extension | Purpose |
|-----------|---------|
| pg_stat_statements | Query performance tracking |
| pgAudit | SQL audit logging |
| pg_cron | Scheduled jobs |
| pg_repack | Online table/index repacking |
| auto_explain | Automatic query plan logging |
| HypoPG | Hypothetical indexes (what-if) |
| PostGIS | Geographic objects and spatial queries |
| TimescaleDB | Time-series hypertables |
| Citus | Distributed PostgreSQL |
