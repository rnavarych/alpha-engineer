# Pagination, N+1, Materialized Views, and Query Anti-Patterns

## When to load
Load when fixing N+1 query problems, implementing cursor-based pagination, refreshing materialized views, or eliminating common query anti-patterns (SELECT *, functions on indexed columns, correlated subqueries).

## N+1 Query Detection and Elimination

### Detection
```sql
-- PostgreSQL: find repeated queries via pg_stat_statements
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
| **Subquery load** | SQLAlchemy: `subqueryload()` | `SELECT * FROM posts WHERE user_id IN (SELECT id ...)` |
| **Window function** | Raw SQL | `SELECT *, COUNT(*) OVER (PARTITION BY user_id)` |

## Pagination Patterns

### Offset-Based (Avoid at Scale)
```sql
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 1000;
-- Problem: DB must scan and discard 1000 rows. O(offset + limit) cost.
```

### Cursor-Based (Recommended)
```sql
-- Single column cursor
SELECT * FROM orders WHERE id > :last_seen_id ORDER BY id LIMIT 20;
-- O(limit) cost regardless of position

-- Multi-column cursor for non-unique sort
SELECT * FROM orders
WHERE (created_at, id) > (:last_created_at, :last_id)
ORDER BY created_at, id
LIMIT 20;

-- Fast approximate count instead of COUNT(*)
SELECT reltuples::bigint AS estimate FROM pg_class WHERE relname = 'orders';
```

## Materialized Views

```sql
-- PostgreSQL
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT date_trunc('day', created_at) AS day,
       SUM(total) AS revenue, COUNT(*) AS order_count
FROM orders WHERE status = 'completed'
GROUP BY 1;

-- Blocking refresh
REFRESH MATERIALIZED VIEW mv_daily_sales;

-- Concurrent refresh (requires unique index, no blocking)
CREATE UNIQUE INDEX idx_mv_daily_sales_day ON mv_daily_sales (day);
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales;
```

**Automated Refresh Patterns:**
- **pg_cron**: Schedule `REFRESH MATERIALIZED VIEW CONCURRENTLY` at intervals
- **Trigger-based**: After significant changes (risky for high-throughput)
- **CDC-based**: Debezium detects source changes and triggers refresh
- **Application-level**: Background job after batch operations

## Query Anti-Patterns

### SELECT * in Production
```sql
-- Bad: fetches all columns, prevents covering index optimization
SELECT * FROM users WHERE id = 1;
-- Good
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
-- Good: expression index
CREATE INDEX idx_users_email_lower ON users (LOWER(email));
```

### Correlated Subqueries
```sql
-- Bad: executes subquery for each row
SELECT u.*, (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) AS order_count
FROM users u;

-- Good: JOIN with aggregation
SELECT u.*, COALESCE(o.order_count, 0) AS order_count
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS order_count FROM orders GROUP BY user_id
) o ON u.id = o.user_id;
```

### Implicit Type Conversions and Missing LIMIT
```sql
-- Bad: string comparison on integer column prevents index
SELECT * FROM orders WHERE id = '123';
-- Good
SELECT * FROM orders WHERE id = 123;

-- Bad: can return millions of rows
SELECT * FROM logs WHERE level = 'ERROR';
-- Good
SELECT * FROM logs WHERE level = 'ERROR' ORDER BY created_at DESC LIMIT 100;
```
