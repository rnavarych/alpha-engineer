# PostgreSQL Configuration and VACUUM

## When to load
Load when tuning postgresql.conf parameters, diagnosing autovacuum issues, bloat removal, or setting up logging for slow query analysis.

## Memory and WAL Parameters

```ini
shared_buffers = '8GB'                  # 25% of total RAM
effective_cache_size = '24GB'           # 75% of RAM; planner hint
work_mem = '64MB'                       # Per sort/hash op
maintenance_work_mem = '2GB'            # VACUUM, CREATE INDEX, ALTER TABLE ADD FK
huge_pages = 'try'                      # Reduce TLB misses on Linux
temp_buffers = '32MB'                   # Per-session temp table buffer

wal_level = 'replica'                   # 'logical' for logical replication or CDC
max_wal_senders = 10
max_replication_slots = 10
wal_keep_size = '2GB'
checkpoint_completion_target = 0.9
checkpoint_timeout = '15min'
max_wal_size = '8GB'
min_wal_size = '1GB'
wal_compression = 'zstd'               # PG 15+
wal_buffers = '64MB'

random_page_cost = 1.1                  # SSD: 1.1, HDD: 4.0
seq_page_cost = 1.0
effective_io_concurrency = 200          # SSD: 200, HDD: 2
jit = on
jit_above_cost = 100000

max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4
max_connections = 200                   # Keep low; use PgBouncer
superuser_reserved_connections = 3
```

## Logging for Diagnostics

```ini
log_min_duration_statement = '500ms'
log_checkpoints = on
log_lock_waits = on
log_temp_files = '10MB'
log_autovacuum_min_duration = '1s'
auto_explain.log_min_duration = '1s'
auto_explain.log_analyze = on
auto_explain.log_buffers = on
```

## Autovacuum Tuning

```ini
autovacuum_max_workers = 4
autovacuum_naptime = '30s'
autovacuum_vacuum_scale_factor = 0.05   # 5% dead tuples (default 20% too high)
autovacuum_analyze_scale_factor = 0.02
autovacuum_vacuum_cost_delay = '2ms'
autovacuum_vacuum_cost_limit = 1000
```

### Per-Table Overrides for Hot Tables

```sql
ALTER TABLE hot_events SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_vacuum_cost_delay = '0ms',
    autovacuum_vacuum_cost_limit = 2000,
    autovacuum_analyze_scale_factor = 0.005
);
```

## Monitoring Bloat

```sql
SELECT schemaname, relname,
       n_dead_tup, n_live_tup,
       ROUND(100.0 * n_dead_tup / GREATEST(n_live_tup + n_dead_tup, 1), 2) AS pct_dead,
       last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;
```

## pg_repack for Online Bloat Removal

```bash
CREATE EXTENSION pg_repack;
pg_repack -d mydb -t schema.bloated_table --no-superuser-check
pg_repack -d mydb --all
pg_repack -d mydb -i schema.bloated_index
```
