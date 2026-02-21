# SQL Database Reference

## PostgreSQL

### Key Features
- MVCC for concurrency without read locks
- JSONB for semi-structured data with GIN indexes
- Full-text search with tsvector/tsquery
- Extensions: PostGIS (geo), pg_trgm (fuzzy text), TimescaleDB (time-series), pgvector (embeddings)
- Logical replication, table partitioning, CTEs, window functions
- Row-level security policies

### Best Practices
- Use `BIGSERIAL` or `UUID` for primary keys (not `SERIAL` for new projects)
- Use `TIMESTAMPTZ` (not `TIMESTAMP`) for all timestamps
- Use `NUMERIC` for money (not `FLOAT`/`DOUBLE`)
- Partial indexes for queries filtering on common conditions
- Use `pg_stat_statements` for query analysis
- Connection pooling via PgBouncer

## MySQL / MariaDB

### Key Features
- InnoDB: ACID, row-level locking, crash recovery
- MySQL 8.0+: CTEs, window functions, JSON support, invisible indexes
- Group Replication for multi-primary HA
- Aurora: managed, auto-scaling, up to 15 read replicas

### Best Practices
- Always use InnoDB engine
- Use `UNSIGNED BIGINT` for IDs, `DATETIME(6)` for timestamps
- Avoid `SELECT *` — specify columns
- Use `utf8mb4` charset (not `utf8` which is 3-byte)
- Monitor with `SHOW PROCESSLIST` and Performance Schema

## Oracle

### Key Features
- RAC (Real Application Clusters) for HA
- Data Guard for disaster recovery
- Advanced partitioning (range, list, hash, composite)
- Flashback for point-in-time recovery
- Automatic Storage Management (ASM)

## MS SQL Server

### Key Features
- AlwaysOn Availability Groups for HA
- Columnstore indexes for analytics
- In-Memory OLTP (Hekaton)
- SSRS/SSIS/SSAS for BI workloads
- Temporal tables for audit history
