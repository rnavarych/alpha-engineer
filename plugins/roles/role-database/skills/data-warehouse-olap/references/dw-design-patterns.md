# Data Warehouse Design Patterns and Cost Optimization

## When to load
Load when designing data warehouse schemas (star/snowflake schema, SCD, Data Vault 2.0), planning cost optimization across Snowflake/BigQuery/Redshift, or implementing general OLAP best practices.

## Star Schema

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

## Snowflake Schema (Normalized Dimensions)

```
dim_product -> dim_category -> dim_department
dim_customer -> dim_geography -> dim_country
```

Use snowflake schema when dimensions are large and often queried independently. Use star schema when query performance is the priority and storage is secondary.

## Slowly Changing Dimensions (SCD)

```sql
-- Type 1: Overwrite (no history)
UPDATE dim_customer SET address = 'new_address' WHERE customer_id = 123;

-- Type 2: New row with versioning (full history)
INSERT INTO dim_customer (customer_id, address, effective_date, expiry_date, is_current)
VALUES (123, 'new_address', CURRENT_DATE, '9999-12-31', TRUE);
UPDATE dim_customer SET is_current = FALSE, expiry_date = CURRENT_DATE
WHERE customer_id = 123 AND is_current = TRUE AND address = 'old_address';

-- Type 3: Previous value column (one level of history)
ALTER TABLE dim_customer ADD COLUMN previous_address VARCHAR;
UPDATE dim_customer SET previous_address = address, address = 'new_address'
WHERE customer_id = 123;
```

## Data Vault 2.0

```
Hub (business keys) -> Link (relationships) -> Satellite (descriptive attributes)

Hubs:      unique business keys (customer_id, order_id) — never change
Links:     many-to-many relationships between hubs
Satellites: temporal attributes with load_date and hash_diff

Benefits: parallel loading, audit trail, schema evolution without breaking changes
Use when: regulatory compliance, frequent schema changes, full auditability needed
```

## Cost Optimization by Platform

### Snowflake
- Auto-suspend: 60s dev, 120s ETL, 300s production (minimum increments)
- Use XSMALL for development, scale up only for production
- Clustering keys only for tables >1TB with predictable filter patterns
- Materialized views for repeated expensive aggregations
- Resource monitors: alerts at 75%, 90%, suspend at 100%

### BigQuery
- Use partitioned tables with `require_partition_filter = TRUE`
- Cluster on high-cardinality filter columns (up to 4)
- Prefer batch loads over streaming inserts (10x cheaper per row)
- Use `SELECT specific_columns` instead of `SELECT *`
- Set `maximum_bytes_billed` per query in client code
- Consider flat-rate pricing at high query volume

### Redshift
- Use RA3 nodes (managed storage, scale compute independently)
- Serverless for variable workloads
- Spectrum for cold data on S3 (avoid loading everything into cluster)
- Concurrency scaling for burst demand (auto-add read clusters)

### General (all platforms)
- Implement data tiering: hot (30 days), warm (1 year), cold (archive)
- Compress storage: Parquet with ZSTD for files, Arrow for in-memory
- Schedule heavy ETL during off-peak hours
- Pre-aggregate: materialized views / summary tables for dashboards
- Monitor query patterns: identify and fix missing partition filters, full scans

## OLAP Query Patterns

```sql
-- Rollup (hierarchical aggregation)
SELECT region, country, city, SUM(revenue)
FROM sales GROUP BY ROLLUP(region, country, city);

-- Cube (all combinations)
SELECT region, product_category, SUM(revenue)
FROM sales GROUP BY CUBE(region, product_category);

-- Window functions for analytics
SELECT customer_id, order_date, amount,
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
       LAG(amount, 1) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order,
       RANK() OVER (PARTITION BY region ORDER BY amount DESC) AS rank_in_region
FROM orders;
```
