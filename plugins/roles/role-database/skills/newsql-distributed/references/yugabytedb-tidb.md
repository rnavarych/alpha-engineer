# YugabyteDB and TiDB — YSQL/YCQL/DocDB, TiKV/TiFlash HTAP, CDC, Diagnostics

## When to load
Load when working with YugabyteDB YSQL/YCQL APIs, DocDB tablet architecture, xCluster replication, TiDB HTAP with TiFlash columnar replicas, TiCDC changefeeds, placement rules, or online DDL in distributed MySQL-compatible SQL.

## YugabyteDB — YSQL and YCQL

```sql
-- YSQL: PostgreSQL-compatible (wire protocol + SQL syntax)
-- Supports PG extensions, stored procedures, triggers, FDWs
CREATE TABLE orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Colocated tables: small tables on same tablet (reduces overhead)
CREATE DATABASE mydb WITH COLOCATED = true;
CREATE TABLE large_events (...) WITH (COLOCATED = false);  -- opt out

-- Tablespace-level geo-partitioning
CREATE TABLESPACE us_east WITH (
    replica_placement = '{"num_replicas": 3, "placement_blocks":
        [{"cloud":"aws","region":"us-east-1","zone":"us-east-1a","min_num_replicas":1},
         {"cloud":"aws","region":"us-east-1","zone":"us-east-1b","min_num_replicas":1},
         {"cloud":"aws","region":"us-east-1","zone":"us-east-1c","min_num_replicas":1}]}'
);

-- YCQL: Cassandra-compatible API (CQL wire protocol) for high-write workloads
CREATE KEYSPACE IF NOT EXISTS iot WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
CREATE TABLE iot.sensor_data (
    device_id TEXT,
    event_time TIMESTAMP,
    temperature DOUBLE,
    humidity DOUBLE,
    PRIMARY KEY (device_id, event_time)
) WITH CLUSTERING ORDER BY (event_time DESC)
  AND default_time_to_live = 2592000;
```

## YugabyteDB — DocDB and xCluster

```bash
# DocDB: distributed document store under both YSQL and YCQL
# Uses Raft consensus per tablet, auto-sharding, auto-rebalancing

# xCluster async replication between universes
yb-admin -master_addresses master1:7100,master2:7100,master3:7100 \
    setup_universe_replication \
    target_universe_uuid \
    source_master1:7100,source_master2:7100 \
    table_id_1,table_id_2

# Read replicas (async, read-only, lower latency)
yb-admin modify_placement_info aws.us-west-2.us-west-2a,aws.us-west-2.us-west-2b 3 \
    --placement_uuid=read_replica_us_west

# Performance tuning flags
--yb_num_shards_per_tserver=8
--ysql_num_shards_per_tserver=4
--enable_automatic_tablet_splitting=true
--tablet_split_low_phase_shard_count_per_node=8
--tablet_split_high_phase_shard_count_per_node=24
```

## YugabyteDB — Backup and Monitoring

```bash
# Snapshot-based backup
yb-admin create_snapshot ysql.mydb
yb-admin export_snapshot <snapshot_id> s3://bucket/backups/

# Monitoring: master UI at :7000, tserver UI at :9000
# pg_stat_statements works via YSQL
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 20;
```

## TiDB — TiKV + TiFlash HTAP

```sql
-- TiDB: MySQL-compatible SQL layer
-- TiKV: distributed KV storage (row-based, OLTP)
-- TiFlash: columnar storage replicas (OLAP)

-- Enable TiFlash replica (same table serves OLTP and OLAP)
ALTER TABLE orders SET TIFLASH REPLICA 2;

-- Optimizer auto-routes: point lookups → TiKV, aggregations → TiFlash
-- Force TiFlash for analytics
SELECT /*+ READ_FROM_STORAGE(TIFLASH[orders]) */
    DATE(created_at) AS day,
    COUNT(*) AS order_count,
    SUM(total) AS revenue
FROM orders
WHERE created_at >= '2024-01-01'
GROUP BY DATE(created_at);
```

## TiDB — CDC, Placement, Online DDL

```bash
# TiCDC: Change data capture for downstream consumers
tiup cdc cli changefeed create \
    --pd=http://pd:2379 \
    --sink-uri="kafka://broker:9092/cdc-topic?protocol=avro" \
    --changefeed-id="orders-cdc" \
    --sort-engine="unified"
```

```sql
-- Placement rules: control data location
CREATE PLACEMENT POLICY us_east_policy
    PRIMARY_REGION="us-east"
    REGIONS="us-east,us-west"
    FOLLOWERS=4;
ALTER TABLE users SET PLACEMENT POLICY=us_east_policy;

-- Online DDL (non-blocking schema changes)
ALTER TABLE orders ADD INDEX idx_status_date (status, created_at);
ADMIN SHOW DDL JOBS 10;  -- Check progress
```

## TiDB — Diagnostics

```bash
# TiDB Dashboard: built-in web UI at http://pd:2379/dashboard
# SQL analysis, slow query log, cluster diagnostics, key visualizer

SELECT * FROM information_schema.slow_query
WHERE time > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY query_time DESC LIMIT 20;

# TiDB BR (Backup & Restore)
tiup br backup full --pd "pd:2379" --storage "s3://bucket/backups" --send-credentials-to-tikv=true
```
