# PostgreSQL Replication, Pooling, Security, and Managed Options

## When to load
Load when configuring streaming or logical replication, setting up PgBouncer, implementing RLS or pgAudit, running pg_basebackup/pgBackRest, or comparing Aurora/AlloyDB/Neon/Supabase.

## Streaming Replication (Physical)

```ini
# Primary
wal_level = 'replica'
max_wal_senders = 10
wal_keep_size = '2GB'
synchronous_standby_names = ''         # Empty = async; 'standby1' = sync

# Standby
primary_conninfo = 'host=primary port=5432 user=replicator'
restore_command = 'cp /archive/%f %p'
```

## Logical Replication

```sql
-- Publisher
CREATE PUBLICATION my_pub FOR TABLE orders, customers;

-- Subscriber
CREATE SUBSCRIPTION my_sub
    CONNECTION 'host=publisher port=5432 dbname=mydb user=replicator'
    PUBLICATION my_pub;

-- Monitor replication lag
SELECT slot_name, confirmed_flush_lsn,
       pg_current_wal_lsn() - confirmed_flush_lsn AS lag_bytes
FROM pg_replication_slots;
```

## PgBouncer Configuration

```ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
pool_mode = transaction
max_client_conn = 5000
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 5
server_lifetime = 3600
server_idle_timeout = 600
server_check_query = SELECT 1
```

| Mode | Session State | Prepared Statements | Use Case |
|------|---------------|---------------------|----------|
| Session | Full | Yes | Legacy apps, long transactions |
| Transaction | Reset between tx | No | Web apps (recommended) |
| Statement | None | No | Simple autocommit queries |

## Key Monitoring Queries

```sql
-- Top queries by total time
SELECT query, calls, total_exec_time / 1000 AS total_sec, mean_exec_time AS avg_ms
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;

-- Active sessions
SELECT pid, usename, datname, state, wait_event_type, wait_event,
       now() - query_start AS duration
FROM pg_stat_activity WHERE state != 'idle' AND pid != pg_backend_pid()
ORDER BY duration DESC;

-- Cache hit ratio (target >99%)
SELECT sum(heap_blks_hit) / GREATEST(sum(heap_blks_hit) + sum(heap_blks_read), 1) AS cache_hit_ratio
FROM pg_statio_user_tables;
```

## Backup

```bash
# pg_basebackup
pg_basebackup -h primary -U replicator -D /backups/base \
    --wal-method=stream --checkpoint=fast --progress -Ft -z

# pgBackRest
pgbackrest --stanza=mydb backup --type=full
pgbackrest --stanza=mydb backup --type=diff
pgbackrest --stanza=mydb restore --type=time --target="2024-03-15 14:30:00"
```

## Security

```
# pg_hba.conf
local   all       postgres                    peer
host    all       all         10.0.0.0/8      scram-sha-256
hostssl all       all         0.0.0.0/0       scram-sha-256
host    replication replicator 10.0.0.0/8     scram-sha-256
```

```sql
-- Row-Level Security
ALTER TABLE tenant_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON tenant_data
    USING (tenant_id = current_setting('app.current_tenant')::int);
SET app.current_tenant = '42';
```

## Managed Options Comparison

| Feature | Aurora PG | AlloyDB | Neon | Supabase | Azure Flexible |
|---------|-----------|---------|------|----------|----------------|
| PG Version | 13-16 | 14-15 | 15-17 | 15-16 | 13-16 |
| Max Storage | 128 TB | 64 TB | 300 GB (free) | 8 GB (free) | 64 TB |
| Scale to Zero | No | No | Yes | No | No |
| Branching | No | No | Yes (instant) | No | No |
| Best For | Enterprise AWS | HTAP, Google Cloud | Dev, serverless | Rapid prototyping | Azure ecosystem |
