# Database Performance

## EXPLAIN ANALYZE

```sql
-- Always use ANALYZE + BUFFERS to see actual execution
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.id, o.total, u.name, u.email
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.status = 'pending'
  AND o.created_at > NOW() - INTERVAL '7 days'
ORDER BY o.created_at DESC
LIMIT 50;

-- Reading the output:
-- Seq Scan:        BAD for large tables — reads every row
-- Index Scan:      GOOD — uses index to find rows
-- Index Only Scan: BEST — answer from index alone (covering index)
-- Nested Loop:     Good for small inner sets
-- Hash Join:       Good for large table joins
-- Bitmap Index:    Good for moderate selectivity

-- Key metrics:
-- actual time: first_row..last_row in ms
-- rows: actual vs estimated — big difference = stale statistics
-- Buffers: hit (cache) vs read (disk) — high read = needs more memory
```

## Indexing Strategies

```sql
-- B-tree index (default) — equality and range queries
CREATE INDEX CONCURRENTLY idx_orders_status_created
  ON orders (status, created_at DESC);
-- Column order matters: filter columns first, sort columns last

-- Partial index — smaller, faster, for common filters
CREATE INDEX CONCURRENTLY idx_orders_active
  ON orders (user_id, created_at DESC)
  WHERE status NOT IN ('cancelled', 'archived');
-- Only indexes non-cancelled orders — much smaller than full index

-- Covering index — query answered from index alone
CREATE INDEX CONCURRENTLY idx_orders_list
  ON orders (user_id, created_at DESC)
  INCLUDE (id, status, total);
-- SELECT id, status, total WHERE user_id = ? ORDER BY created_at DESC
-- -> Index Only Scan — never touches the table

-- GIN index — for JSONB and array columns
CREATE INDEX CONCURRENTLY idx_orders_metadata
  ON orders USING GIN (metadata jsonb_path_ops);
-- SELECT * WHERE metadata @> '{"priority": "high"}'

-- Composite index vs multiple single indexes
-- Composite (a, b): works for WHERE a = ?, WHERE a = ? AND b = ?
-- Does NOT work for WHERE b = ? alone (leftmost prefix rule)
```

## Query Optimization

```sql
-- Find slowest queries (requires pg_stat_statements)
SELECT
  query,
  calls,
  round(total_exec_time::numeric, 2) AS total_ms,
  round(mean_exec_time::numeric, 2) AS mean_ms,
  round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 2) AS pct
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_%'
ORDER BY total_exec_time DESC
LIMIT 20;

-- Pagination: keyset (cursor) vs OFFSET
-- BAD: OFFSET grows slower as page increases
SELECT * FROM orders ORDER BY created_at DESC LIMIT 20 OFFSET 10000;
-- Scans and discards 10000 rows!

-- GOOD: keyset pagination — constant performance
SELECT * FROM orders
WHERE created_at < '2024-01-15T10:30:00Z'
ORDER BY created_at DESC
LIMIT 20;
-- Uses index directly, no scanning discarded rows
```

## Table Partitioning

```sql
-- Partition large tables by date range
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  status VARCHAR(20) NOT NULL,
  total NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Monthly partitions
CREATE TABLE orders_2024_01 PARTITION OF orders
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE orders_2024_02 PARTITION OF orders
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Benefits:
-- Queries with date filter scan only relevant partitions
-- Old data: DROP PARTITION (instant) vs DELETE (slow, locks)
-- Vacuum operates on smaller tables
-- Index builds are smaller and faster

-- When to partition:
-- Table > 100M rows
-- Queries always filter by partition key (date, tenant_id)
-- Need to drop old data efficiently
```

## Statistics and Maintenance

```sql
-- Update statistics after bulk operations
ANALYZE orders;

-- Check table bloat
SELECT
  relname,
  n_live_tup,
  n_dead_tup,
  round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS dead_pct
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- Autovacuum settings for high-write tables
ALTER TABLE orders SET (
  autovacuum_vacuum_scale_factor = 0.01,     -- Vacuum at 1% dead rows (default 20%)
  autovacuum_analyze_scale_factor = 0.005    -- Analyze at 0.5% changes
);
```

## Anti-Patterns
- Adding indexes without CONCURRENTLY — locks table for writes
- Missing index on foreign keys — JOIN scans entire table
- OFFSET for deep pagination — use keyset/cursor pagination
- Not running ANALYZE after bulk loads — planner uses stale statistics
- Over-indexing — each index slows writes and uses disk space

## Quick Reference
```
EXPLAIN: always ANALYZE + BUFFERS — see actual execution
Seq Scan: bad (full table), Index Scan: good, Index Only: best
Index order: filter columns first, sort columns last
Partial index: WHERE clause — smaller, faster for common queries
Covering index: INCLUDE columns — Index Only Scan
CONCURRENTLY: always for production index creation
Keyset pagination: WHERE created_at < cursor — constant performance
Partitioning: >100M rows, always filter by partition key
pg_stat_statements: find top-N slowest queries by total time
ANALYZE: run after bulk operations to update statistics
```

## When to load
Load when optimizing slow queries, choosing index strategies, diagnosing EXPLAIN ANALYZE output, implementing keyset pagination, or deciding whether to partition a table.
