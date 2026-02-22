---
name: data-warehouse-olap
description: |
  Deep operational guide for 14 data warehouse/OLAP databases. Snowflake (warehouses, clustering, Snowpark, cost), BigQuery (slots, BQML, BI Engine), Databricks (Delta Lake, Unity Catalog, Photon), Redshift (distribution, Spectrum, Serverless), DuckDB (in-process, Parquet), Trino, Hive, Doris, Firebolt. Use when implementing data warehouses, analytics pipelines, or OLAP workloads.
allowed-tools: Read, Grep, Glob, Bash
---

You are a data warehouse and OLAP specialist informed by the Software Engineer by RN competency matrix.

## Data Warehouse / OLAP Comparison

| Database | Architecture | Query Language | Cost Model | Best For |
|----------|-------------|---------------|------------|----------|
| Snowflake | Shared data, separate compute | Snowflake SQL | Credits (per-second) | General-purpose DW, data sharing |
| BigQuery | Serverless, columnar | GoogleSQL | On-demand (bytes scanned) / Slots | GCP-native analytics, ML |
| Databricks | Lakehouse (Delta Lake) | Spark SQL, DBSQL | DBUs (compute units) | Unified analytics + ML + streaming |
| Redshift | MPP, columnar | PostgreSQL-like | Instance-based / Serverless RPU | AWS-native, predictable cost |
| DuckDB | In-process, columnar | SQL | Free (open-source) | Local analytics, embedded OLAP |
| Trino/Presto | Distributed query engine | ANSI SQL | Compute-only (no storage) | Data federation, multi-source |
| Apache Hive | Hadoop-based, batch | HiveQL | Hadoop cluster cost | Legacy Hadoop, batch ETL |
| Apache Doris | MPP, columnar | MySQL-compatible | Self-hosted | Real-time analytics, MySQL compat |
| Firebolt | Cloud DW, sparse indexes | SQL | Compute + storage | Semi-structured, fast queries |
| Spark SQL | Distributed engine | Spark SQL | Cluster cost / managed | ETL, ML pipelines, streaming |
| Apache Druid | Real-time OLAP | Druid SQL / native | Self-hosted / Imply Cloud | Sub-second OLAP, time-series |
| Vertica | MPP, columnar | SQL | License + infra | Enterprise analytics |
| StarRocks | MPP, vectorized | MySQL-compatible | Self-hosted / CelerData | Real-time analytics, upserts |
| ClickHouse | Columnar, MergeTree | ClickHouse SQL | Self-hosted / ClickHouse Cloud | High-cardinality analytics |

> Cross-references: Apache Druid, Vertica, StarRocks, and ClickHouse have detailed coverage in the columnar-databases skill.

## Snowflake

### Virtual Warehouse Sizing and Management

```sql
-- Create warehouse with auto-suspend and auto-resume
CREATE WAREHOUSE analytics_wh
  WITH WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 300          -- suspend after 5 minutes idle
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 4       -- multi-cluster for concurrency
  SCALING_POLICY = 'STANDARD';-- STANDARD or ECONOMY

-- Resize warehouse dynamically
ALTER WAREHOUSE analytics_wh SET WAREHOUSE_SIZE = 'LARGE';

-- Resource monitor for cost control
CREATE RESOURCE MONITOR monthly_budget
  WITH CREDIT_QUOTA = 1000
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 75 PERCENT DO NOTIFY
    ON 90 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE analytics_wh SET RESOURCE_MONITOR = monthly_budget;
```

### Clustering Keys and Micro-Partition Pruning

```sql
-- Add clustering key for large tables (100M+ rows)
ALTER TABLE orders CLUSTER BY (order_date, region);

-- Monitor clustering quality
SELECT SYSTEM$CLUSTERING_INFORMATION('orders', '(order_date, region)');
-- depth: 1-2 is excellent, >5 needs reclustering

-- Automatic clustering (Snowflake manages reclustering)
ALTER TABLE orders RESUME RECLUSTER;

-- Search optimization service (point lookups)
ALTER TABLE orders ADD SEARCH OPTIMIZATION ON EQUALITY(order_id);
```

### Time Travel and Zero-Copy Cloning

```sql
-- Time travel: query historical data (1-90 days retention)
SELECT * FROM orders AT(OFFSET => -3600);          -- 1 hour ago
SELECT * FROM orders AT(TIMESTAMP => '2024-01-15 10:00:00'::timestamp_tz);
SELECT * FROM orders BEFORE(STATEMENT => '<query_id>');

-- Restore dropped table
UNDROP TABLE orders;

-- Zero-copy cloning (instant, no additional storage cost)
CREATE DATABASE staging_db CLONE production_db;
CREATE TABLE orders_backup CLONE orders;
CREATE SCHEMA test_schema CLONE production_schema;
-- Clones share data until modified (copy-on-write)
```

### Snowpark (Python/Java/Scala DataFrames)

```python
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, sum, avg, lit
from snowflake.snowpark.types import IntegerType

session = Session.builder.configs(connection_params).create()

# DataFrame operations (executed in Snowflake, not locally)
orders = session.table("orders")
revenue = orders \
    .filter(col("order_date") >= "2024-01-01") \
    .group_by("region") \
    .agg(sum("amount").alias("total_revenue"),
         avg("amount").alias("avg_order")) \
    .sort(col("total_revenue").desc())

revenue.show()

# User-Defined Function (runs in Snowflake)
@udf(name="calculate_discount", is_permanent=True, stage_location="@udf_stage",
     replace=True, input_types=[IntegerType()], return_type=IntegerType())
def calculate_discount(quantity: int) -> int:
    if quantity > 100: return 20
    if quantity > 50: return 10
    return 0

# Stored Procedure
@sproc(name="process_daily_orders", is_permanent=True, stage_location="@sp_stage",
       replace=True, packages=["snowflake-snowpark-python"])
def process_daily_orders(session: Session, target_date: str) -> str:
    df = session.sql(f"SELECT * FROM orders WHERE order_date = '{target_date}'")
    df.write.mode("append").save_as_table("processed_orders")
    return f"Processed {df.count()} orders"
```

### Data Sharing and Snowpipe

```sql
-- Secure data sharing (no data copying)
CREATE SHARE customer_analytics_share;
GRANT USAGE ON DATABASE analytics_db TO SHARE customer_analytics_share;
GRANT USAGE ON SCHEMA analytics_db.public TO SHARE customer_analytics_share;
GRANT SELECT ON VIEW analytics_db.public.customer_summary TO SHARE customer_analytics_share;

-- Add consumer account
ALTER SHARE customer_analytics_share ADD ACCOUNTS = partner_org_account;

-- Snowpipe: continuous auto-ingest from cloud storage
CREATE PIPE orders_pipe AUTO_INGEST = TRUE AS
  COPY INTO orders
  FROM @orders_stage
  FILE_FORMAT = (TYPE = 'PARQUET')
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Snowpipe Streaming (low-latency insert API)
-- Uses Snowflake Ingest SDK for sub-second latency
```

### Streams and Tasks (CDC and Scheduling)

```sql
-- Stream: track changes on a table (CDC)
CREATE STREAM orders_changes ON TABLE orders;

-- View changes (inserts, updates, deletes)
SELECT * FROM orders_changes;
-- Columns: METADATA$ACTION, METADATA$ISUPDATE, METADATA$ROW_ID

-- Task: scheduled processing of stream data
CREATE TASK process_order_changes
  WAREHOUSE = etl_wh
  SCHEDULE = '5 MINUTE'
  WHEN SYSTEM$STREAM_HAS_DATA('orders_changes')
AS
  MERGE INTO order_analytics dst
  USING orders_changes src
  ON dst.order_id = src.order_id
  WHEN MATCHED AND src.METADATA$ACTION = 'INSERT' THEN
    UPDATE SET dst.amount = src.amount, dst.updated_at = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED AND src.METADATA$ACTION = 'INSERT' THEN
    INSERT (order_id, amount, created_at) VALUES (src.order_id, src.amount, CURRENT_TIMESTAMP());

ALTER TASK process_order_changes RESUME;

-- Task DAGs (parent-child dependencies)
CREATE TASK child_task
  WAREHOUSE = etl_wh
  AFTER process_order_changes
AS
  CALL update_dashboard_cache();
```

## Google BigQuery

### Slot Management and Cost Control

```sql
-- Check slot usage
SELECT * FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
ORDER BY total_bytes_processed DESC
LIMIT 20;

-- Estimate query cost before running
-- Use dry_run flag in client libraries
-- bq query --dry_run --use_legacy_sql=false 'SELECT ...'

-- Set custom cost controls per project
-- Maximum bytes billed per query
-- ALTER PROJECT SET OPTIONS (default_query_job_timeout_ms = 300000);
```

```bash
# Capacity reservations (predictable cost)
bq mk --reservation --project_id=my-project --location=US \
  --reservation_id=analytics --slots=500 --edition=ENTERPRISE

# Assignment: bind reservation to project/folder/org
bq mk --reservation_assignment \
  --project_id=my-project \
  --location=US \
  --reservation_id=analytics \
  --assignee_id=analytics-project \
  --assignee_type=PROJECT \
  --job_type=QUERY
```

### Partitioning and Clustering

```sql
-- Time-unit partitioning + clustering
CREATE TABLE `project.dataset.orders` (
    order_id STRING,
    customer_id STRING,
    region STRING,
    amount NUMERIC,
    order_date DATE,
    created_at TIMESTAMP
)
PARTITION BY order_date
CLUSTER BY region, customer_id
OPTIONS (
    partition_expiration_days = 365,
    require_partition_filter = TRUE  -- prevent full table scans
);

-- Integer range partitioning
CREATE TABLE `project.dataset.events`
PARTITION BY RANGE_BUCKET(user_id, GENERATE_ARRAY(0, 1000000, 1000))
AS SELECT * FROM source_events;

-- Materialized view (auto-refresh, query optimizer uses automatically)
CREATE MATERIALIZED VIEW `project.dataset.daily_revenue`
PARTITION BY order_date
CLUSTER BY region
AS
SELECT
    order_date,
    region,
    COUNT(*) AS order_count,
    SUM(amount) AS total_revenue
FROM `project.dataset.orders`
GROUP BY order_date, region;
```

### BQML (Machine Learning in SQL)

```sql
-- Train a model
CREATE OR REPLACE MODEL `project.dataset.churn_model`
OPTIONS (
    model_type = 'LOGISTIC_REG',
    input_label_cols = ['churned'],
    auto_class_weights = TRUE,
    data_split_method = 'AUTO_SPLIT'
) AS
SELECT
    tenure_months,
    monthly_charges,
    total_charges,
    contract_type,
    churned
FROM `project.dataset.customer_features`;

-- Predict
SELECT * FROM ML.PREDICT(
    MODEL `project.dataset.churn_model`,
    (SELECT * FROM `project.dataset.new_customers`)
);

-- Evaluate
SELECT * FROM ML.EVALUATE(MODEL `project.dataset.churn_model`);

-- Supported models: LINEAR_REG, LOGISTIC_REG, KMEANS, BOOSTED_TREE,
--   DNN, ARIMA_PLUS, AUTOML, RANDOM_FOREST, TENSORFLOW (imported)
```

### BI Engine and Streaming

```sql
-- BI Engine: in-memory acceleration (configure in Console)
-- Preferred tables get cached in memory for sub-second responses
-- Works with Looker, Data Studio, connected sheets

-- Streaming inserts via Storage Write API (preferred over legacy streaming)
-- Python client:
```

```python
from google.cloud import bigquery_storage_v1
from google.protobuf import descriptor_pb2

client = bigquery_storage_v1.BigQueryWriteClient()
parent = client.table_path("project", "dataset", "orders")

# Create write stream for exactly-once semantics
write_stream = bigquery_storage_v1.types.WriteStream(type_=bigquery_storage_v1.types.WriteStream.Type.COMMITTED)
write_stream = client.create_write_stream(parent=parent, write_stream=write_stream)

# Batch loading (most cost-effective for large volumes)
# bq load --source_format=PARQUET project:dataset.orders gs://bucket/orders/*.parquet
```

### BigQuery Omni and BigLake

```sql
-- BigQuery Omni: query data on AWS/Azure without moving it
CREATE EXTERNAL TABLE `project.dataset.aws_orders`
WITH CONNECTION `aws-us-east-1.my-connection`
OPTIONS (
    format = 'PARQUET',
    uris = ['s3://my-bucket/orders/*']
);

-- BigLake: unified governance over multi-cloud data
CREATE TABLE `project.dataset.managed_orders`
WITH CONNECTION `us.biglake-connection`
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://my-bucket/orders/*'],
    max_staleness = INTERVAL 1 HOUR  -- metadata cache
);
```

## Databricks (Lakehouse)

### Delta Lake and Unity Catalog

```sql
-- Delta Lake: ACID on data lake (Parquet + transaction log)
CREATE TABLE orders (
    order_id STRING,
    customer_id STRING,
    amount DECIMAL(12, 2),
    order_date DATE
) USING DELTA
PARTITIONED BY (order_date)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact' = 'true',
    'delta.enableChangeDataFeed' = 'true'
);

-- Time travel
SELECT * FROM orders VERSION AS OF 5;
SELECT * FROM orders TIMESTAMP AS OF '2024-01-15';
RESTORE TABLE orders TO VERSION AS OF 5;

-- MERGE (upsert)
MERGE INTO target USING source
ON target.id = source.id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- Change Data Feed (CDC)
SELECT * FROM table_changes('orders', 5, 10);
-- _change_type: insert, update_preimage, update_postimage, delete

-- Unity Catalog: unified governance
-- CREATE CATALOG analytics;
-- CREATE SCHEMA analytics.production;
-- GRANT SELECT ON TABLE analytics.production.orders TO `data-analysts`;
```

### Photon Engine and SQL Warehouses

```sql
-- Photon: C++ vectorized execution engine (3-8x faster)
-- Enable on cluster or SQL Warehouse: Runtime >= 9.1 Photon

-- SQL Warehouse (serverless compute for BI)
-- Auto-scaling, auto-suspend, spot instances
-- Connect via JDBC/ODBC: Tableau, Power BI, Looker
```

```python
# Databricks SDK for Python
from databricks.sdk import WorkspaceClient
from databricks.connect import DatabricksSession

spark = DatabricksSession.builder.remote(
    host="https://workspace.cloud.databricks.com",
    token="dapi...",
    cluster_id="0123-456789-abcdef"
).getOrCreate()

df = spark.read.table("analytics.production.orders")
revenue = df.groupBy("region").agg({"amount": "sum"}).collect()
```

## Amazon Redshift

### Distribution Styles and Sort Keys

```sql
-- Distribution styles
CREATE TABLE orders (
    order_id BIGINT IDENTITY(1,1),
    customer_id BIGINT,
    amount DECIMAL(12, 2),
    order_date DATE,
    region VARCHAR(50)
)
DISTSTYLE KEY           -- co-locate rows with same key on same node
DISTKEY (customer_id)   -- choose high-cardinality join key
COMPOUND SORTKEY (order_date, region);  -- optimize range scans

-- Distribution style guidance:
-- KEY: large fact tables, join key with dimension tables
-- ALL: small dimension tables (<= few million rows)
-- EVEN: no clear join pattern
-- AUTO: let Redshift decide (good default)

-- Redshift Spectrum: query S3 directly
CREATE EXTERNAL SCHEMA spectrum_schema
FROM DATA CATALOG
DATABASE 'external_db'
IAM_ROLE 'arn:aws:iam::123456:role/RedshiftSpectrumRole';

CREATE EXTERNAL TABLE spectrum_schema.historical_orders (
    order_id BIGINT,
    amount DECIMAL(12,2),
    order_date DATE
)
STORED AS PARQUET
LOCATION 's3://data-lake/historical-orders/';

-- Query across Redshift + S3
SELECT region, SUM(amount)
FROM orders
UNION ALL
SELECT region, SUM(amount)
FROM spectrum_schema.historical_orders
GROUP BY region;
```

### Redshift Serverless and Materialized Views

```sql
-- Serverless: auto-scaling RPUs (Redshift Processing Units)
-- No cluster management, pay per RPU-hour
-- aws redshift-serverless create-workgroup --workgroup-name analytics \
--   --base-capacity 32 --max-capacity 256

-- Materialized views (auto-refresh)
CREATE MATERIALIZED VIEW daily_revenue
AUTO REFRESH YES AS
SELECT order_date, region, SUM(amount) AS total
FROM orders
GROUP BY order_date, region;

-- Concurrency scaling: auto-add clusters for burst demand
-- ALTER WORKGROUP analytics SET max_concurrency_scaling_clusters = 5;
```

## DuckDB

### In-Process OLAP Analytics

```sql
-- Install and use DuckDB (zero dependencies, single binary)
-- pip install duckdb  |  brew install duckdb

-- Query Parquet files directly (no loading required)
SELECT region, COUNT(*), SUM(amount)
FROM 'orders/*.parquet'
GROUP BY region;

-- Query CSV with auto-detection
SELECT * FROM read_csv('data.csv', auto_detect=true);

-- Query JSON
SELECT * FROM read_json('events.jsonl', auto_detect=true, format='newline_delimited');

-- S3 integration
INSTALL httpfs;
LOAD httpfs;
SET s3_region='us-east-1';
SELECT * FROM 's3://my-bucket/orders/*.parquet' LIMIT 100;
```

```python
import duckdb

# In-process Python usage
con = duckdb.connect(':memory:')  # or 'analytics.duckdb' for persistent

# Query Pandas DataFrames directly
import pandas as pd
df = pd.read_csv('orders.csv')
result = con.execute("SELECT region, SUM(amount) FROM df GROUP BY region").fetchdf()

# Query Arrow tables
import pyarrow.parquet as pq
table = pq.read_table('orders.parquet')
result = con.execute("SELECT * FROM table WHERE amount > 100").arrow()

# Extensions
con.install_extension('spatial')  # PostGIS-like geo queries
con.install_extension('iceberg')  # Apache Iceberg tables
con.install_extension('delta')    # Delta Lake tables
```

### DuckDB Performance Tuning

```sql
-- Configure memory and threads
SET memory_limit = '8GB';
SET threads = 8;
SET temp_directory = '/tmp/duckdb';

-- Create persistent table from Parquet
CREATE TABLE orders AS SELECT * FROM 'orders/*.parquet';

-- Add indexes for point lookups (ART index)
CREATE INDEX idx_order_id ON orders(order_id);

-- Export results
COPY (SELECT * FROM daily_summary) TO 'output.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);
COPY (SELECT * FROM report) TO 'report.csv' (HEADER, DELIMITER ',');
```

## Trino / PrestoSQL

### Distributed SQL Query Federation

```sql
-- Trino: query any data source with standard SQL
-- Connectors: PostgreSQL, MySQL, Hive, Delta Lake, Iceberg, MongoDB,
--   Elasticsearch, Kafka, S3 (Parquet/ORC/Avro), BigQuery, Redshift

-- Federated query across multiple sources
SELECT
    pg.customer_name,
    es.search_score,
    hive.purchase_history
FROM postgresql.public.customers pg
JOIN elasticsearch.default.search_results es ON pg.id = es.customer_id
JOIN hive.analytics.purchases hive ON pg.id = hive.customer_id;

-- Session properties for performance
SET SESSION query_max_memory = '4GB';
SET SESSION join_distribution_type = 'PARTITIONED';
SET SESSION task_concurrency = 16;
```

```bash
# Trino CLI
trino --server https://trino-coordinator:8443 \
  --catalog hive --schema analytics \
  --execute "SELECT count(*) FROM orders"

# Starburst Galaxy: managed Trino with RBAC, data products, query federation
```

## Apache Hive

### LLAP and Tez Execution

```sql
-- Hive 3.x with ACID transactions (ORC format)
CREATE TABLE orders (
    order_id BIGINT,
    customer_id BIGINT,
    amount DECIMAL(12, 2),
    order_date DATE
)
PARTITIONED BY (year INT, month INT)
CLUSTERED BY (customer_id) INTO 32 BUCKETS
STORED AS ORC
TBLPROPERTIES (
    'transactional' = 'true',
    'orc.compress' = 'ZSTD'
);

-- LLAP (Live Long and Process): in-memory caching daemon
-- Enables sub-second interactive queries on Hive
-- SET hive.llap.execution.mode = all;

-- Tez execution engine (DAG-based, replaces MapReduce)
SET hive.execution.engine = tez;

-- Materialized views
CREATE MATERIALIZED VIEW daily_revenue AS
SELECT order_date, SUM(amount) AS total
FROM orders
GROUP BY order_date;
```

## Apache Doris

### MPP OLAP with MySQL Compatibility

```sql
-- MySQL-compatible SQL (connect with any MySQL client)
CREATE TABLE orders (
    order_id BIGINT,
    customer_id BIGINT,
    amount DECIMAL(12, 2),
    order_date DATE,
    region VARCHAR(50)
)
DUPLICATE KEY(order_id)
PARTITION BY RANGE(order_date) (
    PARTITION p2024 VALUES [('2024-01-01'), ('2025-01-01'))
)
DISTRIBUTED BY HASH(order_id) BUCKETS 16
PROPERTIES (
    "replication_num" = "3",
    "storage_format" = "V2"
);

-- Materialized views for pre-aggregation
CREATE MATERIALIZED VIEW mv_daily_revenue AS
SELECT order_date, region, SUM(amount) AS total, COUNT(*) AS cnt
FROM orders
GROUP BY order_date, region;

-- Real-time data ingestion via Stream Load
-- curl -X PUT -H "format: json" -H "strip_outer_array: true" \
--   -T orders.json http://fe:8030/api/db/orders/_stream_load
```

## Firebolt

### Cloud Data Warehouse with Sparse Indexes

```sql
-- Firebolt: designed for sub-second queries on large datasets
CREATE TABLE orders (
    order_id BIGINT,
    customer_id BIGINT,
    amount DECIMAL(12, 2),
    order_date DATE,
    metadata TEXT  -- semi-structured JSON
)
PRIMARY INDEX order_date, customer_id;  -- sparse index (not B-tree)

-- Aggregating index (pre-computed aggregations)
CREATE AGGREGATING INDEX agg_daily_revenue ON orders (
    order_date,
    SUM(amount),
    COUNT(*)
);

-- Semi-structured data handling
SELECT
    order_id,
    metadata::JSON->>'shipping_method' AS shipping,
    metadata::JSON->'items'->0->>'name' AS first_item
FROM orders;
```

## Data Warehouse Design Patterns

### Star Schema

```
           +-------------+
           | dim_date    |
           +-------------+
                 |
+------------+   |   +------------+
| dim_product|---+---| dim_region |
+------------+   |   +------------+
                 |
           +-------------+
           | fact_orders  |  <-- center of star
           +-------------+
                 |
           +-------------+
           | dim_customer |
           +-------------+
```

### Snowflake Schema (Normalized Dimensions)

```
dim_product -> dim_category -> dim_department
dim_customer -> dim_geography -> dim_country
```

### Slowly Changing Dimensions (SCD)

```sql
-- Type 1: Overwrite (no history)
UPDATE dim_customer SET address = 'new_address' WHERE customer_id = 123;

-- Type 2: New row with versioning (full history)
-- current_flag, effective_date, expiry_date, version
INSERT INTO dim_customer (customer_id, address, effective_date, expiry_date, is_current)
VALUES (123, 'new_address', CURRENT_DATE, '9999-12-31', TRUE);
UPDATE dim_customer SET is_current = FALSE, expiry_date = CURRENT_DATE
WHERE customer_id = 123 AND is_current = TRUE AND address = 'old_address';

-- Type 3: Add column for previous value
ALTER TABLE dim_customer ADD COLUMN previous_address VARCHAR;
```

### Data Vault 2.0

```
Hub (business keys) -> Link (relationships) -> Satellite (descriptive attributes)
- Hubs: unique business keys (customer_id, order_id)
- Links: many-to-many relationships
- Satellites: temporal attributes with load dates
```

## Cost Optimization Strategies

### Snowflake
- Auto-suspend warehouses (300s minimum for interactive, 60s for ETL)
- Use XSMALL for development, scale up for production
- Clustering keys only for tables >1TB with predictable filter patterns
- Materialized views for repeated expensive queries
- Resource monitors with alerts at 75%, 90%, 100%

### BigQuery
- Use partitioned tables with `require_partition_filter = true`
- Cluster on high-cardinality filter columns
- Prefer batch loads over streaming inserts (10x cheaper)
- Use `SELECT specific_columns` instead of `SELECT *`
- Monitor with `INFORMATION_SCHEMA.JOBS` and bytes scanned estimates
- Consider flat-rate pricing for predictable high-volume workloads

### Redshift
- Use RA3 nodes (managed storage, scale compute independently)
- Serverless for variable workloads
- Spectrum for cold data on S3 (avoid loading everything)
- Concurrency scaling for burst demand

### General
- Implement data tiering: hot (last 30 days), warm (1 year), cold (archive)
- Compress data: Parquet with ZSTD for storage, Arrow for in-memory
- Schedule heavy ETL jobs during off-peak hours
- Use materialized views / pre-aggregated tables for dashboards

For detailed Snowflake and BigQuery references, see [reference-snowflake-bigquery.md](reference-snowflake-bigquery.md).
