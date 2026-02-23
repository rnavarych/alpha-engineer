# PostgreSQL and MySQL Diagnostics

## When to load
Load when troubleshooting slow queries, lock contention, deadlocks, or table bloat in PostgreSQL or MySQL. Covers pg_stat_statements, EXPLAIN ANALYZE BUFFERS, lock wait queries, auto_explain, InnoDB status, Performance Schema, and optimizer trace.

## PostgreSQL Diagnostics

### Slow Query Investigation
```sql
-- Top queries by total time
SELECT query, calls, mean_exec_time::numeric(10,2) AS avg_ms,
       total_exec_time::numeric(10,2) AS total_ms,
       rows,
       ROUND(shared_blks_hit::numeric / NULLIF(shared_blks_hit + shared_blks_read, 0) * 100, 2) AS cache_hit_pct
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 20;

-- Analyze specific query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.*, c.name FROM orders o JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'pending' AND o.created_at > now() - interval '7 days';

-- Check for missing indexes
SELECT schemaname, tablename, seq_scan, seq_tup_read, idx_scan,
       ROUND(seq_scan::numeric / NULLIF(seq_scan + idx_scan, 0) * 100, 2) AS seq_scan_pct
FROM pg_stat_user_tables
WHERE seq_scan > 1000
ORDER BY seq_tup_read DESC;
```

### Lock Contention and Deadlocks
```sql
-- Active lock waits
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_query,
       blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Deadlock count
SELECT deadlocks FROM pg_stat_database WHERE datname = current_database();
-- postgresql.conf: log_lock_waits = on, deadlock_timeout = 1s
```

### Bloat and Wait Events
```sql
-- Table bloat estimate
SELECT schemaname, tablename, n_live_tup, n_dead_tup,
       ROUND(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) AS bloat_pct,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
       last_autovacuum
FROM pg_stat_user_tables WHERE n_dead_tup > 10000 ORDER BY n_dead_tup DESC;
-- Fix: VACUUM FULL (locks) or pg_repack (online)

-- Wait event analysis
SELECT wait_event_type, wait_event, COUNT(*) AS count
FROM pg_stat_activity
WHERE state = 'active' AND wait_event IS NOT NULL
GROUP BY wait_event_type, wait_event ORDER BY count DESC;
-- LWLock:BufferContent → increase shared_buffers
-- Lock:transactionid → long transactions
-- IO:DataFileRead → insufficient cache
```

### auto_explain Configuration
```sql
-- postgresql.conf
shared_preload_libraries = 'auto_explain'
auto_explain.log_min_duration = '100ms'
auto_explain.log_analyze = true
auto_explain.log_buffers = true
auto_explain.log_format = 'json'
```

## MySQL Diagnostics

### InnoDB and Performance Schema
```sql
-- Buffer pool hit ratio (target > 99%)
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool%';
-- Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests

-- Row lock contention
SHOW GLOBAL STATUS LIKE 'Innodb_row_lock%';
-- Innodb_row_lock_waits, Innodb_row_lock_time_avg

-- Comprehensive status
SHOW ENGINE INNODB STATUS\G
-- Check: LATEST DETECTED DEADLOCK, TRANSACTIONS, BUFFER POOL AND MEMORY

-- Query digest analysis
SELECT DIGEST_TEXT, COUNT_STAR,
       AVG_TIMER_WAIT/1000000000 AS avg_ms,
       MAX_TIMER_WAIT/1000000000 AS max_ms,
       ROUND(SUM_ROWS_EXAMINED/NULLIF(SUM_ROWS_SENT, 0), 0) AS examine_to_send_ratio
FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC LIMIT 20;
```

### Optimizer Trace
```sql
SET optimizer_trace = 'enabled=on';
SELECT * FROM orders WHERE customer_id = 123 AND status = 'pending';
SELECT * FROM information_schema.optimizer_trace\G
SET optimizer_trace = 'enabled=off';
-- Shows why optimizer chose a plan (index selection, join order, cost estimates)
```
