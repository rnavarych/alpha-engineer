# Oracle Database + MS SQL Server Deep-Dive Reference

---

## Oracle Database

### RAC (Real Application Clusters)

RAC provides active-active clustering with shared storage (ASM or Exadata). All nodes read/write to the same database simultaneously.

#### Architecture
- **Shared storage**: Oracle ASM (Automatic Storage Management) or Exadata storage cells.
- **Cache Fusion**: Inter-node memory transfer of data blocks via private interconnect. Eliminates disk I/O for cross-node data access.
- **GCS (Global Cache Service)**: Coordinates block ownership across nodes.
- **GES (Global Enqueue Service)**: Coordinates locks across nodes.

#### Key Configuration

```sql
-- Check RAC status
SELECT inst_id, instance_name, host_name, status FROM gv$instance;

-- Monitor Cache Fusion performance
SELECT * FROM gv$cr_block_server;
SELECT * FROM gv$current_block_server;

-- Interconnect traffic
SELECT inst_id, name, value FROM gv$sysstat
WHERE name IN ('gc cr blocks received', 'gc current blocks received',
               'gc cr block receive time', 'gc current block receive time');

-- Service-based workload routing
BEGIN
  DBMS_SERVICE.CREATE_SERVICE(
    service_name => 'oltp_svc',
    network_name => 'oltp_svc.example.com'
  );
  DBMS_SERVICE.START_SERVICE(service_name => 'oltp_svc');
END;
/
```

#### RAC Best Practices
- Use application-level connection pooling with service-based routing.
- Partition data by node affinity to minimize Cache Fusion traffic.
- Monitor `gc wait` events in AWR reports for interconnect bottlenecks.
- Use separate VLANs for interconnect (low-latency, high-bandwidth).
- Rolling upgrades: patch one node at a time with service relocation.

---

### Data Guard

Oracle's disaster recovery and high availability solution using standby databases.

#### Modes

| Protection Mode | Redo Transport | Data Loss Risk | Performance Impact |
|----------------|---------------|----------------|-------------------|
| Maximum Protection | SYNC (AFFIRM) | Zero | Highest (blocks on standby failure) |
| Maximum Availability | SYNC (AFFIRM), fallback to ASYNC | Near-zero | Moderate (degrades to async) |
| Maximum Performance | ASYNC | Possible | Lowest (default) |

#### Configuration

```sql
-- Primary: enable archiving and standby redo logs
ALTER DATABASE FORCE LOGGING;
ALTER SYSTEM SET log_archive_config = 'DG_CONFIG=(primary,standby1)' SCOPE=BOTH;
ALTER SYSTEM SET log_archive_dest_2 = 'SERVICE=standby1 ASYNC NOAFFIRM
    VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=standby1' SCOPE=BOTH;

-- Standby: apply redo
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;

-- Active Data Guard: open standby for read-only queries
ALTER DATABASE OPEN READ ONLY;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;

-- Far Sync: zero data loss over long distances
-- Far Sync instance receives SYNC redo, forwards ASYNC to remote standby
```

#### Switchover and Failover

```sql
-- Planned switchover (zero data loss)
-- On primary:
ALTER DATABASE COMMIT TO SWITCHOVER TO STANDBY WITH SESSION SHUTDOWN;
-- On standby:
ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY WITH SESSION SHUTDOWN;

-- Emergency failover (potential data loss)
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;
ALTER DATABASE ACTIVATE STANDBY DATABASE;

-- Fast-Start Failover (automatic, with Observer)
DGMGRL> ENABLE FAST_START FAILOVER;
DGMGRL> START OBSERVER;
```

---

### AWR / ASH / ADDM

#### AWR (Automatic Workload Repository)

```sql
-- Create manual AWR snapshot
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT();

-- Generate AWR report (HTML)
@$ORACLE_HOME/rdbms/admin/awrrpt.sql

-- Top SQL by elapsed time
SELECT sql_id, elapsed_time_total/1e6 AS elapsed_sec,
       executions_total, cpu_time_total/1e6 AS cpu_sec,
       buffer_gets_total, disk_reads_total
FROM dba_hist_sqlstat
WHERE snap_id BETWEEN :begin_snap AND :end_snap
ORDER BY elapsed_time_total DESC
FETCH FIRST 10 ROWS ONLY;

-- AWR baseline for comparison
BEGIN
  DBMS_WORKLOAD_REPOSITORY.CREATE_BASELINE(
    start_snap_id => 100,
    end_snap_id   => 120,
    baseline_name => 'peak_load_baseline'
  );
END;
/
```

#### ASH (Active Session History)

```sql
-- Real-time session analysis (1-second sampling)
SELECT sample_time, session_id, sql_id, event, wait_class,
       session_state, blocking_session
FROM v$active_session_history
WHERE sample_time > SYSDATE - INTERVAL '10' MINUTE
  AND session_state = 'WAITING'
ORDER BY sample_time DESC;

-- Top wait events in last hour
SELECT event, wait_class, COUNT(*) AS samples,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM v$active_session_history
WHERE sample_time > SYSDATE - INTERVAL '1' HOUR
GROUP BY event, wait_class
ORDER BY samples DESC
FETCH FIRST 10 ROWS ONLY;
```

#### ADDM (Automatic Database Diagnostic Monitor)

```sql
-- Run ADDM analysis
DECLARE
  task_name VARCHAR2(100) := 'my_addm_task';
BEGIN
  DBMS_ADVISOR.CREATE_TASK('ADDM', task_name);
  DBMS_ADVISOR.SET_TASK_PARAMETER(task_name, 'START_SNAPSHOT', 100);
  DBMS_ADVISOR.SET_TASK_PARAMETER(task_name, 'END_SNAPSHOT', 120);
  DBMS_ADVISOR.EXECUTE_TASK(task_name);
END;
/

-- View findings
SELECT type, message, impact FROM dba_advisor_findings
WHERE task_name = 'my_addm_task'
ORDER BY impact DESC;
```

---

### Partitioning

```sql
-- Range partitioning (most common)
CREATE TABLE sales (
    sale_id    NUMBER,
    sale_date  DATE,
    amount     NUMBER(12,2),
    region     VARCHAR2(20)
)
PARTITION BY RANGE (sale_date) (
    PARTITION p_2024_q1 VALUES LESS THAN (DATE '2024-04-01'),
    PARTITION p_2024_q2 VALUES LESS THAN (DATE '2024-07-01'),
    PARTITION p_2024_q3 VALUES LESS THAN (DATE '2024-10-01'),
    PARTITION p_2024_q4 VALUES LESS THAN (DATE '2025-01-01'),
    PARTITION p_max VALUES LESS THAN (MAXVALUE)
);

-- Interval partitioning (auto-create monthly)
CREATE TABLE logs (
    log_id    NUMBER,
    log_time  TIMESTAMP,
    message   CLOB
)
PARTITION BY RANGE (log_time) INTERVAL (NUMTOYMINTERVAL(1, 'MONTH')) (
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2024-01-01 00:00:00')
);

-- Composite partitioning (range-hash)
CREATE TABLE orders (
    order_id    NUMBER,
    order_date  DATE,
    customer_id NUMBER,
    total       NUMBER(12,2)
)
PARTITION BY RANGE (order_date) SUBPARTITION BY HASH (customer_id) SUBPARTITIONS 8 (
    PARTITION p_2024_h1 VALUES LESS THAN (DATE '2024-07-01'),
    PARTITION p_2024_h2 VALUES LESS THAN (DATE '2025-01-01')
);

-- Partition exchange loading (instant bulk load)
ALTER TABLE sales EXCHANGE PARTITION p_2024_q1
    WITH TABLE staging_sales_q1 WITHOUT VALIDATION;
```

---

### Flashback

```sql
-- Flashback Query (query data at a point in time)
SELECT * FROM employees AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' HOUR)
WHERE employee_id = 100;

-- Flashback Table (restore table to a point in time)
ALTER TABLE employees ENABLE ROW MOVEMENT;
FLASHBACK TABLE employees TO TIMESTAMP (SYSTIMESTAMP - INTERVAL '2' HOUR);

-- Flashback Database (whole database restore, requires flashback logs)
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
FLASHBACK DATABASE TO TIMESTAMP (SYSDATE - 1);
ALTER DATABASE OPEN RESETLOGS;

-- Flashback Transaction Query (trace transaction changes)
SELECT * FROM flashback_transaction_query
WHERE xid = HEXTORAW('0003001200000456');

-- Flashback Archive (long-term compliance retention)
CREATE FLASHBACK ARCHIVE fla_compliance
    TABLESPACE fla_ts RETENTION 7 YEAR;
ALTER TABLE audit_records FLASHBACK ARCHIVE fla_compliance;
```

---

### Autonomous Database

| Feature | Description |
|---------|-------------|
| Auto-indexing | ML-driven index creation and removal |
| Auto-scaling | CPU scales 1-128 OCPUs, storage to 383 TB |
| Auto-patching | Zero-downtime security and bug patches |
| Auto-tuning | SQL plan management, statistics, memory |
| Auto-backup | Automatic daily backups, 60-day retention |
| Workload types | Transaction Processing, Data Warehouse, JSON, APEX |

### JSON Relational Duality Views (23c)

```sql
-- Access relational data as JSON documents
CREATE JSON RELATIONAL DUALITY VIEW order_dv AS
    orders @insert @update @delete {
        _id    : order_id,
        date   : order_date,
        total  : total_amount,
        customer : customers @insert @update {
            customerId : customer_id,
            name       : customer_name,
            email      : email
        },
        items  : order_items @insert @update @delete [{
            lineId   : line_id,
            product  : product_name,
            quantity : qty,
            price    : unit_price
        }]
    };

-- Query as JSON
SELECT JSON_SERIALIZE(data PRETTY) FROM order_dv WHERE JSON_VALUE(data, '$._id') = 1001;

-- Update via JSON
UPDATE order_dv SET data = '{"_id":1001,"total":999.99}' WHERE JSON_VALUE(data,'$._id') = 1001;
```

### Multi-Tenant Architecture (CDB/PDB)

```sql
-- Create Pluggable Database
CREATE PLUGGABLE DATABASE pdb_sales ADMIN USER sales_admin IDENTIFIED BY secret
    FILE_NAME_CONVERT = ('/pdbseed/', '/pdb_sales/');
ALTER PLUGGABLE DATABASE pdb_sales OPEN;

-- Clone PDB (thin clone, space-efficient)
CREATE PLUGGABLE DATABASE pdb_test FROM pdb_sales SNAPSHOT COPY;

-- Relocate PDB to another CDB
ALTER PLUGGABLE DATABASE pdb_sales CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE pdb_sales UNPLUG INTO '/tmp/pdb_sales.xml';
-- On target CDB:
CREATE PLUGGABLE DATABASE pdb_sales USING '/tmp/pdb_sales.xml' COPY;
```

---

---

## MS SQL Server

### AlwaysOn Availability Groups

#### Architecture
- **Primary replica**: Read-write. Hosts the database.
- **Secondary replicas**: Up to 8 (5 synchronous, 3 asynchronous). Readable secondaries optional.
- **Listener**: Virtual network name for client connections. Automatic failover routing.
- **Availability modes**: Synchronous commit (zero data loss) or asynchronous commit (best performance).

#### Configuration

```sql
-- Create Availability Group
CREATE AVAILABILITY GROUP [MyAG]
WITH (
    AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
    DB_FAILOVER = ON,
    CLUSTER_TYPE = WSFC
)
FOR DATABASE [MyDB]
REPLICA ON
    N'SQL-Node1' WITH (
        ENDPOINT_URL = N'TCP://SQL-Node1:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY, READ_ONLY_ROUTING_URL = N'TCP://SQL-Node1:1433')
    ),
    N'SQL-Node2' WITH (
        ENDPOINT_URL = N'TCP://SQL-Node2:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY, READ_ONLY_ROUTING_URL = N'TCP://SQL-Node2:1433')
    ),
    N'SQL-Node3' WITH (
        ENDPOINT_URL = N'TCP://SQL-Node3:5022',
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
        FAILOVER_MODE = MANUAL,
        SEEDING_MODE = AUTOMATIC
    );

-- Create listener
ALTER AVAILABILITY GROUP [MyAG]
ADD LISTENER N'MyAGListener' (
    WITH IP ((N'10.0.0.100', N'255.255.255.0')),
    PORT = 1433
);

-- Configure read-only routing
ALTER AVAILABILITY GROUP [MyAG]
MODIFY REPLICA ON N'SQL-Node1' WITH (
    PRIMARY_ROLE (READ_ONLY_ROUTING_LIST = (N'SQL-Node2', N'SQL-Node3'))
);
```

#### Monitoring

```sql
-- AG health
SELECT ag.name AS ag_name, ar.replica_server_name,
       drs.database_id, db.name AS db_name,
       drs.synchronization_state_desc,
       drs.synchronization_health_desc,
       drs.log_send_queue_size,
       drs.redo_queue_size
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON drs.replica_id = ar.replica_id
JOIN sys.availability_groups ag ON ar.group_id = ag.group_id
JOIN sys.databases db ON drs.database_id = db.database_id;
```

---

### Columnstore Indexes

```sql
-- Clustered columnstore (replaces heap or b-tree for entire table)
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales ON dbo.FactSales;

-- Nonclustered columnstore (hybrid: OLTP + analytics on same table)
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders
ON dbo.Orders (order_date, customer_id, total_amount, status);

-- Filtered nonclustered columnstore
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_RecentOrders
ON dbo.Orders (order_date, total_amount)
WHERE order_date >= '2024-01-01';

-- Archive compression (higher compression, slower queries)
ALTER INDEX CCI_Sales ON dbo.FactSales
REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);
```

#### Batch Mode Processing
Columnstore enables batch-mode execution (processing 900 rows at a time instead of row-by-row). Since SQL Server 2019, batch mode is available on rowstore tables too (Batch Mode on Rowstore).

```sql
-- Force batch mode hint (when optimizer chooses row mode)
SELECT customer_id, SUM(total) AS revenue
FROM dbo.FactSales
GROUP BY customer_id
OPTION (USE HINT('ENABLE_BATCH_MODE_ON_ROWSTORE'));
```

---

### In-Memory OLTP (Hekaton)

```sql
-- Create memory-optimized filegroup
ALTER DATABASE [MyDB] ADD FILEGROUP [InMemFG] CONTAINS MEMORY_OPTIMIZED_DATA;
ALTER DATABASE [MyDB] ADD FILE (
    NAME = 'InMemFile', FILENAME = 'D:\Data\InMemFile'
) TO FILEGROUP [InMemFG];

-- Create memory-optimized table
CREATE TABLE dbo.SessionState (
    session_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY NONCLUSTERED,
    user_id INT NOT NULL,
    data NVARCHAR(MAX),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    INDEX ix_user HASH (user_id) WITH (BUCKET_COUNT = 1048576)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

-- Natively compiled stored procedure (compiled to machine code)
CREATE PROCEDURE dbo.GetSession
    @session_id UNIQUEIDENTIFIER
WITH NATIVE_COMPILATION, SCHEMABINDING
AS BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = 'English')
    SELECT session_id, user_id, data, created_at
    FROM dbo.SessionState
    WHERE session_id = @session_id;
END;
```

#### Performance Considerations
- Hash indexes: Use for point lookups. Set BUCKET_COUNT to 1-2x expected unique values.
- Nonclustered indexes: Use for range scans and ordered access.
- SCHEMA_ONLY durability: Data lost on restart but highest performance (session state, caching).
- Interop overhead: Cross-engine queries between disk-based and memory-optimized tables have overhead.

---

### Query Store

```sql
-- Enable Query Store
ALTER DATABASE [MyDB] SET QUERY_STORE = ON (
    OPERATION_MODE = READ_WRITE,
    DATA_FLUSH_INTERVAL_SECONDS = 900,
    INTERVAL_LENGTH_MINUTES = 30,
    MAX_STORAGE_SIZE_MB = 1024,
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30),
    QUERY_CAPTURE_MODE = AUTO,
    WAIT_STATS_CAPTURE_MODE = ON
);

-- Find regressed queries (performance degradation)
SELECT q.query_id, qt.query_sql_text,
       rs1.avg_duration AS old_avg_duration,
       rs2.avg_duration AS new_avg_duration,
       rs2.avg_duration / NULLIF(rs1.avg_duration, 0) AS regression_factor
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p1 ON q.query_id = p1.query_id
JOIN sys.query_store_runtime_stats rs1 ON p1.plan_id = rs1.plan_id
JOIN sys.query_store_plan p2 ON q.query_id = p2.query_id
JOIN sys.query_store_runtime_stats rs2 ON p2.plan_id = rs2.plan_id
WHERE rs2.avg_duration > rs1.avg_duration * 2
ORDER BY regression_factor DESC;

-- Force a specific plan
EXEC sp_query_store_force_plan @query_id = 42, @plan_id = 7;

-- Unforce a plan
EXEC sp_query_store_unforce_plan @query_id = 42, @plan_id = 7;

-- Top resource-consuming queries
SELECT TOP 10 q.query_id, qt.query_sql_text,
       SUM(rs.count_executions) AS total_executions,
       SUM(rs.avg_duration * rs.count_executions) AS total_duration,
       AVG(rs.avg_cpu_time) AS avg_cpu_time,
       AVG(rs.avg_logical_io_reads) AS avg_logical_reads
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
GROUP BY q.query_id, qt.query_sql_text
ORDER BY total_duration DESC;
```

---

### DMVs for Diagnostics

```sql
-- Top waits (system-wide)
SELECT TOP 10 wait_type,
       wait_time_ms / 1000.0 AS wait_sec,
       signal_wait_time_ms / 1000.0 AS signal_wait_sec,
       (wait_time_ms - signal_wait_time_ms) / 1000.0 AS resource_wait_sec,
       waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%' AND wait_type NOT LIKE '%IDLE%'
  AND wait_type NOT LIKE '%QUEUE%' AND wait_type NOT LIKE '%XE%'
  AND wait_type NOT IN ('BROKER_TASK_STOP','CLR_AUTO_EVENT','CHECKPOINT_QUEUE')
ORDER BY wait_time_ms DESC;

-- Currently executing queries with resource usage
SELECT r.session_id, r.status, r.wait_type, r.wait_time,
       r.cpu_time, r.logical_reads, r.reads, r.writes,
       r.total_elapsed_time / 1000 AS elapsed_ms,
       t.text AS query_text,
       p.query_plan
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) p
WHERE r.session_id > 50
ORDER BY r.total_elapsed_time DESC;

-- Index usage statistics
SELECT OBJECT_NAME(i.object_id) AS table_name,
       i.name AS index_name, i.type_desc,
       s.user_seeks, s.user_scans, s.user_lookups, s.user_updates,
       s.last_user_seek, s.last_user_scan
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;

-- Missing index recommendations
SELECT d.statement AS table_name,
       d.equality_columns, d.inequality_columns, d.included_columns,
       s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans) AS improvement_measure
FROM sys.dm_db_missing_index_details d
JOIN sys.dm_db_missing_index_groups g ON d.index_handle = g.index_handle
JOIN sys.dm_db_missing_index_group_stats s ON g.index_group_handle = s.group_handle
ORDER BY improvement_measure DESC;

-- Blocking chains
SELECT blocking.session_id AS blocking_session,
       blocked.session_id AS blocked_session,
       blocked.wait_type, blocked.wait_time,
       bt.text AS blocking_query,
       wt.text AS blocked_query
FROM sys.dm_exec_requests blocked
JOIN sys.dm_exec_sessions blocking ON blocked.blocking_session_id = blocking.session_id
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) wt
OUTER APPLY sys.dm_exec_sql_text(blocking.most_recent_sql_handle) bt;
```

---

### Temporal Tables

```sql
-- Create system-versioned temporal table
CREATE TABLE dbo.Products (
    ProductId INT PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory));

-- Query at a point in time
SELECT * FROM dbo.Products FOR SYSTEM_TIME AS OF '2024-03-15 10:00:00';

-- Query over a time range
SELECT * FROM dbo.Products FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-06-01';

-- All historical versions of a row
SELECT * FROM dbo.Products FOR SYSTEM_TIME ALL WHERE ProductId = 42 ORDER BY ValidFrom;
```

---

### Ledger Tables

```sql
-- Updatable ledger table (tracks all changes with cryptographic hashes)
CREATE TABLE dbo.AuditTrail (
    TransactionId INT NOT NULL PRIMARY KEY,
    Amount DECIMAL(18,2) NOT NULL,
    Description NVARCHAR(500)
) WITH (SYSTEM_VERSIONING = ON, LEDGER = ON);

-- Append-only ledger table (insert-only, tamper-evident)
CREATE TABLE dbo.ComplianceLog (
    LogId INT IDENTITY PRIMARY KEY,
    Action NVARCHAR(100) NOT NULL,
    Details NVARCHAR(MAX),
    Timestamp DATETIME2 DEFAULT SYSDATETIME()
) WITH (LEDGER = ON (APPEND_ONLY = ON));

-- Verify ledger integrity
EXEC sp_verify_database_ledger;
```

---

### Azure SQL

| Tier | Description | Max Size | Use Case |
|------|-------------|----------|----------|
| Basic/Standard/Premium | DTU-based | 4 TB | Predictable workloads |
| General Purpose | vCore-based | 16 TB | Most workloads |
| Business Critical | vCore + local SSD | 4 TB | Low-latency OLTP |
| Hyperscale | Disaggregated storage | 100 TB | Large databases, fast scaling |
| Serverless | Auto-pause compute | 16 TB | Intermittent workloads |

#### Hyperscale Architecture
- Page servers: Distributed storage with local SSD cache.
- Log service: Centralized transaction log with zone-redundant storage.
- Named replicas: Independent compute endpoints for read scale-out (up to 30).
- Near-instant database snapshots and backups.
- Fast scaling: Add/remove compute in seconds.

```sql
-- Create Hyperscale database
CREATE DATABASE [MyDB] (
    EDITION = 'Hyperscale',
    SERVICE_OBJECTIVE = 'HS_Gen5_4',
    MAX_SIZE = 100 TB
);

-- Create named replica for analytics
ALTER DATABASE [MyDB] ADD SECONDARY ON SERVER [analytics-server]
    WITH (SERVICE_OBJECTIVE = 'HS_Gen5_8', SECONDARY_TYPE = Named, DATABASE_NAME = 'MyDB_Analytics');
```

#### Elastic Pools

```sql
-- Create elastic pool for multi-tenant SaaS
CREATE ELASTIC POOL [SaaSPool] (
    EDITION = 'GeneralPurpose',
    MAX_SIZE = 2 TB,
    SERVICE_OBJECTIVE = 'GP_Gen5',
    MIN_CAPACITY = 0.25,
    MAX_CAPACITY_PER_DATABASE = 4,
    DATABASE_MAX_COUNT = 100
);

-- Add database to pool
ALTER DATABASE [TenantDB1] MODIFY (SERVICE_OBJECTIVE = ELASTIC_POOL(name = [SaaSPool]));
```
