# Migration Strategies

## Zero-Downtime Migrations

```
The problem: ALTER TABLE locks the table. If a migration takes 30 seconds,
your API returns 500s for 30 seconds.

The solution: Expand-Contract pattern
  1. EXPAND: Add new column/table (backwards compatible)
  2. MIGRATE: Backfill data, update application code
  3. CONTRACT: Remove old column/table (cleanup)

Each step is a separate deploy — never break the running application.
```

## Expand-Contract Example

### Step 1: Expand (Add New Column)

```sql
-- Migration: add_shipping_method.sql
-- Safe: adding nullable column with default does NOT lock table (Postgres 11+)
ALTER TABLE orders ADD COLUMN shipping_method VARCHAR(20) DEFAULT 'standard';

-- Add index concurrently — does NOT block reads or writes
CREATE INDEX CONCURRENTLY idx_orders_shipping ON orders (shipping_method);
```

```
Deploy: application code still reads/writes old columns.
New column exists but is unused by the app. No downtime.
```

### Step 2: Migrate (Backfill + Dual Write)

```typescript
// Application code: write to BOTH old and new columns
async function createOrder(input: CreateOrderInput) {
  return db.insert(orders).values({
    ...input,
    shipping_method: input.shippingMethod ?? 'standard', // New column
    legacy_shipping: input.shippingMethod ?? 'standard', // Old column still populated
  });
}
```

```sql
-- Backfill existing data (run in batches to avoid lock contention)
UPDATE orders
SET shipping_method = CASE
  WHEN total >= 100 THEN 'express'
  ELSE 'standard'
END
WHERE shipping_method IS NULL
LIMIT 1000; -- Process in batches of 1000
```

### Step 3: Contract (Remove Old Column)

```sql
-- After verifying new column is fully populated and app only reads new column
ALTER TABLE orders DROP COLUMN legacy_shipping;
```

```
Deploy order:
  1. Deploy migration (add column) -> deploy app (dual write) -> backfill
  2. Deploy app (read from new column) -> verify in production
  3. Deploy migration (drop old column)

Total: 3 deploys, zero downtime.
```

## Renaming a Column

```sql
-- NEVER: ALTER TABLE orders RENAME COLUMN status TO order_status;
-- This breaks all running application instances immediately.

-- INSTEAD: Expand-Contract
-- Step 1: Add new column
ALTER TABLE orders ADD COLUMN order_status VARCHAR(20);

-- Step 2: Backfill
UPDATE orders SET order_status = status WHERE order_status IS NULL;

-- Step 3: App writes to both, reads from new
-- Step 4: Drop old column
ALTER TABLE orders DROP COLUMN status;
```

## Adding NOT NULL Constraint

```sql
-- NEVER: ALTER TABLE orders ALTER COLUMN email SET NOT NULL;
-- Fails if any NULL values exist. Locks table for validation.

-- INSTEAD:
-- Step 1: Add CHECK constraint as NOT VALID (no lock, no validation)
ALTER TABLE orders ADD CONSTRAINT orders_email_not_null
  CHECK (email IS NOT NULL) NOT VALID;

-- Step 2: Validate constraint (scans table but allows concurrent writes)
ALTER TABLE orders VALIDATE CONSTRAINT orders_email_not_null;

-- Step 3: Now safe to add NOT NULL (Postgres knows constraint is valid)
ALTER TABLE orders ALTER COLUMN email SET NOT NULL;
ALTER TABLE orders DROP CONSTRAINT orders_email_not_null;
```

## Anti-Patterns
- `ALTER TABLE RENAME COLUMN` on live table — breaks running code instantly
- Dropping column without verifying app doesn't read it — 500 errors
- Large `UPDATE` without batching — locks table, blocks all writes
- Not using `CONCURRENTLY` for index creation — blocks writes
- Adding `NOT NULL` to column with existing NULLs — migration fails

## Quick Reference
```
Expand-Contract: add column -> dual write + backfill -> drop old
Column rename: add new -> copy data -> switch reads -> drop old
NOT NULL: CHECK NOT VALID -> VALIDATE -> SET NOT NULL
Index: CREATE INDEX CONCURRENTLY — never without CONCURRENTLY
Deploy order: migration first, then app code (expand); app first, then migration (contract)
```

## When to load
Load when planning schema migrations, renaming columns on live tables, adding NOT NULL constraints, or structuring a zero-downtime multi-step deploy.
