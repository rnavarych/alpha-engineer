---
name: query-optimization
description: |
  Cross-engine query optimization guide. EXPLAIN/EXPLAIN ANALYZE across PostgreSQL, MySQL, MongoDB, Cassandra, ClickHouse. Index strategies (B-tree, hash, GIN, GiST, BRIN, partial, covering, composite). N+1 detection, cursor-based pagination, materialized views, query plan analysis, slow query diagnosis. Use when optimizing slow queries, designing indexes, or analyzing query performance.
allowed-tools: Read, Grep, Glob, Bash
---

# Query Optimization

## EXPLAIN Analysis by Engine

### PostgreSQL
```sql
-- Full analysis with buffers and timing
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT ...;

-- Key metrics to check:
-- Planning Time / Execution Time
-- Seq Scan vs Index Scan (seq scan on large tables = problem)
-- Rows estimated vs actual (large mismatch = stale statistics)
-- Shared hit vs shared read (low hit ratio = insufficient shared_buffers)
-- Sort Method: external merge (= insufficient work_mem)
```

**Red Flags in PostgreSQL Plans:**
- `Seq Scan` on tables > 10K rows with WHERE clause → missing index
- `Nested Loop` with large outer table → consider Hash Join (check work_mem)
- `Sort → external merge` → increase `work_mem`
- `Bitmap Heap Scan → Recheck Cond` with many lossy blocks → index too wide
- Estimated vs actual rows differ by 10x+ → run `ANALYZE` on table

### MySQL
```sql
-- Tree format (MySQL 8.0+)
EXPLAIN FORMAT=TREE SELECT ...;
EXPLAIN ANALYZE SELECT ...;  -- Actually executes query

-- Key metrics:
-- type: ALL (full scan) < index < range < ref < eq_ref < const
-- rows: estimated rows examined
-- filtered: percentage of rows filtered by WHERE
-- Extra: Using filesort, Using temporary = potential issues
```

### MongoDB
```javascript
// Execution stats
db.collection.find({...}).explain("executionStats");

// Key metrics:
// totalDocsExamined vs nReturned (ratio should be close to 1:1)
// stage: COLLSCAN = collection scan (no index)
// stage: IXSCAN = index scan (good)
// executionTimeMillis
// indexesUsed
```

### ClickHouse
```sql
EXPLAIN PIPELINE SELECT ...;
EXPLAIN PLAN actions=1 SELECT ...;

-- Check system.query_log for performance
SELECT query, read_rows, read_bytes, memory_usage, query_duration_ms
FROM system.query_log WHERE type = 'QueryFinish' ORDER BY event_time DESC LIMIT 10;
```

## Index Strategies

### Index Types by Engine

| Index Type | PostgreSQL | MySQL | MongoDB | Use Case |
|-----------|------------|-------|---------|----------|
| **B-tree** | Default | Default (InnoDB) | Default | Equality, range, sorting, LIKE 'prefix%' |
| **Hash** | Yes | Adaptive (InnoDB) | Hashed | Equality only, no range |
| **GIN** | Yes | — | — | Arrays, JSONB, full-text, tsvector |
| **GiST** | Yes | — | 2dsphere | Geometric, range types, nearest-neighbor |
| **SP-GiST** | Yes | — | — | Non-balanced structures (quad-tree, k-d tree) |
| **BRIN** | Yes | — | — | Large sequential/time-ordered tables |
| **Full-text** | tsvector/tsquery | FULLTEXT | Text | Natural language search |
| **Partial** | Yes | — | Partial filter | Index subset of rows (WHERE condition) |
| **Covering** | INCLUDE clause | Covering | Covered | Avoid heap access (index-only scan) |
| **Multikey** | GIN on arrays | — | Yes | Array/embedded document fields |

### Composite Index Design Rules
1. **Equality columns first**: Columns in `WHERE col = value` go first
2. **Range/sort columns last**: Columns in `WHERE col > value` or `ORDER BY col`
3. **Most selective column first** (within equality group): Column with most distinct values
4. **Index order matches query**: `INDEX(a, b, c)` supports `WHERE a=1`, `WHERE a=1 AND b=2`, but NOT `WHERE b=2` alone

### Partial Indexes (PostgreSQL)
```sql
-- Index only active users (smaller, faster)
CREATE INDEX idx_users_active_email ON users (email) WHERE is_active = true;

-- Index only non-deleted records
CREATE INDEX idx_orders_pending ON orders (created_at) WHERE deleted_at IS NULL AND status = 'pending';

-- Unique constraint for soft-delete
CREATE UNIQUE INDEX uq_users_email_active ON users (email) WHERE deleted_at IS NULL;
```

### Covering Indexes
```sql
-- PostgreSQL: INCLUDE to avoid heap access
CREATE INDEX idx_orders_customer ON orders (customer_id) INCLUDE (total, status, created_at);
-- Query can be satisfied entirely from index (index-only scan)

-- MySQL: InnoDB secondary indexes include PK columns automatically
CREATE INDEX idx_orders_customer_status ON orders (customer_id, status);
-- If PK is (id), the index effectively stores (customer_id, status, id)
```

## N+1 Query Detection and Elimination

### Detection
```sql
-- PostgreSQL: Find repeated queries via pg_stat_statements
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
WHERE calls > 100 AND query LIKE '%SELECT%FROM%WHERE%id =%'
ORDER BY total_exec_time DESC;
```

### Elimination Patterns

| Pattern | ORM Implementation | SQL Equivalent |
|---------|-------------------|----------------|
| **Eager loading** | Prisma: `include: { posts: true }` | `JOIN` or second query with `IN` |
| **Batch loading** | DataLoader (GraphQL) | `SELECT * FROM posts WHERE user_id IN (...)` |
| **Subquery** | SQLAlchemy: `subqueryload()` | `SELECT * FROM posts WHERE user_id IN (SELECT id FROM users WHERE ...)` |
| **Window function** | Raw SQL | `SELECT *, COUNT(*) OVER (PARTITION BY user_id)` |

## Pagination Patterns

### Offset-Based (Simple, Problematic at Scale)
```sql
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 1000;
-- Problem: DB must scan and discard 1000 rows. Gets slower as offset increases.
-- O(offset + limit) cost for each page
```

### Cursor-Based (Performant, Recommended)
```sql
-- Using primary key as cursor
SELECT * FROM orders WHERE id > :last_seen_id ORDER BY id LIMIT 20;
-- O(limit) cost regardless of position. Requires unique, sortable column.

-- Multi-column cursor (for non-unique sort columns)
SELECT * FROM orders
WHERE (created_at, id) > (:last_created_at, :last_id)
ORDER BY created_at, id
LIMIT 20;
```

### Keyset Pagination with Estimated Counts
```sql
-- Fast approximate count (PostgreSQL)
SELECT reltuples::bigint AS estimate FROM pg_class WHERE relname = 'orders';
-- Use this for "showing X of ~Y results" instead of COUNT(*)
```

## Materialized Views

### PostgreSQL
```sql
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT date_trunc('day', created_at) AS day, SUM(total) AS revenue, COUNT(*) AS order_count
FROM orders WHERE status = 'completed'
GROUP BY 1;

-- Refresh (blocks reads during refresh)
REFRESH MATERIALIZED VIEW mv_daily_sales;

-- Concurrent refresh (requires unique index, no blocking)
CREATE UNIQUE INDEX idx_mv_daily_sales_day ON mv_daily_sales (day);
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales;
```

### Automated Refresh Patterns
- **pg_cron**: Schedule `REFRESH MATERIALIZED VIEW CONCURRENTLY` at intervals
- **Trigger-based**: Refresh after significant changes (risky for high-throughput)
- **CDC-based**: Use Debezium to detect source changes and trigger refresh
- **Application-level**: Refresh in background job after batch operations

## Query Anti-Patterns

### SELECT * in Production
```sql
-- Bad: fetches all columns, prevents covering index optimization
SELECT * FROM users WHERE id = 1;
-- Good: only fetch needed columns
SELECT id, name, email FROM users WHERE id = 1;
```

### Functions on Indexed Columns
```sql
-- Bad: cannot use index on created_at
SELECT * FROM orders WHERE YEAR(created_at) = 2024;
-- Good: range condition uses index
SELECT * FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01';

-- Bad: function prevents index usage
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';
-- Good: expression index (PostgreSQL)
CREATE INDEX idx_users_email_lower ON users (LOWER(email));
```

### Implicit Type Conversions
```sql
-- Bad: string comparison on integer column prevents index
SELECT * FROM orders WHERE id = '123';
-- Good: use correct type
SELECT * FROM orders WHERE id = 123;
```

### Correlated Subqueries
```sql
-- Bad: executes subquery for each row
SELECT u.*, (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) AS order_count FROM users u;
-- Good: JOIN with aggregation
SELECT u.*, COALESCE(o.order_count, 0) AS order_count
FROM users u LEFT JOIN (SELECT user_id, COUNT(*) AS order_count FROM orders GROUP BY user_id) o ON u.id = o.user_id;
```

### Missing LIMIT on Unbounded Queries
```sql
-- Bad: can return millions of rows
SELECT * FROM logs WHERE level = 'ERROR';
-- Good: always limit
SELECT * FROM logs WHERE level = 'ERROR' ORDER BY created_at DESC LIMIT 100;
```

## Statistics and Cardinality

### PostgreSQL
```sql
-- Update statistics for a table
ANALYZE orders;

-- Check table statistics
SELECT schemaname, tablename, n_live_tup, n_dead_tup, last_analyze, last_autoanalyze
FROM pg_stat_user_tables WHERE tablename = 'orders';

-- Check column statistics (most common values, histogram bounds)
SELECT * FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';

-- Increase statistics target for columns with skewed distribution
ALTER TABLE orders ALTER COLUMN status SET STATISTICS 1000;
ANALYZE orders;
```

### MySQL
```sql
-- Update statistics
ANALYZE TABLE orders;

-- Check index cardinality
SHOW INDEX FROM orders;

-- InnoDB persistent statistics
SELECT * FROM mysql.innodb_table_stats WHERE table_name = 'orders';
SELECT * FROM mysql.innodb_index_stats WHERE table_name = 'orders';

-- Histogram statistics (MySQL 8.0+)
ANALYZE TABLE orders UPDATE HISTOGRAM ON status, payment_method WITH 256 BUCKETS;
```

## Quick Reference: Optimization Checklist

1. **Read EXPLAIN first** — never optimize without analyzing the query plan
2. **Check statistics** — run ANALYZE if estimates are off
3. **Add indexes** — for WHERE, JOIN, ORDER BY, GROUP BY columns used together
4. **Use covering indexes** — include SELECT columns to avoid heap access
5. **Paginate with cursors** — never use large OFFSET values
6. **Avoid functions on indexed columns** — use expression indexes if needed
7. **Batch N+1 queries** — use JOINs, IN clauses, or DataLoader
8. **Limit result sets** — always use LIMIT, avoid SELECT *
9. **Monitor slow queries** — enable pg_stat_statements / slow query log / profiler
10. **Test with production data volumes** — plans change dramatically with scale
