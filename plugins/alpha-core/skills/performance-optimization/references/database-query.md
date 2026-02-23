# Database Query Optimization

## When to load
Load when analyzing slow queries with EXPLAIN ANALYZE, choosing index types, or tuning connection pools.

## EXPLAIN ANALYZE Examples

### PostgreSQL
```sql
-- Analyze a slow query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.id, o.total, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.created_at > NOW() - INTERVAL '30 days'
  AND o.status = 'completed'
ORDER BY o.created_at DESC
LIMIT 50;

-- Reading the output:
-- Seq Scan: Full table scan (bad for large tables, consider index)
-- Index Scan: Using index (good)
-- Index Only Scan: Covered by index (best)
-- Hash Join: Good for larger joins
-- Buffers: shared hit = from cache, shared read = from disk
```

### Before/After Optimization Example
```sql
-- Before: Sequential scan, 2.3 seconds
-- Seq Scan on orders  (rows=50000)  actual time=0.01..2300.00
-- Buffers: shared read=125000

-- Add composite index matching query pattern
CREATE INDEX idx_orders_customer_date ON orders(customer_id, created_at DESC);

-- After: Index scan, 2ms
-- Index Scan using idx_orders_customer_date  (rows=150)  actual time=0.02..1.80
-- Buffers: shared hit=12

-- Covering index to avoid table lookup
CREATE INDEX idx_orders_cover ON orders(customer_id, created_at DESC)
  INCLUDE (total, status);

-- Partial index for common filter
CREATE INDEX idx_orders_pending ON orders(created_at DESC)
  WHERE status = 'pending';

-- GIN index for JSONB queries
CREATE INDEX idx_metadata_gin ON orders USING gin(metadata jsonb_path_ops);
-- Supports: metadata @> '{"priority": "high"}'

ANALYZE orders;  -- Update statistics for accurate query plans
```

### MySQL
```sql
EXPLAIN FORMAT=TREE
SELECT o.id, o.total, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.customer_id = 42 AND o.created_at > '2025-01-01'
ORDER BY o.created_at DESC LIMIT 20;

-- Find slow queries
SELECT * FROM sys.statements_with_runtimes_in_95th_percentile
ORDER BY avg_latency DESC LIMIT 10;

-- Unused indexes (candidates for removal)
SELECT * FROM sys.schema_unused_indexes;
```

## Index Types

| Index Type | Engine | Use Case | Example |
|-----------|--------|----------|---------|
| **B-tree** | PG, MySQL, all | Default. Equality, range, sorting, prefix | `CREATE INDEX idx ON orders(created_at)` |
| **Hash** | PG, MySQL 8.0+ | Exact equality only | `CREATE INDEX idx ON users USING hash(email)` |
| **GIN** | PostgreSQL | Arrays, JSONB, full-text search | `CREATE INDEX idx ON docs USING gin(tags)` |
| **GiST** | PostgreSQL | Geometric, range types, PostGIS | `CREATE INDEX idx ON places USING gist(location)` |
| **BRIN** | PostgreSQL | Large sequential data (timestamps) | `CREATE INDEX idx ON logs USING brin(created_at)` |
| **Partial** | PostgreSQL | Index subset of rows | `CREATE INDEX idx ON orders(id) WHERE status='pending'` |
| **Covering** | PG 11+, MySQL 8.0+ | Avoid table lookup | `CREATE INDEX idx ON orders(status) INCLUDE (total, created_at)` |
| **Composite** | All | Multi-column queries. Column order matters. | `CREATE INDEX idx ON orders(customer_id, created_at DESC)` |

## Query Plan Red Flags
- **Sequential scan on large table**: Add appropriate index
- **High rows estimate vs. actual**: Statistics are stale, run `ANALYZE`
- **Nested loop with large inner table**: Consider hash join, add index, or restructure
- **Sort operation**: Can often be eliminated with index matching ORDER BY
- **High buffer reads vs. hits**: Working set exceeds shared_buffers

## Connection Pooling

### PgBouncer Configuration
```ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_port = 6432
pool_mode = transaction          ; transaction (recommended), session, statement
default_pool_size = 20
min_pool_size = 5
max_client_conn = 1000
max_db_connections = 50
server_idle_timeout = 300
query_wait_timeout = 120
```

### HikariCP (Java)
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      leak-detection-threshold: 60000
```

### Pool Sizing Formula
```
optimal_pool_size = (core_count * 2) + effective_spindle_count
# For SSD: effective_spindle_count = 1
# Example: 4-core server with SSD: (4 * 2) + 1 = 9 connections per pool

# Multiple app instances sharing one database:
max_per_instance = total_db_connections / number_of_instances
```
