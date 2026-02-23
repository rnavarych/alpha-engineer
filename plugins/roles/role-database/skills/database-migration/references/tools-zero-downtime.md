# Migration Tools and Zero-Downtime Patterns

## When to load
Load when choosing a migration tool (Flyway, Liquibase, Alembic, Prisma Migrate, Atlas, etc.), implementing expand-contract for zero-downtime schema changes, or handling large table migrations with batch processing or online DDL tools.

## Migration Tools Comparison

| Tool | Language | Approach | Rollback | Key Feature |
|------|----------|----------|----------|-------------|
| **Flyway** | Java (CLI for all) | SQL files, versioned | Manual down scripts | Baseline, repeatable migrations |
| **Liquibase** | Java (CLI for all) | XML/YAML/SQL changesets | Automatic rollback tags | Database diff, changelog |
| **Alembic** | Python | Python scripts | `downgrade()` | SQLAlchemy integration, autogenerate |
| **Prisma Migrate** | TypeScript | Schema-driven | `migrate reset` | Schema diff from Prisma schema |
| **Atlas** | Go | HCL/SQL, declarative | Versioned rollback | Schema-as-code, linting, CI |
| **golang-migrate** | Go | SQL files up/down | Down migrations | Simple, database-agnostic |
| **Knex** | JavaScript | JS migration files | `knex migrate:rollback` | Query builder integration |
| **Ecto** | Elixir | Elixir scripts | `mix ecto.rollback` | Changesets, schema introspection |
| **EF Core** | C# | C# code-first | Remove-Migration | Model snapshots, scaffolding |
| **Diesel** | Rust | SQL files | `diesel migration revert` | Compile-time schema checking |
| **ActiveRecord** | Ruby | Ruby DSL | `rails db:rollback` | Convention over configuration |

## Zero-Downtime: Expand-Contract Pattern

**Phase 1: Expand** — Add new structure alongside old
```sql
ALTER TABLE users ADD COLUMN full_name TEXT;
```

**Phase 2: Dual-Write** — Application writes to both old and new
```python
user.first_name = first
user.last_name = last
user.full_name = f"{first} {last}"
```

**Phase 3: Backfill** — Populate new column for existing rows
```sql
UPDATE users SET full_name = first_name || ' ' || last_name
WHERE full_name IS NULL AND id BETWEEN :start AND :end;
```

**Phase 4: Switch Reads** — Application reads from new column

**Phase 5: Contract** — Remove old columns
```sql
ALTER TABLE users DROP COLUMN first_name;
ALTER TABLE users DROP COLUMN last_name;
ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;
```

## Online DDL Techniques

| Operation | PostgreSQL | MySQL | Locking |
|-----------|------------|-------|---------|
| Add column (nullable) | Instant | Instant (8.0+) | None |
| Add column with default | Instant (11+) | Instant (8.0.12+) | None |
| Add index | `CREATE INDEX CONCURRENTLY` | `ALGORITHM=INPLACE` | Minimal |
| Drop column | Needs rewrite (pre-16) | `ALGORITHM=INSTANT` (8.0.29+) | Varies |
| Change column type | Rewrite required | Usually rewrite | Heavy |
| Add NOT NULL | Scan required | Scan required | Read lock |

### PostgreSQL Concurrent Index
```sql
CREATE INDEX CONCURRENTLY idx_orders_customer ON orders (customer_id);
-- If it fails, check for INVALID index:
SELECT indexrelid::regclass, indisvalid FROM pg_index WHERE NOT indisvalid;
DROP INDEX CONCURRENTLY idx_orders_customer;  -- drop invalid, retry
```

## Large Table Migration

### Batch Processing (PostgreSQL)
```sql
DO $$
DECLARE
    batch_size INT := 10000;
    max_id BIGINT;
    current_id BIGINT := 0;
BEGIN
    SELECT MAX(id) INTO max_id FROM large_table;
    WHILE current_id < max_id LOOP
        UPDATE large_table
        SET new_column = compute_value(old_column)
        WHERE id > current_id AND id <= current_id + batch_size
          AND new_column IS NULL;
        current_id := current_id + batch_size;
        COMMIT;
        PERFORM pg_sleep(0.1);  -- throttle to reduce load
    END LOOP;
END $$;
```

### MySQL Online Schema Tools
```bash
# pt-online-schema-change: shadow table + atomic swap
pt-online-schema-change --alter "ADD COLUMN full_name VARCHAR(255)" \
    --execute D=mydb,t=users --chunk-size=1000 --max-lag=1

# gh-ost: binlog-based, no triggers, controllable
gh-ost --host=primary --database=mydb --table=users \
    --alter="ADD COLUMN full_name VARCHAR(255)" \
    --execute --chunk-size=1000 --max-lag-millis=1500
```
