---
name: role-database:performance-diagnostics
description: |
  Database performance troubleshooting across all engines. PostgreSQL (pg_stat_statements, auto_explain, pg_locks, EXPLAIN ANALYZE BUFFERS), MySQL (EXPLAIN FORMAT=TREE, Performance Schema, InnoDB status, optimizer trace), MongoDB (explain executionStats, currentOp, profiler), Redis (SLOWLOG, LATENCY, MEMORY DOCTOR, bigkeys). Lock contention, deadlocks, I/O bottlenecks, memory pressure, benchmarking (pgbench, sysbench, YCSB). Use when troubleshooting slow queries, diagnosing lock contention, or investigating database performance issues.
allowed-tools: Read, Grep, Glob, Bash
---

# Performance Diagnostics

## Diagnostic Methodology

1. **Identify the symptom**: Slow queries? High CPU? Connection exhaustion? Lock waits?
2. **Establish baseline**: What's normal? Compare current metrics to historical
3. **Narrow the scope**: Is it one query, one table, one connection, or systemic?
4. **Analyze the cause**: Use EXPLAIN, wait events, system metrics
5. **Fix and verify**: Apply fix, measure improvement, monitor for regression

## Reference Files

Load from `references/` based on what's needed:

### references/postgres-mysql-diagnostics.md
PostgreSQL: pg_stat_statements top queries, EXPLAIN ANALYZE BUFFERS, lock wait query, deadlock detection, bloat estimation, wait event analysis, auto_explain config.
MySQL: InnoDB buffer pool hit ratio, row lock stats, SHOW ENGINE INNODB STATUS, Performance Schema query digest, optimizer trace.
Load when: diagnosing performance issues in PostgreSQL or MySQL.

### references/mongodb-redis-benchmarking.md
MongoDB: profiler setup, explain executionStats, currentOp kill long-running operations.
Redis: latency measurement, memory analysis (bigkeys, MEMORY DOCTOR), SLOWLOG configuration.
Common issues/fixes table covering CPU, I/O, locks, deadlocks, connections, memory, replication, disk.
pgbench, sysbench, redis-benchmark usage.
Load when: diagnosing MongoDB/Redis issues or running performance benchmarks.
