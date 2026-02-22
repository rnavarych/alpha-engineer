---
name: performance-diagnostics
description: |
  Database performance troubleshooting across all engines. PostgreSQL (pg_stat_statements, auto_explain, pg_locks, EXPLAIN ANALYZE BUFFERS), MySQL (EXPLAIN FORMAT=TREE, Performance Schema, InnoDB status, optimizer trace), MongoDB (explain executionStats, currentOp, profiler), Redis (SLOWLOG, LATENCY, MEMORY DOCTOR, bigkeys). Lock contention, deadlocks, I/O bottlenecks, memory pressure, benchmarking (pgbench, sysbench, YCSB). Use when troubleshooting slow queries, diagnosing lock contention, or investigating database performance issues.
allowed-tools: Read, Grep, Glob, Bash
---

# Performance Diagnostics

## Diagnostic Methodology

### Step-by-Step Approach
1. **Identify the symptom**: Slow queries? High CPU? Connection exhaustion? Lock waits?
2. **Establish baseline**: What's normal? Compare current metrics to historical
3. **Narrow the scope**: Is it one query, one table, one connection, or systemic?
4. **Analyze the cause**: Use EXPLAIN, wait events, system metrics
5. **Fix and verify**: Apply fix, measure improvement, monitor for regression

## PostgreSQL Diagnostics

### Slow Query Investigation
```sql
-- Step 1: Find top queries by total time
SELECT query, calls, mean_exec_time::numeric(10,2) AS avg_ms,
       total_exec_time::numeric(10,2) AS total_ms,
       rows, shared_blks_hit, shared_blks_read,
       ROUND(shared_blks_hit::numeric / NULLIF(shared_blks_hit + shared_blks_read, 0) * 100, 2) AS cache_hit_pct
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 20;

-- Step 2: Analyze specific query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.*, c.name FROM orders o JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'pending' AND o.created_at > now() - interval '7 days';

-- Step 3: Check for missing indexes
SELECT schemaname, tablename, seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch,
       ROUND(seq_scan::numeric / NULLIF(seq_scan + idx_scan, 0) * 100, 2) AS seq_scan_pct
FROM pg_stat_user_tables
WHERE seq_scan > 1000
ORDER BY seq_tup_read DESC;
```

### Lock Contention
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
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### Deadlock Detection
```sql
-- Check for recent deadlocks in PostgreSQL log
-- postgresql.conf: log_lock_waits = on, deadlock_timeout = 1s

-- Monitor deadlock count
SELECT deadlocks FROM pg_stat_database WHERE datname = current_database();
```

### Bloat Detection
```sql
-- Table bloat estimate
SELECT schemaname, tablename, n_live_tup, n_dead_tup,
       ROUND(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) AS bloat_pct,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
       last_vacuum, last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;

-- Fix: VACUUM FULL (locks table) or pg_repack (online)
-- pg_repack --table=orders --no-superuser-check -d mydb
```

### Wait Event Analysis
```sql
-- What are connections waiting on?
SELECT wait_event_type, wait_event, COUNT(*) AS count
FROM pg_stat_activity
WHERE state = 'active' AND wait_event IS NOT NULL
GROUP BY wait_event_type, wait_event
ORDER BY count DESC;

-- Common wait events:
-- LWLock: BufferContent → high concurrent writes, increase shared_buffers
-- Lock: transactionid → long transactions blocking others
-- IO: DataFileRead → insufficient shared_buffers or high I/O demand
-- Client: ClientRead → application not consuming results fast enough
```

### auto_explain for Slow Query Plans
```sql
-- postgresql.conf
shared_preload_libraries = 'auto_explain'
auto_explain.log_min_duration = '100ms'  -- log plans for queries > 100ms
auto_explain.log_analyze = true
auto_explain.log_buffers = true
auto_explain.log_format = 'json'
```

## MySQL Diagnostics

### InnoDB Performance
```sql
-- Buffer pool efficiency
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool%';
-- Key: Innodb_buffer_pool_read_requests vs Innodb_buffer_pool_reads
-- Hit ratio = 1 - (reads / read_requests), target > 99%

-- Row lock contention
SHOW GLOBAL STATUS LIKE 'Innodb_row_lock%';
-- Innodb_row_lock_waits: number of times a row lock had to wait
-- Innodb_row_lock_time_avg: average wait time in milliseconds

-- InnoDB status (comprehensive)
SHOW ENGINE INNODB STATUS\G
-- Check: LATEST DETECTED DEADLOCK, TRANSACTIONS, BUFFER POOL AND MEMORY
```

### Performance Schema Wait Events
```sql
-- Top wait events
SELECT event_name, COUNT_STAR, SUM_TIMER_WAIT/1000000000 AS total_wait_ms
FROM performance_schema.events_waits_summary_global_by_event_name
WHERE COUNT_STAR > 0
ORDER BY SUM_TIMER_WAIT DESC LIMIT 20;

-- Query digest analysis
SELECT DIGEST_TEXT, COUNT_STAR,
       AVG_TIMER_WAIT/1000000000 AS avg_ms,
       MAX_TIMER_WAIT/1000000000 AS max_ms,
       SUM_ROWS_EXAMINED, SUM_ROWS_SENT,
       ROUND(SUM_ROWS_EXAMINED/NULLIF(SUM_ROWS_SENT, 0), 0) AS examine_to_send_ratio
FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC LIMIT 20;
```

### Optimizer Trace (MySQL)
```sql
SET optimizer_trace = 'enabled=on';
SELECT * FROM orders WHERE customer_id = 123 AND status = 'pending';
SELECT * FROM information_schema.optimizer_trace\G
SET optimizer_trace = 'enabled=off';
-- Shows why optimizer chose a particular plan (index selection, join order, cost estimates)
```

## MongoDB Diagnostics

### Slow Query Analysis
```javascript
// Enable profiler for queries > 50ms
db.setProfilingLevel(1, { slowms: 50 });

// Analyze slow queries
db.system.profile.find({
    millis: { $gt: 100 },
    op: { $in: ["query", "update", "remove"] }
}).sort({ ts: -1 }).limit(10);

// Explain with execution stats
db.orders.find({ status: "pending", customer_id: ObjectId("...") })
    .explain("executionStats");

// Key metrics in explain:
// totalDocsExamined vs nReturned (ratio should approach 1:1)
// totalKeysExamined: how many index entries scanned
// executionTimeMillis: total time
// stage: COLLSCAN = bad, IXSCAN = good
```

### Current Operations
```javascript
// Find long-running operations
db.currentOp({
    "active": true,
    "secs_running": { "$gt": 5 },
    "op": { "$ne": "none" }
});

// Kill long-running operation
db.killOp(opId);
```

## Redis Diagnostics

### Latency Analysis
```bash
# Continuous latency measurement
redis-cli --latency
# Output: min: 0, max: 15, avg: 0.12 (2038 samples)

# Latency history (10-second windows)
redis-cli --latency-history -i 10

# Intrinsic latency measurement (system-level)
redis-cli --intrinsic-latency 5
# Shows baseline latency of the system

# Latency monitoring
redis-cli LATENCY LATEST
redis-cli LATENCY HISTORY <event-name>
```

### Memory Analysis
```bash
# Memory overview
redis-cli INFO memory
# used_memory: total allocated
# used_memory_rss: resident set (actual OS memory)
# mem_fragmentation_ratio: RSS/used (>1.5 = fragmentation problem)
# used_memory_peak: historical peak

# Find big keys (sampled scan, safe for production)
redis-cli --bigkeys

# Memory usage per key
redis-cli MEMORY USAGE mykey

# Memory doctor (diagnostics)
redis-cli MEMORY DOCTOR
```

### Slowlog
```bash
# View slow commands (default threshold: 10ms)
redis-cli SLOWLOG GET 25

# Each entry shows: id, timestamp, duration (microseconds), command + args
# Configure threshold
redis-cli CONFIG SET slowlog-log-slower-than 5000  # 5ms

# Common slow commands: KEYS *, SORT, SMEMBERS on large sets, LRANGE on large lists
# Fix: Use SCAN instead of KEYS, paginate with SSCAN/HSCAN/ZSCAN
```

## Common Performance Issues and Fixes

| Symptom | Likely Cause | Diagnostic | Fix |
|---------|-------------|-----------|-----|
| High CPU | Missing indexes, bad queries | EXPLAIN, pg_stat_statements | Add indexes, rewrite queries |
| High I/O | Table scans, insufficient cache | EXPLAIN BUFFERS, cache hit ratio | Increase shared_buffers, add indexes |
| Lock waits | Long transactions, hot rows | pg_locks, InnoDB status | Shorter transactions, advisory locks |
| Deadlocks | Inconsistent lock ordering | Deadlock logs | Consistent access ordering, retry logic |
| Connection exhaustion | No pooling, leaks | Connection count monitoring | PgBouncer, fix leaks, increase pool |
| Memory pressure | Large queries, sorts | work_mem, sort method | Increase work_mem, add indexes to avoid sorts |
| Replication lag | Heavy writes, slow replica | Replication monitoring | Faster replica, parallel apply |
| Disk full | WAL accumulation, bloat | Disk monitoring, slot lag | Clean WAL, VACUUM, fix stuck replication slots |

## Benchmarking

### pgbench (PostgreSQL)
```bash
# Initialize (scale 100 ≈ 1.5 GB)
pgbench -i -s 100 mydb

# Read-heavy test
pgbench -c 20 -j 4 -T 300 -S mydb  # -S = select-only

# Read-write test
pgbench -c 20 -j 4 -T 300 mydb

# Key output: TPS (transactions per second), latency average and stddev
```

### sysbench (MySQL/PostgreSQL)
```bash
# OLTP read-write
sysbench oltp_read_write --db-driver=pgsql --pgsql-host=host --pgsql-db=test \
    --tables=10 --table-size=1000000 --threads=16 --time=300 run
```

### redis-benchmark
```bash
# Default benchmark
redis-benchmark -h host -p 6379 -c 50 -n 100000

# Pipeline mode (batch commands)
redis-benchmark -h host -p 6379 -c 50 -n 100000 -P 16 -t set,get

# Key metrics: requests per second, latency percentiles
```

## Quick Reference

1. **Start with monitoring data** — never guess, always measure
2. **Check EXPLAIN first** for query issues
3. **Monitor wait events** to understand what the database is waiting on
4. **Track lock contention** — deadlocks and long waits indicate design issues
5. **Watch cache hit ratios** — below 95% means memory is insufficient
6. **Profile before optimizing** — use pg_stat_statements, Performance Schema, profiler
7. **Benchmark with realistic data** — performance changes dramatically with scale
8. **Document findings** — record what you found and what you changed
