# Snowflake + BigQuery Deep Reference

## Snowflake

### Virtual Warehouse Sizing

| Size | Credits/Hour | Nodes | Typical Use Case |
|------|-------------|-------|------------------|
| X-Small | 1 | 1 | Development, light queries |
| Small | 2 | 2 | Small team analytics |
| Medium | 4 | 4 | Production dashboards |
| Large | 8 | 8 | Complex joins, ETL |
| X-Large | 16 | 16 | Heavy ETL, data science |
| 2X-Large | 32 | 32 | Large-scale transformations |
| 3X-Large | 64 | 64 | Massive parallel processing |
| 4X-Large | 128 | 128 | Extreme workloads |
| 5X-Large | 256 | 256 | Rare, very large datasets |
| 6X-Large | 512 | 512 | Maximum compute |

```sql
-- Auto-suspend and auto-resume configuration
ALTER WAREHOUSE dev_wh SET
  AUTO_SUSPEND = 60           -- 1 minute for dev (minimum)
  AUTO_RESUME = TRUE
  WAREHOUSE_SIZE = 'XSMALL';

ALTER WAREHOUSE prod_wh SET
  AUTO_SUSPEND = 300          -- 5 minutes for production
  AUTO_RESUME = TRUE
  WAREHOUSE_SIZE = 'MEDIUM';

ALTER WAREHOUSE etl_wh SET
  AUTO_SUSPEND = 120          -- 2 minutes for ETL
  AUTO_RESUME = TRUE
  WAREHOUSE_SIZE = 'LARGE'
  INITIALLY_SUSPENDED = TRUE; -- don't start until needed

-- Multi-cluster warehouse scaling policy
ALTER WAREHOUSE prod_wh SET
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 6
  SCALING_POLICY = 'STANDARD';
-- STANDARD: add cluster when query queues (fast scaling)
-- ECONOMY: add cluster only when sustained load (cost savings, slower scaling)

-- Query acceleration service (for outlier queries)
ALTER WAREHOUSE prod_wh SET
  ENABLE_QUERY_ACCELERATION = TRUE
  QUERY_ACCELERATION_MAX_SCALE_FACTOR = 4;  -- up to 4x additional compute

-- Monitor warehouse usage
SELECT
    warehouse_name,
    SUM(credits_used) AS total_credits,
    AVG(avg_running) AS avg_concurrent_queries,
    MAX(queued_overload) AS max_queued
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time > DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;
```

### Clustering Keys

```sql
-- When to use clustering keys:
-- 1. Table > 1 TB
-- 2. Queries consistently filter on specific columns
-- 3. Clustering depth > 4 for common query patterns

-- Selection guidance:
-- - Choose columns that appear in WHERE clauses and JOIN conditions
-- - Date/timestamp columns for time-range queries
-- - High-cardinality columns AFTER low-cardinality ones
-- - Maximum 3-4 columns per clustering key

-- Add clustering key
ALTER TABLE events CLUSTER BY (event_date, user_id);

-- Monitor clustering quality
SELECT SYSTEM$CLUSTERING_INFORMATION('events', '(event_date, user_id)');
-- Returns JSON with:
-- - total_partition_count: total micro-partitions
-- - average_overlaps: lower is better (0 = perfectly clustered)
-- - average_depth: lower is better (1 = perfectly pruned)

-- Clustering depth interpretation:
-- 1.0-2.0: Excellent, no action needed
-- 2.0-4.0: Good, monitor periodically
-- 4.0-8.0: Consider reclustering or reviewing key selection
-- > 8.0: Active reclustering recommended

-- Automatic clustering (recommended over manual)
ALTER TABLE events RESUME RECLUSTER;  -- enable auto-reclustering
ALTER TABLE events SUSPEND RECLUSTER; -- disable

-- Micro-partition pruning analysis
SELECT
    partition_count,
    partitions_scanned,
    partitions_total,
    ROUND(partitions_scanned / partitions_total * 100, 2) AS scan_pct
FROM TABLE(information_schema.query_history_by_warehouse('PROD_WH'))
WHERE query_text LIKE '%events%'
ORDER BY start_time DESC
LIMIT 20;
```

### Time Travel and Fail-Safe

```sql
-- Time travel retention configuration (per table or account)
-- Standard edition: 0-1 day
-- Enterprise edition: 0-90 days
ALTER TABLE orders SET DATA_RETENTION_TIME_IN_DAYS = 30;

-- Query historical data
-- By timestamp
SELECT * FROM orders AT(TIMESTAMP => '2024-06-15 14:30:00'::TIMESTAMP_LTZ);

-- By offset (seconds ago)
SELECT * FROM orders AT(OFFSET => -7200); -- 2 hours ago

-- By query ID (before a specific query ran)
SELECT * FROM orders BEFORE(STATEMENT => '01b12345-0123-4567-8901-abcdef123456');

-- Restore dropped objects
DROP TABLE orders;
UNDROP TABLE orders;

DROP SCHEMA staging;
UNDROP SCHEMA staging;

DROP DATABASE analytics;
UNDROP DATABASE analytics;

-- Compare current vs historical data
SELECT
    current_data.order_id,
    current_data.status AS current_status,
    historical_data.status AS previous_status
FROM orders current_data
JOIN orders AT(OFFSET => -3600) historical_data
    ON current_data.order_id = historical_data.order_id
WHERE current_data.status != historical_data.status;

-- Fail-safe: 7-day recovery after Time Travel expires
-- Accessible only by Snowflake support
-- Not configurable, automatic protection
```

### Zero-Copy Cloning

```sql
-- Database clone (instant, zero additional storage)
CREATE DATABASE dev_db CLONE prod_db;

-- Schema clone
CREATE SCHEMA test_schema CLONE prod_schema;

-- Table clone
CREATE TABLE orders_test CLONE orders;

-- Clone at a point in time (Time Travel + clone)
CREATE DATABASE recovery_db CLONE prod_db
    AT(TIMESTAMP => '2024-06-15 10:00:00'::TIMESTAMP_LTZ);

-- Clone with statement
CREATE TABLE orders_before_migration CLONE orders
    BEFORE(STATEMENT => '01b12345-0123-4567-8901-abcdef123456');

-- Clone behavior:
-- - Shares underlying micro-partitions (no data duplication)
-- - Copy-on-write: modifications create new micro-partitions
-- - Cloned objects are independent (changes don't affect source)
-- - Streams, tasks, stages are NOT cloned
-- - Grants/privileges are NOT cloned (must be re-applied)
-- - Pipes are paused in cloned databases

-- Common use cases:
-- 1. Development/testing environments from production
-- 2. Pre-migration snapshots
-- 3. Point-in-time recovery
-- 4. Data science sandboxes
```

### Snowpark Deep Dive

```python
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, sum as sum_, avg, when, lit, udf, sproc
from snowflake.snowpark.types import StructType, StructField, StringType, DecimalType

# Session creation
session = Session.builder.configs({
    "account": "myaccount",
    "user": "myuser",
    "password": "mypassword",
    "warehouse": "compute_wh",
    "database": "analytics",
    "schema": "public",
    "role": "data_engineer"
}).create()

# DataFrame operations (lazy evaluation, pushdown to Snowflake)
orders = session.table("orders")
customers = session.table("customers")

# Complex transformation pipeline
result = (
    orders
    .join(customers, orders["customer_id"] == customers["id"])
    .filter(col("order_date") >= "2024-01-01")
    .with_column("order_tier", when(col("amount") > 1000, lit("premium"))
                                .when(col("amount") > 100, lit("standard"))
                                .otherwise(lit("basic")))
    .group_by("region", "order_tier")
    .agg(
        sum_("amount").alias("total_revenue"),
        avg("amount").alias("avg_order_value"),
    )
    .sort(col("total_revenue").desc())
)

# Save to table
result.write.mode("overwrite").save_as_table("regional_revenue_summary")

# User-Defined Functions (vectorized for performance)
@udf(name="sentiment_score", is_permanent=True,
     stage_location="@udf_stage", replace=True,
     packages=["textblob"])
def sentiment_score(text: str) -> float:
    from textblob import TextBlob
    return TextBlob(text).sentiment.polarity

# Vectorized UDF (pandas-based, batch processing)
from snowflake.snowpark.functions import pandas_udf
from snowflake.snowpark.types import PandasSeriesType, FloatType

@pandas_udf(name="batch_normalize", is_permanent=True,
            stage_location="@udf_stage", replace=True)
def batch_normalize(series: pd.Series) -> pd.Series:
    return (series - series.mean()) / series.std()

# Stored Procedures
@sproc(name="run_daily_etl", is_permanent=True,
       stage_location="@sp_stage", replace=True,
       packages=["snowflake-snowpark-python"])
def run_daily_etl(session: Session, date: str) -> str:
    raw = session.table("raw_events").filter(col("event_date") == date)
    transformed = raw.with_column("processed_at", lit(session.sql("SELECT CURRENT_TIMESTAMP()").collect()[0][0]))
    transformed.write.mode("append").save_as_table("processed_events")
    return f"Processed {raw.count()} events for {date}"
```

### Data Sharing

```sql
-- Provider: create and manage shares
CREATE SHARE analytics_share;
GRANT USAGE ON DATABASE analytics TO SHARE analytics_share;
GRANT USAGE ON SCHEMA analytics.public TO SHARE analytics_share;

-- Share secure view (prevents consumers from accessing raw data)
CREATE SECURE VIEW analytics.public.customer_summary AS
SELECT
    customer_id,
    region,
    total_orders,
    total_spent,
    last_order_date
FROM analytics.public.customer_metrics;

GRANT SELECT ON VIEW analytics.public.customer_summary TO SHARE analytics_share;

-- Add consumer accounts
ALTER SHARE analytics_share ADD ACCOUNTS = consumer_account_1, consumer_account_2;

-- Reader accounts (for non-Snowflake consumers)
CREATE MANAGED ACCOUNT reader_account
    ADMIN_NAME = 'reader_admin'
    ADMIN_PASSWORD = 'SecurePassword123!'
    TYPE = READER;

-- Consumer: mount shared data
CREATE DATABASE shared_analytics FROM SHARE provider_account.analytics_share;

-- Snowflake Marketplace: discover and consume shared data
-- Browse at https://app.snowflake.com/marketplace
```

### Snowpipe and Snowpipe Streaming

```sql
-- Snowpipe: auto-ingest from cloud storage (event-driven)
-- 1. Create stage
CREATE STAGE orders_stage
    URL = 's3://my-bucket/orders/'
    STORAGE_INTEGRATION = s3_integration
    FILE_FORMAT = (TYPE = 'PARQUET');

-- 2. Create pipe
CREATE PIPE orders_pipe AUTO_INGEST = TRUE AS
    COPY INTO orders
    FROM @orders_stage
    FILE_FORMAT = (TYPE = 'PARQUET')
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- 3. Configure S3 event notification to SQS queue
-- (provided by SHOW PIPES -> notification_channel)

-- Check pipe status
SELECT SYSTEM$PIPE_STATUS('orders_pipe');
SELECT * FROM TABLE(information_schema.copy_history(
    table_name => 'orders', start_time => DATEADD(hour, -24, CURRENT_TIMESTAMP())
));

-- Snowpipe Streaming (Java SDK, sub-second latency)
-- Uses Snowflake Ingest SDK, no staging files needed
-- Ideal for real-time ingestion from Kafka, custom apps
```

### Streams and Tasks

```sql
-- Stream: CDC on Snowflake tables
CREATE STREAM orders_stream ON TABLE orders;

-- Stream types:
-- STANDARD (default): tracks INSERT, UPDATE, DELETE
-- APPEND_ONLY: tracks only INSERTs (lower overhead)
CREATE STREAM orders_append_stream ON TABLE orders APPEND_ONLY = TRUE;

-- Query stream data
SELECT
    order_id,
    amount,
    METADATA$ACTION,      -- INSERT or DELETE
    METADATA$ISUPDATE,    -- TRUE if part of an UPDATE
    METADATA$ROW_ID
FROM orders_stream;

-- Task: scheduled SQL execution
CREATE TASK hourly_aggregation
    WAREHOUSE = etl_wh
    SCHEDULE = 'USING CRON 0 * * * * America/New_York'  -- every hour
    WHEN SYSTEM$STREAM_HAS_DATA('orders_stream')
AS
    INSERT INTO hourly_order_summary
    SELECT
        DATE_TRUNC('hour', CURRENT_TIMESTAMP()) AS hour,
        COUNT(*) AS new_orders,
        SUM(amount) AS total_amount
    FROM orders_stream
    WHERE METADATA$ACTION = 'INSERT';

-- Serverless tasks (no warehouse needed, lower cost)
CREATE TASK serverless_task
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '5 MINUTE'
AS SELECT 1;

-- Task DAGs
CREATE TASK parent_task WAREHOUSE = etl_wh SCHEDULE = '1 HOUR' AS ...;
CREATE TASK child_task_1 WAREHOUSE = etl_wh AFTER parent_task AS ...;
CREATE TASK child_task_2 WAREHOUSE = etl_wh AFTER parent_task AS ...;
CREATE TASK final_task WAREHOUSE = etl_wh AFTER child_task_1, child_task_2 AS ...;

-- Enable tasks (must resume root task last)
ALTER TASK final_task RESUME;
ALTER TASK child_task_1 RESUME;
ALTER TASK child_task_2 RESUME;
ALTER TASK parent_task RESUME;

-- Monitor tasks
SELECT * FROM TABLE(information_schema.task_history(
    task_name => 'hourly_aggregation',
    scheduled_time_range_start => DATEADD(day, -1, CURRENT_TIMESTAMP())
));
```

### Cost Optimization

```sql
-- Resource monitors (budget alerts and enforcement)
CREATE RESOURCE MONITOR team_budget
    WITH CREDIT_QUOTA = 500
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 50 PERCENT DO NOTIFY
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO SUSPEND
        ON 100 PERCENT DO SUSPEND_IMMEDIATE;

-- Assign to warehouse
ALTER WAREHOUSE analytics_wh SET RESOURCE_MONITOR = team_budget;

-- Query profiling for optimization
SELECT
    query_id,
    query_text,
    warehouse_name,
    total_elapsed_time / 1000 AS elapsed_seconds,
    bytes_scanned / (1024*1024*1024) AS gb_scanned,
    partitions_scanned,
    partitions_total,
    ROUND(partitions_scanned / NULLIF(partitions_total, 0) * 100, 2) AS scan_pct
FROM snowflake.account_usage.query_history
WHERE start_time > DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND total_elapsed_time > 60000  -- queries > 1 minute
ORDER BY total_elapsed_time DESC
LIMIT 50;

-- Warehouse utilization analysis
SELECT
    warehouse_name,
    DATE_TRUNC('hour', start_time) AS hour,
    SUM(credits_used) AS credits,
    AVG(avg_running) AS avg_queries,
    SUM(queued_overload) AS queued_count
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time > DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, hour
ORDER BY credits DESC;
```

### Security

```sql
-- Key-pair authentication (service accounts)
-- ALTER USER service_user SET RSA_PUBLIC_KEY = 'MIIB...';

-- Network policies
CREATE NETWORK POLICY office_only
    ALLOWED_IP_LIST = ('203.0.113.0/24', '198.51.100.0/24')
    BLOCKED_IP_LIST = ('203.0.113.50');
ALTER ACCOUNT SET NETWORK_POLICY = office_only;

-- Column-level masking
CREATE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ADMIN', 'DATA_ENGINEER') THEN val
        ELSE REGEXP_REPLACE(val, '.+@', '***@')
    END;
ALTER TABLE customers MODIFY COLUMN email SET MASKING POLICY email_mask;

-- Row access policies
CREATE ROW ACCESS POLICY region_filter AS (region_val VARCHAR) RETURNS BOOLEAN ->
    CURRENT_ROLE() = 'ADMIN'
    OR region_val IN (SELECT region FROM user_regions WHERE user = CURRENT_USER());
ALTER TABLE orders ADD ROW ACCESS POLICY region_filter ON (region);

-- Tag-based masking (classify and protect at scale)
CREATE TAG pii_type ALLOWED_VALUES 'EMAIL', 'PHONE', 'SSN';
ALTER TABLE customers MODIFY COLUMN email SET TAG pii_type = 'EMAIL';
ALTER TABLE customers MODIFY COLUMN phone SET TAG pii_type = 'PHONE';
-- Attach masking policies to tags (applied automatically to all tagged columns)
```

---

## BigQuery

### Slot Management

```sql
-- On-demand pricing: $6.25 per TB scanned (first 1 TB/month free)
-- Capacity pricing: purchase dedicated slots

-- Check current slot usage
SELECT
    period_start,
    period_slot_ms,
    project_id,
    job_type,
    ROUND(period_slot_ms / 1000 / 60, 2) AS slot_minutes
FROM `region-us`.INFORMATION_SCHEMA.JOBS_TIMELINE
WHERE period_start > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
ORDER BY period_slot_ms DESC;

-- Identify expensive queries
SELECT
    job_id,
    user_email,
    query,
    total_bytes_processed / POW(1024, 3) AS gb_processed,
    total_slot_ms / 1000 AS slot_seconds,
    creation_time,
    TIMESTAMP_DIFF(end_time, start_time, SECOND) AS duration_seconds
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND job_type = 'QUERY'
    AND state = 'DONE'
ORDER BY total_bytes_processed DESC
LIMIT 20;
```

```bash
# Create reservation (Enterprise edition)
bq mk --reservation \
  --project_id=my-project \
  --location=US \
  --reservation_id=prod-analytics \
  --slots=500 \
  --edition=ENTERPRISE

# Autoscaling (Enterprise edition)
bq mk --reservation \
  --project_id=my-project \
  --location=US \
  --reservation_id=autoscale-pool \
  --slots=100 \
  --edition=ENTERPRISE \
  --autoscale_max_slots=1000  # scale up to 1000 slots

# Flex slots (short-term commitments, 60-second minimum)
bq mk --capacity_commitment \
  --project_id=my-project \
  --location=US \
  --slots=500 \
  --plan=FLEX \
  --edition=ENTERPRISE

# Reservation assignment
bq mk --reservation_assignment \
  --project_id=my-project \
  --location=US \
  --reservation_id=prod-analytics \
  --assignee_id=analytics-project \
  --assignee_type=PROJECT \
  --job_type=QUERY
```

### Partitioning and Clustering Deep Dive

```sql
-- Ingestion-time partitioning (automatic, based on load time)
CREATE TABLE `project.dataset.events` (
    event_id STRING,
    event_type STRING,
    user_id STRING,
    payload STRING,
    event_time TIMESTAMP
)
PARTITION BY _PARTITIONDATE  -- pseudo column
OPTIONS (partition_expiration_days = 90);

-- Time-unit column partitioning (recommended)
CREATE TABLE `project.dataset.orders` (
    order_id STRING,
    customer_id STRING,
    amount NUMERIC,
    region STRING,
    order_date DATE
)
PARTITION BY order_date
CLUSTER BY region, customer_id
OPTIONS (
    partition_expiration_days = 365,
    require_partition_filter = TRUE
);

-- Integer range partitioning
CREATE TABLE `project.dataset.user_events` (
    user_id INT64,
    event_type STRING,
    event_time TIMESTAMP
)
PARTITION BY RANGE_BUCKET(user_id, GENERATE_ARRAY(0, 10000000, 10000))
CLUSTER BY event_type;

-- Clustering rules:
-- - Up to 4 clustering columns
-- - Order matters: most filtered column first
-- - Clustering is free (automatic re-clustering)
-- - Works best with partitioned tables
-- - Most effective for high-cardinality filter columns

-- Check partition and clustering stats
SELECT
    table_name,
    partition_id,
    total_rows,
    total_logical_bytes / POW(1024, 3) AS gb_size
FROM `project.dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'orders'
ORDER BY partition_id DESC
LIMIT 20;
```

### BQML Deep Dive

```sql
-- Supported model types:
-- Classification: LOGISTIC_REG, BOOSTED_TREE_CLASSIFIER, DNN_CLASSIFIER, RANDOM_FOREST_CLASSIFIER, AUTOML_CLASSIFIER
-- Regression: LINEAR_REG, BOOSTED_TREE_REGRESSOR, DNN_REGRESSOR, RANDOM_FOREST_REGRESSOR, AUTOML_REGRESSOR
-- Clustering: KMEANS
-- Time Series: ARIMA_PLUS
-- Recommendation: MATRIX_FACTORIZATION
-- Imported: TENSORFLOW, ONNX, XGBOOST

-- Feature engineering with TRANSFORM
CREATE OR REPLACE MODEL `project.dataset.fraud_detector`
TRANSFORM (
    amount,
    ML.BUCKETIZE(amount, [10, 50, 100, 500, 1000]) AS amount_bucket,
    ML.FEATURE_CROSS(STRUCT(category, region)) AS category_region,
    ML.QUANTILE_BUCKETIZE(hour_of_day, 4) AS time_bucket,
    is_fraud
)
OPTIONS (
    model_type = 'BOOSTED_TREE_CLASSIFIER',
    input_label_cols = ['is_fraud'],
    auto_class_weights = TRUE,
    num_parallel_tree = 50,
    max_tree_depth = 8,
    data_split_method = 'CUSTOM',
    data_split_col = 'is_test_row'
) AS
SELECT * FROM `project.dataset.transaction_features`;

-- Model evaluation
SELECT * FROM ML.EVALUATE(MODEL `project.dataset.fraud_detector`);
-- Returns: precision, recall, accuracy, f1_score, log_loss, roc_auc

-- Feature importance
SELECT * FROM ML.FEATURE_IMPORTANCE(MODEL `project.dataset.fraud_detector`);

-- Confusion matrix
SELECT * FROM ML.CONFUSION_MATRIX(MODEL `project.dataset.fraud_detector`);

-- Batch prediction
SELECT
    transaction_id,
    predicted_is_fraud,
    predicted_is_fraud_probs
FROM ML.PREDICT(
    MODEL `project.dataset.fraud_detector`,
    (SELECT * FROM `project.dataset.new_transactions`)
);

-- ARIMA_PLUS for time series forecasting
CREATE OR REPLACE MODEL `project.dataset.sales_forecast`
OPTIONS (
    model_type = 'ARIMA_PLUS',
    time_series_timestamp_col = 'date',
    time_series_data_col = 'daily_sales',
    time_series_id_col = 'product_category',
    auto_arima = TRUE,
    holiday_region = 'US'
) AS
SELECT date, product_category, daily_sales
FROM `project.dataset.daily_sales_history`;

-- Forecast future values
SELECT * FROM ML.FORECAST(
    MODEL `project.dataset.sales_forecast`,
    STRUCT(30 AS horizon, 0.9 AS confidence_level)
);
```

### BI Engine

```sql
-- BI Engine: in-memory analysis service
-- - Sub-second query response for dashboards
-- - Automatic vectorized processing
-- - Works with Looker, Connected Sheets, BI tools via ODBC/JDBC

-- Configuration (via Console or API):
-- 1. Enable BI Engine in project settings
-- 2. Set memory capacity (GB)
-- 3. Optionally specify preferred tables for caching

-- Preferred tables (prioritize caching)
-- Configured via Console: BigQuery > BI Engine > Preferred Tables

-- Monitor BI Engine usage
SELECT
    project_id,
    bi_engine_statistics.bi_engine_mode,
    bi_engine_statistics.bi_engine_reasons,
    total_bytes_processed
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE bi_engine_statistics.bi_engine_mode IS NOT NULL
ORDER BY creation_time DESC;

-- BI Engine modes:
-- FULL: entire query accelerated
-- PARTIAL: some stages accelerated
-- DISABLED: not used (check reasons)
```

### Materialized Views

```sql
-- Create materialized view (auto-refresh, auto-tuning)
CREATE MATERIALIZED VIEW `project.dataset.daily_metrics`
PARTITION BY metric_date
CLUSTER BY region
OPTIONS (
    enable_refresh = TRUE,
    refresh_interval_minutes = 30,
    max_staleness = INTERVAL "4:0:0" HOUR TO SECOND
)
AS
SELECT
    DATE(order_time) AS metric_date,
    region,
    COUNT(*) AS order_count,
    SUM(amount) AS total_revenue,
    AVG(amount) AS avg_order_value,
    APPROX_COUNT_DISTINCT(customer_id) AS unique_customers
FROM `project.dataset.orders`
GROUP BY metric_date, region;

-- BigQuery automatically uses materialized views
-- even when querying the base table (smart tuning)
-- No need to change queries - optimizer rewrites automatically

-- Limitations:
-- - Aggregation queries only (GROUP BY)
-- - Single table (no JOINs, as of 2024)
-- - Limited function support
-- - Same dataset as base table
```

### Streaming and Batch Loading

```python
# Storage Write API (recommended for streaming)
from google.cloud import bigquery_storage_v1
from google.cloud.bigquery_storage_v1 import types, writer
from google.protobuf import descriptor_pb2
import json

client = bigquery_storage_v1.BigQueryWriteClient()
parent = f"projects/{project}/datasets/{dataset}/tables/{table}"

# Default stream (at-least-once, highest throughput)
write_stream = types.WriteStream(type_=types.WriteStream.Type.DEFAULT)

# Committed stream (exactly-once, lower throughput)
write_stream = types.WriteStream(type_=types.WriteStream.Type.COMMITTED)
stream = client.create_write_stream(parent=parent, write_stream=write_stream)

# Batch loading (most cost-effective, free for batch)
from google.cloud import bigquery
client = bigquery.Client()

# Load from GCS
job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.PARQUET,
    write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
)
load_job = client.load_table_from_uri(
    "gs://bucket/orders/*.parquet",
    "project.dataset.orders",
    job_config=job_config,
)
load_job.result()  # wait for completion

# Load from local file
with open("orders.jsonl", "rb") as f:
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        autodetect=True,
    )
    client.load_table_from_file(f, "project.dataset.orders", job_config=job_config)
```

### BigQuery Omni

```sql
-- Query data on AWS S3 without moving it
-- Requires BigQuery Omni connection in AWS region

CREATE EXTERNAL TABLE `project.dataset.aws_logs`
WITH CONNECTION `aws-us-east-1.my-connection`
OPTIONS (
    format = 'PARQUET',
    uris = ['s3://my-bucket/logs/year=*/month=*/*.parquet'],
    hive_partition_uri_prefix = 's3://my-bucket/logs/',
    max_staleness = INTERVAL 1 DAY
);

-- Cross-cloud join (data stays in place, query runs in each region)
SELECT
    gcp_orders.order_id,
    aws_logs.event_type
FROM `project.dataset.gcp_orders` gcp_orders
JOIN `project.dataset.aws_logs` aws_logs
    ON gcp_orders.order_id = aws_logs.order_id;
```

### BigLake

```sql
-- BigLake: unified governance over multi-cloud data lakes
CREATE TABLE `project.dataset.managed_events`
WITH CONNECTION `us.biglake-managed`
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://data-lake/events/*'],
    max_staleness = INTERVAL 30 MINUTE,
    metadata_cache_mode = 'AUTOMATIC',
    -- Fine-grained access control
    -- Column-level security and row-level security apply
);

-- BigLake with Apache Iceberg
CREATE TABLE `project.dataset.iceberg_orders`
WITH CONNECTION `us.biglake-managed`
OPTIONS (
    format = 'ICEBERG',
    uris = ['gs://data-lake/iceberg/orders'],
    -- Iceberg metadata is managed by BigQuery
);

-- BigLake tables support:
-- - Column-level security
-- - Row-level security (row access policies)
-- - Data masking policies
-- - Audit logging
-- - Works with open formats (Parquet, ORC, Avro, Iceberg)
```

### Cost Control

```sql
-- Monitor bytes scanned per user/project
SELECT
    user_email,
    COUNT(*) AS query_count,
    SUM(total_bytes_processed) / POW(1024, 4) AS tb_processed,
    SUM(total_bytes_processed) / POW(1024, 4) * 6.25 AS estimated_cost_usd
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND job_type = 'QUERY'
    AND state = 'DONE'
GROUP BY user_email
ORDER BY tb_processed DESC;

-- Set maximum bytes billed per query (prevent expensive accidents)
-- In client: job_config.maximum_bytes_billed = 10 * (1024 ** 3)  # 10 GB

-- Custom cost controls via labels
-- bq query --label=team:analytics --label=env:prod 'SELECT ...'
-- Track costs by label in billing export

-- Cost reduction strategies:
-- 1. Always use partitioned tables with partition filters
-- 2. Cluster on frequently filtered columns
-- 3. Use SELECT specific_columns (not SELECT *)
-- 4. Use APPROX_COUNT_DISTINCT instead of COUNT(DISTINCT)
-- 5. Avoid repeated JOINs by pre-joining into materialized views
-- 6. Use BigQuery BI Engine for repeated dashboard queries
-- 7. Set up custom quotas per user/project
-- 8. Monitor with Cloud Monitoring alerts on bytes scanned
```

### Security

```sql
-- VPC Service Controls (prevent data exfiltration)
-- Configured at organization level via Access Context Manager

-- Customer-Managed Encryption Keys (CMEK)
-- CREATE TABLE orders (...) OPTIONS (kms_key_name = 'projects/.../cryptoKeys/my-key');

-- Column-level security
-- 1. Create policy tag taxonomy
-- 2. Assign policy tags to columns
-- 3. Grant datacatalog.categoryFineGrainedReader to authorized users

-- Dynamic data masking
CREATE FUNCTION `project.dataset.mask_email`(email STRING)
RETURNS STRING
AS (
    CONCAT(LEFT(email, 2), '***@', SPLIT(email, '@')[SAFE_OFFSET(1)])
);

-- Row-level security (row access policies)
CREATE ROW ACCESS POLICY region_filter
ON `project.dataset.orders`
GRANT TO ('group:analysts@company.com')
FILTER USING (region IN ('US', 'EU'));

-- Authorized views (share specific data without table access)
-- Grant bigquery.dataViewer on the view, not the underlying tables
```
