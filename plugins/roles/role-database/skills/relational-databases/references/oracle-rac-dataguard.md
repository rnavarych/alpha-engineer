# Oracle Database — RAC, Data Guard, AWR/ASH, Partitioning, Flashback

## When to load
Load when working with Oracle RAC clustering, Data Guard standby configuration, AWR/ASH performance diagnostics, Oracle partitioning, Flashback, or multi-tenant CDB/PDB architecture.

## RAC (Real Application Clusters)

```sql
-- Check RAC status
SELECT inst_id, instance_name, host_name, status FROM gv$instance;

-- Monitor Cache Fusion
SELECT inst_id, name, value FROM gv$sysstat
WHERE name IN ('gc cr blocks received', 'gc current blocks received',
               'gc cr block receive time', 'gc current block receive time');

-- Service-based workload routing
BEGIN
  DBMS_SERVICE.CREATE_SERVICE(service_name => 'oltp_svc', network_name => 'oltp_svc.example.com');
  DBMS_SERVICE.START_SERVICE(service_name => 'oltp_svc');
END;
/
```

**Best practices:** partition data by node affinity to minimize Cache Fusion traffic; monitor `gc wait` events in AWR; use separate VLANs for interconnect; rolling upgrades patch one node at a time.

## Data Guard

| Protection Mode | Redo Transport | Data Loss Risk |
|----------------|---------------|----------------|
| Maximum Protection | SYNC (AFFIRM) | Zero |
| Maximum Availability | SYNC, fallback to ASYNC | Near-zero |
| Maximum Performance | ASYNC | Possible |

```sql
ALTER DATABASE FORCE LOGGING;
ALTER SYSTEM SET log_archive_dest_2 =
    'SERVICE=standby1 ASYNC NOAFFIRM VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE)
     DB_UNIQUE_NAME=standby1' SCOPE=BOTH;

-- Active Data Guard: open standby for reads
ALTER DATABASE OPEN READ ONLY;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;

-- Planned switchover
-- On primary:
ALTER DATABASE COMMIT TO SWITCHOVER TO STANDBY WITH SESSION SHUTDOWN;
-- On standby:
ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY WITH SESSION SHUTDOWN;

-- Fast-Start Failover
DGMGRL> ENABLE FAST_START FAILOVER;
DGMGRL> START OBSERVER;
```

## AWR / ASH / ADDM

```sql
-- Top SQL by elapsed time
SELECT sql_id, elapsed_time_total/1e6 AS elapsed_sec, executions_total
FROM dba_hist_sqlstat
WHERE snap_id BETWEEN :begin_snap AND :end_snap
ORDER BY elapsed_time_total DESC FETCH FIRST 10 ROWS ONLY;

-- Top wait events (ASH, last hour)
SELECT event, wait_class, COUNT(*) AS samples
FROM v$active_session_history
WHERE sample_time > SYSDATE - INTERVAL '1' HOUR
GROUP BY event, wait_class ORDER BY samples DESC FETCH FIRST 10 ROWS ONLY;
```

## Partitioning

```sql
-- Range partitioning
CREATE TABLE sales (sale_id NUMBER, sale_date DATE, amount NUMBER(12,2), region VARCHAR2(20))
PARTITION BY RANGE (sale_date) (
    PARTITION p_2024_q1 VALUES LESS THAN (DATE '2024-04-01'),
    PARTITION p_max VALUES LESS THAN (MAXVALUE)
);

-- Interval partitioning (auto-create monthly)
CREATE TABLE logs (log_id NUMBER, log_time TIMESTAMP, message CLOB)
PARTITION BY RANGE (log_time) INTERVAL (NUMTOYMINTERVAL(1, 'MONTH')) (
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2024-01-01 00:00:00')
);

-- Partition exchange loading (instant bulk load)
ALTER TABLE sales EXCHANGE PARTITION p_2024_q1
    WITH TABLE staging_sales_q1 WITHOUT VALIDATION;
```

## Flashback

```sql
-- Flashback Query
SELECT * FROM employees AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' HOUR)
WHERE employee_id = 100;

-- Flashback Table
ALTER TABLE employees ENABLE ROW MOVEMENT;
FLASHBACK TABLE employees TO TIMESTAMP (SYSTIMESTAMP - INTERVAL '2' HOUR);

-- Flashback Archive (compliance retention)
CREATE FLASHBACK ARCHIVE fla_compliance TABLESPACE fla_ts RETENTION 7 YEAR;
ALTER TABLE audit_records FLASHBACK ARCHIVE fla_compliance;
```

## JSON Relational Duality Views (23c) and Multi-Tenant

```sql
-- JSON Duality View
CREATE JSON RELATIONAL DUALITY VIEW order_dv AS
    orders @insert @update @delete {
        _id : order_id, date : order_date,
        customer : customers @insert @update { customerId : customer_id, name : customer_name }
    };

-- Create Pluggable Database
CREATE PLUGGABLE DATABASE pdb_sales ADMIN USER sales_admin IDENTIFIED BY secret
    FILE_NAME_CONVERT = ('/pdbseed/', '/pdb_sales/');
ALTER PLUGGABLE DATABASE pdb_sales OPEN;

-- Thin clone (space-efficient)
CREATE PLUGGABLE DATABASE pdb_test FROM pdb_sales SNAPSHOT COPY;
```
