# Cross-Engine Migration and CI/CD Integration

## When to load
Load when migrating between database engines (MySQL to PostgreSQL, Oracle to PostgreSQL, MongoDB to PostgreSQL), using CDC-based migration (Debezium, AWS DMS), integrating migrations into CI/CD pipelines, or validating migration correctness.

## Cross-Engine Migration

### MySQL to PostgreSQL

**Tools:** pgloader (automated, handles type mapping), AWS DMS (managed, continuous replication), pg_chameleon (CDC-based replica)

**Type Mapping:**
| MySQL | PostgreSQL |
|-------|------------|
| `TINYINT(1)` | `BOOLEAN` |
| `INT UNSIGNED` | `BIGINT` |
| `DATETIME` | `TIMESTAMP` |
| `DOUBLE` | `DOUBLE PRECISION` |
| `ENUM('a','b')` | `TEXT CHECK (col IN ('a','b'))` |
| `BLOB` | `BYTEA` |
| `AUTO_INCREMENT` | `GENERATED ALWAYS AS IDENTITY` |

```bash
# pgloader one-liner
pgloader mysql://user:pass@mysql-host/mydb postgresql://user:pass@pg-host/mydb
```

### Oracle to PostgreSQL

**Tools:** Ora2Pg (schema + data, free), AWS SCT + DMS, EDB Migration Toolkit

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

### AWS DMS
- Full load + CDC for continuous replication
- Supports: Oracle, MySQL, PostgreSQL, SQL Server, MongoDB, S3, Redshift, DynamoDB
- Schema conversion with AWS SCT
- Monitoring via CloudWatch

## Migration Validation

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

```yaml
- name: Run migrations
  run: |
    flyway -url=$DB_URL -validateOnMigrate=true info
    flyway -url=$DB_URL migrate
    flyway -url=$DB_URL validate
```

### Safety Checklist
1. Review migration SQL in PR before applying
2. Run on staging with production-like data first, measure duration
3. Ensure rollback path exists (down migration or compensating change)
4. Apply during low-traffic window for heavy migrations
5. Monitor replication lag during migration
6. Keep migrations small and focused (one concern per migration)

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Manual DDL in production | All schema changes through migration files, reviewed in PR |
| Irreversible migration without backup | `pg_dump` affected tables before destructive changes |
| Giant migration | Split into small, independently reversible migrations |
| Migration that depends on new app code | Expand-contract: migration and app changes in separate deploys |
