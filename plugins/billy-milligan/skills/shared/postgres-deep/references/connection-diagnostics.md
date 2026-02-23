# PostgreSQL Connection Diagnostics

## When to Load
Load when debugging connection exhaustion, monitoring active connections and pool health, or troubleshooting slow queries caused by connection saturation.

## Monitoring PgBouncer

```sql
-- Connect to PgBouncer admin interface:
-- psql -h pgbouncer -p 5432 -U pgbouncer_admin pgbouncer

-- Pool statistics
SHOW POOLS;
-- database | user | cl_active | cl_waiting | sv_active | sv_idle | sv_used | maxwait
-- cl_waiting > 0 → pool exhausted; clients waiting for connections
-- maxwait > 1    → latency being added to all queries

SHOW CLIENTS;   -- Current clients connected to PgBouncer
SHOW SERVERS;   -- Server connections to PostgreSQL
SHOW STATS;     -- total_requests, avg_req, avg_query
```

### Key Alert Thresholds

```
cl_waiting > 0          → increase pool size or scale PostgreSQL
maxwait > 100ms         → pool is a bottleneck
sv_idle / sv_active     → utilization rate; if sv_idle=0, fully saturated
```

## pg_stat_activity — Live Connection View

```sql
-- All active connections right now
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  wait_event_type,
  wait_event,
  EXTRACT(EPOCH FROM (NOW() - query_start))::INT AS query_age_secs,
  LEFT(query, 120) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_age_secs DESC NULLS LAST;

-- Count connections by state
SELECT state, COUNT(*)
FROM pg_stat_activity
GROUP BY state
ORDER BY count DESC;

-- Find long-running queries (> 30 seconds)
SELECT pid, usename, query_start, state,
  EXTRACT(EPOCH FROM (NOW() - query_start))::INT AS secs,
  LEFT(query, 200) AS query
FROM pg_stat_activity
WHERE query_start < NOW() - INTERVAL '30 seconds'
  AND state != 'idle';

-- Kill a stuck query (safe — rolls back transaction)
SELECT pg_cancel_backend(pid);

-- Hard terminate (use when pg_cancel_backend doesn't work)
SELECT pg_terminate_backend(pid);
```

## PgBouncer with Kubernetes

```yaml
# Deploy PgBouncer as a sidecar or DaemonSet
# Sidecar: per-pod PgBouncer, app connects to localhost
# DaemonSet: per-node PgBouncer, apps connect to node IP

apiVersion: v1
kind: Secret
metadata:
  name: pgbouncer-config
stringData:
  pgbouncer.ini: |
    [databases]
    orderdb = host=postgres.prod.svc.cluster.local dbname=orderdb
    [pgbouncer]
    pool_mode = transaction
    default_pool_size = 25
    max_client_conn = 500
    listen_addr = *
    listen_port = 5432
    auth_type = scram-sha-256
    auth_file = /etc/pgbouncer/userlist.txt
  userlist.txt: |
    "app_user" "SCRAM-SHA-256$4096:..."
```

## Troubleshooting Runbook

```
Symptom: "remaining connection slots are reserved for non-replication superuser connections"
  → max_connections reached; check pg_stat_activity; kill idle connections; increase pool
  → Long-term: lower max_connections, route everything through PgBouncer

Symptom: queries suddenly slow, cl_waiting spikes
  → Pool exhausted; check if a migration/long transaction is holding connections
  → SELECT pid, query_start, state, query FROM pg_stat_activity ORDER BY query_start;
  → Identify and cancel long-running idle-in-transaction sessions

Symptom: "ERROR: prepared statement does not exist"
  → ORMs sending named prepared statements through PgBouncer transaction mode
  → Fix: prepare: false (postgres.js) or disablePreparedStatements: true (Prisma)

Symptom: intermittent connection errors after replica failover
  → PgBouncer holds stale connections to old primary
  → Fix: server_lifetime = 3600 ensures rotation; or RECONNECT in PgBouncer admin
```

## Quick Reference

```
SHOW POOLS: cl_waiting > 0 → pool exhausted
SHOW STATS: avg_query rising → DB under pressure, not pool
pg_stat_activity: find long-running queries and idle-in-transaction sessions
pg_cancel_backend(pid): graceful query cancel
pg_terminate_backend(pid): hard kill (use after cancel fails)
server_lifetime = 3600: prevents stale connections after replica rotation
```
