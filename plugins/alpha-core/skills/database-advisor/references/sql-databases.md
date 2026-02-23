# SQL Database Reference

## When to load
Load when working with PostgreSQL, MySQL/MariaDB, Oracle, MS SQL Server, or SQLite — including extensions, best practices, managed options, schema design, query optimization, migration tooling, and ORMs.

## PostgreSQL

### Key Features
- MVCC for concurrency without read locks; JSONB with GIN indexes; full-text search (tsvector/tsquery)
- Extensions: PostGIS (geo), pg_trgm (fuzzy text), TimescaleDB (time-series), pgvector (embeddings), Citus (distributed), pg_partman (partitions), pgAudit (audit), pg_cron (scheduled jobs), pgroonga (multilingual FTS), pg_repack (online repacking), pglogical (logical replication), HypoPG (hypothetical indexes)
- Row-level security, foreign data wrappers (postgres_fdw, mysql_fdw, oracle_fdw), generated columns
- Parallel query execution, JIT compilation, BRIN indexes, declarative partitioning

### Best Practices
- `BIGSERIAL` or `UUID v7` for PKs; `TIMESTAMPTZ` (not `TIMESTAMP`); `NUMERIC` for money
- Partial indexes for common WHERE conditions; `pg_stat_statements` for query analysis
- Connection pooling via PgBouncer or pgcat; `log_min_duration_statement` for slow queries
- Schedule `VACUUM ANALYZE`, monitor bloat; advisory locks for application-level coordination

### Managed Options
- **Aurora PostgreSQL**: Multi-AZ, 15 read replicas, Serverless v2
- **AlloyDB**: HTAP with Columnar Engine, 4x faster than standard PG
- **Neon**: Serverless, branching, scale-to-zero
- **Supabase**: PG + Auth + Realtime + Edge Functions
- **Azure Flexible Server**: Citus extension for distributed; **Crunchy Bridge**: multi-cloud

## MySQL / MariaDB

- InnoDB: ACID, row-level locking, crash recovery. Always `utf8mb4`, `UNSIGNED BIGINT` IDs.
- MySQL 8.0+: CTEs, window functions, JSON, invisible indexes, instant DDL, hash joins
- MySQL 9.0+: JavaScript stored programs, vector type. Group Replication, InnoDB Cluster.
- MariaDB: Aria engine, ColumnStore, system versioning, Galera Cluster (sync multi-master), MaxScale
- **pt-query-digest** for slow query analysis; Online DDL (ALGORITHM=INPLACE, LOCK=NONE)
- Managed: **Aurora MySQL** (Serverless v2, Global DB), **PlanetScale** (Vitess, branching, non-blocking DDL)

## Oracle
- RAC for HA, Data Guard for DR; advanced partitioning (range, list, hash, composite, interval)
- Flashback (database, table, query, transaction); Autonomous Database; JSON Relational Duality (23c)
- Blockchain/immutable tables; Spatial and Graph (PGQL); OML in-database ML

## MS SQL Server
- AlwaysOn AG for HA; Columnstore indexes (batch mode analytics); In-Memory OLTP (Hekaton)
- Temporal tables, ledger tables, graph tables (node + edge); PolyBase; Intelligent Query Processing
- Managed: Azure SQL Database, Azure SQL MI, RDS SQL Server

## SQLite
- Zero-config, single-file, 700B+ databases in use. WAL mode, FTS5, JSON1, R*Tree.
- `STRICT` tables (3.37+), `PRAGMA foreign_keys=ON`, batch in transactions
- **libSQL** (Turso): server mode, HTTP API, vector search, embedded replicas
- **Litestream**: streaming replication to S3/GCS/Azure; **cr-sqlite**: CRDTs for multi-writer
- **Cloudflare D1**: SQLite at edge; **sql.js / wa-sqlite**: WebAssembly for browser

## Schema Design, Query Optimization, Migrations, ORMs

**Schema design**: normalize to 3NF first then denormalize with evidence; always FK constraints; index WHERE/JOIN/ORDER BY columns; UUID v7 for distributed PKs; plan partitioning for tables >100M rows; design for soft deletes when GDPR compliance required

**Query optimization**: EXPLAIN/EXPLAIN ANALYZE; avoid N+1 (use JOINs or DataLoader); covering indexes for read-heavy queries; CTEs and window functions over multiple round-trips; read replicas for read-heavy workloads; monitor pg_stat_statements/slow_query_log

**Migrations**: Blue-green, expand-contract, shadow writes, backfill strategies
**Tools**: Flyway, Liquibase, Alembic, Prisma Migrate, Atlas, golang-migrate, TypeORM migrations

**ORMs**: Prisma (TS, schema-first, type-safe), Drizzle (TS, SQL-like, lightweight), SQLAlchemy 2.0 (Python, async, Alembic), GORM (Go, auto-migration), Diesel (Rust, compile-time verification), EF Core 8 (.NET, LINQ), Hibernate/JPA (Java, Criteria API), Sequelize/TypeORM/Knex/Kysely (Node.js), Exposed (Kotlin, JetBrains)
