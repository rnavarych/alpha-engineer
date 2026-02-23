# Google BigQuery

## When to load
Load when working with BigQuery: slot management, partitioning/clustering, BQML, BI Engine, materialized views, Storage Write API, BigQuery Omni, BigLake, cost control, row-level security.

## Slot Management

```sql
-- Identify expensive queries
SELECT job_id, user_email,
       total_bytes_processed / POW(1024, 3) AS gb_processed,
       total_slot_ms / 1000 AS slot_seconds
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND job_type = 'QUERY' AND state = 'DONE'
ORDER BY total_bytes_processed DESC LIMIT 20;
```

```bash
# Enterprise reservation + autoscale
bq mk --reservation --project_id=my-project --location=US \
  --reservation_id=prod-analytics --slots=500 --edition=ENTERPRISE
bq mk --reservation --project_id=my-project --location=US \
  --reservation_id=autoscale-pool --slots=100 --edition=ENTERPRISE --autoscale_max_slots=1000
bq mk --reservation_assignment --project_id=my-project --location=US \
  --reservation_id=prod-analytics --assignee_id=analytics-project --assignee_type=PROJECT --job_type=QUERY
```

## Partitioning and Clustering

```sql
-- Time-unit partitioning + clustering (require_partition_filter prevents full scans)
CREATE TABLE `project.dataset.orders` (
    order_id STRING, customer_id STRING, region STRING, amount NUMERIC, order_date DATE
)
PARTITION BY order_date
CLUSTER BY region, customer_id
OPTIONS (partition_expiration_days = 365, require_partition_filter = TRUE);

-- Materialized view (auto-refresh, auto-used by query optimizer)
CREATE MATERIALIZED VIEW `project.dataset.daily_metrics`
PARTITION BY metric_date CLUSTER BY region
OPTIONS (enable_refresh = TRUE, refresh_interval_minutes = 30)
AS SELECT DATE(order_time) AS metric_date, region,
          COUNT(*) AS order_count, SUM(amount) AS total_revenue
   FROM `project.dataset.orders` GROUP BY 1, 2;
```

## BQML

```sql
-- Boosted tree classifier with feature engineering
CREATE OR REPLACE MODEL `project.dataset.fraud_detector`
TRANSFORM (
    ML.BUCKETIZE(amount, [10, 50, 100, 500, 1000]) AS amount_bucket,
    ML.FEATURE_CROSS(STRUCT(category, region)) AS category_region,
    is_fraud
)
OPTIONS (model_type = 'BOOSTED_TREE_CLASSIFIER', input_label_cols = ['is_fraud'],
         auto_class_weights = TRUE)
AS SELECT * FROM `project.dataset.transaction_features`;

SELECT * FROM ML.EVALUATE(MODEL `project.dataset.fraud_detector`);
SELECT transaction_id, predicted_is_fraud FROM ML.PREDICT(
    MODEL `project.dataset.fraud_detector`,
    (SELECT * FROM `project.dataset.new_transactions`));

-- ARIMA_PLUS time-series forecast
CREATE OR REPLACE MODEL `project.dataset.sales_forecast`
OPTIONS (model_type = 'ARIMA_PLUS', time_series_timestamp_col = 'date',
         time_series_data_col = 'daily_sales', auto_arima = TRUE, holiday_region = 'US')
AS SELECT date, daily_sales FROM `project.dataset.daily_sales_history`;
SELECT * FROM ML.FORECAST(MODEL `project.dataset.sales_forecast`,
    STRUCT(30 AS horizon, 0.9 AS confidence_level));
```

## BI Engine and Streaming

```sql
-- BI Engine mode check (FULL / PARTIAL / DISABLED)
SELECT bi_engine_statistics.bi_engine_mode, total_bytes_processed
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE bi_engine_statistics.bi_engine_mode IS NOT NULL ORDER BY creation_time DESC;
```

```python
# Storage Write API: COMMITTED stream = exactly-once semantics
from google.cloud import bigquery_storage_v1, bigquery
write_stream = bigquery_storage_v1.types.WriteStream(type_=bigquery_storage_v1.types.WriteStream.Type.COMMITTED)
# Batch load (free — most cost-effective for bulk)
bigquery.Client().load_table_from_uri("gs://bucket/orders/*.parquet", "project.dataset.orders",
    job_config=bigquery.LoadJobConfig(source_format=bigquery.SourceFormat.PARQUET)).result()
```

## BigQuery Omni and BigLake

```sql
-- Omni: query AWS S3 without moving data (runs compute in AWS region)
CREATE EXTERNAL TABLE `project.dataset.aws_logs`
WITH CONNECTION `aws-us-east-1.my-connection`
OPTIONS (format = 'PARQUET', uris = ['s3://my-bucket/logs/*'], max_staleness = INTERVAL 1 DAY);

-- BigLake: open formats with unified governance (column/row-level security applies)
CREATE TABLE `project.dataset.iceberg_orders`
WITH CONNECTION `us.biglake-managed`
OPTIONS (format = 'ICEBERG', uris = ['gs://data-lake/iceberg/orders']);
```

## Security and Cost Optimization

```sql
-- Row-level security
CREATE ROW ACCESS POLICY region_filter ON `project.dataset.orders`
GRANT TO ('group:analysts@company.com') FILTER USING (region IN ('US', 'EU'));
```

- Use `require_partition_filter = TRUE` on large tables — prevents full scan accidents
- Prefer `SELECT specific_columns` over `SELECT *`; batch loads are free, streaming ~10x cost
- Set `maximum_bytes_billed` per query in client code to prevent accidents
- Use `APPROX_COUNT_DISTINCT` instead of `COUNT(DISTINCT)` for large cardinality
