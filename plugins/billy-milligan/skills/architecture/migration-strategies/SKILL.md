---
name: migration-strategies
description: |
  Migration strategies: expand-contract pattern for zero-downtime schema changes,
  batch data migration (1000 rows, 50ms delay), strangler fig for system migrations,
  dual-write patterns, blue-green database migrations, big bang rewrite anti-pattern.
  Use when planning schema changes, system migrations, database upgrades.
allowed-tools: Read, Grep, Glob
---

# Migration Strategies

## When to Use This Skill
- Planning schema changes that cannot afford downtime
- Migrating from one database to another
- Large-scale data transformations on live systems
- System-level migrations (monolith to services)
- Upgrading databases or changing data models

## Core Principles

1. **Expand-contract is the default for zero-downtime** — never add NOT NULL columns in one step
2. **Batch migrations in small chunks** — 1000 rows per batch with 50ms pause prevents lock contention
3. **Dual-write for system migrations** — write to both old and new until new is proven
4. **Never a big bang rewrite** — strangler fig takes longer but succeeds more often
5. **Always have a rollback plan** — test it before you need it

---

## Patterns ✅

### Expand-Contract (Zero-Downtime Schema Migration)

Adding a NOT NULL column to a large table with a single `ALTER TABLE` locks the table.
The expand-contract pattern avoids this:

```
Phase 1 — EXPAND (backward compatible):
  Deploy → Add column as nullable, no default

Phase 2 — BACKFILL (background process):
  Batch-fill existing rows with data

Phase 3 — WRITE (dual-write in code):
  Deploy → Application writes to both old and new column

Phase 4 — VERIFY:
  Confirm 100% of rows have new column populated

Phase 5 — CONTRACT (make required):
  Deploy → Application reads from new column only
  → Apply NOT NULL constraint (fast — no null rows exist)

Phase 6 — CLEANUP:
  Deploy → Remove old column (optional — saves storage)
```

```sql
-- Phase 1: Add nullable column (instant, no lock)
ALTER TABLE orders ADD COLUMN payment_method TEXT;

-- Phase 2: Backfill existing rows (batched — see below)
-- Update orders SET payment_method = 'card' WHERE payment_method IS NULL LIMIT 1000

-- Phase 5: Apply NOT NULL constraint
-- With PostgreSQL 12+, this validates without full table lock if default is set
ALTER TABLE orders
  ALTER COLUMN payment_method SET DEFAULT 'card',
  ALTER COLUMN payment_method SET NOT NULL;
-- Verify existing rows first, or: ALTER TABLE ... ADD CONSTRAINT ... NOT VALID; then VALIDATE CONSTRAINT
```

### Batch Data Migration (Live Table)

```typescript
// Migrate large table without locking
// Never: UPDATE large_table SET ... (no WHERE) — locks entire table for minutes

async function backfillPaymentMethod(db: Database): Promise<void> {
  const BATCH_SIZE = 1000;
  const PAUSE_MS = 50;  // Give DB time to breathe between batches
  let processedCount = 0;

  while (true) {
    // Process one batch
    const result = await db.execute(sql`
      WITH batch AS (
        SELECT id FROM orders
        WHERE payment_method IS NULL
        ORDER BY id
        LIMIT ${BATCH_SIZE}
      )
      UPDATE orders
      SET payment_method = 'card'
      WHERE id IN (SELECT id FROM batch)
      RETURNING id
    `);

    processedCount += result.rowCount;
    logger.info({ processedCount }, 'Backfill progress');

    if (result.rowCount === 0) {
      logger.info({ processedCount }, 'Backfill complete');
      break;
    }

    // Pause to avoid overwhelming the DB
    await sleep(PAUSE_MS);
  }
}
```

**Duration estimate**: 10M rows ÷ 1000 rows/batch × 50ms/batch = ~500 seconds (~8 minutes).
**Lock behavior**: Each batch holds a row lock for <5ms. Table never fully locked.

### Dual-Write Migration Pattern

Use when migrating from one system/database to another:

```typescript
// Phase 1: Write to OLD system only (current state)
// Phase 2: Write to BOTH — new data goes to both systems
// Phase 3: Read from OLD, verify against NEW
// Phase 4: Read from NEW (it's now primary)
// Phase 5: Stop writing to OLD

class OrderRepository {
  constructor(
    private readonly oldDb: OldDatabase,
    private readonly newDb: NewDatabase,
    private readonly migrationPhase: 1 | 2 | 3 | 4 | 5
  ) {}

  async create(order: Order): Promise<Order> {
    if (this.migrationPhase === 1) {
      return this.oldDb.create(order);
    }

    if (this.migrationPhase === 2 || this.migrationPhase === 3) {
      // Write to both — old is primary for reads
      const [oldResult] = await Promise.allSettled([
        this.oldDb.create(order),
        this.newDb.create(order).catch(err => {
          logger.error({ err, orderId: order.id }, 'New DB write failed — non-blocking');
        }),
      ]);
      return (oldResult as PromiseFulfilledResult<Order>).value;
    }

    if (this.migrationPhase === 4 || this.migrationPhase === 5) {
      return this.newDb.create(order);
    }

    throw new Error('Invalid migration phase');
  }

  async findById(id: string): Promise<Order | null> {
    if (this.migrationPhase <= 3) {
      return this.oldDb.findById(id);
    }
    return this.newDb.findById(id);
  }
}
```

### Database Version Migrations (Flyway/Liquibase Pattern)

```sql
-- V1__create_users.sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- V2__add_users_name.sql
ALTER TABLE users ADD COLUMN name TEXT;

-- V3__users_name_not_null.sql
-- Run AFTER backfill confirms no nulls
ALTER TABLE users ALTER COLUMN name SET NOT NULL;

-- V4__users_add_index.sql
-- Use CONCURRENTLY to avoid table lock (PostgreSQL)
CREATE INDEX CONCURRENTLY idx_users_email_lower ON users(LOWER(email));
```

```typescript
// Automated migrations with Drizzle
import { migrate } from 'drizzle-orm/postgres-js/migrator';

// Run at application startup (or as a separate job)
await migrate(db, { migrationsFolder: './drizzle' });
```

---

## Anti-Patterns ❌

### Big Bang Rewrite
**What it is**: "Stop all new feature work, rewrite the whole system in 6 months."
**Historical failure rate**: >70% (Standish CHAOS Report). The new system takes 2× estimated time. Business keeps shipping on old system. Feature parity is never complete. You end up maintaining two systems.
**Real examples**: Netscape Navigator 6, Borland, the DailyWTF classic. Always the same story.
**Fix**: Strangler Fig — extract one module at a time. Run old and new in parallel. Old system is decommissioned gradually over 12–24 months.

### ALTER TABLE with NOT NULL on Large Tables
**What it is**: `ALTER TABLE orders ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'`
**What breaks**: On PostgreSQL < 11, this rewrites the entire table. On PG 11+, adding a constant DEFAULT is instant, but combined with NOT NULL on existing tables with millions of rows still causes problems in many contexts.
**Fix**: Expand-contract. Add nullable. Backfill. Then constrain.

### Running Migrations Inside Application Startup
**What it is**: `migrate(db, ...)` called in `server.start()`.
**What breaks**: Multiple instances start simultaneously → all try to run migration at the same time → migration runs multiple times or deadlocks.
**Fix**: Run migrations as a separate pre-deployment step (Kubernetes init container, CI step before rolling deploy). One migration run, then app starts.

### Unbounded UPDATE on Live Table
**What it is**: `UPDATE orders SET status = 'processed' WHERE status = 'pending'` — no LIMIT.
**What breaks**: Acquires row locks on potentially millions of rows. Other transactions wait. Under high load, causes cascading timeouts. Can take minutes on large tables.
**Fix**: Batch migration pattern above — 1000 rows at a time, 50ms pause.

---

## Quick Reference

```
Expand-contract phases: add nullable → backfill → dual-write → verify → constrain → cleanup
Batch size: 1000 rows per batch
Pause between batches: 50ms (prevents DB overload)
10M row migration time: ~500s (8 minutes) at 1000 rows/50ms
CREATE INDEX: always CONCURRENTLY on live PostgreSQL tables
Dual-write phases: old-only → both (old primary) → both (verify) → new primary → old off
Big bang rewrite: don't. Use strangler fig.
Migration concurrency: run as init container, not in app startup
```
