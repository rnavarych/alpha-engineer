# PostgreSQL Query Anti-Patterns

## When to Load
Load when diagnosing N+1 query problems, fixing over-fetching, correcting broken pagination, or reviewing query patterns that silently destroy performance at scale.

## N+1 Queries

```sql
-- Anti-pattern: one query per row (classic ORM trap)
-- SELECT * FROM users;  → then for each user:
-- SELECT * FROM orders WHERE user_id = $1;
-- 1000 users = 1001 queries; at 1ms each = 1 second wasted per request

-- Fix: JOIN or subquery
SELECT
  u.id, u.name,
  COUNT(o.id) AS order_count,
  COALESCE(SUM(o.total), 0) AS lifetime_value
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;

-- Fix with lateral for last N per group
SELECT u.id, u.name, recent.orders
FROM users u
CROSS JOIN LATERAL (
  SELECT json_agg(o ORDER BY o.created_at DESC) AS orders
  FROM (
    SELECT id, total, created_at FROM orders
    WHERE user_id = u.id
    ORDER BY created_at DESC
    LIMIT 3
  ) o
) recent;
```

## Missing Foreign Key Indexes

```sql
-- PostgreSQL does NOT auto-create indexes on FK columns
-- Every JOIN on an un-indexed FK = Seq Scan on the referencing table

-- Detect missing FK indexes
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS referenced_table
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = tc.table_name
      AND indexdef LIKE '%' || kcu.column_name || '%'
  );

-- Fix: always index FK columns
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
CREATE INDEX CONCURRENTLY idx_order_items_order_id ON order_items(order_id);
```

## Over-Fetching

```sql
-- Anti-pattern: SELECT * in production queries
SELECT * FROM orders WHERE user_id = $1;
-- Fetches TOAST-compressed large text/JSON even when not needed
-- Forces heap fetch even when a covering index could avoid it

-- Fix: name the columns you need
SELECT id, total, status, created_at FROM orders WHERE user_id = $1;

-- Anti-pattern: loading entire tree when only root needed
SELECT * FROM categories;  -- 50k rows when you need 10 top-level categories

-- Fix: filter at the query layer
SELECT id, name FROM categories WHERE parent_id IS NULL ORDER BY sort_order;
```

## OFFSET Pagination at Scale

```sql
-- Anti-pattern: OFFSET grows → full scan of discarded rows
SELECT * FROM orders ORDER BY created_at DESC LIMIT 20 OFFSET 50000;
-- At page 2500: scans and discards 50,000 rows → 2-10 seconds at 10M rows

-- Fix: keyset pagination (cursor-based)
-- First page:
SELECT id, total, created_at FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Next page (pass last row's values as cursor):
SELECT id, total, created_at FROM orders
WHERE (created_at, id) < ($last_created_at, $last_id)
ORDER BY created_at DESC, id DESC
LIMIT 20;
-- → Index Scan; constant time regardless of page number
```

## NOT IN with Subquery

```sql
-- Anti-pattern: NULL gotcha in NOT IN
SELECT * FROM orders WHERE user_id NOT IN (SELECT id FROM banned_users);
-- If banned_users contains ANY NULL, the entire result is empty
-- PostgreSQL cannot determine: is this value "not in" the set if the set has unknowns?

-- Fix: NOT EXISTS
SELECT o.* FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM banned_users b WHERE b.id = o.user_id);

-- Fix: LEFT JOIN / IS NULL
SELECT o.* FROM orders o
LEFT JOIN banned_users b ON b.id = o.user_id
WHERE b.id IS NULL;
```

## Function on Indexed Column

```sql
-- Anti-pattern: wrapping indexed column in a function defeats the index
SELECT * FROM orders WHERE DATE(created_at) = '2024-01-15';
SELECT * FROM users WHERE UPPER(email) = 'TEST@EXAMPLE.COM';
-- → Seq Scan; planner cannot use the index on created_at or email

-- Fix: rewrite as range condition
SELECT * FROM orders
WHERE created_at >= '2024-01-15' AND created_at < '2024-01-16';

-- Fix: expression index (if you must use the function form)
CREATE INDEX idx_users_email_upper ON users(upper(email));
SELECT * FROM users WHERE upper(email) = upper($1);
```

## DISTINCT as a Bug Fix

```sql
-- Anti-pattern: DISTINCT papering over a bad JOIN
SELECT DISTINCT u.id, u.name
FROM users u
JOIN orders o ON o.user_id = u.id
JOIN order_items oi ON oi.order_id = o.id
WHERE oi.product_id = $1;
-- DISTINCT on large sets is expensive; this means the JOIN produces duplicates

-- Fix: diagnose the join; use EXISTS instead
SELECT u.id, u.name
FROM users u
WHERE EXISTS (
  SELECT 1 FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  WHERE o.user_id = u.id AND oi.product_id = $1
);
```

## Quick Reference

```
N+1: JOIN or LATERAL instead of per-row queries
Missing FK index: PostgreSQL does not auto-create them; always add manually
SELECT *: name your columns; avoid TOAST overhead and heap fetches
OFFSET pagination: use keyset (cursor) pagination; OFFSET is O(n)
NOT IN + subquery: use NOT EXISTS (NULL-safe)
Function on column: rewrite as range or create expression index
DISTINCT: signals a broken JOIN; use EXISTS instead
LIKE '%text': cannot use B-tree; use GIN full-text search
```
