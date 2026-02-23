# MySQL / MariaDB — InnoDB Tuning and Replication

## When to load
Load when tuning InnoDB buffer pool, configuring GTID or semi-sync replication, setting up InnoDB Cluster/Group Replication, or deploying InnoDB ClusterSet for multi-region DR.

## InnoDB Buffer Pool and Durability

```ini
innodb_buffer_pool_size = 24G           # 70-80% of RAM on dedicated server
innodb_buffer_pool_instances = 8        # 1 per GB up to 64
innodb_buffer_pool_dump_at_shutdown = ON
innodb_buffer_pool_load_at_startup = ON

innodb_redo_log_capacity = 8G           # MySQL 8.0.30+ (replaces log_file_size)
innodb_flush_log_at_trx_commit = 1      # 1=ACID, 2=1s data loss risk
innodb_flush_method = O_DIRECT          # Bypass OS cache
innodb_flush_neighbors = 0              # Disable for SSD

innodb_io_capacity = 2000               # SSD baseline IOPS
innodb_io_capacity_max = 4000
innodb_read_io_threads = 8
innodb_write_io_threads = 8

innodb_change_buffer_max_size = 25
innodb_adaptive_hash_index = ON
innodb_adaptive_hash_index_parts = 8

innodb_doublewrite = ON
innodb_purge_threads = 4
max_connections = 500
thread_cache_size = 64
table_open_cache = 4096
```

## Async Replication with GTID

```ini
# Source
server-id = 1
log_bin = mysql-bin
binlog_format = ROW
gtid_mode = ON
enforce_gtid_consistency = ON
binlog_expire_logs_seconds = 604800

# Replica
server-id = 2
read_only = ON
super_read_only = ON
replica_parallel_workers = 8
replica_parallel_type = LOGICAL_CLOCK
replica_preserve_commit_order = ON
```

## Semi-Synchronous Replication

```sql
INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.so';
SET GLOBAL rpl_semi_sync_source_enabled = ON;
SET GLOBAL rpl_semi_sync_source_wait_for_replica_count = 1;
SET GLOBAL rpl_semi_sync_source_timeout = 5000;

INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.so';
SET GLOBAL rpl_semi_sync_replica_enabled = ON;
```

## Group Replication / InnoDB Cluster

```sql
SET GLOBAL group_replication_group_name = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
SET GLOBAL group_replication_local_address = "node1:33061";
SET GLOBAL group_replication_group_seeds = "node1:33061,node2:33061,node3:33061";
SET GLOBAL group_replication_single_primary_mode = ON;
SET GLOBAL group_replication_bootstrap_group = ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group = OFF;
```

```javascript
// InnoDB ClusterSet (multi-region DR via MySQL Shell)
cluster = dba.getCluster()
clusterset = cluster.createClusterSet('myClusterSet')
replicaCluster = clusterset.createReplicaCluster('dr-node1:3306', 'dr-cluster')

// Controlled switchover
clusterset.setPrimaryCluster('dr-cluster')
// Emergency failover (data loss possible)
clusterset.forcePrimaryCluster('dr-cluster')
```

## Query Optimization

```sql
-- EXPLAIN ANALYZE (MySQL 8.0+)
EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending' AND total > 100;

-- Force index usage
SELECT /*+ INDEX(orders idx_orders_status) */ * FROM orders WHERE status = 'pending';

-- Invisible indexes (test impact before dropping)
ALTER TABLE orders ALTER INDEX idx_old_column INVISIBLE;

-- Functional indexes (MySQL 8.0.13+)
CREATE INDEX idx_email_domain ON users((SUBSTRING_INDEX(email, '@', -1)));
```
