---
name: schema-design
description: |
  Database schema design principles and patterns. Normalization (1NF through 5NF/BCNF), strategic denormalization for read performance, multi-tenancy schema patterns (shared schema, schema-per-tenant, database-per-tenant), primary key strategies (UUID v7, ULID, KSUID, Snowflake ID, BIGSERIAL, CUID2, NanoID), soft delete patterns, temporal tables (SCD Type 1/2/3/4/6), audit trails, schema evolution (expand-contract pattern), naming conventions, data type best practices, and anti-patterns to avoid (EAV, polymorphic associations, god tables). Use when designing new schemas, reviewing existing schema design, planning schema migrations, or choosing PK strategies.
allowed-tools: Read, Grep, Glob, Bash
---

# Schema Design

## Normalization

### Normal Forms

| Form | Rule | Violation Example | Fix |
|------|------|--------------------|-----|
| **1NF** | Atomic values, no repeating groups | `tags = "a,b,c"` in a column | Separate `tags` table |
| **2NF** | No partial dependencies on composite PK | `order_items(order_id, product_id, product_name)` | Move `product_name` to `products` |
| **3NF** | No transitive dependencies | `orders(customer_id, customer_name)` | Move `customer_name` to `customers` |
| **BCNF** | Every determinant is a candidate key | Overlapping candidate keys with partial overlap | Decompose into separate tables |
| **4NF** | No multi-valued dependencies | `employee(id, skill, language)` where skills and languages are independent | Separate into `employee_skills` and `employee_languages` |
| **5NF** | No join dependencies | Ternary relationships that decompose into binary | Decompose if each binary relationship is independently meaningful |

### When to Normalize

```
Start at 3NF for OLTP systems.
Consider BCNF when update anomalies appear.
4NF/5NF rarely needed in practice — only for complex multi-valued relationships.
```

### Normalization Decision Flow

```
Is the system OLTP (transactional)?
  YES → Normalize to 3NF minimum
    Are there complex candidate keys?
      YES → Consider BCNF
    Are there multi-valued facts?
      YES → Consider 4NF
  NO → Is it OLAP (analytical)?
    YES → Denormalize (star/snowflake schema)
    NO → Is it a hybrid workload?
      YES → Normalize base tables, create materialized views for reads
```

## Strategic Denormalization

### When to Denormalize

| Scenario | Pattern | Trade-off |
|----------|---------|-----------|
| **Read-heavy dashboards** | Materialized views, summary tables | Stale data (refresh interval) |
| **Avoid expensive JOINs** | Embed frequently-read data | Update anomalies (must sync) |
| **Counter/aggregate columns** | `orders_count` on `customers` | Must maintain via triggers or app logic |
| **Hierarchical data display** | `full_path` column in tree tables | Must recompute on tree changes |
| **Search optimization** | Denormalized search index table | Synchronization overhead |

### Safe Denormalization Patterns

```sql
-- Pattern 1: Materialized view (PostgreSQL)
CREATE MATERIALIZED VIEW order_summary AS
SELECT c.id AS customer_id, c.name, c.email,
       COUNT(o.id) AS order_count,
       SUM(o.total) AS lifetime_value,
       MAX(o.created_at) AS last_order_at
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name, c.email;

CREATE UNIQUE INDEX ON order_summary(customer_id);
-- Refresh: REFRESH MATERIALIZED VIEW CONCURRENTLY order_summary;

-- Pattern 2: Trigger-maintained counter
CREATE OR REPLACE FUNCTION update_order_count() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE customers SET orders_count = orders_count + 1
        WHERE id = NEW.customer_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE customers SET orders_count = orders_count - 1
        WHERE id = OLD.customer_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Pattern 3: Computed column (SQL Server)
ALTER TABLE orders ADD total_with_tax AS (total * 1.2) PERSISTED;
-- MySQL: Generated column
ALTER TABLE orders ADD total_with_tax DECIMAL(12,2)
    GENERATED ALWAYS AS (total * 1.2) STORED;
```

## Multi-Tenancy Schema Patterns

### Pattern Comparison

| Pattern | Isolation | Complexity | Cost | Scale | Use Case |
|---------|-----------|------------|------|-------|----------|
| **Shared schema (row-level)** | Low | Low | Low | 1000s of tenants | SaaS with many small tenants |
| **Schema-per-tenant** | Medium | Medium | Medium | 100s of tenants | Moderate data separation needs |
| **Database-per-tenant** | High | High | High | 10s of tenants | Regulated industries, large tenants |
| **Hybrid** | Variable | High | Variable | Mixed | Enterprise SaaS with tenant tiers |

### Shared Schema (Row-Level Tenancy)

```sql
-- Every table has tenant_id
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    customer_id BIGINT NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Composite indexes always start with tenant_id
CREATE INDEX idx_orders_tenant_customer ON orders(tenant_id, customer_id);
CREATE INDEX idx_orders_tenant_created ON orders(tenant_id, created_at DESC);

-- Row-Level Security (PostgreSQL)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Set tenant context per request
SET app.current_tenant = 'tenant-uuid-here';
```

### Schema-Per-Tenant

```sql
-- Create schema per tenant
CREATE SCHEMA tenant_acme;
CREATE TABLE tenant_acme.orders (LIKE public.orders_template INCLUDING ALL);

-- Search path approach
SET search_path TO tenant_acme, public;
-- Now "SELECT * FROM orders" queries tenant_acme.orders
```

### Database-Per-Tenant

```
Use when:
- Regulatory requirements mandate physical data separation
- Tenants need independent backup/restore schedules
- Tenants may need different database configurations
- Data residency requirements (different regions per tenant)

Connection routing:
- Application resolves tenant → connection string mapping
- Use connection pool per tenant (PgBouncer with separate databases)
- Consider a tenant registry database for routing metadata
```

## Primary Key Strategies

### Strategy Comparison

| Strategy | Size | Sortable | Globally Unique | Guessable | Performance | Best For |
|----------|------|----------|-----------------|-----------|-------------|----------|
| **BIGSERIAL** | 8B | Yes | No (per-table) | Yes | Best (sequential) | Internal tables, high-throughput OLTP |
| **UUID v4** | 16B | No | Yes | No | Poor (random I/O) | Legacy compatibility only |
| **UUID v7** | 16B | Yes | Yes | No | Good (time-ordered) | New projects needing UUID compatibility |
| **ULID** | 16B | Yes | Yes | No | Good (time-ordered) | Cross-language, string-sortable |
| **KSUID** | 20B | Yes | Yes | No | Good (time-ordered) | Segment ecosystem, 136-year range |
| **Snowflake ID** | 8B | Yes | Yes (with config) | Partially | Best (sequential, compact) | High-throughput distributed, Twitter/Discord |
| **CUID2** | ~24B | No | Yes | No | Moderate | Security-focused, no timestamp leak |
| **NanoID** | Variable | No | Yes | No | Moderate | URL-safe short IDs |

### Implementation Examples

```sql
-- BIGSERIAL (PostgreSQL)
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);

-- UUID v7 (PostgreSQL 17+ or via extension)
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7()
);

-- UUID v7 (application-generated, any PostgreSQL version)
CREATE TABLE orders (
    id UUID PRIMARY KEY  -- Application generates UUID v7 before INSERT
);

-- Snowflake ID (application-generated)
-- Typically generated in application layer (Twitter Snowflake, Discord Snowflake, Instagram)
-- 64-bit: timestamp (41 bits) + machine ID (10 bits) + sequence (12 bits)
CREATE TABLE events (
    id BIGINT PRIMARY KEY  -- Application generates Snowflake ID
);
```

### Primary Key Anti-Patterns

```
AVOID:
- Natural keys as PK (email, SSN, phone) — they change
- Composite PKs with >2 columns — complicates JOINs and ORMs
- UUID v4 as clustered PK — random I/O kills write performance on B-tree indexes
- Sequential IDs exposed in URLs — information disclosure (use UUID/ULID for external-facing)
- SERIAL (32-bit) for tables that might exceed 2B rows — use BIGSERIAL

PREFER:
- BIGSERIAL for internal-only tables (fastest, smallest)
- UUID v7 or ULID for distributed or external-facing IDs
- Surrogate PK + unique constraint on natural key
```

## Soft Delete Patterns

### Approaches

| Approach | Column | Query Impact | Recovery | Storage |
|----------|--------|-------------|----------|---------|
| **Boolean flag** | `is_deleted BOOLEAN DEFAULT false` | Every query needs `WHERE NOT is_deleted` | Easy | Grows forever |
| **Timestamp** | `deleted_at TIMESTAMPTZ` | `WHERE deleted_at IS NULL` | Easy + when deleted | Grows forever |
| **Status enum** | `status = 'deleted'` | `WHERE status != 'deleted'` | Easy | Grows forever |
| **Archive table** | Move rows to `orders_archive` | No query impact on main table | Moderate | Separate table |
| **Partitioned** | Partition by `is_active` | Partition pruning | Moderate | Clean separation |

### Recommended: Timestamp + Partial Index

```sql
-- Soft delete with timestamp
ALTER TABLE orders ADD COLUMN deleted_at TIMESTAMPTZ;

-- Partial index: only index active rows (smaller, faster)
CREATE INDEX idx_orders_active_customer
    ON orders(customer_id) WHERE deleted_at IS NULL;

-- Default scope: active records only
-- Application layer should add "WHERE deleted_at IS NULL" by default
-- ORM examples:
--   Rails: default_scope { where(deleted_at: nil) }
--   Django: custom Manager with get_queryset().filter(deleted_at__isnull=True)
--   SQLAlchemy: @hybrid_property for is_active

-- Unique constraints with soft delete
CREATE UNIQUE INDEX idx_orders_number_unique
    ON orders(order_number) WHERE deleted_at IS NULL;
-- Allows re-use of order_number after soft deletion
```

### Archive Table Pattern

```sql
-- Move deleted rows to archive (better for large tables)
CREATE TABLE orders_archive (LIKE orders INCLUDING ALL);

-- Delete + archive in one transaction
WITH deleted AS (
    DELETE FROM orders WHERE id = $1 RETURNING *
)
INSERT INTO orders_archive SELECT * FROM deleted;
```

## Temporal Tables & Slowly Changing Dimensions

### SCD Types

| Type | Description | History | Use Case |
|------|-------------|---------|----------|
| **Type 1** | Overwrite | No history | Corrections, non-critical data |
| **Type 2** | Add new row with versioning | Full history | Audit requirements, analytics |
| **Type 3** | Add previous value column | Limited (1 prior) | When only last change matters |
| **Type 4** | Separate history table | Full history | Clean current + full history |
| **Type 6** | Hybrid (1+2+3) | Full + current flag | Complex analytics needs |

### System-Versioned Temporal Tables

```sql
-- PostgreSQL (manual implementation)
CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ NOT NULL DEFAULT 'infinity',
    is_current BOOLEAN NOT NULL DEFAULT true,
    PRIMARY KEY (id, valid_from)
);

-- Insert new version (SCD Type 2)
-- Step 1: Close current version
UPDATE products SET valid_to = now(), is_current = false
WHERE id = 42 AND is_current = true;
-- Step 2: Insert new version
INSERT INTO products (id, name, price) OVERRIDING SYSTEM VALUE
VALUES (42, 'Widget Pro', 29.99);

-- Query: current state
SELECT * FROM products WHERE is_current = true;
-- Query: state at a point in time
SELECT * FROM products
WHERE valid_from <= '2024-06-01' AND valid_to > '2024-06-01';

-- SQL Server (native support)
CREATE TABLE products (
    id INT PRIMARY KEY,
    name NVARCHAR(100),
    price DECIMAL(12,2),
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START,
    valid_to DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.products_history));

-- Query historical state natively
SELECT * FROM products FOR SYSTEM_TIME AS OF '2024-06-01';
```

## Audit Trails

### Application-Level Audit

```sql
CREATE TABLE audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id BIGINT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    user_id BIGINT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_created ON audit_log(created_at);

-- Generic audit trigger (PostgreSQL)
CREATE OR REPLACE FUNCTION audit_trigger() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_fields, user_id)
    VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        TG_OP,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END,
        CASE WHEN TG_OP = 'UPDATE' THEN
            ARRAY(SELECT key FROM jsonb_each(to_jsonb(NEW))
                  WHERE to_jsonb(NEW) -> key IS DISTINCT FROM to_jsonb(OLD) -> key)
        END,
        current_setting('app.current_user_id', true)::bigint
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply to any table
CREATE TRIGGER orders_audit AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

## Schema Evolution

### Expand-Contract Pattern

```
Phase 1: EXPAND — add new structure alongside old
Phase 2: MIGRATE — move data / update application code
Phase 3: CONTRACT — remove old structure

This enables zero-downtime schema changes by ensuring both old and new
application versions can work with the database simultaneously.
```

### Safe Migration Operations

| Operation | Safe? | Technique |
|-----------|-------|-----------|
| **Add column (nullable)** | Yes | `ALTER TABLE ADD COLUMN` |
| **Add column (NOT NULL + default)** | Yes (PG 11+, MySQL 8.0.12+) | Metadata-only in modern engines |
| **Drop column** | Careful | Stop reading first, then drop |
| **Rename column** | No | Add new, copy, drop old (expand-contract) |
| **Change type** | No | Add new column, migrate, drop old |
| **Add index** | Yes | `CREATE INDEX CONCURRENTLY` (PG), `ALGORITHM=INPLACE` (MySQL) |
| **Drop index** | Yes | Direct drop, no lock issues |
| **Add NOT NULL** | No | Add CHECK constraint first, then NOT NULL |
| **Add foreign key** | Careful | `NOT VALID` first, then `VALIDATE` separately (PG) |

### Zero-Downtime Column Rename

```sql
-- Step 1: Add new column
ALTER TABLE users ADD COLUMN full_name TEXT;

-- Step 2: Backfill (batched)
UPDATE users SET full_name = name WHERE full_name IS NULL AND id BETWEEN 1 AND 10000;
-- ... repeat for all batches

-- Step 3: Deploy app reading BOTH columns (COALESCE(full_name, name))
-- Step 4: Deploy app writing BOTH columns
-- Step 5: Deploy app reading ONLY full_name
-- Step 6: Drop old column
ALTER TABLE users DROP COLUMN name;
```

## Naming Conventions

### Recommended Standards

| Element | Convention | Example | Anti-Pattern |
|---------|-----------|---------|-------------|
| **Tables** | Plural, snake_case | `order_items` | `OrderItem`, `tbl_order_item` |
| **Columns** | Singular, snake_case | `created_at` | `CreatedAt`, `dtCreated` |
| **Primary keys** | `id` | `orders.id` | `order_id`, `OrderID` |
| **Foreign keys** | `{referenced_table_singular}_id` | `orders.customer_id` | `custID`, `fk_customer` |
| **Indexes** | `idx_{table}_{columns}` | `idx_orders_customer_id` | `index1`, `IX_Orders` |
| **Unique constraints** | `unq_{table}_{columns}` | `unq_users_email` | `unique1` |
| **Check constraints** | `chk_{table}_{description}` | `chk_orders_total_positive` | `CK1` |
| **Booleans** | `is_` or `has_` prefix | `is_active`, `has_verified` | `active`, `verified` |
| **Timestamps** | `_at` suffix | `created_at`, `updated_at` | `creation_date`, `dtUpdated` |
| **Enums / status** | Descriptive | `status`, `payment_method` | `type`, `flag` |

### Consistent Timestamp Columns

```sql
-- Standard timestamp columns for every table
created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()

-- Auto-update updated_at (PostgreSQL)
CREATE OR REPLACE FUNCTION update_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- MySQL equivalent
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

## Data Type Best Practices

### Common Decisions

| Data | Recommended Type | Avoid | Reason |
|------|-----------------|-------|--------|
| **Money** | `DECIMAL(12,2)` or `BIGINT` (cents) | `FLOAT`, `DOUBLE` | Floating point precision errors |
| **Timestamps** | `TIMESTAMPTZ` (PG), `DATETIME` (MySQL) | `TIMESTAMP` without TZ | Timezone confusion |
| **IP addresses** | `INET` (PG), `VARBINARY(16)` (MySQL) | `VARCHAR(45)` | Efficient storage and operations |
| **Email** | `CITEXT` (PG) or `VARCHAR(254)` | `TEXT` without constraint | Max email length is 254 per RFC 5321 |
| **JSON data** | `JSONB` (PG), `JSON` (MySQL 8+) | `TEXT` + parse in app | Indexable, validatable |
| **Enums** | `VARCHAR` with CHECK or lookup table | Native ENUM type | ENUMs are hard to modify |
| **Country** | `CHAR(2)` (ISO 3166-1 alpha-2) | `VARCHAR(100)` for country name | Standardized, compact |
| **Currency** | `CHAR(3)` (ISO 4217) | `VARCHAR` for currency name | Standardized |
| **Phone** | `VARCHAR(20)` (E.164 format) | `BIGINT` | Leading zeros, formatting |
| **Percentage** | `DECIMAL(5,2)` or `DECIMAL(5,4)` | `INT` | Need decimal precision |

### PostgreSQL-Specific Types

```sql
-- Use domain types for validation
CREATE DOMAIN email AS CITEXT CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
CREATE DOMAIN positive_amount AS DECIMAL(12,2) CHECK (VALUE > 0);

-- Use arrays for simple lists (avoid separate table overhead for small, rarely-queried lists)
tags TEXT[] DEFAULT '{}'

-- Use JSONB for semi-structured data
metadata JSONB DEFAULT '{}'

-- Range types for intervals
CREATE TABLE reservations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id INT NOT NULL,
    during TSTZRANGE NOT NULL,
    EXCLUDE USING GIST (room_id WITH =, during WITH &&)  -- no overlapping reservations
);
```

## Anti-Patterns

### Entity-Attribute-Value (EAV)

```sql
-- ANTI-PATTERN: EAV table
CREATE TABLE attributes (
    entity_id INT,
    attribute_name VARCHAR(100),
    attribute_value TEXT     -- everything is a string, no type safety
);
-- Problems: no type safety, no constraints, impossible to query efficiently, no referential integrity

-- BETTER: JSONB column for flexible attributes
ALTER TABLE products ADD COLUMN attributes JSONB DEFAULT '{}';
-- Or: separate typed columns with NULLs for optional fields
-- Or: table-per-type inheritance (PostgreSQL)
```

### Polymorphic Associations

```sql
-- ANTI-PATTERN: polymorphic FK
CREATE TABLE comments (
    id BIGINT PRIMARY KEY,
    commentable_type VARCHAR(50),  -- 'Post', 'Photo', 'Video'
    commentable_id BIGINT,         -- no FK constraint possible
    body TEXT
);

-- BETTER: separate FK columns (exclusive arc)
CREATE TABLE comments (
    id BIGINT PRIMARY KEY,
    post_id BIGINT REFERENCES posts(id),
    photo_id BIGINT REFERENCES photos(id),
    video_id BIGINT REFERENCES videos(id),
    body TEXT,
    CHECK (
        (post_id IS NOT NULL)::int +
        (photo_id IS NOT NULL)::int +
        (video_id IS NOT NULL)::int = 1
    )
);

-- OR: separate junction/comment tables per type
```

### God Tables

```
ANTI-PATTERN: Single table with 100+ columns, many NULL
- users table with billing_address, shipping_address, preferences, profile, settings,
  subscription, payment, notification preferences all in one table

BETTER: Vertical split into focused tables
- users (core identity: id, email, name, created_at)
- user_profiles (bio, avatar, preferences)
- user_addresses (type, street, city, country)
- user_settings (notification, privacy, display)
- user_subscriptions (plan, billing, payment_method)
Each table has user_id FK. Query only what you need.
```

### Other Anti-Patterns

| Anti-Pattern | Problem | Solution |
|-------------|---------|----------|
| **Missing timestamps** | Cannot audit or debug | Always add `created_at`, `updated_at` |
| **Implicit defaults** | Unclear behavior | Always specify `DEFAULT` or `NOT NULL` explicitly |
| **Over-indexing** | Slow writes, wasted space | Index only columns used in WHERE, JOIN, ORDER BY |
| **Missing foreign keys** | Orphaned data, inconsistency | Always define FK constraints in OLTP |
| **VARCHAR(255) everywhere** | Wasted space estimation | Use appropriate lengths or TEXT |
| **Business logic in triggers** | Hidden, hard to test | Keep logic in application, triggers for audit/timestamps only |
| **No check constraints** | Invalid data enters | Add CHECK for enums, ranges, positive values |

## Quick Reference

1. **Start at 3NF** for OLTP — denormalize only when measured read performance requires it
2. **Use surrogate PKs** (BIGSERIAL or UUID v7) — never natural keys as PK
3. **Pick one PK strategy per project** — consistency across all tables
4. **Row-level security** for multi-tenant SaaS — schema-per-tenant for regulated industries
5. **Soft delete with timestamp** + partial indexes — archive table for very large datasets
6. **Expand-contract** for all schema changes — never rename/change type in place
7. **Consistent naming** — plural tables, snake_case, standard suffixes
8. **Typed columns** — DECIMAL for money, TIMESTAMPTZ for times, JSONB for flexible data
9. **Audit everything** — generic trigger + audit_log table
10. **Avoid EAV** — use JSONB or table-per-type instead
