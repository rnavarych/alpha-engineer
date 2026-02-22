# SQL Database Reference

## PostgreSQL

### Key Features
- MVCC for concurrency without read locks
- JSONB for semi-structured data with GIN indexes
- Full-text search with tsvector/tsquery
- Extensions: PostGIS (geo), pg_trgm (fuzzy text), TimescaleDB (time-series), pgvector (embeddings), Citus (distributed), pg_partman (partition mgmt), pgAudit (audit), pg_stat_monitor, pg_cron (scheduled jobs), pgroonga (multilingual FTS), pg_repack (online repacking), pglogical (logical replication), HypoPG (hypothetical indexes), pg_hint_plan, pg_bigm
- Logical replication, table partitioning, CTEs, window functions
- Row-level security policies
- Foreign data wrappers (postgres_fdw, mysql_fdw, file_fdw, oracle_fdw)
- Generated columns, identity columns
- Parallel query execution, JIT compilation
- BRIN indexes for large sequential datasets
- Table inheritance and declarative partitioning

### Best Practices
- Use `BIGSERIAL` or `UUID v7` for primary keys
- Use `TIMESTAMPTZ` (not `TIMESTAMP`) for all timestamps
- Use `NUMERIC` for money (not `FLOAT`/`DOUBLE`)
- Partial indexes for common WHERE conditions
- Use `pg_stat_statements` for query analysis
- Connection pooling via PgBouncer or pgcat
- Advisory locks for application-level coordination
- Enable `log_min_duration_statement` for slow queries
- Schedule `VACUUM ANALYZE`, monitor bloat

### Managed Options
- **Aurora PostgreSQL**: Multi-AZ, 15 read replicas, Serverless v2
- **AlloyDB**: HTAP with Columnar Engine, 4x faster than standard PG
- **Neon**: Serverless, branching, scale-to-zero
- **Supabase**: PG + Auth + Realtime + Edge Functions
- **Azure Flexible Server**: Citus extension for distributed
- **Crunchy Bridge**: Multi-cloud, PG experts

## MySQL / MariaDB

### Key Features
- InnoDB: ACID, row-level locking, crash recovery
- MySQL 8.0+: CTEs, window functions, JSON, invisible indexes, instant DDL, hash joins
- MySQL 9.0+: JavaScript stored programs, vector type
- Group Replication, InnoDB Cluster
- Clone Plugin for fast replica provisioning

### MariaDB Extras
- Aria engine, ColumnStore for analytics, system versioning
- Spider for sharding, Galera Cluster for synchronous multi-master
- MaxScale proxy for load balancing

### Best Practices
- Always InnoDB, `utf8mb4`, `UNSIGNED BIGINT` IDs
- `pt-query-digest` for slow query analysis
- Online DDL (ALGORITHM=INPLACE, LOCK=NONE)

### Managed Options
- **Aurora MySQL**: Serverless v2, Global Database, Parallel Query
- **PlanetScale**: Vitess-powered, branching, non-blocking DDL
- **Google Cloud SQL**, **Azure Flexible Server**

## Oracle

### Key Features
- RAC for HA, Data Guard for DR
- Advanced partitioning (range, list, hash, composite, interval, reference)
- Flashback (database, table, query, transaction)
- Autonomous Database (self-driving, self-securing)
- JSON Relational Duality Views (23c)
- Blockchain tables, immutable tables
- Spatial and Graph (PGQL), OML in-database ML

## MS SQL Server

### Key Features
- AlwaysOn AG for HA
- Columnstore indexes (batch mode analytics)
- In-Memory OLTP (Hekaton)
- SSRS/SSIS/SSAS for BI
- Temporal tables, ledger tables
- Graph tables (node + edge)
- PolyBase, Intelligent Query Processing

### Managed: Azure SQL Database, Azure SQL MI, RDS SQL Server

## SQLite

### Key Features
- Zero-config, single-file, 700B+ databases in use
- WAL mode, FTS5, JSON1, R*Tree, session extension

### Modern Evolution
- **libSQL**: Turso fork. Server mode. HTTP API. Vector search. Embedded replicas.
- **LiteFS**: Distributed SQLite with Fly.io
- **Litestream**: Streaming replication to S3/GCS/Azure
- **cr-sqlite**: CRDTs for multi-writer conflict-free replication
- **sql.js / wa-sqlite**: WebAssembly for browser
- **Cloudflare D1**: SQLite at edge

### Best Practices
- WAL mode for web apps, `PRAGMA foreign_keys=ON`
- `STRICT` tables (3.37+), batch in transactions
- Ideal for: mobile, embedded, edge, CLI, testing, prototyping
