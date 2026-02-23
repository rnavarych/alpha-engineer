# PostgreSQL Index Tuning

## When to Load
Load when optimizing a specific slow query with EXPLAIN, creating partial or expression indexes, auditing existing indexes for bloat and redundancy, or running index maintenance in production.

## Partial Indexes

```sql
-- Index only rows matching a condition
-- Smaller, faster to build, lower write overhead

-- Only active users
CREATE INDEX idx_users_active ON users(email)
WHERE status = 'active';
-- Useful when: 5% of users are active; avoids indexing 95% irrelevant rows

-- Only unprocessed jobs
CREATE INDEX idx_jobs_pending ON jobs(priority DESC, created_at)
WHERE status IN ('pending', 'retrying');
-- Queue polling: WHERE status = 'pending' ORDER BY priority DESC, created_at → tiny fast index

-- Only non-null optional fields
CREATE INDEX idx_orders_coupon ON orders(coupon_id)
WHERE coupon_id IS NOT NULL;
-- 90% of orders have no coupon; index only the 10% that matter

-- Rule: partial index predicate must match query WHERE clause exactly
-- SET enable_seqscan=off to verify the query planner picks your partial index
```

## Expression Indexes

```sql
-- Index on computed value — query MUST use the same expression
CREATE INDEX idx_users_email_lower ON users(lower(email));

SELECT * FROM users WHERE lower(email) = lower($1);  -- uses index
SELECT * FROM users WHERE email = $1;                -- does NOT use index
```

## Index Maintenance

```sql
-- Find unused indexes (wasteful writes with no read benefit)
SELECT
  indexrelid::regclass AS index_name,
  relid::regclass AS table_name,
  idx_scan AS scans,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND NOT indisprimary
  AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find bloated indexes (fragmented after many updates/deletes)
SELECT
  indexrelid::regclass AS index_name,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
JOIN pg_index USING (indexrelid)
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 20;

-- Rebuild index without locking table
REINDEX INDEX CONCURRENTLY idx_orders_user_created;

-- Check index hit rate (should be >99% in healthy system)
SELECT
  relname AS table_name,
  ROUND(100.0 * idx_scan / NULLIF(seq_scan + idx_scan, 0), 1) AS index_hit_pct,
  seq_scan,
  idx_scan
FROM pg_stat_user_tables
WHERE seq_scan + idx_scan > 0
ORDER BY index_hit_pct ASC;
```

## Index Creation Best Practices

```sql
-- CONCURRENTLY: no table lock; takes longer but safe in production
CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status)
WHERE status IN ('pending', 'processing');

-- IF NOT EXISTS: idempotent migration scripts
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id ON orders(user_id);

-- Never create indexes in production without CONCURRENTLY
-- Regular CREATE INDEX takes ACCESS EXCLUSIVE lock → full table lock → outage
```

## Anti-Patterns

### Index on Every Column
Every index adds write overhead (INSERT/UPDATE/DELETE must update all indexes). A table with 15 indexes and heavy writes will be slower than one with 5 well-chosen indexes. Profile write vs read ratio.

### Wrong Column Order in Composite Index
`(created_at, user_id)` for queries filtering `WHERE user_id = $1` — the index cannot be used because `user_id` is not the leftmost column. Put the equality filter column first.

### Index on Low-Cardinality Column
Indexing `status` with values `('active', 'inactive')` on a 10M row table. Planner may prefer Seq Scan anyway (50% of rows = half the table). Use partial index (`WHERE status = 'active'`) or combine with a high-cardinality column.

## Quick Reference

```
Partial: WHERE condition reduces index size; predicate must match query
Expression: index on lower(email) only helps WHERE lower(email) = ...
CONCURRENTLY: always in production; no lock; twice the build time
Unused indexes: pg_stat_user_indexes WHERE idx_scan = 0
Redundant: if (user_id) and (user_id, created_at) both exist, drop (user_id)
REINDEX CONCURRENTLY: rebuild bloated index without table lock
Index hit rate: pg_stat_user_tables; healthy system > 99%
```
