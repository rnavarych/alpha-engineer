---
name: database-migration
description: |
  Schema and data migration patterns across all engines. Migration tools (Flyway, Liquibase, Alembic, Prisma Migrate, Atlas, golang-migrate, Knex, Ecto, EF Core, Diesel, ActiveRecord). Zero-downtime migration (expand-contract, blue-green, shadow writes). Cross-engine migration (MySQL→PG, Oracle→PG, MongoDB→PG). CDC-based migration (Debezium, DMS). Use when planning schema changes, migrating between databases, or implementing zero-downtime deployments.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Migration

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
| **dbmate** | Go | SQL files | Down migrations | Lightweight, database-agnostic |
| **Sqitch** | Perl | SQL scripts | Revert scripts | Dependency-based, not versioned |

## Zero-Downtime Migration Patterns

### Expand-Contract (Recommended Default)

**Phase 1: Expand** — Add new structure alongside old
```sql
-- Add new column (nullable, no default required)
ALTER TABLE users ADD COLUMN full_name TEXT;
```

**Phase 2: Dual-Write** — Application writes to both old and new
```python
# Application code writes to both during transition
user.first_name = first
user.last_name = last
user.full_name = f"{first} {last}"  # new column
```

**Phase 3: Backfill** — Populate new column for existing rows
```sql
-- Batch backfill (avoid locking entire table)
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

### Online DDL Techniques

| Operation | PostgreSQL | MySQL | Locking |
|-----------|------------|-------|---------|
| **Add column (nullable)** | Instant | Instant (8.0+) | None |
| **Add column with default** | Instant (11+) | Instant (8.0.12+) | None |
| **Add index** | `CREATE INDEX CONCURRENTLY` | `ALGORITHM=INPLACE` | Minimal |
| **Drop column** | Needs rewrite (pre-16) | `ALGORITHM=INSTANT` (8.0.29+) | Varies |
| **Change column type** | Rewrite required | Usually rewrite | Heavy |
| **Rename column** | Instant | Instant | Metadata only |
| **Add NOT NULL** | Scan required | Scan required | Read lock |

### PostgreSQL Concurrent Index Creation
```sql
-- Non-blocking index creation (takes longer but no locks)
CREATE INDEX CONCURRENTLY idx_orders_customer ON orders (customer_id);

-- If it fails partway, it leaves an INVALID index
-- Check and retry:
SELECT indexrelid::regclass, indisvalid FROM pg_index WHERE NOT indisvalid;
DROP INDEX CONCURRENTLY idx_orders_customer;  -- drop invalid
CREATE INDEX CONCURRENTLY idx_orders_customer ON orders (customer_id);  -- retry
```

### Large Table Migration (Billions of Rows)

**Batch Processing Pattern:**
```sql
-- Process in batches using PK range
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

**pt-online-schema-change (MySQL):**
```bash
# Creates shadow table, copies data, swaps atomically
pt-online-schema-change --alter "ADD COLUMN full_name VARCHAR(255)" \
    --execute D=mydb,t=users \
    --chunk-size=1000 --max-lag=1
```

**gh-ost (MySQL, GitHub):**
```bash
# Binary log-based, no triggers, controllable
gh-ost --host=primary --database=mydb --table=users \
    --alter="ADD COLUMN full_name VARCHAR(255)" \
    --execute --chunk-size=1000 --max-lag-millis=1500
```

## Cross-Engine Migration

### MySQL to PostgreSQL

**Tools:**
- **pgloader**: Automated, handles type mapping, indexes, constraints
- **AWS DMS**: Managed, continuous replication during migration
- **pg_chameleon**: MySQL to PostgreSQL replica with CDC

**Type Mapping:**
| MySQL | PostgreSQL |
|-------|------------|
| `TINYINT(1)` | `BOOLEAN` |
| `INT UNSIGNED` | `BIGINT` |
| `DATETIME` | `TIMESTAMP` |
| `DOUBLE` | `DOUBLE PRECISION` |
| `ENUM('a','b')` | `TEXT CHECK (col IN ('a','b'))` or custom enum |
| `TEXT` | `TEXT` |
| `BLOB` | `BYTEA` |
| `AUTO_INCREMENT` | `GENERATED ALWAYS AS IDENTITY` |

```bash
# pgloader one-liner
pgloader mysql://user:pass@mysql-host/mydb postgresql://user:pass@pg-host/mydb
```

### Oracle to PostgreSQL

**Tools:**
- **Ora2Pg**: Schema + data migration, free, well-maintained
- **AWS SCT**: Schema Conversion Tool + DMS for data
- **EDB Migration Toolkit**: Oracle compatibility layer

**Key Differences:**
- Oracle `SEQUENCE.NEXTVAL` → PostgreSQL `nextval('sequence_name')`
- Oracle `NVL()` → PostgreSQL `COALESCE()`
- Oracle `SYSDATE` → PostgreSQL `now()`
- Oracle `ROWNUM` → PostgreSQL `LIMIT` / `ROW_NUMBER()`
- PL/SQL → PL/pgSQL (mostly compatible with minor syntax changes)

### MongoDB to PostgreSQL

**Patterns:**
- Flatten embedded documents into relational tables
- Arrays → junction tables or PostgreSQL arrays
- Mixed types → JSONB column (preserve flexibility)
- ObjectId → UUID v7 (new) or TEXT (preserve original)

## CDC-Based Migration (Zero-Downtime)

### Debezium
```json
// Debezium connector config for PostgreSQL source
{
    "name": "pg-source",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "database.hostname": "source-db",
        "database.port": "5432",
        "database.user": "debezium",
        "database.dbname": "mydb",
        "plugin.name": "pgoutput",
        "slot.name": "debezium_slot",
        "topic.prefix": "migration",
        "table.include.list": "public.orders,public.customers"
    }
}
```

### AWS DMS (Database Migration Service)
- Full load + CDC for continuous replication
- Supports: Oracle, MySQL, PostgreSQL, SQL Server, MongoDB, S3, Redshift, DynamoDB
- Schema conversion with AWS SCT
- Monitoring via CloudWatch

### Migration Validation
```sql
-- Row count comparison
SELECT 'source' AS db, COUNT(*) FROM source_db.orders
UNION ALL
SELECT 'target' AS db, COUNT(*) FROM target_db.orders;

-- Checksum comparison (sample-based)
SELECT MD5(string_agg(row_hash, '' ORDER BY id))
FROM (
    SELECT id, MD5(ROW(id, customer_id, total, status)::text) AS row_hash
    FROM orders WHERE id BETWEEN 1 AND 10000
) t;
```

## Migration in CI/CD

### Pipeline Integration
```yaml
# GitHub Actions example
- name: Run migrations
  run: |
    # Dry run first
    flyway -url=$DB_URL -validateOnMigrate=true info
    # Apply
    flyway -url=$DB_URL migrate
    # Verify
    flyway -url=$DB_URL validate
```

### Migration Safety Checklist
1. Review migration SQL before applying (PR review process)
2. Run migration on staging with production-like data first
3. Measure migration duration on staging
4. Ensure rollback path exists (down migration or compensating change)
5. Apply during low-traffic window for heavy migrations
6. Monitor replication lag during migration
7. Keep migrations small and focused (one concern per migration)

## Anti-Patterns

### Manual DDL in Production
- **Problem**: Running `ALTER TABLE` directly in production without version control
- **Fix**: All schema changes go through migration files, reviewed in PR, applied by CI/CD

### Irreversible Migrations Without Backup
- **Problem**: Dropping columns or tables without backup or rollback plan
- **Fix**: Always `pg_dump` affected tables before destructive migrations

### Giant Migrations
- **Problem**: Single migration that adds 10 columns, creates 5 indexes, and restructures data
- **Fix**: Split into small, focused, independently reversible migrations

### Migrations That Depend on Application Code
- **Problem**: Migration uses new column that old application version doesn't know about
- **Fix**: Expand-contract pattern — migration and application changes in separate deploys
