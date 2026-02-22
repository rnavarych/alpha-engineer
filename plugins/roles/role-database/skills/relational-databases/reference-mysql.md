# MySQL / MariaDB Deep-Dive Reference

## InnoDB Tuning

### Buffer Pool

```ini
# Primary tuning target: 70-80% of RAM on dedicated MySQL server
innodb_buffer_pool_size = 24G

# Multiple instances reduce contention (1 per GB, max 64)
innodb_buffer_pool_instances = 8

# Dump/load buffer pool on restart for warm cache
innodb_buffer_pool_dump_at_shutdown = ON
innodb_buffer_pool_load_at_startup = ON
innodb_buffer_pool_dump_pct = 40        # Dump 40% of hottest pages
```

### Redo Log and Durability

```ini
# MySQL 8.0.30+ unified redo log capacity (replaces innodb_log_file_size * innodb_log_files_in_group)
innodb_redo_log_capacity = 8G           # Larger = fewer checkpoints, longer crash recovery

# Pre-8.0.30: two redo log files
innodb_log_file_size = 2G
innodb_log_files_in_group = 2

# Durability vs performance tradeoff
innodb_flush_log_at_trx_commit = 1      # 1 = ACID (fsync per commit)
                                         # 2 = fsync per second (risk 1s data loss)
                                         # 0 = fsync per second + buffer flush per second

# Flushing
innodb_flush_method = O_DIRECT           # Bypass OS cache (avoid double buffering)
innodb_flush_neighbors = 0               # Disable for SSD (enable for HDD)
```

### I/O Configuration

```ini
innodb_io_capacity = 2000               # Baseline IOPS (SSD: 2000-10000, HDD: 200)
innodb_io_capacity_max = 4000           # Burst IOPS
innodb_read_io_threads = 8              # Read threads (default 4)
innodb_write_io_threads = 8             # Write threads (default 4)
innodb_page_cleaners = 4                # Buffer pool page cleaner threads
```

### Change Buffer and Adaptive Hash Index

```ini
innodb_change_buffer_max_size = 25      # % of buffer pool for buffering secondary index changes
innodb_change_buffering = all            # Buffer: inserts, deletes, purges, changes, all, none

innodb_adaptive_hash_index = ON          # Auto-hash index for hot pages
innodb_adaptive_hash_index_parts = 8     # Partition AHI to reduce contention
```

### Doublewrite Buffer

```ini
innodb_doublewrite = ON                  # Crash safety for torn pages
innodb_doublewrite_dir = /fast_ssd/dblwr # Separate fast storage (8.0.20+)
innodb_doublewrite_pages = 64            # Pages per batch write
```

### Thread and Connection Tuning

```ini
innodb_thread_concurrency = 0            # Let InnoDB manage (0 = unlimited)
innodb_purge_threads = 4                 # Undo purge parallelism
innodb_rollback_segments = 128           # Max undo rollback segments

max_connections = 500                    # Adjust to workload (monitor Threads_connected)
thread_cache_size = 64                   # Cache threads for reuse
table_open_cache = 4096                  # Cached open table handles
table_open_cache_instances = 16          # Reduce mutex contention
```

---

## Replication

### Asynchronous Replication (Default)

```ini
# Source (primary)
server-id = 1
log_bin = mysql-bin
binlog_format = ROW                      # ROW is required for GTID, Group Replication
gtid_mode = ON
enforce_gtid_consistency = ON
binlog_expire_logs_seconds = 604800      # 7 days retention

# Replica
server-id = 2
relay_log = relay-bin
read_only = ON
super_read_only = ON                     # Prevent even SUPER from writing
replica_parallel_workers = 8             # Parallel applier threads
replica_parallel_type = LOGICAL_CLOCK    # Order-preserving parallelism
replica_preserve_commit_order = ON       # Maintain commit order
```

### Semi-Synchronous Replication

```sql
-- On source
INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.so';
SET GLOBAL rpl_semi_sync_source_enabled = ON;
SET GLOBAL rpl_semi_sync_source_wait_for_replica_count = 1;  -- Wait for 1 replica ACK
SET GLOBAL rpl_semi_sync_source_timeout = 5000;               -- Fallback to async after 5s

-- On replica
INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.so';
SET GLOBAL rpl_semi_sync_replica_enabled = ON;
```

### Group Replication / InnoDB Cluster

```sql
-- Bootstrap single-primary Group Replication
SET GLOBAL group_replication_group_name = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
SET GLOBAL group_replication_local_address = "node1:33061";
SET GLOBAL group_replication_group_seeds = "node1:33061,node2:33061,node3:33061";
SET GLOBAL group_replication_single_primary_mode = ON;      -- Single-primary (recommended)
SET GLOBAL group_replication_bootstrap_group = ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group = OFF;

-- InnoDB Cluster via MySQL Shell
mysqlsh -- dba.createCluster('myCluster')
mysqlsh -- cluster.addInstance('node2:3306')
mysqlsh -- cluster.addInstance('node3:3306')
mysqlsh -- cluster.status()
```

### InnoDB ClusterSet (Multi-Region DR)

```javascript
// MySQL Shell
cluster = dba.getCluster()
clusterset = cluster.createClusterSet('myClusterSet')
replicaCluster = clusterset.createReplicaCluster('dr-node1:3306', 'dr-cluster')
replicaCluster.addInstance('dr-node2:3306')

// Controlled switchover
clusterset.setPrimaryCluster('dr-cluster')

// Emergency failover (data loss possible)
clusterset.forcePrimaryCluster('dr-cluster')
```

---

## Sharding with Vitess

### Architecture
- **vtgate**: Query router and API gateway. Parses SQL, plans cross-shard queries.
- **vttablet**: Per-MySQL agent. Connection pooling, query rewriting, health checking.
- **vtctld**: Control plane. Schema management, resharding orchestration.
- **topology**: Metadata store (etcd, ZooKeeper, or Consul).

### VSchema Configuration

```json
{
  "sharded": true,
  "vindexes": {
    "hash": { "type": "hash" },
    "lookup_unique": {
      "type": "lookup_unique",
      "params": {
        "table": "user_email_idx",
        "from": "email",
        "to": "user_id"
      }
    }
  },
  "tables": {
    "users": {
      "column_vindexes": [
        { "column": "id", "name": "hash" },
        { "column": "email", "name": "lookup_unique" }
      ]
    },
    "orders": {
      "column_vindexes": [
        { "column": "user_id", "name": "hash" }
      ]
    }
  }
}
```

### Online DDL

```sql
-- Vitess online DDL (non-blocking schema changes)
ALTER TABLE users ADD COLUMN avatar_url VARCHAR(512);
-- Vitess uses: vitess (default), gh-ost, or pt-osc strategy

-- Check migration status
SHOW VITESS_MIGRATIONS LIKE 'users' \G
```

### Resharding Workflow

```bash
# Move tables between keyspaces
vtctldclient MoveTables --target-keyspace=commerce --workflow=move_orders create --source-keyspace=main --tables=orders

# Reshard from 2 shards to 4 shards
vtctldclient Reshard --target-keyspace=commerce --workflow=reshard_4 create --source-shards='-80,80-' --target-shards='-40,40-80,80-c0,c0-'

# Switch traffic
vtctldclient MoveTables --target-keyspace=commerce --workflow=move_orders switchtraffic
vtctldclient MoveTables --target-keyspace=commerce --workflow=move_orders complete
```

---

## ProxySQL

### Core Configuration

```sql
-- Admin interface (port 6032)
-- Query routing rules
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES
    (1, 1, '^SELECT .* FOR UPDATE', 0, 1),    -- Writes to writer group
    (2, 1, '^SELECT', 1, 1),                   -- Reads to reader group
    (3, 1, '.*', 0, 1);                        -- Default to writer group

-- Server configuration
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight, max_connections)
VALUES
    (0, 'primary.mysql.local', 3306, 1000, 200),   -- Writer
    (1, 'replica1.mysql.local', 3306, 1000, 200),   -- Reader
    (1, 'replica2.mysql.local', 3306, 500, 200);     -- Reader (lower weight)

-- Connection multiplexing
UPDATE mysql_servers SET max_connections = 100;
UPDATE global_variables SET variable_value = 2000 WHERE variable_name = 'mysql-max_connections';

-- Query caching
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, cache_ttl, apply)
VALUES (10, 1, '^SELECT .* FROM config_table', 60000, 1);  -- Cache for 60 seconds

-- Apply changes
LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL QUERY RULES TO RUNTIME; SAVE MYSQL QUERY RULES TO DISK;
```

### Traffic Mirroring

```sql
-- Mirror production traffic to staging for testing
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, mirror_hostgroup, apply)
VALUES (20, 1, '^SELECT', 2, 0);  -- Mirror reads to hostgroup 2 (staging)
```

---

## Query Optimization

### EXPLAIN FORMAT=TREE (MySQL 8.0+)

```sql
EXPLAIN FORMAT=TREE
SELECT o.id, o.total, c.name
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.created_at > '2024-01-01'
ORDER BY o.total DESC
LIMIT 10;

-- EXPLAIN ANALYZE (actual execution statistics)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'pending' AND total > 100;
```

### Optimizer Hints

```sql
-- Force index usage
SELECT /*+ INDEX(orders idx_orders_status) */ * FROM orders WHERE status = 'pending';

-- Force join order
SELECT /*+ JOIN_ORDER(o, c, p) */ o.id, c.name, p.name
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN products p ON o.product_id = p.id;

-- Control parallelism
SELECT /*+ SET_VAR(max_execution_time=5000) */ * FROM large_table WHERE complex_condition;

-- Skip secondary index merge
SELECT /*+ NO_INDEX_MERGE(orders) */ * FROM orders WHERE status = 'active' OR priority = 'high';
```

### Index Optimization

```sql
-- Invisible indexes (test drop impact without actually dropping)
ALTER TABLE orders ALTER INDEX idx_old_column INVISIBLE;
-- Monitor: if no performance regression, safely drop
ALTER TABLE orders DROP INDEX idx_old_column;

-- Descending indexes (MySQL 8.0+)
CREATE INDEX idx_orders_desc ON orders(created_at DESC, total DESC);

-- Functional indexes (MySQL 8.0.13+)
CREATE INDEX idx_email_domain ON users((SUBSTRING_INDEX(email, '@', -1)));
```

---

## MariaDB Specifics

### Galera Cluster

```ini
# my.cnf for Galera
[galera]
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name = "my_galera"
wsrep_cluster_address = "gcomm://node1,node2,node3"
wsrep_node_name = "node1"
wsrep_node_address = "10.0.0.1"
wsrep_sst_method = mariabackup                 # Full state snapshot transfer method
wsrep_slave_threads = 4                         # Parallel apply threads
binlog_format = ROW                             # Required for Galera
innodb_autoinc_lock_mode = 2                    # Interleaved (required for Galera)
```

### MaxScale (Proxy/Load Balancer)

```ini
# /etc/maxscale.cnf
[Read-Write-Service]
type = service
router = readwritesplit
servers = server1, server2, server3
user = maxscale_monitor
password = encrypted_pass
max_slave_connections = 100%
max_slave_replication_lag = 5s

[Read-Write-Listener]
type = listener
service = Read-Write-Service
protocol = MariaDBClient
port = 3306
```

### MariaDB ColumnStore

```sql
-- Create a ColumnStore table for analytics
CREATE TABLE analytics_events (
    event_id BIGINT,
    event_time DATETIME,
    user_id INT,
    event_type VARCHAR(50),
    payload TEXT
) ENGINE=ColumnStore;

-- Cross-engine JOINs between InnoDB (OLTP) and ColumnStore (OLAP)
SELECT c.name, COUNT(*) as events
FROM innodb_customers c
JOIN columnstore_events e ON c.id = e.user_id
WHERE e.event_time > '2024-01-01'
GROUP BY c.name;
```

### System Versioning (Temporal Tables)

```sql
-- MariaDB system-versioned tables
CREATE TABLE products (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    price DECIMAL(10,2)
) WITH SYSTEM VERSIONING;

-- Query historical data
SELECT * FROM products FOR SYSTEM_TIME AS OF '2024-01-15 10:00:00';
SELECT * FROM products FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-03-01';
SELECT * FROM products FOR SYSTEM_TIME ALL;
```

---

## Backup

### XtraBackup (Percona)

```bash
# Full hot backup (no locking for InnoDB)
xtrabackup --backup --target-dir=/backups/full --user=backup --password=secret

# Prepare backup (apply redo logs)
xtrabackup --prepare --target-dir=/backups/full

# Incremental backup
xtrabackup --backup --target-dir=/backups/inc1 --incremental-basedir=/backups/full

# Prepare incremental
xtrabackup --prepare --apply-log-only --target-dir=/backups/full
xtrabackup --prepare --target-dir=/backups/full --incremental-dir=/backups/inc1

# Restore
xtrabackup --copy-back --target-dir=/backups/full --datadir=/var/lib/mysql
```

### MySQL Shell Dump/Load

```bash
# Parallel logical dump (much faster than mysqldump)
mysqlsh -- util.dumpInstance('/backups/dump', {threads: 8, compression: 'zstd'})

# Dump specific schemas
mysqlsh -- util.dumpSchemas(['mydb'], '/backups/schema_dump', {threads: 8})

# Parallel load (with deferred index creation)
mysqlsh -- util.loadDump('/backups/dump', {threads: 8, deferTableIndexes: 'all'})
```

### Clone Plugin (MySQL 8.0.17+)

```sql
-- Fast physical clone (local or remote)
INSTALL PLUGIN clone SONAME 'mysql_clone.so';

-- Clone from donor to local instance
CLONE INSTANCE FROM 'donor_user'@'donor_host':3306 IDENTIFIED BY 'password';

-- Monitor progress
SELECT * FROM performance_schema.clone_progress;
```

---

## Security

### Authentication

```ini
# Default authentication plugin (MySQL 8.0+)
default_authentication_plugin = caching_sha2_password

# For backward compatibility
# default_authentication_plugin = mysql_native_password
```

### TDE (Transparent Data Encryption)

```ini
# Keyring plugin
early-plugin-load = keyring_file.so
keyring_file_data = /var/lib/mysql-keyring/keyring

# Or enterprise key management
early-plugin-load = keyring_encrypted_file.so
keyring_encrypted_file_data = /var/lib/mysql-keyring/keyring-encrypted
keyring_encrypted_file_password = vault_password
```

```sql
-- Encrypt a table
ALTER TABLE sensitive_data ENCRYPTION = 'Y';

-- Encrypt redo log and undo tablespaces
ALTER INSTANCE ROTATE INNODB MASTER KEY;
```

### Audit Log

```sql
-- Enterprise Audit (or Percona Audit Log Plugin for community)
INSTALL PLUGIN audit_log SONAME 'audit_log.so';
SET GLOBAL audit_log_policy = 'QUERIES';
SET GLOBAL audit_log_format = 'JSON';
```

---

## MySQL 8.0 / 8.4 / 9.0 Features

| Version | Feature | Description |
|---------|---------|-------------|
| 8.0 | CTEs | `WITH ... AS` recursive and non-recursive |
| 8.0 | Window functions | ROW_NUMBER, RANK, LAG, LEAD, NTILE |
| 8.0 | Invisible indexes | Test index removal without dropping |
| 8.0 | Instant DDL | ADD COLUMN without table rebuild |
| 8.0 | Hash joins | Equi-join without indexes |
| 8.0.17 | Clone Plugin | Physical instance cloning |
| 8.0.30 | Unified redo log | `innodb_redo_log_capacity` replaces file-based config |
| 8.4 | Firewall improvements | Allowlist-based SQL filtering |
| 9.0 | JavaScript stored programs | Write stored routines in JS |
| 9.0 | VECTOR type | Native vector data type for AI/ML |

---

## Managed Options Comparison

| Feature | Aurora MySQL | PlanetScale | Cloud SQL | Azure Flexible |
|---------|-------------|-------------|-----------|----------------|
| MySQL Version | 8.0 | 8.0 (Vitess) | 8.0/8.4 | 8.0 |
| Max Storage | 128 TB | Unlimited (sharded) | 64 TB | 16 TB |
| Read Replicas | 15 | N/A (horizontal) | 10 | 10 |
| HA | Multi-AZ auto-failover | Built-in | Regional/zonal | Zone-redundant |
| Sharding | No | Built-in (Vitess) | No | No |
| Online DDL | Limited | Non-blocking | Limited | Limited |
| Branching | No | Yes (schema only) | No | No |
| Serverless | v2 | No | No | No |
| Global | Global Database | Multi-region | Cross-region replicas | Geo-replication |
| Pricing | Instance + I/O | Row reads/writes | Instance | Instance |
