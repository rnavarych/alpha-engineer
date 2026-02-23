# Temporal Tables, Audit Trails, and Schema Evolution

## When to load
Load when implementing SCD (Slowly Changing Dimensions), temporal/versioned tables, generic audit logging triggers, soft delete patterns, or zero-downtime schema changes with expand-contract.

## Soft Delete Patterns

| Approach | Column | Recovery | Storage |
|----------|--------|----------|---------|
| **Timestamp** | `deleted_at TIMESTAMPTZ` | Easy + when deleted | Grows forever |
| **Boolean flag** | `is_deleted BOOLEAN DEFAULT false` | Easy | Grows forever |
| **Archive table** | Move rows to `orders_archive` | Moderate | Separate table |

```sql
-- Recommended: timestamp + partial index
ALTER TABLE orders ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_orders_active_customer ON orders(customer_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_orders_number_unique ON orders(order_number) WHERE deleted_at IS NULL;

-- Archive table pattern
CREATE TABLE orders_archive (LIKE orders INCLUDING ALL);
WITH deleted AS (DELETE FROM orders WHERE id = $1 RETURNING *)
INSERT INTO orders_archive SELECT * FROM deleted;
```

## Temporal Tables (SCD Type 2)

### PostgreSQL Manual Implementation
```sql
CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ NOT NULL DEFAULT 'infinity',
    is_current BOOLEAN NOT NULL DEFAULT true,
    PRIMARY KEY (id, valid_from)
);

-- Insert new version
UPDATE products SET valid_to = now(), is_current = false WHERE id = 42 AND is_current = true;
INSERT INTO products (id, name, price) OVERRIDING SYSTEM VALUE VALUES (42, 'Widget Pro', 29.99);

-- Query current state
SELECT * FROM products WHERE is_current = true;
-- Query at point in time
SELECT * FROM products WHERE valid_from <= '2024-06-01' AND valid_to > '2024-06-01';
```

### SQL Server Native Temporal
```sql
CREATE TABLE products (
    id INT PRIMARY KEY, name NVARCHAR(100), price DECIMAL(12,2),
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START,
    valid_to DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.products_history));

SELECT * FROM products FOR SYSTEM_TIME AS OF '2024-06-01';
```

## Generic Audit Trigger (PostgreSQL)

```sql
CREATE TABLE audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name TEXT NOT NULL, record_id BIGINT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB, new_values JSONB, changed_fields TEXT[],
    user_id BIGINT, ip_address INET, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_table_record ON audit_log(table_name, record_id);

CREATE OR REPLACE FUNCTION audit_trigger() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_fields, user_id)
    VALUES (
        TG_TABLE_NAME, COALESCE(NEW.id, OLD.id), TG_OP,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END,
        CASE WHEN TG_OP = 'UPDATE' THEN
            ARRAY(SELECT key FROM jsonb_each(to_jsonb(NEW))
                  WHERE to_jsonb(NEW) -> key IS DISTINCT FROM to_jsonb(OLD) -> key) END,
        current_setting('app.current_user_id', true)::bigint
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_audit AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

## Schema Evolution: Expand-Contract

```
Phase 1: EXPAND — add new structure alongside old
Phase 2: MIGRATE — backfill data, update app to write both
Phase 3: CONTRACT — remove old structure

Enables zero-downtime: both old and new app versions work simultaneously.
```

### Safe Migration Operations

| Operation | Safe? | Technique |
|-----------|-------|-----------|
| Add column (nullable) | Yes | `ALTER TABLE ADD COLUMN` |
| Add column (NOT NULL + default) | Yes (PG 11+) | Metadata-only in modern engines |
| Rename column | No | Add new → copy → drop old (expand-contract) |
| Add index | Yes | `CREATE INDEX CONCURRENTLY` (PG) |
| Add NOT NULL | No | Add CHECK constraint first, then NOT NULL |
| Add foreign key | Careful | `NOT VALID` first, then `VALIDATE` separately (PG) |

### Zero-Downtime Column Rename
```sql
-- Step 1: Add new column
ALTER TABLE users ADD COLUMN full_name TEXT;
-- Step 2: Backfill in batches
UPDATE users SET full_name = name WHERE full_name IS NULL AND id BETWEEN 1 AND 10000;
-- Step 3: Deploy app reading BOTH (COALESCE(full_name, name))
-- Step 4: Deploy app writing BOTH
-- Step 5: Deploy app reading ONLY full_name
-- Step 6: Drop old column
ALTER TABLE users DROP COLUMN name;
```
