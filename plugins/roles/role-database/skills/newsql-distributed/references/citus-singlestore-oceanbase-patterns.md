# Citus, SingleStore, OceanBase — Distributed Tables, Hybrid Storage, Design Patterns, Operations

## When to load
Load when distributing PostgreSQL with Citus, designing SingleStore rowstore/columnstore hybrid tables with Kafka pipelines, working with OceanBase multi-tenancy, or applying distributed SQL design patterns (sharding keys, cross-shard queries, schema migrations, ID generation, monitoring, connection management).

## Citus — Distributed Tables and Columnar Storage

```sql
-- Citus extends PostgreSQL as a native extension
CREATE EXTENSION citus;

-- Add worker nodes
SELECT citus_set_coordinator_host('coordinator', 5432);
SELECT * FROM citus_add_node('worker1', 5432);
SELECT * FROM citus_add_node('worker2', 5432);

-- Distribute by a column (shards across workers)
SELECT create_distributed_table('orders', 'user_id');

-- Reference tables (replicated to all nodes, for JOINs)
SELECT create_reference_table('countries');

-- Colocate related tables (same shard key = local JOINs, no cross-shard traffic)
SELECT create_distributed_table('order_items', 'user_id', colocate_with := 'orders');

-- Columnar storage (append-only, compressed, for analytics)
CREATE TABLE events_archive (LIKE events) USING columnar;
SELECT alter_table_set_access_method('events_archive', 'columnar');

-- Check shard placement
SELECT * FROM citus_shards WHERE table_name = 'orders'::regclass;
SELECT * FROM citus_stat_statements ORDER BY total_time DESC LIMIT 10;
```

## SingleStore — Rowstore and Columnstore Hybrid

```sql
-- Rowstore table (in-memory, fast point lookups and writes)
CREATE TABLE user_sessions (
    session_id BINARY(16) NOT NULL,
    user_id BIGINT NOT NULL,
    data JSON,
    created_at DATETIME NOT NULL,
    SHARD KEY (user_id),
    SORT KEY (created_at),
    PRIMARY KEY (session_id)
) USING ROWSTORE;

-- Columnstore table (disk-based, fast analytics)
CREATE TABLE events (
    event_id BIGINT AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    event_type VARCHAR(50),
    properties JSON,
    created_at DATETIME NOT NULL,
    SHARD KEY (user_id),
    SORT KEY (created_at),
    KEY (event_type) USING HASH
) USING COLUMNSTORE;

-- Kafka pipeline ingestion
CREATE PIPELINE events_pipeline AS
LOAD DATA KAFKA 'broker:9092/events'
INTO TABLE events
FORMAT JSON (
    user_id <- user_id,
    event_type <- event_type,
    properties <- properties,
    created_at <- created_at
);
START PIPELINE events_pipeline;

-- Vector search (semantic search in distributed SQL)
SELECT id, content, DOT_PRODUCT(embedding, @query_vec) AS similarity
FROM documents ORDER BY similarity DESC LIMIT 10;
```

## OceanBase — Multi-Tenancy and Partitioning

```sql
-- OceanBase: distributed database from Ant Group
-- Supports MySQL and Oracle compatibility modes

-- Create tenant (multi-tenancy is a core feature)
CREATE TENANT app_tenant
    RESOURCE_POOL_LIST = ('pool1')
    SET ob_compatibility_mode = 'mysql',
        ob_tcp_invited_nodes = '%';

-- Partitioned table for distributed data
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    amount DECIMAL(12,2),
    created_at DATETIME
) PARTITION BY HASH(user_id) PARTITIONS 16;

-- Parallel DML for bulk operations
SET _force_parallel_dml_dop = 8;
INSERT /*+PARALLEL(8)*/ INTO orders_archive
SELECT * FROM orders WHERE created_at < '2023-01-01';
```

## Sharding Key Selection

```
Good shard keys:
  user_id     — isolates user data, enables user-scoped queries
  tenant_id   — natural multi-tenant isolation
  region      — geo-partitioning alignment

Bad shard keys:
  auto-increment ID  — hot-spot on single shard for inserts
  timestamp          — all recent writes go to one shard
  boolean / low-cardinality — uneven distribution
```

## Cross-Shard Query Patterns

```sql
-- Pattern 1: Colocate related tables on same shard key
-- orders and order_items both sharded by user_id → local JOIN
SELECT o.id, oi.product_name, oi.quantity
FROM orders o JOIN order_items oi ON o.id = oi.order_id
WHERE o.user_id = $1;

-- Pattern 2: Reference tables for dimension lookups (replicated everywhere)
SELECT o.*, c.name AS country_name
FROM orders o JOIN countries c ON o.country_code = c.code;

-- Pattern 3: Scatter-gather for cross-shard aggregations
SELECT country_code, COUNT(*), SUM(total)
FROM orders GROUP BY country_code;
-- Add indexes that support the aggregation to reduce per-shard work
```

## Schema Migration in Distributed SQL

```bash
# Non-blocking DDL is critical in distributed environments
# CockroachDB: DDL is online by default (schema change jobs)
# TiDB: Online DDL via internal DDL framework
# Vitess/PlanetScale: Online DDL via gh-ost or Vitess native strategy

# Expand-contract migration pattern:
# Step 1: Add nullable column (no default, no lock)
ALTER TABLE users ADD COLUMN email_verified BOOLEAN;

# Step 2: Backfill in batches (avoid full-table lock)
UPDATE users SET email_verified = false
WHERE email_verified IS NULL AND id BETWEEN $start AND $end;

# Step 3: Add NOT NULL after backfill completes
ALTER TABLE users ALTER COLUMN email_verified SET NOT NULL;
ALTER TABLE users ALTER COLUMN email_verified SET DEFAULT false;
```

## Global ID Generation

```sql
-- 1. UUID v7 (time-sortable, no coordination needed)
-- CockroachDB: gen_random_uuid()  YugabyteDB: gen_random_uuid()

-- 2. CockroachDB unique_rowid() (built-in distributed ID)
CREATE TABLE events (id INT DEFAULT unique_rowid() PRIMARY KEY, data JSONB);

-- 3. TiDB AUTO_RANDOM (distributed auto-increment alternative, no hotspot)
CREATE TABLE orders (
    id BIGINT AUTO_RANDOM PRIMARY KEY,
    user_id BIGINT,
    total DECIMAL(12,2)
);

-- 4. Snowflake IDs — application-level, 64-bit sortable (timestamp + worker + sequence)
```

## Connection Management and Monitoring

```bash
# Distributed SQL has higher per-query latency — connection pooling is essential
# CockroachDB: PgBouncer or built-in (Serverless)
# YugabyteDB: PgBouncer or Odyssey; set --ysql_max_connections flag
# TiDB: ProxySQL or HAProxy; configure max-server-connections

# Connection string with retry and timeout
postgresql://user:pass@cockroachdb:26257/mydb?sslmode=verify-full&connect_timeout=10&application_name=myapp
```

```sql
-- CockroachDB: DB Console at :8080
SELECT * FROM crdb_internal.node_statement_statistics ORDER BY service_lat_avg DESC LIMIT 20;
SHOW RANGES FROM TABLE orders;

-- YugabyteDB: master UI :7000, tserver UI :9000
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 20;

-- TiDB: Dashboard at http://pd:2379/dashboard, slow query log
SELECT * FROM information_schema.cluster_slow_query
WHERE time > DATE_SUB(NOW(), INTERVAL 1 HOUR) ORDER BY query_time DESC LIMIT 20;
```
