---
name: newsql-distributed
description: |
  Deep operational guide for 12 NewSQL/distributed SQL databases. CockroachDB (multi-region, geo-partitioning, CDC), YugabyteDB (YSQL/YCQL, DocDB, xCluster), TiDB (TiKV/TiFlash HTAP), Spanner (TrueTime), Vitess (sharding, VSchema), PlanetScale, Citus, SingleStore, OceanBase. Use when implementing globally distributed SQL, horizontal scaling, or HTAP workloads.
allowed-tools: Read, Grep, Glob, Bash
---

You are a NewSQL and distributed SQL database specialist informed by the Software Engineer by RN competency matrix.

## Distributed SQL Comparison

| Database | Consistency Model | PG Compatible | Horizontal Scale | Managed Options | HTAP |
|----------|------------------|---------------|-------------------|-----------------|------|
| CockroachDB | Serializable (default) | Wire protocol + SQL | Automatic sharding | CockroachDB Cloud (Dedicated/Serverless) | No |
| YugabyteDB | Serializable (YSQL) | Full PG (YSQL) + CQL (YCQL) | Automatic sharding | YugabyteDB Aeon | No |
| TiDB | Snapshot isolation (SI) | MySQL wire protocol | TiKV auto-split | TiDB Cloud | Yes (TiFlash) |
| Google Spanner | External consistency | PG interface (limited) | Automatic splits | Fully managed | No |
| Vitess | Depends on MySQL | MySQL wire protocol | Manual sharding (VSchema) | PlanetScale | No |
| PlanetScale | Depends on MySQL | MySQL wire protocol | Vitess-based sharding | Fully managed | No |
| CockroachDB Serverless | Serializable | Wire protocol + SQL | Auto-scaling | Fully managed | No |
| Citus (PostgreSQL) | PG defaults (RC) | Native PG extension | Manual distribution | Azure Cosmos DB for PG | No |
| SingleStore (MemSQL) | Read committed | MySQL wire protocol | Shard-nothing | SingleStore Helios | Yes (columnstore) |
| OceanBase | Read committed / Snapshot | MySQL + Oracle modes | Automatic partitioning | OceanBase Cloud | Yes |
| AlloyDB | PG defaults | Full PG | Read replicas | Google Cloud managed | Analytics accelerator |
| Neon | PG defaults | Full PG | Scale-to-zero compute | Fully managed serverless | No |

## CAP Theorem and Distributed SQL Tradeoffs

```
              Consistency
                 /\
                /  \
               /    \
              / CRDB \
             / YugaDB \
            / Spanner  \
           /____________\
          /              \
Availability ----------- Partition Tolerance

NewSQL databases choose CP (Consistency + Partition Tolerance):
- Automatic failover preserves availability in practice (high availability, not perfect)
- Raft/Paxos consensus ensures consistency across partitions
- Latency increases with geographic distance between replicas
```

## CockroachDB

### Multi-Region Topologies

```sql
-- Set up a multi-region database
ALTER DATABASE mydb PRIMARY REGION "us-east1";
ALTER DATABASE mydb ADD REGION "us-west1";
ALTER DATABASE mydb ADD REGION "eu-west1";

-- Survival goals
ALTER DATABASE mydb SURVIVE REGION FAILURE;  -- 3+ regions required
ALTER DATABASE mydb SURVIVE ZONE FAILURE;    -- default, single-region sufficient

-- Table locality strategies
-- GLOBAL: reads from any region without cross-region latency (non-blocking reads)
ALTER TABLE reference_data SET LOCALITY GLOBAL;

-- REGIONAL BY TABLE: all data in the primary region
ALTER TABLE user_sessions SET LOCALITY REGIONAL BY TABLE IN PRIMARY REGION;

-- REGIONAL BY ROW: row-level geo-partitioning (most flexible)
ALTER TABLE users ADD COLUMN region crdb_internal_region AS (
    CASE
        WHEN country IN ('US', 'CA', 'MX') THEN 'us-east1'
        WHEN country IN ('GB', 'DE', 'FR') THEN 'eu-west1'
        ELSE 'us-west1'
    END
) STORED;
ALTER TABLE users SET LOCALITY REGIONAL BY ROW AS region;
```

### CDC Changefeeds

```sql
-- Create a changefeed to Kafka
CREATE CHANGEFEED FOR TABLE orders, order_items
INTO 'kafka://broker1:9092?topic_prefix=cdc_'
WITH updated, resolved='10s',
     format = avro,
     confluent_schema_registry = 'http://schema-registry:8081',
     min_checkpoint_frequency = '30s';

-- Changefeed to cloud storage (for data lake ingestion)
CREATE CHANGEFEED FOR TABLE events
INTO 's3://my-bucket/cdc/?AWS_ACCESS_KEY_ID=xxx&AWS_SECRET_ACCESS_KEY=xxx'
WITH format = json, resolved, compression = gzip;

-- Webhook changefeed
CREATE CHANGEFEED FOR TABLE users
INTO 'webhook-https://api.example.com/webhooks/cdc'
WITH updated, webhook_auth_header = 'Bearer token123';
```

### Serializable Isolation Tuning

```sql
-- CockroachDB uses serializable isolation by default (strongest level)
-- Transaction retry loop pattern (required for serializable)
-- Application must handle 40001 RETRY_SERIALIZABLE errors

-- Check contention on specific tables
SELECT * FROM crdb_internal.cluster_contended_tables ORDER BY num_contention_events DESC;

-- Reduce contention with SELECT FOR UPDATE
BEGIN;
SELECT balance FROM accounts WHERE id = $1 FOR UPDATE;
UPDATE accounts SET balance = balance - $2 WHERE id = $1;
COMMIT;

-- Follower reads for stale-tolerant queries (reduce cross-region latency)
SELECT * FROM products AS OF SYSTEM TIME follower_read_timestamp();

-- Bounded staleness reads
SELECT * FROM inventory
AS OF SYSTEM TIME with_max_staleness('10s')
WHERE product_id = $1;
```

### Connection Pooling and Cluster Settings

```bash
# Recommended: use a connection pooler (CockroachDB has built-in SQL proxy in Serverless)
# For Dedicated clusters, use PgBouncer or application-level pooling

# Critical cluster settings
cockroach sql --execute="
SET CLUSTER SETTING kv.rangefeed.enabled = true;                    -- Required for CDC
SET CLUSTER SETTING kv.range_merge.queue_enabled = true;            -- Merge small ranges
SET CLUSTER SETTING server.time_until_store_dead = '5m0s';          -- Node failure detection
SET CLUSTER SETTING sql.defaults.idle_in_transaction_session_timeout = '60s';
"

# EXPLAIN ANALYZE for distributed query plans
EXPLAIN ANALYZE (DISTSQL) SELECT * FROM orders
JOIN users ON orders.user_id = users.id
WHERE users.region = 'us-east1'
ORDER BY orders.created_at DESC LIMIT 20;
```

## YugabyteDB

### YSQL vs YCQL

```sql
-- YSQL: PostgreSQL-compatible SQL (wire protocol + SQL syntax)
-- Supports PG extensions, stored procedures, triggers, foreign data wrappers
CREATE TABLE orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Colocated tables: small tables stored together on same tablet (reduces overhead)
CREATE DATABASE mydb WITH COLOCATED = true;
-- Opt specific large tables OUT of colocation
CREATE TABLE large_events (...) WITH (COLOCATED = false);

-- Tablespace-level geo-partitioning
CREATE TABLESPACE us_east WITH (
    replica_placement = '{"num_replicas": 3, "placement_blocks":
        [{"cloud":"aws","region":"us-east-1","zone":"us-east-1a","min_num_replicas":1},
         {"cloud":"aws","region":"us-east-1","zone":"us-east-1b","min_num_replicas":1},
         {"cloud":"aws","region":"us-east-1","zone":"us-east-1c","min_num_replicas":1}]}'
);

-- YCQL: Cassandra-compatible API (CQL wire protocol)
-- Use for wide-column workloads requiring extreme write throughput
CREATE KEYSPACE IF NOT EXISTS iot WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
CREATE TABLE iot.sensor_data (
    device_id TEXT,
    event_time TIMESTAMP,
    temperature DOUBLE,
    humidity DOUBLE,
    PRIMARY KEY (device_id, event_time)
) WITH CLUSTERING ORDER BY (event_time DESC)
  AND default_time_to_live = 2592000;  -- 30 days TTL
```

### DocDB Architecture and xCluster Replication

```bash
# DocDB: distributed document store underpinning both YSQL and YCQL
# Uses Raft consensus per tablet, auto-sharding, auto-rebalancing

# xCluster replication (async replication between universes)
yb-admin -master_addresses master1:7100,master2:7100,master3:7100 \
    setup_universe_replication \
    target_universe_uuid \
    source_master1:7100,source_master2:7100 \
    table_id_1,table_id_2

# Read replicas (async, read-only, lower latency for reads)
yb-admin modify_placement_info aws.us-west-2.us-west-2a,aws.us-west-2.us-west-2b 3 \
    --placement_uuid=read_replica_us_west

# Performance tuning flags
--yb_num_shards_per_tserver=8           # Tablets per tserver per table
--ysql_num_shards_per_tserver=4         # YSQL-specific tablet count
--enable_automatic_tablet_splitting=true # Auto-split large tablets
--tablet_split_low_phase_shard_count_per_node=8
--tablet_split_high_phase_shard_count_per_node=24
```

## TiDB

### TiKV + TiFlash HTAP Architecture

```sql
-- TiDB: MySQL-compatible SQL layer
-- TiKV: distributed KV storage (row-based, OLTP)
-- TiFlash: columnar storage replicas (OLAP)

-- Enable TiFlash replica for a table (HTAP: same table serves both OLTP and OLAP)
ALTER TABLE orders SET TIFLASH REPLICA 2;

-- TiDB optimizer automatically routes:
--   Point lookups / small range scans --> TiKV (row store)
--   Analytical aggregations --> TiFlash (columnar store)

-- Force TiFlash for analytics
SELECT /*+ READ_FROM_STORAGE(TIFLASH[orders]) */
    DATE(created_at) AS day,
    COUNT(*) AS order_count,
    SUM(total) AS revenue
FROM orders
WHERE created_at >= '2024-01-01'
GROUP BY DATE(created_at);

-- TiCDC: Change data capture for downstream consumers
-- Deploy TiCDC and create a changefeed
tiup cdc cli changefeed create \
    --pd=http://pd:2379 \
    --sink-uri="kafka://broker:9092/cdc-topic?protocol=avro" \
    --changefeed-id="orders-cdc" \
    --sort-engine="unified"

-- Placement rules: control data location
ALTER TABLE users SET PLACEMENT POLICY=us_east_policy;
CREATE PLACEMENT POLICY us_east_policy
    PRIMARY_REGION="us-east"
    REGIONS="us-east,us-west"
    FOLLOWERS=4;

-- Online DDL (non-blocking schema changes)
ALTER TABLE orders ADD INDEX idx_status_date (status, created_at);
-- Check DDL job progress
ADMIN SHOW DDL JOBS 10;
```

### TiDB Dashboard and Diagnostics

```bash
# TiDB Dashboard: built-in web UI at http://pd:2379/dashboard
# Features: SQL analysis, slow query log, cluster diagnostics, key visualizer

# Slow query analysis
SELECT * FROM information_schema.slow_query
WHERE time > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY query_time DESC LIMIT 20;

# TiSpark: run Spark SQL directly on TiKV data
spark.sql("SELECT region, SUM(amount) FROM tikv_orders GROUP BY region").show()
```

## Google Spanner

### TrueTime and External Consistency

```sql
-- Spanner uses TrueTime (GPS + atomic clocks) for globally consistent timestamps
-- Guarantees external consistency: if T1 commits before T2 starts, T1's timestamp < T2's

-- PostgreSQL interface (pgAdapter)
-- Connect using standard PG clients via pgAdapter proxy
CREATE TABLE users (
    user_id TEXT NOT NULL,
    email TEXT NOT NULL,
    name TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) PRIMARY KEY (user_id);

-- Interleaved tables (parent-child co-location for efficient joins)
CREATE TABLE orders (
    user_id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    total NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending'
) PRIMARY KEY (user_id, order_id),
INTERLEAVE IN PARENT users ON DELETE CASCADE;

-- This ensures all orders for a user are stored on the same split as the user row
-- Eliminates cross-node joins for user->orders queries

-- Change streams (CDC)
CREATE CHANGE STREAM user_changes FOR users, orders
OPTIONS (retention_period = '7d', value_capture_type = 'NEW_AND_OLD_VALUES');

-- Read staleness for reduced latency (bounded staleness)
-- Via client library: .singleUse(TimestampBound.ofMaxStaleness(15, TimeUnit.SECONDS))

-- Multi-region configuration
-- Managed via Google Cloud Console or Terraform
-- Instance configs: nam6 (US), eur6 (Europe), nam-eur-asia1 (global)
```

## Vitess

### Sharding Topology and VSchema

```json
// VSchema: defines sharding strategy
{
  "sharded": true,
  "vindexes": {
    "hash_user_id": {
      "type": "hash"
    },
    "lookup_email": {
      "type": "consistent_lookup_unique",
      "params": {
        "table": "email_user_id_lookup",
        "from": "email",
        "to": "user_id"
      },
      "owner": "users"
    }
  },
  "tables": {
    "users": {
      "column_vindexes": [
        { "column": "user_id", "name": "hash_user_id" }
      ]
    },
    "orders": {
      "column_vindexes": [
        { "column": "user_id", "name": "hash_user_id" }
      ]
    }
  }
}
```

```bash
# Vitess components
# vtgate: query router (stateless, clients connect here)
# vttablet: per-MySQL shard process (manages replication, schema)
# vtctld: cluster management daemon

# MoveTables: migrate tables between keyspaces (zero-downtime)
vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users create \
    --source-keyspaces=unsharded_ks --tables=users,orders

vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users show
vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users switchtraffic
vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users complete

# Reshard: split or merge shards
vtctldclient Reshard --target-keyspace=sharded_ks --workflow=reshard_4_to_8 create \
    --source-shards='-80,80-' --target-shards='-40,40-80,80-c0,c0-'

# Online DDL (non-blocking schema changes via gh-ost or vitess native)
vtctldclient ApplySchema --sql="ALTER TABLE users ADD COLUMN phone VARCHAR(20)" \
    --ddl-strategy="vitess" --keyspace=sharded_ks
```

## PlanetScale

### Vitess-Powered Database Branching

```bash
# PlanetScale CLI (pscale)
# Create database
pscale database create myapp --region us-east

# Branch workflow (git-like branching for database schemas)
pscale branch create myapp add-phone-column
pscale shell myapp add-phone-column
# > ALTER TABLE users ADD COLUMN phone VARCHAR(20);

# Create deploy request (like a PR for schema changes)
pscale deploy-request create myapp add-phone-column
pscale deploy-request deploy myapp 1

# Non-blocking schema changes: PlanetScale applies DDL without locking tables
# Uses Vitess Online DDL under the hood

# Connection strings
pscale connect myapp main --port 3306
# Or use connection string from dashboard

# PlanetScale Boost (query caching at edge)
# Enabled per-query via dashboard or API
# Automatically caches SELECT query results, invalidates on writes
```

## Citus / PostgreSQL

### Distributed Tables and Columnar Storage

```sql
-- Citus extends PostgreSQL with distributed tables
-- Install as PG extension
CREATE EXTENSION citus;

-- Add worker nodes
SELECT citus_set_coordinator_host('coordinator', 5432);
SELECT * FROM citus_add_node('worker1', 5432);
SELECT * FROM citus_add_node('worker2', 5432);

-- Distribute a table by a distribution column
SELECT create_distributed_table('orders', 'user_id');

-- Reference tables (replicated to all nodes, for JOINs with distributed tables)
SELECT create_reference_table('countries');

-- Colocate related tables (same distribution key = local JOINs)
SELECT create_distributed_table('order_items', 'user_id', colocate_with := 'orders');

-- Queries automatically distributed
SELECT user_id, COUNT(*), SUM(total)
FROM orders
WHERE created_at >= '2024-01-01'
GROUP BY user_id
ORDER BY SUM(total) DESC
LIMIT 100;

-- Columnar storage (append-only, compressed, for analytics)
CREATE TABLE events_archive (LIKE events)
USING columnar;

-- Convert existing table to columnar
SELECT alter_table_set_access_method('events_archive', 'columnar');

-- Check distribution and shard placement
SELECT * FROM citus_shards WHERE table_name = 'orders'::regclass;
SELECT * FROM citus_stat_statements ORDER BY total_time DESC LIMIT 10;
```

## SingleStore (MemSQL)

### Rowstore + Columnstore Hybrid

```sql
-- SingleStore combines rowstore (OLTP) and columnstore (OLAP)

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

-- Real-time analytics: pipeline ingestion from Kafka
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

-- Vector functions (semantic search in distributed SQL)
SELECT id, content,
       DOT_PRODUCT(embedding, @query_vec) AS similarity
FROM documents
ORDER BY similarity DESC
LIMIT 10;
```

## OceanBase

### Hybrid OLTP/OLAP and Multi-Tenancy

```sql
-- OceanBase: distributed database from Ant Group
-- Supports MySQL and Oracle compatibility modes

-- Create tenant (multi-tenancy is a core feature)
CREATE TENANT app_tenant
    RESOURCE_POOL_LIST = ('pool1')
    SET ob_compatibility_mode = 'mysql',
        ob_tcp_invited_nodes = '%';

-- Partitioning for distributed data
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    amount DECIMAL(12,2),
    created_at DATETIME
) PARTITION BY HASH(user_id) PARTITIONS 16;

-- Parallel DML for bulk operations
SET _force_parallel_dml_dop = 8;
INSERT /*+PARALLEL(8)*/ INTO orders_archive SELECT * FROM orders WHERE created_at < '2023-01-01';
```

## Distributed SQL Design Patterns

### Sharding Key Selection

```
Good shard keys:
  - user_id: isolates user data, enables user-scoped queries
  - tenant_id: natural multi-tenant isolation
  - region: geo-partitioning alignment

Bad shard keys:
  - auto-increment ID: causes hot-spot on single shard for inserts
  - timestamp: all recent writes go to one shard
  - boolean / low-cardinality: uneven distribution
```

### Cross-Shard Query Patterns

```sql
-- Pattern 1: Colocate related tables on same shard key
-- orders and order_items both sharded by user_id
-- JOIN is local (no cross-shard traffic)
SELECT o.id, oi.product_name, oi.quantity
FROM orders o JOIN order_items oi ON o.id = oi.order_id
WHERE o.user_id = $1;

-- Pattern 2: Reference tables for lookups
-- countries, currencies, config tables replicated to all nodes
SELECT o.*, c.name AS country_name
FROM orders o JOIN countries c ON o.country_code = c.code;

-- Pattern 3: Scatter-gather for cross-shard aggregations
-- Query is sent to all shards, results merged at coordinator
SELECT country_code, COUNT(*), SUM(total)
FROM orders
GROUP BY country_code;
-- Tip: add indexes that support the aggregation to reduce per-shard work
```

### Schema Migration in Distributed SQL

```bash
# Non-blocking DDL is critical in distributed databases
# CockroachDB: DDL is online by default (schema change jobs)
# TiDB: Online DDL via internal DDL framework
# Vitess/PlanetScale: Online DDL via gh-ost or Vitess native strategy

# Pattern: expand-contract migration
# Step 1: Add new column (nullable, no default)
ALTER TABLE users ADD COLUMN email_verified BOOLEAN;

# Step 2: Backfill in batches (avoid locking entire table)
UPDATE users SET email_verified = false WHERE email_verified IS NULL AND id BETWEEN $start AND $end;

# Step 3: Add NOT NULL constraint (after backfill completes)
ALTER TABLE users ALTER COLUMN email_verified SET NOT NULL;

# Step 4: Add default for new rows
ALTER TABLE users ALTER COLUMN email_verified SET DEFAULT false;
```

### Global Sequence / ID Generation

```sql
-- Distributed databases cannot use traditional auto-increment efficiently
-- Recommended approaches:

-- 1. UUID v7 (time-sortable, no coordination)
-- CockroachDB: gen_random_uuid() or use UUIDv7 library
-- YugabyteDB: gen_random_uuid()

-- 2. Snowflake IDs (timestamp + worker + sequence)
-- Application-level generation, 64-bit sortable IDs

-- 3. CockroachDB unique_rowid() (built-in distributed ID)
CREATE TABLE events (
    id INT DEFAULT unique_rowid() PRIMARY KEY,
    data JSONB
);

-- 4. TiDB AUTO_RANDOM (distributed auto-increment alternative)
CREATE TABLE orders (
    id BIGINT AUTO_RANDOM PRIMARY KEY,
    user_id BIGINT,
    total DECIMAL(12,2)
);
```

## Operational Best Practices

### Connection Management

```bash
# Distributed SQL databases have higher per-query latency than single-node
# Connection pooling is essential

# CockroachDB: use PgBouncer or built-in connection pooling (Serverless)
# YugabyteDB: use PgBouncer or Odyssey; set --ysql_max_connections flag
# TiDB: use ProxySQL or HAProxy; configure max-server-connections in TiDB

# Connection string with retry and timeout
postgresql://user:pass@cockroachdb:26257/mydb?sslmode=verify-full&connect_timeout=10&application_name=myapp
```

### Monitoring Distributed SQL

```sql
-- CockroachDB: built-in DB Console at :8080
SELECT * FROM crdb_internal.node_statement_statistics ORDER BY service_lat_avg DESC LIMIT 20;
SHOW RANGES FROM TABLE orders;

-- YugabyteDB: master UI at :7000, tserver UI at :9000
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 20;

-- TiDB: TiDB Dashboard, slow query log, INFORMATION_SCHEMA
SELECT * FROM information_schema.cluster_slow_query
WHERE time > DATE_SUB(NOW(), INTERVAL 1 HOUR) ORDER BY query_time DESC LIMIT 20;
```

### Backup and Recovery

```bash
# CockroachDB: incremental backups to cloud storage
BACKUP DATABASE mydb INTO 's3://bucket/backups?AUTH=implicit'
WITH revision_history, incremental_location = 's3://bucket/backups/incremental';

# YugabyteDB: snapshot-based backups
yb-admin create_snapshot ysql.mydb
yb-admin export_snapshot <snapshot_id> s3://bucket/backups/

# TiDB: BR (Backup & Restore) tool
tiup br backup full --pd "pd:2379" --storage "s3://bucket/backups" --send-credentials-to-tikv=true

# Spanner: managed automatic backups + on-demand
gcloud spanner backups create mydb-backup --instance=myinstance --database=mydb --retention-period=30d
```
