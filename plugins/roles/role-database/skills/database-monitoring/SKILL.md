---
name: database-monitoring
description: |
  Database monitoring, alerting, and observability across all engines. PostgreSQL (pg_stat_statements, pg_stat_activity, pg_stat_user_tables), MySQL (Performance Schema, sys schema, slow query log), MongoDB (mongostat, mongotop, profiler), Redis (INFO, SLOWLOG, LATENCY). Monitoring tools (Datadog, PMM, pganalyze, Grafana). Key metrics, alert thresholds, dashboard templates. Use when setting up database monitoring, troubleshooting performance, or configuring alerting.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Monitoring

## Key Metrics by Category

### Connection Metrics

| Metric | PostgreSQL | MySQL | MongoDB | Alert Threshold |
|--------|-----------|-------|---------|-----------------|
| **Active connections** | `pg_stat_activity` count | `SHOW PROCESSLIST` / `Threads_connected` | `db.serverStatus().connections` | > 80% of max |
| **Idle connections** | `state = 'idle'` | `Command = 'Sleep'` | — | > 50% of pool |
| **Waiting connections** | `wait_event IS NOT NULL` | `State = 'Waiting for...'` | `currentOp.waitingForLock` | > 0 sustained |
| **Connection errors** | `pg_stat_database.sessions_fatal` | `Connection_errors_*` | `db.serverStatus().connections` | Any increase |

### Query Performance Metrics

| Metric | PostgreSQL | MySQL | MongoDB | Alert |
|--------|-----------|-------|---------|-------|
| **Slow queries** | `pg_stat_statements` rows with high mean_exec_time | `slow_query_log` count | Profiler entries | Increasing trend |
| **Query latency p95/p99** | Derived from pg_stat_statements | Performance Schema digest | Profiler / Atlas | > 500ms (OLTP) |
| **Queries per second** | `pg_stat_database.xact_commit + xact_rollback` | `Questions` / `Com_*` | opcounters | Baseline deviation |
| **Long-running queries** | `pg_stat_activity` age > threshold | `SHOW PROCESSLIST` time > threshold | `db.currentOp()` | > 30 seconds |

### Storage Metrics

| Metric | Alert Threshold |
|--------|-----------------|
| **Disk usage** | > 80% capacity |
| **Disk I/O utilization** | > 80% sustained |
| **Table bloat** (PostgreSQL) | > 50% dead tuples |
| **Index bloat** | Index size > 3x data size |
| **WAL/binlog growth** | Unusual spikes |
| **Tablespace growth rate** | Exceeding capacity planning |

### Replication Metrics

| Metric | Alert Threshold |
|--------|-----------------|
| **Replication lag** | > 30 seconds (tune per use case) |
| **Replication slot lag** | > 1 GB unprocessed WAL |
| **Replica status** | Not streaming/applying |
| **ISR count** (Kafka) | < replication factor |

### Cache Metrics

| Metric | PostgreSQL | MySQL | Redis | Alert |
|--------|-----------|-------|-------|-------|
| **Cache hit ratio** | `pg_stat_database.blks_hit / (blks_hit + blks_read)` | `Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests` | `keyspace_hits / (keyspace_hits + keyspace_misses)` | < 95% |
| **Memory usage** | shared_buffers usage | Buffer pool pages | `used_memory` / `maxmemory` | > 90% |
| **Evictions** | — | `Innodb_buffer_pool_pages_flushed` | `evicted_keys` | Increasing |

## Engine-Specific Monitoring

### PostgreSQL

**pg_stat_statements (Top Queries)**
```sql
-- Enable
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top 10 by total time
SELECT query, calls, mean_exec_time, total_exec_time,
       rows, shared_blks_hit, shared_blks_read
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 10;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

**pg_stat_activity (Current Sessions)**
```sql
-- Active queries with wait events
SELECT pid, usename, application_name, state, wait_event_type, wait_event,
       query, age(clock_timestamp(), query_start) AS duration
FROM pg_stat_activity
WHERE state != 'idle' ORDER BY duration DESC;

-- Kill long-running query
SELECT pg_cancel_backend(pid);     -- graceful cancel
SELECT pg_terminate_backend(pid);  -- force terminate
```

**pg_stat_user_tables (Table Health)**
```sql
-- Tables needing VACUUM
SELECT schemaname, relname, n_live_tup, n_dead_tup,
       round(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) AS dead_pct,
       last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

**Table and Index Sizes**
```sql
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
       pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) AS table_size,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename) -
                      pg_relation_size(schemaname || '.' || tablename)) AS index_size
FROM pg_tables WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC;
```

### MySQL

**Performance Schema**
```sql
-- Top queries by total latency
SELECT DIGEST_TEXT, COUNT_STAR, AVG_TIMER_WAIT/1000000000 AS avg_ms,
       SUM_TIMER_WAIT/1000000000 AS total_ms, SUM_ROWS_EXAMINED, SUM_ROWS_SENT
FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC LIMIT 10;

-- Current wait events
SELECT * FROM performance_schema.events_waits_current WHERE TIMER_WAIT > 0;
```

**InnoDB Status**
```sql
SHOW ENGINE INNODB STATUS\G

-- Key sections to check:
-- SEMAPHORES: mutex/rw-lock contention
-- TRANSACTIONS: long-running, lock waits
-- BUFFER POOL AND MEMORY: hit rate, pages dirty
-- LOG: checkpoint age, log sequence number
```

**sys Schema (MySQL 5.7+)**
```sql
-- Statements with full table scans
SELECT * FROM sys.statements_with_full_table_scans LIMIT 10;

-- Tables with unused indexes
SELECT * FROM sys.schema_unused_indexes;

-- Host summary
SELECT * FROM sys.host_summary;
```

### MongoDB

**Server Status**
```javascript
// Overall health
db.serverStatus()

// Key sections:
db.serverStatus().opcounters       // operation counts
db.serverStatus().connections      // connection stats
db.serverStatus().wiredTiger.cache // storage engine cache
db.serverStatus().globalLock       // lock statistics
db.serverStatus().mem              // memory usage
```

**mongostat and mongotop**
```bash
# Real-time operation counters
mongostat --rowcount=10 --uri="mongodb://..."

# Per-collection read/write time
mongotop 5 --uri="mongodb://..."
```

**Profiler**
```javascript
// Enable profiling for slow queries (> 100ms)
db.setProfilingLevel(1, { slowms: 100 });

// Query profiler data
db.system.profile.find().sort({ ts: -1 }).limit(10);

// Disable profiling
db.setProfilingLevel(0);
```

### Redis

**INFO Command**
```bash
# All sections
redis-cli INFO

# Specific sections
redis-cli INFO memory       # used_memory, fragmentation_ratio
redis-cli INFO stats        # keyspace_hits/misses, evictions
redis-cli INFO replication  # role, connected_slaves, repl_offset
redis-cli INFO clients      # connected_clients, blocked_clients
redis-cli INFO keyspace     # keys per database, expires
```

**SLOWLOG**
```bash
# Get slow queries (default threshold: 10ms)
redis-cli SLOWLOG GET 10

# Configure threshold
redis-cli CONFIG SET slowlog-log-slower-than 5000  # 5ms in microseconds
redis-cli CONFIG SET slowlog-max-len 256
```

**LATENCY**
```bash
redis-cli LATENCY LATEST
redis-cli LATENCY HISTORY command
redis-cli --latency              # continuous latency measurement
redis-cli --latency-history      # latency over time
redis-cli --bigkeys              # find large keys
redis-cli --memkeys              # memory usage per key
```

## Monitoring Tools

| Tool | Type | Best For | Cost |
|------|------|----------|------|
| **Datadog Database Monitoring** | SaaS | Multi-engine, query-level insights | Per host |
| **Percona PMM** | Open source | MySQL, PostgreSQL, MongoDB | Free |
| **pganalyze** | SaaS | PostgreSQL deep analysis | Per database |
| **New Relic Database** | SaaS | Multi-engine, APM integration | Per host |
| **Prometheus + Grafana** | Open source | Custom metrics, alerting | Free |
| **VividCortex (SolarWinds DPM)** | SaaS | MySQL, PostgreSQL | Per host |
| **pg_stat_monitor** | Extension | PostgreSQL (Percona) | Free |
| **Zabbix** | Open source | Infrastructure + database | Free |

### Prometheus Exporters
```yaml
# PostgreSQL
- postgres_exporter (prometheus-community)
  # Key metrics: pg_stat_activity, pg_stat_statements, replication lag

# MySQL
- mysqld_exporter (prometheus-community)
  # Key metrics: mysql_global_status, mysql_slave_status

# MongoDB
- mongodb_exporter (percona)
  # Key metrics: mongodb_mongod_op_counters, mongodb_connections

# Redis
- redis_exporter (oliver006)
  # Key metrics: redis_connected_clients, redis_memory_used_bytes
```

## Alert Configuration

### Critical Alerts (Page Immediately)
- Database unreachable / connection refused
- Replication broken (replica not streaming)
- Disk space > 90%
- Deadlock rate increasing
- Backup job failed

### Warning Alerts (Investigate During Business Hours)
- Replication lag > 30 seconds
- Cache hit ratio < 95%
- Connection count > 80% of max
- Slow query rate increasing > 20% from baseline
- Table bloat > 50% dead tuples
- Long-running queries > 5 minutes

### Informational (Dashboard Only)
- Query latency p50/p95/p99 trends
- Throughput (QPS) trends
- Storage growth rate
- Index usage statistics
- Connection pool utilization

## Dashboard Essentials

### Minimum Viable Database Dashboard
1. **Connection pool utilization** — are we running out of connections?
2. **Query latency distribution** (p50/p95/p99) — are queries getting slower?
3. **Error rate** — are queries failing?
4. **Replication lag** — is data consistent across replicas?
5. **Disk usage and growth** — when do we need more storage?
6. **Cache hit ratio** — is our buffer/cache working effectively?
7. **Top N slow queries** — what should we optimize?
8. **Lock waits** — are there contention issues?
