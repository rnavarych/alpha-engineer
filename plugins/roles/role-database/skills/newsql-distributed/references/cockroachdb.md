# CockroachDB — Multi-Region, CDC Changefeeds, Serializable Isolation, Cluster Settings

## When to load
Load when configuring CockroachDB multi-region topologies, setting up CDC changefeeds to Kafka or S3, tuning serializable isolation with follower reads, or managing cluster settings and connection pooling.

## Multi-Region Topologies

```sql
-- Set up a multi-region database
ALTER DATABASE mydb PRIMARY REGION "us-east1";
ALTER DATABASE mydb ADD REGION "us-west1";
ALTER DATABASE mydb ADD REGION "eu-west1";

-- Survival goals
ALTER DATABASE mydb SURVIVE REGION FAILURE;  -- 3+ regions required
ALTER DATABASE mydb SURVIVE ZONE FAILURE;    -- default, single-region sufficient

-- GLOBAL: non-blocking reads from any region (reference data)
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

## CDC Changefeeds

```sql
-- Changefeed to Kafka with Avro + schema registry
CREATE CHANGEFEED FOR TABLE orders, order_items
INTO 'kafka://broker1:9092?topic_prefix=cdc_'
WITH updated, resolved='10s',
     format = avro,
     confluent_schema_registry = 'http://schema-registry:8081',
     min_checkpoint_frequency = '30s';

-- Changefeed to cloud storage (data lake ingestion)
CREATE CHANGEFEED FOR TABLE events
INTO 's3://my-bucket/cdc/?AWS_ACCESS_KEY_ID=xxx&AWS_SECRET_ACCESS_KEY=xxx'
WITH format = json, resolved, compression = gzip;

-- Webhook changefeed
CREATE CHANGEFEED FOR TABLE users
INTO 'webhook-https://api.example.com/webhooks/cdc'
WITH updated, webhook_auth_header = 'Bearer token123';
```

## Serializable Isolation Tuning

```sql
-- CockroachDB uses serializable isolation by default (strongest level)
-- Application must handle 40001 RETRY_SERIALIZABLE errors

-- Check contention on specific tables
SELECT * FROM crdb_internal.cluster_contended_tables ORDER BY num_contention_events DESC;

-- Reduce contention with SELECT FOR UPDATE
BEGIN;
SELECT balance FROM accounts WHERE id = $1 FOR UPDATE;
UPDATE accounts SET balance = balance - $2 WHERE id = $1;
COMMIT;

-- Follower reads: stale-tolerant queries at reduced cross-region latency
SELECT * FROM products AS OF SYSTEM TIME follower_read_timestamp();

-- Bounded staleness reads
SELECT * FROM inventory
AS OF SYSTEM TIME with_max_staleness('10s')
WHERE product_id = $1;
```

## Connection Pooling and Cluster Settings

```bash
# Dedicated clusters: use PgBouncer or application-level pooling
# Serverless clusters: built-in SQL proxy

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

## Monitoring and Diagnostics

```sql
-- Built-in DB Console at :8080
SELECT * FROM crdb_internal.node_statement_statistics ORDER BY service_lat_avg DESC LIMIT 20;
SHOW RANGES FROM TABLE orders;
```

## Backup and Recovery

```sql
BACKUP DATABASE mydb INTO 's3://bucket/backups?AUTH=implicit'
WITH revision_history, incremental_location = 's3://bucket/backups/incremental';
```
