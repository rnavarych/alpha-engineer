# Databricks and Amazon Redshift

## When to load
Load when working with Databricks (Delta Lake, Unity Catalog, Photon, Spark DataFrames) or Amazon Redshift (distribution styles, sort keys, Spectrum, Serverless, materialized views).

## Databricks — Delta Lake

```sql
CREATE TABLE orders (
    order_id STRING, customer_id STRING,
    amount DECIMAL(12, 2), order_date DATE
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
MERGE INTO target USING source ON target.id = source.id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- Change Data Feed
SELECT * FROM table_changes('orders', 5, 10);
-- _change_type: insert, update_preimage, update_postimage, delete
```

## Databricks — Unity Catalog

```sql
CREATE CATALOG analytics;
CREATE SCHEMA analytics.production;
GRANT SELECT ON TABLE analytics.production.orders TO `data-analysts`;
-- Three-level namespace: catalog.schema.table
```

## Databricks — Python SDK

```python
from databricks.connect import DatabricksSession

spark = DatabricksSession.builder.remote(
    host="https://workspace.cloud.databricks.com",
    token="dapi...",
    cluster_id="0123-456789-abcdef"
).getOrCreate()

df = spark.read.table("analytics.production.orders")
revenue = df.groupBy("region").agg({"amount": "sum"}).collect()
```

**Photon**: C++ vectorized execution engine (3-8x faster). Enable on cluster Runtime >= 9.1 Photon or SQL Warehouse.

## Amazon Redshift — Distribution Styles

```sql
CREATE TABLE orders (
    order_id BIGINT IDENTITY(1,1),
    customer_id BIGINT,
    amount DECIMAL(12, 2),
    order_date DATE,
    region VARCHAR(50)
)
DISTSTYLE KEY
DISTKEY (customer_id)           -- co-locate rows with same key on same node
COMPOUND SORTKEY (order_date, region);

-- Distribution guidance:
-- KEY:  large fact tables, join key with dimension tables
-- ALL:  small dimension tables (<= few million rows)
-- EVEN: no clear join pattern
-- AUTO: let Redshift decide (good default for new tables)
```

## Redshift — Spectrum and Serverless

```sql
-- Spectrum: query S3 directly
CREATE EXTERNAL SCHEMA spectrum_schema
FROM DATA CATALOG DATABASE 'external_db'
IAM_ROLE 'arn:aws:iam::123456:role/RedshiftSpectrumRole';

CREATE EXTERNAL TABLE spectrum_schema.historical_orders (
    order_id BIGINT, amount DECIMAL(12,2), order_date DATE
)
STORED AS PARQUET
LOCATION 's3://data-lake/historical-orders/';

-- Federated query: Redshift + S3
SELECT region, SUM(amount) FROM orders
UNION ALL
SELECT region, SUM(amount) FROM spectrum_schema.historical_orders
GROUP BY region;

-- Serverless: auto-scaling RPUs, pay per RPU-hour
-- aws redshift-serverless create-workgroup --workgroup-name analytics \
--   --base-capacity 32 --max-capacity 256

-- Materialized views (auto-refresh)
CREATE MATERIALIZED VIEW daily_revenue AUTO REFRESH YES AS
SELECT order_date, region, SUM(amount) AS total
FROM orders GROUP BY order_date, region;
```

## Cost Optimization

- Databricks: Photon SQL Warehouses for BI; Delta auto-optimize for small files; Unity Catalog for RBAC
- Redshift: RA3 nodes (managed storage, scale compute separately); Serverless for variable workloads; Spectrum for cold S3 data
