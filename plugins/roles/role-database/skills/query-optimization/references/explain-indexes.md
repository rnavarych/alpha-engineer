# EXPLAIN Analysis and Index Strategies

## When to load
Load when analyzing query execution plans across PostgreSQL, MySQL, MongoDB, or ClickHouse, designing composite or partial indexes, or creating covering indexes to eliminate heap access.

## EXPLAIN Analysis by Engine

### PostgreSQL
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT ...;

-- Key metrics:
-- Planning Time / Execution Time
-- Seq Scan vs Index Scan (seq scan on large tables = problem)
-- Rows estimated vs actual (large mismatch = stale statistics → run ANALYZE)
-- Shared hit vs shared read (low hit ratio = insufficient shared_buffers)
-- Sort Method: external merge = insufficient work_mem
```

**Red Flags in PostgreSQL Plans:**
- `Seq Scan` on tables > 10K rows with WHERE clause → missing index
- `Nested Loop` with large outer table → consider Hash Join (check work_mem)
- `Sort → external merge` → increase `work_mem`
- Estimated vs actual rows differ by 10x+ → run `ANALYZE` on table

### MySQL
```sql
EXPLAIN FORMAT=TREE SELECT ...;
EXPLAIN ANALYZE SELECT ...;  -- Actually executes query

-- type column: ALL (full scan) < index < range < ref < eq_ref < const
-- Extra: Using filesort, Using temporary = potential issues
-- filtered: percentage of rows filtered by WHERE
```

### MongoDB
```javascript
db.collection.find({...}).explain("executionStats");
// totalDocsExamined vs nReturned (should approach 1:1)
// stage: COLLSCAN = no index, IXSCAN = good
// executionTimeMillis
```

### ClickHouse
```sql
EXPLAIN PIPELINE SELECT ...;
EXPLAIN PLAN actions=1 SELECT ...;

SELECT query, read_rows, read_bytes, memory_usage, query_duration_ms
FROM system.query_log WHERE type = 'QueryFinish' ORDER BY event_time DESC LIMIT 10;
```

## Index Types by Engine

| Index Type | PostgreSQL | MySQL | MongoDB | Use Case |
|-----------|------------|-------|---------|----------|
| **B-tree** | Default | Default (InnoDB) | Default | Equality, range, sorting, LIKE 'prefix%' |
| **Hash** | Yes | Adaptive (InnoDB) | Hashed | Equality only |
| **GIN** | Yes | — | — | Arrays, JSONB, full-text |
| **GiST** | Yes | — | 2dsphere | Geometric, range types, nearest-neighbor |
| **BRIN** | Yes | — | — | Large sequential/time-ordered tables |
| **Full-text** | tsvector/tsquery | FULLTEXT | Text | Natural language search |
| **Partial** | Yes | — | Partial filter | Index subset of rows |
| **Covering** | INCLUDE clause | Covering | Covered | Avoid heap access (index-only scan) |

## Composite Index Design Rules
1. **Equality columns first**: Columns in `WHERE col = value` go first
2. **Range/sort columns last**: Columns in `WHERE col > value` or `ORDER BY col`
3. **Most selective column first** within equality group
4. `INDEX(a, b, c)` supports `WHERE a=1`, `WHERE a=1 AND b=2`, but NOT `WHERE b=2` alone

## Partial and Covering Indexes

```sql
-- Partial indexes (PostgreSQL)
CREATE INDEX idx_users_active_email ON users (email) WHERE is_active = true;
CREATE INDEX idx_orders_pending ON orders (created_at) WHERE deleted_at IS NULL AND status = 'pending';
CREATE UNIQUE INDEX uq_users_email_active ON users (email) WHERE deleted_at IS NULL;

-- Covering index: INCLUDE avoids heap access (index-only scan)
CREATE INDEX idx_orders_customer ON orders (customer_id) INCLUDE (total, status, created_at);

-- MySQL: secondary indexes include PK columns automatically
CREATE INDEX idx_orders_customer_status ON orders (customer_id, status);
-- Effectively stores (customer_id, status, id) if PK is (id)
```

## Statistics and Cardinality

```sql
-- PostgreSQL: update statistics
ANALYZE orders;

-- Check column statistics (most common values, histogram)
SELECT * FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';

-- Increase statistics target for skewed distribution
ALTER TABLE orders ALTER COLUMN status SET STATISTICS 1000;
ANALYZE orders;

-- MySQL: update and check statistics
ANALYZE TABLE orders;
SHOW INDEX FROM orders;
ANALYZE TABLE orders UPDATE HISTOGRAM ON status, payment_method WITH 256 BUCKETS;
```
