# PostgreSQL Deep-Dive Reference

## Configuration Tuning

### Memory Parameters

```ini
# === Memory ===
shared_buffers = '8GB'                  # 25% of total RAM; kernel will cache the rest
effective_cache_size = '24GB'           # 75% of RAM; planner hint, not allocation
work_mem = '64MB'                       # Per sort/hash op; conservative: (RAM / max_connections / 4)
maintenance_work_mem = '2GB'            # VACUUM, CREATE INDEX, ALTER TABLE ADD FK
huge_pages = 'try'                      # Enable HugePages (reduces TLB misses on Linux)
temp_buffers = '32MB'                   # Per-session temp table buffer

# === WAL ===
wal_level = 'replica'                   # 'logical' if using logical replication or CDC
max_wal_senders = 10                    # Max concurrent streaming replication connections
max_replication_slots = 10              # Track replication progress; one per subscriber + standby
wal_keep_size = '2GB'                   # Retain WAL for slow replicas (PG 13+)
checkpoint_completion_target = 0.9      # Spread checkpoint writes; reduce I/O spikes
checkpoint_timeout = '15min'            # Max time between checkpoints
max_wal_size = '8GB'                    # Trigger checkpoint if WAL exceeds this
min_wal_size = '1GB'                    # Pre-allocate WAL files
wal_compression = 'zstd'               # Compress WAL (PG 15+); reduces I/O and network
wal_buffers = '64MB'                    # WAL write buffer; -1 for auto (1/32 of shared_buffers)

# === Query Planner ===
random_page_cost = 1.1                  # SSD: 1.1, HDD: 4.0
seq_page_cost = 1.0                     # Keep at 1.0
effective_io_concurrency = 200          # SSD: 200, HDD: 2
jit = on                               # JIT compilation for complex queries (PG 11+)
jit_above_cost = 100000                 # Cost threshold for JIT activation

# === Parallelism ===
max_parallel_workers_per_gather = 4     # Max parallel workers per query node
max_parallel_workers = 8                # Total parallel workers system-wide
max_parallel_maintenance_workers = 4    # Parallel CREATE INDEX, VACUUM
parallel_setup_cost = 1000              # Lower to encourage parallelism
parallel_tuple_cost = 0.01              # Lower for wide result sets

# === Connections ===
max_connections = 200                   # Keep low; use PgBouncer for multiplexing
superuser_reserved_connections = 3      # Emergency access
```

### Logging for Diagnostics

```ini
log_min_duration_statement = '500ms'    # Log queries slower than 500ms
log_checkpoints = on                    # Log checkpoint activity
log_lock_waits = on                     # Log lock waits > deadlock_timeout
log_temp_files = '10MB'                 # Log temp file creation > 10MB
log_autovacuum_min_duration = '1s'      # Log autovacuum runs > 1 second
auto_explain.log_min_duration = '1s'    # auto_explain extension: log plans for slow queries
auto_explain.log_analyze = on           # Include EXPLAIN ANALYZE output
auto_explain.log_buffers = on           # Include buffer usage
```

---

## VACUUM Strategies

### How Autovacuum Works
PostgreSQL MVCC creates dead tuples on UPDATE/DELETE. VACUUM reclaims space and updates visibility maps. Autovacuum triggers when: `dead_tuples > autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor * n_live_tup)`.

### Tuning Autovacuum

```ini
# System-wide defaults
autovacuum_max_workers = 4                      # Increase for many tables
autovacuum_naptime = '30s'                      # Check frequency (default 1min)
autovacuum_vacuum_scale_factor = 0.05           # 5% dead tuples (default 20% is too high)
autovacuum_analyze_scale_factor = 0.02          # 2% changed tuples trigger re-analyze
autovacuum_vacuum_cost_delay = '2ms'            # Throttle I/O (default 2ms)
autovacuum_vacuum_cost_limit = 1000             # I/O tokens per round (default 200 is too slow)
```

### Per-Table Overrides for Hot Tables

```sql
ALTER TABLE hot_events SET (
    autovacuum_vacuum_scale_factor = 0.01,      -- More aggressive: 1%
    autovacuum_vacuum_cost_delay = '0ms',        -- No throttle for critical tables
    autovacuum_vacuum_cost_limit = 2000,
    autovacuum_analyze_scale_factor = 0.005
);
```

### Monitoring Bloat

```sql
-- Dead tuple ratio per table
SELECT schemaname, relname,
       n_dead_tup, n_live_tup,
       ROUND(100.0 * n_dead_tup / GREATEST(n_live_tup + n_dead_tup, 1), 2) AS pct_dead,
       last_autovacuum, last_autoanalyze,
       autovacuum_count, autoanalyze_count
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;

-- Estimated table bloat (pgstattuple extension)
CREATE EXTENSION IF NOT EXISTS pgstattuple;
SELECT * FROM pgstattuple('my_table');
-- Look at dead_tuple_percent and free_space
```

### pg_repack for Online Bloat Removal

```bash
# Install pg_repack extension
CREATE EXTENSION pg_repack;

# Repack a bloated table without exclusive locks
pg_repack -d mydb -t schema.bloated_table --no-superuser-check

# Repack all tables in a database
pg_repack -d mydb --all

# Repack specific indexes
pg_repack -d mydb -i schema.bloated_index
```

---

## Partitioning

### Declarative Partitioning (PG 10+)

```sql
-- Range partitioning (most common: time-based)
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMPTZ NOT NULL,
    customer_id BIGINT NOT NULL,
    total NUMERIC(12,2),
    status TEXT
) PARTITION BY RANGE (created_at);

-- Create partitions
CREATE TABLE orders_2024_q1 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE orders_2024_q2 PARTITION OF orders
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Default partition for unmatched rows
CREATE TABLE orders_default PARTITION OF orders DEFAULT;

-- List partitioning
CREATE TABLE events (
    id BIGINT, region TEXT, payload JSONB
) PARTITION BY LIST (region);

CREATE TABLE events_us PARTITION OF events FOR VALUES IN ('us-east', 'us-west');
CREATE TABLE events_eu PARTITION OF events FOR VALUES IN ('eu-west', 'eu-central');

-- Hash partitioning (even distribution)
CREATE TABLE sessions (
    id UUID, user_id BIGINT, data JSONB
) PARTITION BY HASH (user_id);

CREATE TABLE sessions_0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE sessions_2 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE sessions_3 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### pg_partman for Automation

```sql
CREATE EXTENSION pg_partman;

SELECT partman.create_parent(
    p_parent_table := 'public.orders',
    p_control := 'created_at',
    p_type := 'range',
    p_interval := '1 month',
    p_premake := 3              -- Pre-create 3 future partitions
);

-- Schedule maintenance (via pg_cron or external cron)
SELECT partman.run_maintenance();
```

### Partition Pruning Verification

```sql
-- Ensure enable_partition_pruning = on (default)
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE created_at >= '2024-03-01' AND created_at < '2024-04-01';
-- Should show: "Partitions selected: 1" (not scanning all partitions)
```

---

## Index Types

| Index Type | Use Case | Example |
|------------|----------|---------|
| B-tree | Equality, range, sorting (default) | `CREATE INDEX idx ON t(col)` |
| Hash | Equality only (rarely needed) | `CREATE INDEX idx ON t USING hash(col)` |
| GIN | JSONB, arrays, full-text search, trigram | `CREATE INDEX idx ON t USING gin(payload jsonb_path_ops)` |
| GiST | Geometric, range types, full-text (ranking) | `CREATE INDEX idx ON t USING gist(location)` |
| SP-GiST | Trie, quad-tree (IP, phone prefixes) | `CREATE INDEX idx ON t USING spgist(ip inet_ops)` |
| BRIN | Large sequential/append-only data | `CREATE INDEX idx ON t USING brin(created_at)` |

### Advanced Index Techniques

```sql
-- Partial index (only index active orders)
CREATE INDEX idx_orders_active ON orders(customer_id) WHERE status = 'active';

-- Covering index (index-only scan)
CREATE INDEX idx_orders_covering ON orders(customer_id) INCLUDE (total, status);

-- Expression index
CREATE INDEX idx_users_email_lower ON users(LOWER(email));

-- Multicolumn with specific ordering
CREATE INDEX idx_events_time_type ON events(created_at DESC, event_type ASC);

-- GIN for JSONB containment queries
CREATE INDEX idx_meta_gin ON documents USING gin(metadata jsonb_path_ops);
-- Query: SELECT * FROM documents WHERE metadata @> '{"type": "invoice"}';

-- GIN for array contains
CREATE INDEX idx_tags_gin ON articles USING gin(tags);
-- Query: SELECT * FROM articles WHERE tags @> ARRAY['postgres', 'tutorial'];

-- BRIN for time-series (extremely small index, ~1000x smaller than B-tree)
CREATE INDEX idx_logs_brin ON logs USING brin(created_at) WITH (pages_per_range = 32);
```

---

## Extensions Ecosystem

### Essential Extensions

| Extension | Purpose | Install |
|-----------|---------|---------|
| pg_stat_statements | Query performance tracking | `CREATE EXTENSION pg_stat_statements;` |
| pgAudit | SQL audit logging | `shared_preload_libraries = 'pgaudit'` |
| pg_cron | Scheduled jobs | `shared_preload_libraries = 'pg_cron'` |
| pg_repack | Online table/index repacking | `CREATE EXTENSION pg_repack;` |
| auto_explain | Automatic query plan logging | `shared_preload_libraries = 'auto_explain'` |
| pg_stat_monitor | Enhanced query monitoring (Percona) | `CREATE EXTENSION pg_stat_monitor;` |
| HypoPG | Hypothetical indexes (what-if) | `CREATE EXTENSION hypopg;` |

### Data & Analytics Extensions

| Extension | Purpose |
|-----------|---------|
| PostGIS | Geographic objects and spatial queries |
| pgvector | Vector similarity search (AI/ML embeddings) |
| TimescaleDB | Time-series hypertables, continuous aggregates |
| Citus | Distributed PostgreSQL (horizontal sharding) |
| pg_partman | Automated partition management |
| pg_hint_plan | Query plan hints (override planner) |
| pgroonga | Multilingual full-text search |
| pg_bigm | 2-gram based full-text search |

### pgvector Usage

```sql
CREATE EXTENSION vector;

CREATE TABLE embeddings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content TEXT,
    embedding vector(1536)  -- OpenAI ada-002 dimension
);

-- HNSW index (recommended for most use cases)
CREATE INDEX idx_embedding_hnsw ON embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Query: find 10 nearest neighbors
SELECT id, content, embedding <=> $1::vector AS distance
FROM embeddings
ORDER BY embedding <=> $1::vector
LIMIT 10;
```

---

## Replication

### Streaming Replication (Physical)

```ini
# Primary
wal_level = 'replica'
max_wal_senders = 10
wal_keep_size = '2GB'
synchronous_standby_names = ''         # Empty = async; 'standby1' = sync

# Standby (recovery.conf / postgresql.auto.conf)
primary_conninfo = 'host=primary port=5432 user=replicator'
restore_command = 'cp /archive/%f %p'
```

### Logical Replication (PG 10+)

```sql
-- Publisher (source)
CREATE PUBLICATION my_pub FOR TABLE orders, customers;
-- Or: CREATE PUBLICATION my_pub FOR ALL TABLES;

-- Subscriber (target)
CREATE SUBSCRIPTION my_sub
    CONNECTION 'host=publisher port=5432 dbname=mydb user=replicator'
    PUBLICATION my_pub;

-- Monitor replication lag
SELECT slot_name, confirmed_flush_lsn,
       pg_current_wal_lsn() - confirmed_flush_lsn AS lag_bytes
FROM pg_replication_slots;
```

### Use Cases for Logical Replication
- Cross-version upgrades (replicate PG 14 to PG 16).
- Selective table replication (subset of data to analytics).
- Multi-datacenter with bidirectional (using pglogical with conflict resolution).

---

## Connection Pooling

### PgBouncer Configuration

```ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

pool_mode = transaction              # transaction | session | statement
max_client_conn = 5000               # Max client connections to PgBouncer
default_pool_size = 25               # Connections per user/database pair to PG
min_pool_size = 5                    # Keep-alive connections
reserve_pool_size = 5                # Emergency connections
reserve_pool_timeout = 3             # Seconds before using reserve pool

server_lifetime = 3600               # Close server connection after 1 hour
server_idle_timeout = 600            # Close idle server connection after 10 min
server_check_query = SELECT 1        # Health check
server_check_delay = 30              # Health check interval
```

### Pool Mode Tradeoffs

| Mode | Session State | Prepared Statements | LISTEN/NOTIFY | Use Case |
|------|---------------|--------------------:|---------------|----------|
| Session | Full | Yes | Yes | Legacy apps, long transactions |
| Transaction | Reset between tx | No (use DEALLOCATE) | No | Web apps (recommended) |
| Statement | None | No | No | Simple autocommit queries |

---

## Monitoring

### Key pg_stat Views

```sql
-- Top queries by total time (pg_stat_statements)
SELECT query, calls, total_exec_time / 1000 AS total_sec,
       mean_exec_time AS avg_ms, rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 10;

-- Active sessions
SELECT pid, usename, datname, state, wait_event_type, wait_event,
       query, query_start, now() - query_start AS duration
FROM pg_stat_activity
WHERE state != 'idle' AND pid != pg_backend_pid()
ORDER BY duration DESC;

-- Table I/O statistics
SELECT schemaname, relname,
       seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch,
       n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables
ORDER BY seq_scan DESC LIMIT 10;

-- Cache hit ratio (should be > 99%)
SELECT
    sum(heap_blks_hit) / GREATEST(sum(heap_blks_hit) + sum(heap_blks_read), 1) AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Replication lag
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS replay_lag_bytes
FROM pg_stat_replication;
```

---

## Backup Strategies

### pg_basebackup (Physical)

```bash
# Full base backup with WAL streaming
pg_basebackup -h primary -U replicator -D /backups/base \
    --wal-method=stream --checkpoint=fast --progress -Ft -z

# Verify backup
pg_verifybackup /backups/base
```

### pgBackRest (Recommended for Production)

```ini
# /etc/pgbackrest/pgbackrest.conf
[global]
repo1-path=/backups/pgbackrest
repo1-retention-full=2
repo1-retention-diff=7
compress-type=zst
process-max=4

[mydb]
pg1-path=/var/lib/postgresql/16/main
```

```bash
# Full backup
pgbackrest --stanza=mydb backup --type=full

# Differential backup
pgbackrest --stanza=mydb backup --type=diff

# Point-in-time recovery
pgbackrest --stanza=mydb restore --type=time --target="2024-03-15 14:30:00"
```

---

## Security

### pg_hba.conf

```
# TYPE  DATABASE  USER        ADDRESS         METHOD
local   all       postgres                    peer
host    all       all         10.0.0.0/8      scram-sha-256
hostssl all       all         0.0.0.0/0       scram-sha-256
host    replication replicator 10.0.0.0/8     scram-sha-256
```

### Row-Level Security (RLS)

```sql
ALTER TABLE tenant_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON tenant_data
    USING (tenant_id = current_setting('app.current_tenant')::int);

-- Set tenant context per request
SET app.current_tenant = '42';
SELECT * FROM tenant_data;  -- Only sees tenant 42's data
```

### pgAudit Configuration

```ini
shared_preload_libraries = 'pgaudit'
pgaudit.log = 'ddl,role,write'        # Log DDL, role changes, and writes
pgaudit.log_catalog = off              # Skip system catalog queries
pgaudit.log_parameter = on            # Log query parameters
```

---

## Managed Options Comparison

| Feature | Aurora PG | AlloyDB | Neon | Supabase | Crunchy Bridge | Azure Flexible |
|---------|-----------|---------|------|----------|----------------|----------------|
| PG Version | 13-16 | 14-15 | 15-17 | 15-16 | 13-17 | 13-16 |
| Max Storage | 128 TB | 64 TB | 300 GB (free) | 8 GB (free) | 2 TB | 64 TB |
| Read Replicas | 15 | 20 | Instant branching | 2 (pro) | 1-5 | 5 |
| Scale to Zero | No (min ACU) | No | Yes | No | No | No |
| Branching | No | No | Yes (instant) | No | No | No |
| HA | Multi-AZ | Regional/cross-region | N/A | N/A | Yes | Zone-redundant |
| Extensions | Limited | Limited | Growing | Many (community) | Most | Citus, pgvector |
| Pricing Model | Instance + I/O | Instance + storage | Compute-hours | Instance | Instance | Instance |
| Best For | Enterprise AWS | HTAP, Google Cloud | Dev, serverless | Rapid prototyping | Multi-cloud PG | Azure ecosystem |
