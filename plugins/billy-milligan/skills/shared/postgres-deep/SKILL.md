---
name: postgres-deep
description: |
  PostgreSQL deep-dive: EXPLAIN ANALYZE interpretation, index types (B-tree, GIN, GiST, BRIN),
  partial/covering/composite indexes, pg_stat_statements slow query analysis, Row Level Security,
  window functions, CTEs, advisory locks, LISTEN/NOTIFY, connection pooling with PgBouncer.
  Use when optimizing slow queries, designing indexing strategy, implementing multi-tenancy.
allowed-tools: Read, Grep, Glob
---

# PostgreSQL Deep Dive

## When to Use This Skill
- Optimizing slow queries with EXPLAIN ANALYZE
- Designing indexes for specific access patterns
- Implementing Row Level Security for multi-tenancy
- Using window functions for analytics queries
- Configuring PgBouncer for connection pooling

## Core Principles

1. **EXPLAIN ANALYZE before optimizing** — never guess; measure first; the plan shows the actual cost
2. **Index the access pattern, not the column** — a composite index `(user_id, created_at DESC)` beats two separate indexes for paginated user queries
3. **Partial indexes reduce size and maintenance cost** — `WHERE status = 'pending'` on a 10M row table with 1000 pending rows = tiny, fast index
4. **RLS is enforced at the DB layer** — even if application code has a bug, unauthorized rows are invisible
5. **pg_stat_statements is your slow query log** — enable it; it shows cumulative query costs across all calls

---

## Patterns ✅

### EXPLAIN ANALYZE — Reading the Plan

```sql
-- Enable timing and buffers for full picture
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.name, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > NOW() - INTERVAL '30 days'
GROUP BY u.id, u.name
ORDER BY order_count DESC
LIMIT 10;

-- What to look for:
-- "Seq Scan" on large table → missing index
-- "rows=50000 width=..." actual vs estimated rows differ by >10x → stale statistics (run ANALYZE)
-- "Hash Join" → OK for large sets; "Nested Loop" with large outer → can be slow
-- Buffers: "hit=1234" (from cache) vs "read=5678" (from disk) — high reads = cold cache or missing index
-- cost=0.00..5432.00 → estimated; actual time=0.001..234.567 → measured
-- "Parallel Seq Scan" → table too big for index (consider partitioning)

-- Warning signs:
-- Actual rows >> Estimated rows → run: ANALYZE users;
-- cost > 10000 on inner loop → N+1 or missing index
-- "Sort Method: external merge Disk" → needs work_mem increase or sorting index
```

### Index Types and When to Use Each

```sql
-- B-tree (default) — range scans, equality, sorting
-- Use for: primary keys, foreign keys, range queries, ORDER BY
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- Partial index — index only the rows you query
-- Only 0.01% of orders are 'pending' — index only those
CREATE INDEX idx_orders_pending ON orders(created_at)
WHERE status = 'pending';
-- Condition: query WHERE clause must match the partial index predicate

-- Covering index — includes extra columns to avoid table fetch (index-only scan)
CREATE INDEX idx_orders_user_covering ON orders(user_id, created_at DESC)
INCLUDE (total, status, id);
-- Query: SELECT id, total, status FROM orders WHERE user_id = $1 ORDER BY created_at DESC
-- → Index-only scan: no heap fetch

-- GIN — full-text search, JSONB queries, array overlap
CREATE INDEX idx_products_search ON products
USING GIN(to_tsvector('english', name || ' ' || description));

CREATE INDEX idx_events_metadata ON events
USING GIN(metadata);  -- JSONB @> queries use this

-- GiST — geometric/spatial queries, ranges, nearest-neighbor
CREATE INDEX idx_stores_location ON stores USING GIST(location);  -- PostGIS

-- BRIN — append-only time-series tables with sequential data
-- Very small index; good for logs/events tables with monotonic timestamps
CREATE INDEX idx_events_created_brin ON events
USING BRIN(created_at) WITH (pages_per_range = 128);
-- Use when: table is huge, data is inserted in order, queries filter on time ranges
```

### pg_stat_statements — Find Slow Queries

```sql
-- Enable in postgresql.conf: shared_preload_libraries = 'pg_stat_statements'
-- After restart:
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top 10 slowest queries by total time
SELECT
  query,
  calls,
  ROUND(total_exec_time::numeric / 1000, 2) AS total_seconds,
  ROUND(mean_exec_time::numeric, 2) AS mean_ms,
  ROUND(stddev_exec_time::numeric, 2) AS stddev_ms,
  rows,
  ROUND(100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0), 1) AS cache_hit_pct
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Queries with worst cache hit rate (reading from disk)
SELECT query, shared_blks_hit, shared_blks_read,
       ROUND(100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0), 1) AS cache_hit_pct
FROM pg_stat_statements
WHERE shared_blks_read > 100
ORDER BY cache_hit_pct ASC
LIMIT 10;

-- Reset stats after optimization to measure improvement
SELECT pg_stat_statements_reset();
```

### Row Level Security (Multi-Tenancy)

```sql
-- Enable RLS on tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders FORCE ROW LEVEL SECURITY;  -- Even for table owner

-- Policy: users see only their own orders
CREATE POLICY orders_user_isolation ON orders
  FOR ALL
  TO application_role  -- DB role your app uses
  USING (user_id = current_setting('app.current_user_id')::uuid);

-- Application: set context per request (in transaction)
-- Using SET LOCAL scopes to current transaction
```

```typescript
// TypeScript: set RLS context per request
export async function withUserContext<T>(
  db: Database,
  userId: string,
  fn: (tx: Transaction) => Promise<T>
): Promise<T> {
  return db.transaction(async (tx) => {
    // Set context — RLS uses this to filter rows
    await tx.execute(sql`SET LOCAL app.current_user_id = ${userId}`);
    return fn(tx);
  });
}

// Usage in application layer
const orders = await withUserContext(db, req.userId, async (tx) => {
  return tx.select().from(ordersTable);
  // RLS automatically filters to req.userId's orders only
});
```

### Window Functions for Analytics

```sql
-- Running total, rank, lead/lag — without subqueries

-- Running total of revenue per month
SELECT
  DATE_TRUNC('month', created_at) AS month,
  SUM(total)                      AS monthly_revenue,
  SUM(SUM(total)) OVER (
    ORDER BY DATE_TRUNC('month', created_at)
  )                               AS cumulative_revenue
FROM orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- Rank customers by lifetime value
SELECT
  customer_id,
  SUM(total) AS ltv,
  RANK() OVER (ORDER BY SUM(total) DESC) AS rank,
  NTILE(4) OVER (ORDER BY SUM(total) DESC) AS quartile  -- 1=top 25%
FROM orders
GROUP BY customer_id;

-- Compare each order to the customer's previous order (lag)
SELECT
  id,
  customer_id,
  total,
  LAG(total) OVER (PARTITION BY customer_id ORDER BY created_at) AS prev_order_total,
  total - LAG(total) OVER (PARTITION BY customer_id ORDER BY created_at) AS change
FROM orders
ORDER BY customer_id, created_at;
```

---

## Anti-Patterns ❌

### Missing Index on Foreign Key
**What it is**: `orders.user_id` references `users.id` but has no index.
**What breaks**: `SELECT * FROM orders WHERE user_id = $1` → sequential scan of entire orders table.
**Fix**: Always create index on foreign key columns. PostgreSQL does NOT create these automatically (unlike MySQL InnoDB).

### OFFSET at Scale
**What it is**: `SELECT * FROM orders OFFSET 50000 LIMIT 20`.
**What breaks**: PostgreSQL scans and discards 50,000 rows. At 10M rows with complex query, this takes 2–10 seconds.
**Fix**: Cursor pagination — see api-design skill. Filter by `(created_at, id) > (last_created_at, last_id)`.

### N+1 via ORM with RLS
**What it is**: Loading orders (50 rows) then calling `ORDER.getUser()` per row inside RLS context.
**What breaks**: 51 transactions: 1 to get orders + 50 to get each user. Each transaction has `SET LOCAL` overhead.
**Fix**: Eager load with JOIN. One transaction, one query.

---

## Quick Reference

```
EXPLAIN ANALYZE: look for Seq Scan on large tables, rows estimation errors
Index types: B-tree (default), GIN (JSONB/FTS), BRIN (time-series), GiST (geo)
Partial index: WHERE clause reduces index size for rare values
Covering index: INCLUDE extra columns for index-only scans
pg_stat_statements: ORDER BY total_exec_time DESC to find top consumers
RLS setup: ENABLE + FORCE + POLICY + SET LOCAL in transaction
Window functions: SUM OVER, RANK OVER, LAG/LEAD OVER, NTILE
PgBouncer pool_mode=transaction for OLTP; pool_size 20-25 connections per PostgreSQL
VACUUM ANALYZE: run after bulk deletes/updates; pg_autovacuum handles routine
```
