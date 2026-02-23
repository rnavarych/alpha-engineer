# Database Migration Patterns

## When to load
Load when discussing schema migrations, expand-contract pattern, zero-downtime column changes, or schema versioning tools like Flyway, golang-migrate, or Prisma Migrate.

## Patterns

### Expand-contract (6 phases, zero downtime)
```
Phase 1: EXPAND - add new column (nullable, with default)
Phase 2: MIGRATE CODE - write to both old and new columns
Phase 3: BACKFILL - populate new column for existing rows
Phase 4: MIGRATE CODE - read from new column only
Phase 5: CLEANUP CODE - stop writing to old column
Phase 6: CONTRACT - drop old column

Example: rename "name" to "full_name"
```

```sql
-- Phase 1: EXPAND (deploy independently, no code change needed)
ALTER TABLE users ADD COLUMN full_name TEXT;
-- Non-blocking in PostgreSQL with default:
-- ALTER TABLE users ADD COLUMN full_name TEXT DEFAULT '';

-- Phase 3: BACKFILL (run as background job)
UPDATE users SET full_name = name
WHERE full_name IS NULL
  AND id > $last_processed_id  -- cursor-based batching
ORDER BY id
LIMIT 1000;
-- Repeat until all rows processed

-- Phase 6: CONTRACT (after all code uses full_name)
ALTER TABLE users DROP COLUMN name;
```

```typescript
// Phase 2: Write to both columns
async function updateUser(id: string, data: { fullName: string }) {
  await db.query(
    'UPDATE users SET name = $1, full_name = $1 WHERE id = $2',
    [data.fullName, id]
  );
}

// Phase 4: Read from new column
async function getUser(id: string) {
  const user = await db.query('SELECT full_name FROM users WHERE id = $1', [id]);
  return { fullName: user.full_name };
}

// Phase 5: Stop writing old column
async function updateUser(id: string, data: { fullName: string }) {
  await db.query(
    'UPDATE users SET full_name = $1 WHERE id = $2',
    [data.fullName, id]
  );
}
```

### Schema versioning tools

#### Flyway (Java/JVM ecosystem)
```sql
-- V1__create_users.sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- V2__add_full_name.sql
ALTER TABLE users ADD COLUMN full_name TEXT DEFAULT '';

-- V3__add_users_index.sql
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
-- CONCURRENTLY = non-blocking in PostgreSQL
```

#### golang-migrate
```bash
# Create migration files
migrate create -ext sql -dir migrations -seq add_orders_table

# migrations/000001_add_orders_table.up.sql
# migrations/000001_add_orders_table.down.sql (rollback)

# Apply migrations
migrate -path migrations -database "postgres://..." up

# Rollback last migration
migrate -path migrations -database "postgres://..." down 1
```

#### Prisma Migrate
```bash
# Generate migration from schema changes
npx prisma migrate dev --name add_full_name

# Apply in production
npx prisma migrate deploy

# Reset (dev only, destroys data)
npx prisma migrate reset
```

### Safe migration rules
```
1. Always add columns as nullable or with default
   BAD:  ALTER TABLE users ADD COLUMN role TEXT NOT NULL;  -- locks table
   GOOD: ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user';

2. Create indexes CONCURRENTLY (PostgreSQL)
   BAD:  CREATE INDEX idx_name ON users(name);  -- locks writes
   GOOD: CREATE INDEX CONCURRENTLY idx_name ON users(name);

3. Never rename columns directly
   Instead: expand-contract (add new, migrate, drop old)

4. Never change column types directly
   Instead: add new column with new type, migrate data, drop old

5. Every migration must have a rollback script
   Test rollback in staging before production
```

## Anti-patterns
- Running migrations during deploy startup -> blocks all instances, extends downtime
- `ALTER TABLE ... NOT NULL` without default on large table -> full table lock
- No rollback script -> stuck if migration causes issues
- Mixing schema and data migrations in one step -> hard to rollback

## Decision criteria
- **Expand-contract**: any column rename/type change in production, zero downtime required
- **Flyway/golang-migrate**: explicit SQL control, complex schemas
- **Prisma Migrate**: TypeScript/Node.js projects, schema-first workflow

## Quick reference
```
Expand-contract: 6 phases, never drop columns directly
Add columns: always nullable or with DEFAULT
Indexes: CREATE INDEX CONCURRENTLY (non-blocking)
Every migration needs: up script + down script
Test rollback in staging before production deploy
Run migrations separately from application deploy
```
