# Snowflake

## When to load
Load when working with Snowflake: warehouse sizing, clustering keys, time travel, zero-copy cloning, Snowpark, Snowpipe, streams/tasks/DAGs, data sharing, security policies, cost control.

## Warehouse Management

```sql
-- Sizes: X-Small=1 credit/hr, Small=2, Medium=4, Large=8, X-Large=16, 2X-Large=32
ALTER WAREHOUSE dev_wh SET AUTO_SUSPEND = 60 AUTO_RESUME = TRUE WAREHOUSE_SIZE = 'XSMALL';
ALTER WAREHOUSE prod_wh SET AUTO_SUSPEND = 300 AUTO_RESUME = TRUE WAREHOUSE_SIZE = 'MEDIUM';

-- Multi-cluster (STANDARD: fast scale | ECONOMY: cost savings, slower)
ALTER WAREHOUSE prod_wh SET MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 6 SCALING_POLICY = 'STANDARD';

-- Monitor usage
SELECT warehouse_name, SUM(credits_used) AS total_credits, MAX(queued_overload) AS max_queued
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time > DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name ORDER BY total_credits DESC;
```

## Clustering Keys

```sql
-- Use when: table > 1TB, queries consistently filter same columns (max 3-4 cols)
ALTER TABLE events CLUSTER BY (event_date, user_id);
SELECT SYSTEM$CLUSTERING_INFORMATION('events', '(event_date, user_id)');
-- depth 1-2: excellent | 4-8: consider recluster | >8: urgent
ALTER TABLE events RESUME RECLUSTER;  -- enable auto-reclustering
```

## Time Travel and Zero-Copy Cloning

```sql
ALTER TABLE orders SET DATA_RETENTION_TIME_IN_DAYS = 30;  -- Enterprise: up to 90 days

SELECT * FROM orders AT(TIMESTAMP => '2024-06-15 14:30:00'::TIMESTAMP_LTZ);
SELECT * FROM orders AT(OFFSET => -7200);
SELECT * FROM orders BEFORE(STATEMENT => '01b12345-0123-4567-8901-abcdef123456');
UNDROP TABLE orders;

-- Zero-copy clone (instant, copy-on-write, no additional storage upfront)
CREATE DATABASE dev_db CLONE prod_db;
CREATE TABLE orders_before_migration CLONE orders BEFORE(STATEMENT => '01b12345-...');
-- NOTE: streams, tasks, stages, and grants are NOT included in clones
```

## Snowpark

```python
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, sum as sum_, avg, when, lit

session = Session.builder.configs({
    "account": "myaccount", "user": "myuser", "password": "mypassword",
    "warehouse": "compute_wh", "database": "analytics", "schema": "public"
}).create()

result = (
    session.table("orders")
    .filter(col("order_date") >= "2024-01-01")
    .with_column("order_tier", when(col("amount") > 1000, lit("premium"))
                                .when(col("amount") > 100, lit("standard"))
                                .otherwise(lit("basic")))
    .group_by("region", "order_tier")
    .agg(sum_("amount").alias("total_revenue"), avg("amount").alias("avg_order"))
    .sort(col("total_revenue").desc())
)
result.write.mode("overwrite").save_as_table("regional_revenue_summary")
```

## Streams, Tasks, and Snowpipe

```sql
CREATE STREAM orders_stream ON TABLE orders;
CREATE STREAM orders_append_stream ON TABLE orders APPEND_ONLY = TRUE;

-- Task DAG (resume leaf nodes first, root task last)
CREATE TASK parent_task WAREHOUSE = etl_wh SCHEDULE = '1 HOUR' AS ...;
CREATE TASK child_task WAREHOUSE = etl_wh AFTER parent_task AS ...;
ALTER TASK child_task RESUME;
ALTER TASK parent_task RESUME;

-- Snowpipe: auto-ingest from S3/GCS/Azure
CREATE PIPE orders_pipe AUTO_INGEST = TRUE AS
  COPY INTO orders FROM @orders_stage FILE_FORMAT = (TYPE = 'PARQUET')
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
```

## Security

```sql
-- Column-level masking
CREATE MASKING POLICY email_mask AS (val STRING) RETURNS STRING ->
    CASE WHEN CURRENT_ROLE() IN ('ADMIN') THEN val
         ELSE REGEXP_REPLACE(val, '.+@', '***@') END;
ALTER TABLE customers MODIFY COLUMN email SET MASKING POLICY email_mask;

-- Row access policy
CREATE ROW ACCESS POLICY region_filter AS (region_val VARCHAR) RETURNS BOOLEAN ->
    CURRENT_ROLE() = 'ADMIN'
    OR region_val IN (SELECT region FROM user_regions WHERE user = CURRENT_USER());
ALTER TABLE orders ADD ROW ACCESS POLICY region_filter ON (region);
```

## Cost Optimization

- Auto-suspend: 60s dev, 120s ETL, 300s production
- Resource monitors: alerts at 75%, 90%, suspend at 100%
- Clustering keys only for tables >1TB with consistent filter patterns
- Materialized views for repeated expensive aggregations
- Monitor `snowflake.account_usage.query_history`: scan % and elapsed time
