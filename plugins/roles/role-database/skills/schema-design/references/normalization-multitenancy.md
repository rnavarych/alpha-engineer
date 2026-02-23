# Normalization and Multi-Tenancy

## When to load
Load when designing relational schemas, deciding normalization depth, implementing multi-tenancy (shared schema, schema-per-tenant, database-per-tenant), or choosing primary key strategies.

## Normalization

### Normal Forms Reference

| Form | Rule | Violation Example | Fix |
|------|------|--------------------|-----|
| **1NF** | Atomic values, no repeating groups | `tags = "a,b,c"` in a column | Separate `tags` table |
| **2NF** | No partial dependencies on composite PK | `order_items(order_id, product_id, product_name)` | Move `product_name` to `products` |
| **3NF** | No transitive dependencies | `orders(customer_id, customer_name)` | Move `customer_name` to `customers` |
| **BCNF** | Every determinant is a candidate key | Overlapping candidate keys | Decompose into separate tables |
| **4NF** | No multi-valued dependencies | `employee(id, skill, language)` | Separate into `employee_skills` and `employee_languages` |

```
OLTP → Start at 3NF. OLAP → Denormalize (star/snowflake). Hybrid → normalize base, materialized views for reads.
```

## Strategic Denormalization

```sql
-- Materialized view (PostgreSQL)
CREATE MATERIALIZED VIEW order_summary AS
SELECT c.id AS customer_id, c.name, COUNT(o.id) AS order_count,
       SUM(o.total) AS lifetime_value, MAX(o.created_at) AS last_order_at
FROM customers c LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name, c.email;
CREATE UNIQUE INDEX ON order_summary(customer_id);
-- REFRESH MATERIALIZED VIEW CONCURRENTLY order_summary;

-- Trigger-maintained counter
CREATE OR REPLACE FUNCTION update_order_count() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE customers SET orders_count = orders_count + 1 WHERE id = NEW.customer_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE customers SET orders_count = orders_count - 1 WHERE id = OLD.customer_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

## Multi-Tenancy Schema Patterns

| Pattern | Isolation | Complexity | Cost | Use Case |
|---------|-----------|------------|------|----------|
| **Shared schema (row-level)** | Low | Low | Low | SaaS with many small tenants |
| **Schema-per-tenant** | Medium | Medium | Medium | Moderate data separation needs |
| **Database-per-tenant** | High | High | High | Regulated industries, large tenants |

### Shared Schema (Row-Level) with RLS
```sql
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    customer_id BIGINT NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_tenant_customer ON orders(tenant_id, customer_id);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.current_tenant')::uuid);
-- SET app.current_tenant = 'tenant-uuid-here' per request
```

### Schema-Per-Tenant
```sql
CREATE SCHEMA tenant_acme;
CREATE TABLE tenant_acme.orders (LIKE public.orders_template INCLUDING ALL);
SET search_path TO tenant_acme, public;
-- "SELECT * FROM orders" now queries tenant_acme.orders
```

## Primary Key Strategies

| Strategy | Size | Sortable | Globally Unique | Performance | Best For |
|----------|------|----------|-----------------|-------------|----------|
| **BIGSERIAL** | 8B | Yes | No | Best (sequential) | Internal tables, high-throughput OLTP |
| **UUID v4** | 16B | No | Yes | Poor (random I/O) | Legacy compatibility only |
| **UUID v7** | 16B | Yes | Yes | Good (time-ordered) | New projects needing UUID compatibility |
| **ULID** | 16B | Yes | Yes | Good (time-ordered) | Cross-language, string-sortable |
| **Snowflake ID** | 8B | Yes | Yes (with config) | Best (sequential) | High-throughput distributed |

```sql
-- BIGSERIAL
CREATE TABLE orders (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY);

-- UUID v7 (PostgreSQL 17+ or pg_uuidv7 extension)
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
CREATE TABLE orders (id UUID PRIMARY KEY DEFAULT uuid_generate_v7());
```

### PK Anti-Patterns
```
AVOID: natural keys as PK, UUID v4 as clustered PK (random I/O), SERIAL for tables > 2B rows
PREFER: BIGSERIAL for internal-only, UUID v7 or ULID for distributed/external-facing
```
