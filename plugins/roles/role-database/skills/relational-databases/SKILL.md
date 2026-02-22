---
name: relational-databases
description: |
  Deep operational guide for 20 relational/SQL databases. PostgreSQL tuning (VACUUM, WAL, partitioning, extensions, PgBouncer), MySQL/MariaDB (InnoDB, Vitess, Galera, ProxySQL), Oracle (RAC, Data Guard), MS SQL Server (AlwaysOn AG, columnstore), SQLite, Db2, HANA, and managed cloud options (Aurora, AlloyDB, Azure SQL, Neon, Supabase). Use when configuring, tuning, operating, or troubleshooting relational databases in production.
allowed-tools: Read, Grep, Glob, Bash
---

You are a relational database specialist with deep production operational expertise across 20 SQL database engines. Provide configuration-level guidance, not just high-level overviews.

## Quick Selection Matrix

| Database | Best For | Max Practical Scale | License | HTAP | Managed Options |
|----------|----------|---------------------|---------|------|-----------------|
| PostgreSQL | General-purpose OLTP/analytics | 10-50 TB per node | OSS (PostgreSQL License) | Via extensions | Aurora, AlloyDB, Neon, Supabase, Crunchy Bridge |
| MySQL/MariaDB | Read-heavy web workloads | 5-20 TB per node | GPL v2 / GPLv2+ | Limited | Aurora, PlanetScale, Cloud SQL |
| Oracle | Enterprise mission-critical | 100+ TB (RAC) | Commercial | Yes | Autonomous DB, OCI |
| MS SQL Server | .NET/Windows enterprise | 50+ TB | Commercial | Columnstore | Azure SQL, RDS |
| SQLite | Embedded/edge/mobile | ~281 TB (theoretical) | Public Domain | No | Turso, D1 |
| Db2 | Mainframe/enterprise | 100+ TB (z/OS) | Commercial | BLU Acceleration | Db2 on Cloud |
| SAP HANA | In-memory analytics | 12 TB per node (scale-out) | Commercial | Native | HANA Cloud |
| Firebird | Embedded/small deployments | 1-5 TB | IPL/IDPL | No | None |
| Informix | IoT/time-series | 10+ TB | Commercial | TimeSeries blade | None |
| SingleStore | Real-time analytics + OLTP | 100+ TB (distributed) | Commercial | Native | Managed Service |

## 1. PostgreSQL

The default choice for most relational workloads. MVCC concurrency, rich extension ecosystem, strong standards compliance.

### Architecture Essentials
- **MVCC**: Multi-Version Concurrency Control -- readers never block writers, writers never block readers. Dead tuples accumulate and require VACUUM.
- **WAL (Write-Ahead Log)**: All changes written to WAL before data files. Enables crash recovery, streaming replication, and point-in-time recovery.
- **Shared Buffer Pool**: PostgreSQL's in-memory cache of data pages. Typically set to 25% of system RAM.
- **Background Workers**: autovacuum, bgwriter, checkpointer, WAL sender/receiver.

### Critical Configuration Parameters

```ini
# Memory
shared_buffers = '8GB'              # 25% of RAM (for 32GB system)
effective_cache_size = '24GB'       # 75% of RAM (hint to planner)
work_mem = '64MB'                   # Per-sort/hash operation (careful: multiplied by active queries)
maintenance_work_mem = '2GB'        # VACUUM, CREATE INDEX

# WAL
wal_level = 'replica'               # Or 'logical' for logical replication
max_wal_senders = 10                # Number of replication connections
checkpoint_completion_target = 0.9  # Spread checkpoint I/O
wal_compression = 'zstd'            # Reduce WAL volume (PG 15+)

# Autovacuum
autovacuum_max_workers = 4
autovacuum_vacuum_cost_delay = '2ms'
autovacuum_vacuum_scale_factor = 0.05   # Trigger at 5% dead tuples (default 20% too high)
autovacuum_analyze_scale_factor = 0.02

# Query Planning
random_page_cost = 1.1              # SSD storage (default 4.0 is for HDD)
effective_io_concurrency = 200      # SSD: 200, HDD: 2
```

### Partitioning
Declarative partitioning (range, list, hash) since PG 10. Use `pg_partman` for automated partition management.

```sql
CREATE TABLE events (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMPTZ NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB
) PARTITION BY RANGE (created_at);

CREATE TABLE events_2024_q1 PARTITION OF events
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
```

### Index Types
B-tree (default), Hash, GIN (JSONB/arrays/FTS), GiST (geometric/range), SP-GiST (trie-based), BRIN (large sequential), partial indexes, covering indexes (INCLUDE), expression indexes.

### Extensions Ecosystem
PostGIS, pgvector, TimescaleDB, Citus, pg_partman, pgAudit, pg_cron, pg_repack, pg_stat_monitor, pgroonga, HypoPG, pg_hint_plan, pg_bigm, pg_stat_statements.

### Connection Pooling
PgBouncer (transaction/session/statement modes) or pgcat (Rust-based, sharding-aware).

### Managed Options
Aurora PostgreSQL, AlloyDB, Neon, Supabase, Crunchy Bridge, Azure Flexible Server.

**Deep reference**: [reference-postgresql.md](reference-postgresql.md)

---

## 2. MySQL / MariaDB

High-read web workloads. InnoDB for ACID. Extensive replication and sharding ecosystem.

### InnoDB Tuning

```ini
innodb_buffer_pool_size = 24G          # 70-80% of RAM for dedicated server
innodb_buffer_pool_instances = 8       # Reduce contention (1 per GB up to 8)
innodb_log_file_size = 2G             # Larger = fewer checkpoints, longer recovery
innodb_flush_log_at_trx_commit = 1    # ACID compliance (2 for perf, risk 1s data loss)
innodb_flush_method = O_DIRECT        # Avoid double buffering with OS cache
innodb_io_capacity = 2000             # SSD IOPS baseline
innodb_io_capacity_max = 4000         # SSD IOPS burst
innodb_change_buffer_max_size = 25    # % of buffer pool for secondary index changes
innodb_adaptive_hash_index = ON       # Auto hash index for frequent lookups
innodb_doublewrite = ON               # Crash safety (slight write penalty)
innodb_redo_log_capacity = 8G         # MySQL 8.0.30+ replaces innodb_log_file_size
```

### Replication Modes
- **Async replication**: Default, minimal lag, risk of data loss on failover.
- **Semi-synchronous**: At least one replica acknowledges before commit returns.
- **GTID-based**: Global Transaction Identifiers for reliable failover.
- **Group Replication / InnoDB Cluster**: Multi-primary or single-primary with automatic failover.
- **InnoDB ClusterSet**: Multi-region disaster recovery across InnoDB Clusters.

### Sharding with Vitess
VSchema for logical sharding, vtgate for query routing, vttablet for MySQL management. Online DDL, MoveTables, Reshard workflows.

### ProxySQL
Query routing, connection multiplexing, query caching, mirror traffic for testing, admin interface for real-time reconfiguration.

### MariaDB Specifics
Galera Cluster (synchronous multi-master), MaxScale (proxy/load balancer), ColumnStore (analytics), Spider (sharding engine), system versioning (temporal tables).

**Deep reference**: [reference-mysql.md](reference-mysql.md)

---

## 3. Oracle Database

Enterprise mission-critical workloads with the most comprehensive feature set of any RDBMS.

### Key Capabilities
- **RAC (Real Application Clusters)**: Shared-disk active-active clustering. Cache Fusion for inter-node data sharing. Rolling upgrades.
- **Data Guard**: Physical standby (block-for-block), logical standby (SQL apply), Active Data Guard (read-only queries on standby), Far Sync (zero data loss at distance).
- **AWR/ASH/ADDM**: Automatic Workload Repository, Active Session History, Automatic Database Diagnostic Monitor. Enterprise performance diagnostics.
- **Partitioning**: Range, list, hash, composite, interval, reference partitioning. Partition exchange loading.
- **Flashback**: Database, table, query, transaction, archive. Time-travel without restoring from backup.
- **Autonomous Database**: Self-driving (auto-tuning, auto-indexing), self-securing (auto-patching), self-repairing (auto-failover). Available as Transaction Processing or Data Warehouse.
- **JSON Relational Duality Views (23c)**: Access relational data as JSON documents and vice versa with full ACID guarantees.
- **Multi-tenant (CDB/PDB)**: Container Database with multiple Pluggable Databases for consolidation.

### Anti-Patterns
- Do not disable the Oracle Optimizer statistics gathering job.
- Avoid excessive use of database links for cross-database queries (use materialized views instead).
- Never run production without Data Guard configured.

**Deep reference**: [reference-oracle-mssql.md](reference-oracle-mssql.md)

---

## 4. MS SQL Server

The enterprise RDBMS for the Microsoft/.NET ecosystem with advanced analytics capabilities.

### Key Capabilities
- **AlwaysOn Availability Groups**: Synchronous or asynchronous commit. Automatic failover with up to 5 synchronous replicas. Read-routing to secondaries.
- **Columnstore Indexes**: Batch-mode processing for analytics. 10x compression. Clustered and nonclustered. Archive compression for cold data.
- **In-Memory OLTP (Hekaton)**: Memory-optimized tables with latch-free data structures. Natively compiled stored procedures. 10-30x throughput improvement for OLTP.
- **Query Store**: Captures query plans and runtime statistics. Plan forcing to prevent regressions. Wait stats per query. Regressed query detection.
- **DMVs (Dynamic Management Views)**: `sys.dm_exec_query_stats`, `sys.dm_os_wait_stats`, `sys.dm_db_index_usage_stats`, `sys.dm_exec_requests` for real-time diagnostics.
- **Temporal Tables**: System-versioned tables with automatic history tracking.
- **Ledger Tables**: Blockchain-verified data integrity. Tamper-evident with digest management.
- **Azure SQL**: Hyperscale (up to 100 TB, named replicas), elastic pools (shared resources), serverless compute (auto-pause), managed instance (full SQL Server compatibility).

### Critical Settings

```sql
-- Recommended server settings
ALTER DATABASE [MyDB] SET COMPATIBILITY_LEVEL = 160;  -- SQL Server 2022
ALTER DATABASE [MyDB] SET QUERY_STORE = ON;
ALTER DATABASE [MyDB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = AUTO);
ALTER DATABASE [MyDB] SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON);

-- Max memory (leave 4-8 GB for OS)
EXEC sp_configure 'max server memory (MB)', 28672;  -- 28 GB for 32 GB system
RECONFIGURE;

-- Cost threshold for parallelism (default 5 is too low)
EXEC sp_configure 'cost threshold for parallelism', 50;
RECONFIGURE;

-- Max degree of parallelism
EXEC sp_configure 'max degree of parallelism', 4;  -- Half of cores or 8, whichever is lower
RECONFIGURE;
```

**Deep reference**: [reference-oracle-mssql.md](reference-oracle-mssql.md)

---

## 5. SQLite

The most deployed database engine in the world. Zero-configuration, serverless, single-file, cross-platform.

### Production Configuration

```sql
PRAGMA journal_mode = WAL;          -- Write-Ahead Logging (concurrent readers + one writer)
PRAGMA synchronous = NORMAL;        -- Balance durability vs. performance (FULL for max safety)
PRAGMA foreign_keys = ON;           -- Enforce referential integrity
PRAGMA cache_size = -64000;         -- 64 MB page cache (negative = KB)
PRAGMA mmap_size = 268435456;       -- 256 MB memory-mapped I/O
PRAGMA busy_timeout = 5000;         -- 5 second busy timeout
PRAGMA temp_store = MEMORY;         -- Keep temp tables in memory
PRAGMA auto_vacuum = INCREMENTAL;   -- Reclaim space without full vacuum
```

### Multi-Threaded Modes
- **Serialized** (default): Thread-safe, global mutex. Safest.
- **Multi-threaded**: Separate connections per thread, no sharing. Good performance.
- **Single-threaded**: No mutex overhead. Fastest but single-threaded only.

### FTS5 (Full-Text Search)

```sql
CREATE VIRTUAL TABLE docs_fts USING fts5(title, body, content='docs', content_rowid='id');
SELECT * FROM docs_fts WHERE docs_fts MATCH 'database AND optimization' ORDER BY rank;
```

### Modern Ecosystem
- **libSQL (Turso)**: Server mode, HTTP API, embedded replicas, vector search.
- **Litestream**: Streaming WAL replication to S3/GCS/Azure.
- **cr-sqlite**: CRDTs for conflict-free multi-writer replication.
- **Cloudflare D1**: SQLite at the edge with Workers integration.

### When to Use SQLite
- Mobile/embedded applications.
- Edge computing and IoT devices.
- Development/testing (drop-in for PostgreSQL in many ORMs).
- Single-writer web applications with moderate traffic (<100K requests/day).
- CLI tools and desktop applications.

### When NOT to Use SQLite
- High write concurrency (multiple writers).
- Large-scale web applications with >1000 concurrent writes/second.
- Multi-server deployments requiring shared database access (use PostgreSQL/MySQL).

---

## 6. IBM Db2

Enterprise database with strong mainframe heritage and modern cloud capabilities.

### Platforms
- **Db2 for z/OS**: Mainframe. Highest transaction throughput. Sysplex data sharing. Utilities integrated with JCL.
- **Db2 LUW (Linux/Unix/Windows)**: Distributed platform. BLU Acceleration for columnar analytics. pureScale for active-active clustering.

### Key Features
- **HADR (High Availability Disaster Recovery)**: Synchronous, near-synchronous, asynchronous, and super-asynchronous modes. Automatic client reroute.
- **pureScale**: Shared-disk clustering for LUW. Continuous availability with member failure isolation.
- **BLU Acceleration**: In-memory columnar processing. Automatic compression. Actionable compression (operates on compressed data).
- **Federation**: Query remote data sources (Oracle, SQL Server, Informix, flat files) as local tables.
- **Temporal Tables**: System time, business time, or bi-temporal versioning.

### Configuration Essentials

```bash
# Buffer pool sizing
db2 "ALTER BUFFERPOOL IBMDEFAULTBP SIZE 250000"  # ~1 GB (4KB pages)

# Sort memory
db2 "UPDATE DB CFG FOR mydb USING SORTHEAP 16384"   # 64 MB

# Self-tuning memory
db2 "UPDATE DB CFG FOR mydb USING SELF_TUNING_MEM ON"
```

---

## 7. SAP HANA

In-memory database designed for real-time analytics and transactional processing.

### Architecture
- **Columnar store**: Default for analytics. Dictionary encoding, run-length encoding, sparse encoding. Delta merge for inserts.
- **Row store**: For OLTP workloads requiring frequent single-row operations.
- **In-memory**: All active data in RAM. Persistence via savepoints and redo logs.
- **Tenant databases**: Multi-tenant architecture with resource isolation.

### Key Capabilities
- HTAP: Simultaneous transactional and analytical processing on same dataset.
- Native graph engine, spatial engine, text analysis, predictive analytics library (PAL).
- Smart Data Access (FDA) and Smart Data Integration for remote data.
- HANA Cloud: Managed service with adaptive server, data lake, and data lake files.

### Sizing Guidelines
- RAM: 1.5x-2x the uncompressed data size for columnar tables.
- CPU: 1 core per 50-100 GB of columnar data.
- Storage: 4x RAM for persistence and log volumes.

---

## 8. Firebird

Open-source RDBMS with multi-generational architecture (MGA), similar to PostgreSQL's MVCC.

### Key Features
- **Embedded mode**: Single-library deployment, no separate server process.
- **Multi-generational architecture**: No read locks, snapshot isolation by default.
- **Dialect 3**: Full SQL compliance, 64-bit integers, millisecond timestamps.
- **Firebird 5.0**: Parallel execution, profiler, partial indexes, SKIP LOCKED.

### Use Cases
- Embedded applications requiring full SQL support.
- Small-to-medium deployments wanting zero-administration.
- Vertical applications distributed to customer sites.

---

## 9. Informix

IBM's database optimized for OLTP, IoT, and time-series data.

### Key Features
- **TimeSeries DataBlade**: Native time-series storage with sub-second query performance. Virtual table interface. Automated roll-off.
- **Flexible Grid**: Elastic clustering with automatic data distribution and replication.
- **Enterprise Replication (ER)**: Multi-master, update-anywhere replication.
- **MQTT integration**: Direct IoT device ingestion without middleware.

### Best For
- IoT sensor data with high-frequency inserts.
- Retail point-of-sale with disconnected/reconnected operation.
- Edge computing requiring embedded relational + time-series.

---

## 10. SingleStore (formerly MemSQL)

Distributed SQL database combining real-time analytics with transactional processing.

### Architecture
- **Rowstore**: In-memory, lock-free skiplist for OLTP. Sub-millisecond reads/writes.
- **Columnstore**: Disk-based columnar storage for analytics. Segment elimination. Zone maps.
- **Universal Storage**: Tables can contain both rowstore and columnstore segments.

### Key Features
- MySQL wire protocol compatible (use MySQL clients/drivers).
- Distributed JOINs across shards.
- JSON support with computed columns for semi-structured data.
- Kafka and S3 pipelines for real-time data ingestion.
- Full-text search with `MATCH ... AGAINST`.
- Vector search with dot product and Euclidean distance functions.

### Configuration

```sql
-- Create a columnstore table for analytics
CREATE TABLE events (
    id BIGINT AUTO_INCREMENT,
    ts DATETIME(6) NOT NULL,
    event_type VARCHAR(64),
    payload JSON,
    SORT KEY (ts),
    SHARD KEY (id)
) USING CLUSTERED COLUMNSTORE;

-- Create a rowstore table for low-latency lookups
CREATE REFERENCE TABLE config (
    key_name VARCHAR(128) PRIMARY KEY,
    value JSON NOT NULL
) USING HASH INDEX;
```

---

## 11. EDB (EnterpriseDB)

Oracle-compatible PostgreSQL distribution for enterprise migration.

### Key Features
- **Oracle compatibility**: PL/SQL, DBMS_OUTPUT, DBMS_SCHEDULER, UTL_FILE, sequences, synonyms, packages, autonomous transactions.
- **EDB Postgres Advanced Server (EPAS)**: Drop-in replacement for Oracle in many workloads.
- **Migration toolkit**: Automated schema and data migration from Oracle, SQL Server, MySQL.
- **EDB Postgres Distributed (PGD)**: Multi-master replication with conflict resolution. Up to 99.999% availability.
- **Failover Manager (EFM)**: Automatic failover with VIP management.

---

## 12. Percona Server

Enhanced open-source builds of MySQL and MongoDB with enterprise features.

### Percona Server for MySQL
- Thread pool for high-concurrency workloads.
- Audit Log plugin (free, vs MySQL Enterprise).
- PAM authentication, data-at-rest encryption.
- MyRocks storage engine (LSM-tree, space-efficient).
- **XtraBackup**: Hot backups without locking. Incremental, compressed, streaming.
- **PMM (Percona Monitoring and Management)**: Query Analytics, metrics, dashboards.
- **pt-tools (Percona Toolkit)**: `pt-query-digest`, `pt-online-schema-change`, `pt-table-checksum`, `pt-archiver`.

---

## 13. Amazon Aurora

MySQL and PostgreSQL-compatible with cloud-native storage architecture.

### Architecture
- Storage: 6-way replication across 3 AZs. 10 GB segments. Quorum writes (4/6), quorum reads (3/6).
- Compute: Writer instance + up to 15 read replicas. Sub-10ms replication lag.
- **I/O-Optimized**: Flat pricing eliminates I/O charges for I/O-intensive workloads.

### Key Features
- **Global Database**: Cross-region replication with <1 second lag. Managed failover.
- **Serverless v2**: Scales from 0.5 to 256 ACUs in increments of 0.5 ACU.
- **Parallel Query**: Pushes query processing to storage layer for analytics on OLTP data.
- **Zero-ETL**: Automatic replication to Redshift for analytics.
- **Blue/Green Deployments**: Managed switchover for major version upgrades.

### When Aurora Over RDS
- Need >5 read replicas.
- Need cross-region replication with <1s lag.
- I/O-intensive workloads (I/O-Optimized pricing).
- Need serverless auto-scaling (Serverless v2).

---

## 14. Google AlloyDB

PostgreSQL-compatible database with intelligent caching and columnar engine for HTAP.

### Architecture
- Disaggregated compute and storage.
- **Columnar Engine**: Automatic columnar processing for analytical queries on OLTP data. Up to 100x faster analytics.
- **Intelligent caching**: ML-driven cache that adapts to workload patterns.
- Up to 4x faster than standard PostgreSQL, 2x faster than Aurora for transactional workloads (per Google benchmarks).

### Key Features
- PostgreSQL 14/15 compatible.
- Cross-region replication.
- AlloyDB AI: Built-in vector embeddings and ML model calling from SQL.
- AlloyDB Omni: Run AlloyDB anywhere (on-prem, other clouds, Kubernetes).

---

## 15. Azure SQL

Microsoft's managed SQL Server family in Azure.

### Tiers
- **Azure SQL Database**: Single database or elastic pools. Hyperscale (up to 100 TB). Serverless compute tier (auto-pause).
- **Azure SQL Managed Instance**: Near 100% SQL Server compatibility. VNet integration. Cross-instance queries.
- **SQL Server on Azure VMs**: Full SQL Server with OS access.

### Hyperscale Architecture
- Disaggregated storage with page servers.
- Up to 100 TB database size.
- Named replicas for read scale-out.
- Near-instant database snapshots.
- Fast backup and restore.

---

## 16-20. Cross-References

The following databases span multiple categories and have dedicated coverage elsewhere:

| Database | Category | Primary Coverage |
|----------|----------|-----------------|
| **Neon** | Serverless PostgreSQL | See `serverless-databases` skill |
| **Supabase** | PostgreSQL Platform | See `serverless-databases` skill |
| **CockroachDB** | Distributed SQL (NewSQL) | See `newsql-distributed` skill |
| **YugabyteDB** | Distributed SQL (NewSQL) | See `newsql-distributed` skill |
| **PlanetScale** | Vitess-powered MySQL | See `newsql-distributed` skill |

### Quick Comparison: Neon vs Supabase vs Aurora Serverless

| Feature | Neon | Supabase | Aurora Serverless v2 |
|---------|------|----------|----------------------|
| Scale to zero | Yes | No (always-on) | No (min 0.5 ACU) |
| Branching | Yes (instant) | No | No |
| Built-in auth | No | Yes | No |
| Realtime | No | Yes (websockets) | No |
| Edge functions | No | Yes (Deno) | No |
| Storage | No | Yes (S3-backed) | No |
| PG version | 16+ | 15+ | 16+ |
| Free tier | Yes (generous) | Yes | No |

---

## Operational Runbook Snippets

### PostgreSQL: Check Bloat and Dead Tuples

```sql
-- Top 10 tables by dead tuple ratio
SELECT schemaname, relname,
       n_dead_tup,
       n_live_tup,
       ROUND(n_dead_tup::numeric / GREATEST(n_live_tup, 1) * 100, 2) AS dead_ratio_pct,
       last_autovacuum,
       last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;
```

### MySQL: InnoDB Buffer Pool Hit Ratio

```sql
SELECT
    (1 - (Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests)) * 100 AS hit_ratio
FROM (
    SELECT
        VARIABLE_VALUE AS Innodb_buffer_pool_reads
    FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads'
) reads,
(
    SELECT
        VARIABLE_VALUE AS Innodb_buffer_pool_read_requests
    FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests'
) requests;
```

### SQL Server: Top Wait Types

```sql
SELECT TOP 10
    wait_type,
    wait_time_ms / 1000.0 AS wait_time_sec,
    signal_wait_time_ms / 1000.0 AS signal_wait_sec,
    waiting_tasks_count,
    wait_time_ms / GREATEST(waiting_tasks_count, 1) AS avg_wait_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
    'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
    'WAITFOR', 'BROKER_TASK_STOP', 'CLR_AUTO_EVENT',
    'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
    'XE_DISPATCHER_WAIT', 'CHECKPOINT_QUEUE'
)
ORDER BY wait_time_ms DESC;
```

### Oracle: Top SQL by Elapsed Time (from AWR)

```sql
SELECT * FROM (
    SELECT sql_id,
           ROUND(elapsed_time_total / 1e6, 2) AS elapsed_sec,
           executions_total,
           ROUND(elapsed_time_total / GREATEST(executions_total, 1) / 1e6, 4) AS avg_sec,
           sql_text
    FROM dba_hist_sqlstat s
    JOIN dba_hist_sqltext t USING (sql_id)
    WHERE snap_id BETWEEN :begin_snap AND :end_snap
    ORDER BY elapsed_time_total DESC
) WHERE ROWNUM <= 10;
```

---

## Anti-Patterns (All Relational Databases)

1. **No connection pooling**: Opening/closing connections per request. Use PgBouncer, ProxySQL, HikariCP, or managed pool.
2. **Missing indexes on foreign keys**: Causes table scans on JOINs and cascading deletes.
3. **SELECT ***: Fetches unnecessary columns, wastes I/O and memory.
4. **N+1 queries**: Load parent then loop for children. Use JOINs, subqueries, or DataLoader.
5. **Storing money as FLOAT**: Use DECIMAL/NUMERIC with explicit precision.
6. **TIMESTAMP without timezone**: Use TIMESTAMPTZ (PostgreSQL) or UTC conversion discipline.
7. **No query parameterization**: SQL injection risk and plan cache pollution.
8. **Unbounded queries**: Missing LIMIT/OFFSET on user-facing queries.
9. **Running DDL without testing**: Always test migrations on a staging replica first.
10. **Ignoring autovacuum / stats maintenance**: Leads to bloat and bad query plans.

---

For detailed deep-dives, see:
- [reference-postgresql.md](reference-postgresql.md)
- [reference-mysql.md](reference-mysql.md)
- [reference-oracle-mssql.md](reference-oracle-mssql.md)
