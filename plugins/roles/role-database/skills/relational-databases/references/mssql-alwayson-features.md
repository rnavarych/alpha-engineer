# MS SQL Server — AlwaysOn AG, Columnstore, In-Memory OLTP, Query Store, DMVs

## When to load
Load when configuring AlwaysOn Availability Groups, columnstore indexes, In-Memory OLTP (Hekaton), Query Store plan forcing, or diagnosing waits/blocking via DMVs and temporal/ledger tables.

## AlwaysOn Availability Groups

```sql
CREATE AVAILABILITY GROUP [MyAG]
WITH (AUTOMATED_BACKUP_PREFERENCE = SECONDARY, DB_FAILOVER = ON, CLUSTER_TYPE = WSFC)
FOR DATABASE [MyDB]
REPLICA ON
    N'SQL-Node1' WITH (
        ENDPOINT_URL = N'TCP://SQL-Node1:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY)
    ),
    N'SQL-Node2' WITH (
        ENDPOINT_URL = N'TCP://SQL-Node2:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC
    );

-- Monitor AG health
SELECT ag.name AS ag_name, ar.replica_server_name, drs.synchronization_state_desc,
       drs.log_send_queue_size, drs.redo_queue_size
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON drs.replica_id = ar.replica_id
JOIN sys.availability_groups ag ON ar.group_id = ag.group_id;
```

## Columnstore Indexes

```sql
-- Clustered columnstore
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales ON dbo.FactSales;

-- Nonclustered columnstore (hybrid OLTP + analytics)
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders
ON dbo.Orders (order_date, customer_id, total_amount, status);

-- Archive compression
ALTER INDEX CCI_Sales ON dbo.FactSales
REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);
```

## In-Memory OLTP (Hekaton)

```sql
ALTER DATABASE [MyDB] ADD FILEGROUP [InMemFG] CONTAINS MEMORY_OPTIMIZED_DATA;
ALTER DATABASE [MyDB] ADD FILE (NAME = 'InMemFile', FILENAME = 'D:\Data\InMemFile')
TO FILEGROUP [InMemFG];

CREATE TABLE dbo.SessionState (
    session_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY NONCLUSTERED,
    user_id INT NOT NULL,
    data NVARCHAR(MAX),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    INDEX ix_user HASH (user_id) WITH (BUCKET_COUNT = 1048576)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

-- Natively compiled stored procedure
CREATE PROCEDURE dbo.GetSession @session_id UNIQUEIDENTIFIER
WITH NATIVE_COMPILATION, SCHEMABINDING
AS BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = 'English')
    SELECT session_id, user_id, data FROM dbo.SessionState WHERE session_id = @session_id;
END;
```

## Query Store

```sql
ALTER DATABASE [MyDB] SET QUERY_STORE = ON (
    OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = AUTO,
    MAX_STORAGE_SIZE_MB = 1024, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30)
);

-- Force a specific plan
EXEC sp_query_store_force_plan @query_id = 42, @plan_id = 7;

-- Top resource consumers
SELECT TOP 10 q.query_id, qt.query_sql_text,
       SUM(rs.count_executions) AS total_executions,
       AVG(rs.avg_cpu_time) AS avg_cpu_time
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
GROUP BY q.query_id, qt.query_sql_text
ORDER BY SUM(rs.avg_cpu_time * rs.count_executions) DESC;
```

## DMVs for Diagnostics

```sql
-- Top wait types
SELECT TOP 10 wait_type, wait_time_ms / 1000.0 AS wait_sec, waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%' AND wait_type NOT LIKE '%IDLE%'
ORDER BY wait_time_ms DESC;

-- Currently executing queries
SELECT r.session_id, r.status, r.wait_type, r.cpu_time, r.logical_reads,
       t.text AS query_text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id > 50 ORDER BY r.total_elapsed_time DESC;

-- Missing index recommendations
SELECT d.statement AS table_name, d.equality_columns, d.included_columns,
       s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans) AS improvement_measure
FROM sys.dm_db_missing_index_details d
JOIN sys.dm_db_missing_index_groups g ON d.index_handle = g.index_handle
JOIN sys.dm_db_missing_index_group_stats s ON g.index_group_handle = s.group_handle
ORDER BY improvement_measure DESC;
```

## Temporal Tables and Ledger

```sql
-- Temporal table
CREATE TABLE dbo.Products (
    ProductId INT PRIMARY KEY, Name NVARCHAR(255), Price DECIMAL(10,2),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory));

SELECT * FROM dbo.Products FOR SYSTEM_TIME AS OF '2024-03-15 10:00:00';

-- Append-only ledger
CREATE TABLE dbo.ComplianceLog (
    LogId INT IDENTITY PRIMARY KEY, Action NVARCHAR(100) NOT NULL,
    Timestamp DATETIME2 DEFAULT SYSDATETIME()
) WITH (LEDGER = ON (APPEND_ONLY = ON));

EXEC sp_verify_database_ledger;
```
