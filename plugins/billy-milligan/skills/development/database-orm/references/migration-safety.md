# Migration Safety

## Data Backfill Patterns

```typescript
// Batch processing — avoid locking entire table
async function backfillShippingMethod() {
  const BATCH_SIZE = 1000;
  let processed = 0;

  while (true) {
    const result = await db.execute(sql`
      UPDATE orders
      SET shipping_method = 'standard'
      WHERE shipping_method IS NULL
      AND id IN (
        SELECT id FROM orders
        WHERE shipping_method IS NULL
        LIMIT ${BATCH_SIZE}
        FOR UPDATE SKIP LOCKED
      )
    `);

    processed += result.rowCount;
    if (result.rowCount === 0) break;

    // Brief pause to reduce DB load
    await new Promise((resolve) => setTimeout(resolve, 100));
    logger.info({ processed }, 'Backfill progress');
  }

  logger.info({ total: processed }, 'Backfill complete');
}
```

```
Key points:
  - LIMIT 1000 per batch — short transaction, minimal lock contention
  - FOR UPDATE SKIP LOCKED — skip rows locked by concurrent writes
  - 100ms pause between batches — let the DB breathe under load
  - Log progress — long backfills need observability
  - Run as background job, not inside the migration transaction
```

## Rollback Strategies

```
Every migration needs a rollback plan. Before running:
  1. Write the down migration before the up migration
  2. Test the rollback on staging — not just the forward path
  3. Verify rollback doesn't destroy data added between deploy and rollback

Safe rollback scenarios:
  - Adding a column: rollback = DROP COLUMN (safe if app not yet reading it)
  - Adding an index: rollback = DROP INDEX CONCURRENTLY
  - Adding a table: rollback = DROP TABLE (safe before app uses it)

Dangerous rollback scenarios (require a plan):
  - Dropping a column: data is gone — need point-in-time restore
  - Changing column type: data may be truncated
  - Backfill already ran: removing the column loses backfilled values
```

```sql
-- Example: reversible migration pair

-- UP: add_email_verified_column.sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT false;
CREATE INDEX CONCURRENTLY idx_users_email_verified ON users (email_verified);

-- DOWN: revert_add_email_verified_column.sql
DROP INDEX CONCURRENTLY idx_users_email_verified;
ALTER TABLE users DROP COLUMN email_verified;
```

## Migration Testing

```typescript
// Test migration in transaction — rollback after verification
async function testMigration(migrationFn: () => Promise<void>) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await migrationFn();

    // Verify: table structure is correct
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'orders'
      ORDER BY ordinal_position
    `);
    logger.info({ schema: result.rows }, 'Schema after migration');

    // Verify: existing queries still work
    await client.query('SELECT id, status, total FROM orders LIMIT 1');

    await client.query('ROLLBACK'); // Always rollback in test
  } finally {
    client.release();
  }
}
```

## Pre-Migration Checklist

```
Before running any migration in production:

1. Backup
   - Point-in-time recovery enabled?
   - Manual snapshot for destructive changes?

2. Estimate lock duration
   - Small table (<1M rows): ALTER TABLE is usually safe
   - Large table (>10M rows): must use expand-contract pattern
   - Run EXPLAIN on affected queries to verify index usage after

3. Verify dual-write is in place
   - Old app instances still writing old columns?
   - New column populated for all existing rows?

4. Monitor during migration
   - Watch pg_stat_activity for blocked queries
   - Watch pg_locks for lock waits
   - Have rollback SQL ready to paste

5. Feature flags for backfills
   - Long backfills should run behind a feature flag
   - Easy to pause or stop if DB load spikes
```

```sql
-- Monitor lock waits during migration
SELECT
  pid,
  now() - pg_stat_activity.query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start < now() - INTERVAL '5 seconds'
ORDER BY duration DESC;

-- Check for blocking locks
SELECT
  blocked.pid,
  blocked.query AS blocked_query,
  blocking.pid AS blocking_pid,
  blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
  ON blocking.pid = ANY(pg_blocking_pids(blocked.pid));
```

## Anti-Patterns
- Running backfill inside the migration transaction — holds lock for entire duration
- No down migration — can't roll back when things go wrong
- Testing migration only on empty staging DB — misses production data edge cases
- Dropping columns in the same deploy as removing them from app code — zero-downtime requires two deploys
- No progress logging for long backfills — impossible to estimate completion time

## Quick Reference
```
Backfill: LIMIT 1000 + FOR UPDATE SKIP LOCKED + 100ms pause
Rollback: write down migration first — test it on staging
Test: run in transaction, verify schema, ROLLBACK
Pre-migration: backup -> estimate lock -> verify dual-write -> monitor
Monitor: pg_stat_activity duration + pg_blocking_pids during migration
Feature flags: long backfills behind flag — easy pause on load spike
```

## When to load
Load when writing rollback strategies, implementing batch data backfills, testing migrations safely, or monitoring a live schema change in production.
