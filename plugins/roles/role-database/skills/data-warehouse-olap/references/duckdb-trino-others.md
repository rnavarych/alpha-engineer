# DuckDB, Trino, Hive, Doris, and Firebolt

## When to load
Load when working with DuckDB (in-process OLAP, Parquet/CSV/Arrow queries), Trino/PrestoSQL (federated queries across multiple sources), Apache Hive (Hadoop/LLAP), Apache Doris (MySQL-compatible OLAP), or Firebolt (sparse indexes).

## DuckDB — In-Process OLAP

```sql
-- Query Parquet files directly — no loading required
SELECT region, COUNT(*), SUM(amount) FROM 'orders/*.parquet' GROUP BY region;

-- CSV with auto-detection
SELECT * FROM read_csv('data.csv', auto_detect=true);

-- S3 integration
INSTALL httpfs; LOAD httpfs;
SET s3_region='us-east-1';
SELECT * FROM 's3://my-bucket/orders/*.parquet' LIMIT 100;

-- Performance tuning
SET memory_limit = '8GB';
SET threads = 8;
SET temp_directory = '/tmp/duckdb';

-- Persistent table from Parquet
CREATE TABLE orders AS SELECT * FROM 'orders/*.parquet';
CREATE INDEX idx_order_id ON orders(order_id);

-- Export
COPY (SELECT * FROM daily_summary) TO 'output.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);
```

```python
import duckdb, pandas as pd
con = duckdb.connect(':memory:')  # or 'analytics.duckdb' for persistent
df = pd.read_csv('orders.csv')
result = con.execute("SELECT region, SUM(amount) FROM df GROUP BY region").fetchdf()
con.install_extension('spatial')  # PostGIS-like geo
con.install_extension('iceberg')  # Iceberg tables
con.install_extension('delta')    # Delta Lake
```

## Trino / PrestoSQL — Federated Queries

```sql
-- Connectors: PostgreSQL, MySQL, Hive, Delta Lake, Iceberg, MongoDB, Kafka, S3, BigQuery, Redshift
-- Federated query: join data from different systems in one SQL statement
SELECT pg.customer_name, es.search_score, hive.purchase_history
FROM postgresql.public.customers pg
JOIN elasticsearch.default.search_results es ON pg.id = es.customer_id
JOIN hive.analytics.purchases hive ON pg.id = hive.customer_id;

SET SESSION query_max_memory = '4GB'; SET SESSION task_concurrency = 16;
```

## Apache Hive — Hadoop/LLAP

```sql
CREATE TABLE orders (
    order_id BIGINT, customer_id BIGINT,
    amount DECIMAL(12, 2), order_date DATE
)
PARTITIONED BY (year INT, month INT)
CLUSTERED BY (customer_id) INTO 32 BUCKETS
STORED AS ORC
TBLPROPERTIES ('transactional' = 'true', 'orc.compress' = 'ZSTD');

-- LLAP: in-memory caching for sub-second interactive queries
-- SET hive.llap.execution.mode = all;

-- Tez execution engine (replaces MapReduce)
SET hive.execution.engine = tez;
```

## Apache Doris — MySQL-Compatible OLAP

```sql
CREATE TABLE orders (
    order_id BIGINT, customer_id BIGINT,
    amount DECIMAL(12, 2), order_date DATE, region VARCHAR(50)
)
DUPLICATE KEY(order_id)
PARTITION BY RANGE(order_date) (
    PARTITION p2024 VALUES [('2024-01-01'), ('2025-01-01'))
)
DISTRIBUTED BY HASH(order_id) BUCKETS 16
PROPERTIES ("replication_num" = "3");

CREATE MATERIALIZED VIEW mv_daily_revenue AS
SELECT order_date, region, SUM(amount) AS total, COUNT(*) AS cnt
FROM orders GROUP BY order_date, region;

-- Real-time ingestion via Stream Load
-- curl -X PUT -H "format: json" -T orders.json http://fe:8030/api/db/orders/_stream_load
```

## Firebolt — Sparse Indexes

```sql
CREATE TABLE orders (
    order_id BIGINT, customer_id BIGINT,
    amount DECIMAL(12, 2), order_date DATE, metadata TEXT
)
PRIMARY INDEX order_date, customer_id;  -- sparse index (not B-tree)

-- Aggregating index: pre-computed aggregations
CREATE AGGREGATING INDEX agg_daily_revenue ON orders (
    order_date, SUM(amount), COUNT(*)
);

-- Semi-structured data
SELECT order_id,
       metadata::JSON->>'shipping_method' AS shipping,
       metadata::JSON->'items'->0->>'name' AS first_item
FROM orders;
```
