# Engine-Specific Monitoring Queries

## When to load
Load when querying live monitoring data from PostgreSQL (pg_stat_statements, pg_stat_activity, pg_stat_user_tables), MySQL (Performance Schema, InnoDB status, sys schema), MongoDB (serverStatus, profiler, mongostat), or Redis (INFO, SLOWLOG, LATENCY).

## PostgreSQL

### pg_stat_statements — Top Queries
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT query, calls, mean_exec_time, total_exec_time,
       rows, shared_blks_hit, shared_blks_read
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 10;

SELECT pg_stat_statements_reset();
```

### pg_stat_activity — Current Sessions
```sql
SELECT pid, usename, application_name, state, wait_event_type, wait_event,
       query, age(clock_timestamp(), query_start) AS duration
FROM pg_stat_activity
WHERE state != 'idle' ORDER BY duration DESC;

SELECT pg_cancel_backend(pid);    -- graceful cancel
SELECT pg_terminate_backend(pid); -- force terminate
```

### pg_stat_user_tables — Table Health
```sql
SELECT schemaname, relname, n_live_tup, n_dead_tup,
       round(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) AS dead_pct,
       last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables WHERE n_dead_tup > 1000 ORDER BY n_dead_tup DESC;
```

### Table and Index Sizes
```sql
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
       pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) AS table_size,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename) -
                      pg_relation_size(schemaname || '.' || tablename)) AS index_size
FROM pg_tables WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC;
```

## MySQL

### Performance Schema and sys Schema
```sql
SELECT DIGEST_TEXT, COUNT_STAR, AVG_TIMER_WAIT/1000000000 AS avg_ms,
       SUM_TIMER_WAIT/1000000000 AS total_ms, SUM_ROWS_EXAMINED, SUM_ROWS_SENT
FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC LIMIT 10;

SELECT * FROM performance_schema.events_waits_current WHERE TIMER_WAIT > 0;

SHOW ENGINE INNODB STATUS\G
-- Check: SEMAPHORES, TRANSACTIONS, BUFFER POOL AND MEMORY, LOG

-- sys schema helpers
SELECT * FROM sys.statements_with_full_table_scans LIMIT 10;
SELECT * FROM sys.schema_unused_indexes;
SELECT * FROM sys.host_summary;
```

## MongoDB

### Server Status and Profiler
```javascript
db.serverStatus().opcounters       // operation counts
db.serverStatus().connections      // connection stats
db.serverStatus().wiredTiger.cache // storage engine cache
db.serverStatus().globalLock       // lock statistics

// Enable profiler for slow queries (> 100ms)
db.setProfilingLevel(1, { slowms: 100 });
db.system.profile.find().sort({ ts: -1 }).limit(10);
db.setProfilingLevel(0);
```

```bash
mongostat --rowcount=10 --uri="mongodb://..."  # real-time op counters
mongotop 5 --uri="mongodb://..."               # per-collection read/write time
```

## Redis

### INFO and SLOWLOG
```bash
redis-cli INFO memory       # used_memory, fragmentation_ratio
redis-cli INFO stats        # keyspace_hits/misses, evictions
redis-cli INFO replication  # role, connected_slaves, repl_offset
redis-cli INFO clients      # connected_clients, blocked_clients
redis-cli INFO keyspace     # keys per database, expires

redis-cli SLOWLOG GET 10
redis-cli CONFIG SET slowlog-log-slower-than 5000   # 5ms threshold
redis-cli CONFIG SET slowlog-max-len 256

redis-cli LATENCY LATEST
redis-cli LATENCY HISTORY command
redis-cli --latency              # continuous measurement
redis-cli --bigkeys              # find large keys
redis-cli --memkeys              # memory usage per key
```
