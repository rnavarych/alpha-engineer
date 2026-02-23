# PostgreSQL Query Optimization

## When to Load
Load when analyzing slow queries, reading EXPLAIN ANALYZE output, or debugging planner decisions.

## EXPLAIN ANALYZE — Reading the Plan

```sql
-- Full diagnostic run: timing, buffer hits, actual row counts
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.name, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > NOW() - INTERVAL '30 days'
GROUP BY u.id, u.name
ORDER BY order_count DESC
LIMIT 10;
```

### Node Types and What They Mean

```
Seq Scan        → reading every row in the table; bad on large tables (>100k rows)
Index Scan      → walking B-tree to find matching rows, then fetching heap
Index Only Scan → all columns in index INCLUDE; zero heap fetch; best case
Bitmap Index Scan + Bitmap Heap Scan → OR conditions, multiple indexes combined
Hash Join       → build hash table from smaller side; good for large unsorted sets
Nested Loop     → for each outer row, scan inner; good when inner is indexed + small result set
Merge Join      → both sides pre-sorted; common with ORDER BY on join keys

cost=0.00..5432.00     → estimated startup..total cost (planner units)
actual time=0.1..234.5 → measured wall time in ms
rows=50000             → estimated rows
actual rows=482        → actual rows; if actual >> estimated → stale statistics
```

### Warning Signs in Plans

```
"Seq Scan" on table with > 100k rows       → missing or unused index
Actual rows >> estimated rows by 10×        → run ANALYZE tablename
"Sort Method: external merge Disk"         → needs work_mem increase or index with ORDER BY
cost > 10000 on inner side of Nested Loop  → N+1 or missing FK index
Buffers: read=5000, hit=100                → low cache ratio; missing index or cold data
"Hash Batches: 8" (not 1)                 → hash join spilled to disk; increase work_mem
```

### Fixing Stale Statistics

```sql
ANALYZE users;
ANALYZE orders;

-- Check last analyze time
SELECT relname, last_analyze, last_autoanalyze, n_live_tup, n_dead_tup
FROM pg_stat_user_tables
ORDER BY last_analyze NULLS FIRST;

-- Tune autovacuum for high-churn tables
ALTER TABLE orders SET (
  autovacuum_analyze_scale_factor = 0.01,
  autovacuum_analyze_threshold    = 1000
);
```

## work_mem Tuning

```sql
-- Per-operation memory (sort, hash join)
-- Caution: per OPERATION; 10 parallel queries × 3 operations = 30× work_mem

-- Session-level (safe for one-off queries)
SET work_mem = '256MB';
EXPLAIN ANALYZE SELECT ...;

-- Global postgresql.conf (be conservative)
-- work_mem = 16MB  (default 4MB is often too low)
-- max_connections = 100; 16MB × 100 = 1.6GB worst case
```

## Join Strategy Hints

```sql
-- Force index scan (disable seq scan for debugging only)
SET enable_seqscan = OFF;
EXPLAIN ANALYZE SELECT ...;
SET enable_seqscan = ON;  -- Always reset

-- Force specific join type for testing
SET enable_hashjoin = OFF;
SET enable_nestloop = OFF;
-- Note: debugging tools only, not production config
```

## Common Table Expressions (CTEs)

```sql
-- PostgreSQL 12+: CTEs are inlined by default (not materialized)
-- Force materialization when CTE is used multiple times
WITH expensive_calc AS MATERIALIZED (
  SELECT user_id, SUM(total) AS ltv
  FROM orders
  GROUP BY user_id
)
SELECT u.name, ec.ltv
FROM users u
JOIN expensive_calc ec ON ec.user_id = u.id
WHERE ec.ltv > 10000;

-- Recursive CTE: org charts, threaded comments, category trees
WITH RECURSIVE category_tree AS (
  SELECT id, name, parent_id, 0 AS depth
  FROM categories WHERE parent_id IS NULL

  UNION ALL

  SELECT c.id, c.name, c.parent_id, ct.depth + 1
  FROM categories c
  INNER JOIN category_tree ct ON ct.id = c.parent_id
  WHERE ct.depth < 10  -- Cycle guard
)
SELECT * FROM category_tree ORDER BY depth, name;
```

## Quick Reference

```
EXPLAIN ANALYZE: Seq Scan on large table → add index
rows estimation off by 10× → ANALYZE tablename
Sort to disk → increase work_mem or add index with ORDER BY
Low buffer hit rate → cold cache or missing index
CTEs: inlined in PG12+; add MATERIALIZED to force isolation
work_mem: set at session level for debugging; tune autovacuum per table
```
