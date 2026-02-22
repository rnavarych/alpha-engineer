# Apache Cassandra + ScyllaDB Deep Reference

## Cassandra Architecture

### Ring Topology
- Consistent hashing distributes data across nodes
- Each node is responsible for a range of tokens
- Partitioner (default: Murmur3Partitioner) hashes partition keys to tokens
- Data routed to nodes owning the corresponding token range

### Virtual Nodes (vnodes)
```yaml
# cassandra.yaml
num_tokens: 256    # Default; some prefer 16-32 for larger clusters
# Benefits: automatic rebalancing when adding/removing nodes
# Trade-off: more tokens = more streaming during topology changes
# Cassandra 4.0+: allocate_tokens_for_local_replication_factor for optimal placement
```

### Gossip Protocol
- Nodes exchange state information every second
- Heartbeat counter, generation number, application state
- Phi Accrual Failure Detector determines node liveness
- Configurable: `phi_convict_threshold` (default 8, increase for cloud/WAN)

### Snitch
```yaml
# Determines node topology (datacenter, rack)
endpoint_snitch: GossipingPropertyFileSnitch    # Production recommended

# cassandra-rackdc.properties
dc=us-east-1
rack=rack1

# Snitch options:
# SimpleSnitch                       - Single DC (dev only)
# GossipingPropertyFileSnitch        - Production standard
# PropertyFileSnitch                 - Static topology file
# Ec2Snitch / Ec2MultiRegionSnitch   - AWS
# GoogleCloudSnitch                  - GCP
# AzureSnitch                        - Azure (DSE)
```

### Seed Nodes
```yaml
# cassandra.yaml
seed_provider:
  - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:
      - seeds: "10.0.1.1,10.0.2.1,10.0.3.1"

# Rules:
# - 2-3 seeds per datacenter
# - Seeds are used for initial node discovery (gossip bootstrap)
# - Seeds should be stable, reliable nodes
# - All nodes do NOT need to be seeds
# - Seed nodes are not special operationally after bootstrap
```

### Replication Strategies
```sql
-- NetworkTopologyStrategy (production)
CREATE KEYSPACE production WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'dc1': 3,     -- 3 replicas in dc1
  'dc2': 3      -- 3 replicas in dc2
};

-- SimpleStrategy (single DC only, dev/test)
CREATE KEYSPACE development WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 3
};
```

## Data Modeling

### Partition Key Design
```sql
-- Single partition key
PRIMARY KEY (user_id, created_at)
-- Partition: user_id, Clustering: created_at

-- Composite partition key (for even distribution)
PRIMARY KEY ((tenant_id, date), event_id)
-- Partition: (tenant_id, date), Clustering: event_id

-- Rules:
-- 1. Partition size < 100MB (ideal < 10MB)
-- 2. Partition should contain < 100K rows
-- 3. All queries must include full partition key
-- 4. Avoid unbounded partition growth (add time bucket)
```

### Clustering Columns
```sql
-- Multi-column clustering with mixed order
CREATE TABLE messages (
  channel_id UUID,
  sent_at TIMESTAMP,
  message_id TIMEUUID,
  sender TEXT,
  body TEXT,
  PRIMARY KEY (channel_id, sent_at, message_id)
) WITH CLUSTERING ORDER BY (sent_at DESC, message_id DESC);

-- Query patterns enabled:
-- All messages in channel (sorted by time DESC)
SELECT * FROM messages WHERE channel_id = ?;
-- Messages after timestamp
SELECT * FROM messages WHERE channel_id = ? AND sent_at > '2024-01-01';
-- Paginated (using message_id)
SELECT * FROM messages WHERE channel_id = ? AND sent_at = ? AND message_id < ? LIMIT 50;
```

### Wide Partitions (Anti-pattern Detection)
```bash
# Find large partitions
nodetool tablehistograms ks.table
# Look at "Partition Size" histogram

# If partitions > 100MB:
# 1. Add time bucket to partition key: (user_id, date)
# 2. Add hash bucket: (user_id, bucket) where bucket = hash(msg_id) % N
# 3. Reduce data per partition via TTL
```

### Materialized Views
```sql
-- Create MV (Cassandra 3.0+, use with caution)
CREATE MATERIALIZED VIEW orders_by_status AS
  SELECT * FROM orders
  WHERE status IS NOT NULL AND order_id IS NOT NULL
  PRIMARY KEY (status, order_date, order_id);

-- Caveats:
-- MVs can have consistency issues under high write load
-- Performance overhead on writes (each write to base = write to MV)
-- Consider application-level denormalization instead
-- Use SAI (Cassandra 5.0) for secondary access patterns when possible
```

## Compaction Strategies

### SizeTieredCompactionStrategy (STCS)
```sql
ALTER TABLE ks.events WITH compaction = {
  'class': 'SizeTieredCompactionStrategy',
  'min_threshold': 4,           -- Min SSTables before compaction
  'max_threshold': 32,          -- Max SSTables per compaction
  'min_sstable_size': 50,       -- MB, ignore smaller SSTables
  'bucket_low': 0.5,
  'bucket_high': 1.5
};
-- Best for: write-heavy workloads
-- Drawback: temporary 2x disk space during compaction
```

### LeveledCompactionStrategy (LCS)
```sql
ALTER TABLE ks.users WITH compaction = {
  'class': 'LeveledCompactionStrategy',
  'sstable_size_in_mb': 160,
  'fanout_size': 10              -- Level size multiplier
};
-- Best for: read-heavy workloads, point queries
-- Benefits: predictable read performance (1 SSTable per level per row)
-- Drawback: higher write amplification (10x)
```

### TimeWindowCompactionStrategy (TWCS)
```sql
ALTER TABLE ks.metrics WITH compaction = {
  'class': 'TimeWindowCompactionStrategy',
  'compaction_window_unit': 'HOURS',
  'compaction_window_size': 1
} AND default_time_to_live = 604800;    -- 7 day TTL
-- Best for: time-series data with TTL
-- Rule: Set TTL and never update/delete individual rows
-- Window should align with query patterns (hourly, daily)
```

### UnifiedCompactionStrategy (UCS) - Cassandra 5.0
```sql
ALTER TABLE ks.data WITH compaction = {
  'class': 'UnifiedCompactionStrategy',
  'scaling_parameters': 'T4'    -- Auto-tune between tiered and leveled
};
-- Adaptive: automatically adjusts compaction behavior
-- Reduces operational complexity of choosing strategy
```

## Consistency Levels

| Level | Read Behavior | Write Behavior | Nodes Contacted |
|---|---|---|---|
| ANY | - | Hinted handoff accepted | 1 (hint counts) |
| ONE | 1 replica responds | 1 replica acknowledges | 1 |
| TWO | 2 replicas respond | 2 replicas acknowledge | 2 |
| THREE | 3 replicas respond | 3 replicas acknowledge | 3 |
| QUORUM | RF/2+1 replicas | RF/2+1 replicas | Majority across all DCs |
| LOCAL_QUORUM | RF/2+1 in local DC | RF/2+1 in local DC | Majority in local DC |
| EACH_QUORUM | - | RF/2+1 in each DC | Majority in each DC |
| ALL | All replicas | All replicas | All |
| LOCAL_ONE | 1 replica in local DC | 1 replica in local DC | 1 in local DC |
| SERIAL | Linearizable read (Paxos) | - | Paxos round |
| LOCAL_SERIAL | Linearizable in local DC | - | Local Paxos round |

### Common Patterns
```
# Standard production (strong in local DC):
Write: LOCAL_QUORUM, Read: LOCAL_QUORUM

# High availability (eventual):
Write: LOCAL_ONE, Read: LOCAL_ONE
# Use read repair and anti-entropy repair for convergence

# Cross-DC strong consistency:
Write: EACH_QUORUM, Read: LOCAL_QUORUM

# Lightweight transactions (compare-and-set):
INSERT INTO users (id, name) VALUES (1, 'Alice') IF NOT EXISTS;
# Uses Paxos protocol, significantly slower (4 round-trips)
```

## nodetool Commands Reference

### Cluster Operations
```bash
nodetool status                          # Node states (UN, DN, UJ, UL)
nodetool describecluster                 # Schema versions, snitch, partitioner
nodetool ring                            # Token assignments
nodetool gossipinfo                      # Raw gossip state

# Add/remove nodes
nodetool decommission                    # Graceful removal (streams data out)
nodetool removenode <host-id>            # Remove dead node
nodetool assassinate <ip>                # Force-remove unresponsive node
nodetool bootstrap resume                # Resume failed bootstrap
```

### Performance Monitoring
```bash
nodetool tpstats                         # Thread pool stats (watch for blocked/pending)
nodetool proxyhistograms                 # Coordinator-level latency
nodetool tablehistograms <ks>.<tbl>      # Table read/write latency distribution
nodetool tablestats <ks>.<tbl>           # Detailed table metrics
nodetool cfstats                         # Legacy name for tablestats
nodetool compactionstats                 # Active compactions
nodetool netstats                        # Streaming operations
nodetool getcompactionthroughput         # MB/s limit
nodetool setcompactionthroughput 256     # Increase during off-peak
```

### Maintenance
```bash
nodetool flush <ks>                      # Flush memtables to SSTables
nodetool compact <ks> <tbl>              # Force major compaction (use sparingly)
nodetool cleanup <ks>                    # Remove data not owned by node (after scaling)
nodetool scrub <ks> <tbl>               # Fix corrupted SSTables
nodetool upgradesstables <ks>            # Rewrite SSTables to current format
nodetool garbagecollect <ks> <tbl>       # Remove tombstoned data
```

## Tombstone Management

### Understanding Tombstones
```
Tombstones are deletion markers (not immediate physical deletion):
1. DELETE creates a tombstone
2. INSERT with TTL creates a tombstone on expiry
3. UPDATE null value creates a tombstone
4. Tombstones kept until gc_grace_seconds expires AND next compaction runs

# gc_grace_seconds (default 864000 = 10 days)
ALTER TABLE ks.events WITH gc_grace_seconds = 86400;   -- 1 day (requires regular repair)
```

### Tombstone Warnings
```yaml
# cassandra.yaml
tombstone_warn_threshold: 1000     # Warn if scan encounters >1000 tombstones
tombstone_failure_threshold: 100000  # Fail query if >100K tombstones

# If hitting tombstone warnings:
# 1. Reduce gc_grace_seconds (but must run repair more frequently)
# 2. Use TWCS for time-series (automatic tombstone cleanup)
# 3. Avoid range deletes on wide partitions
# 4. Use TTL instead of explicit DELETE when possible
# 5. Compact the affected table
```

### Repair to Clear Tombstones
```bash
# Tombstones cannot be GC'd until data is consistent across replicas
# Run repair before gc_grace_seconds expires

# Full repair (all data)
nodetool repair -full <ks>

# Incremental repair (only unrepaired data, faster)
nodetool repair <ks>

# Primary range repair (only data owned by this node)
nodetool repair -pr <ks>

# Subrange repair (specific token range)
nodetool repair -st <start_token> -et <end_token> <ks>
```

## SAI (Storage-Attached Indexing) - Cassandra 5.0

```sql
-- Create SAI index (replaces SASI and legacy secondary indexes)
CREATE CUSTOM INDEX ON ks.orders (status) USING 'StorageAttachedIndex';
CREATE CUSTOM INDEX ON ks.orders (total) USING 'StorageAttachedIndex';
CREATE CUSTOM INDEX ON ks.orders (order_date) USING 'StorageAttachedIndex';

-- Query with SAI (no ALLOW FILTERING needed)
SELECT * FROM ks.orders WHERE status = 'shipped' AND total > 100;

-- SAI advantages over legacy indexes:
-- Attached to SSTables (no separate index structure)
-- Efficient range queries on numeric columns
-- Lower write amplification
-- Works with compaction naturally
```

## Anti-Entropy Repair

### Repair Strategies
```bash
# Full repair: compare all replicas, ensure consistency
nodetool repair -full ks

# Incremental repair: only check data written since last repair
nodetool repair ks
# Marks SSTables as repaired/unrepaired

# Primary range only: reduce work by only repairing owned ranges
nodetool repair -pr ks

# Parallel repair: repair multiple ranges concurrently
nodetool repair -par ks

# Datacenter-aware repair
nodetool repair -dc dc1 ks
nodetool repair -local ks     # Only local DC
```

### Reaper (Automated Repair)
```bash
# Cassandra Reaper: automated repair orchestration
# Schedule repairs across cluster without manual intervention
# Features:
# - Segment-based repair (small chunks for minimal impact)
# - Parallel/sequential scheduling
# - Web UI for monitoring
# - Blackout windows
# - Adaptive scheduling based on cluster load

# Register cluster
reaper-cli add-cluster --host cassandra1 --jmx-port 7199

# Create repair schedule
reaper-cli add-schedule --cluster production \
  --keyspace ecommerce \
  --intensity 0.5 \
  --schedule-days-between 7 \
  --segment-count 256
```

## Backup

### Snapshots
```bash
# Create snapshot (hard links, instant, zero overhead)
nodetool snapshot -t backup_20240315 ks

# Snapshot location: data_dir/ks/table-uuid/snapshots/backup_20240315/
# Copy snapshot files to backup storage

nodetool listsnapshots
nodetool clearsnapshot -t backup_20240315
```

### Incremental Backups
```yaml
# cassandra.yaml
incremental_backups: true
# New SSTables hard-linked to data_dir/ks/table-uuid/backups/
# Must be managed externally (cleanup after copying)
```

### Medusa (Netflix Backup Tool)
```bash
# Medusa: backup/restore tool supporting S3, GCS, Azure, local
medusa backup --backup-name daily-20240315

medusa list-backups
medusa verify --backup-name daily-20240315

# Restore
medusa restore-cluster --backup-name daily-20240315
medusa restore-node --backup-name daily-20240315
```

## Performance Tuning

### Key Configuration
```yaml
# cassandra.yaml

# Memtable
memtable_heap_space_in_mb: 2048              # Off-heap memtable size
memtable_offheap_space_in_mb: 2048
memtable_flush_writers: 4                     # Concurrent flush threads

# Commitlog
commitlog_sync: periodic                      # periodic or batch
commitlog_sync_period_in_ms: 10000           # For periodic
commitlog_segment_size_in_mb: 32

# Thread pools
concurrent_reads: 32                          # Typically 16 * num_drives
concurrent_writes: 32                         # Typically 8 * num_cores
concurrent_counter_writes: 32
concurrent_compactors: 4                      # Match number of SSDs

# Networking
native_transport_max_threads: 128
native_transport_max_concurrent_connections: -1  # Unlimited
rpc_min_threads: 16
rpc_max_threads: 2048

# Compaction
compaction_throughput_mb_per_sec: 64          # Increase during low-traffic
concurrent_compactors: 2                      # Per drive

# Caching
key_cache_size_in_mb: 100                    # Index file offset cache
row_cache_size_in_mb: 0                      # Disabled by default (use carefully)

# GC (jvm.options)
# G1GC recommended for heap > 4GB
# -Xms8G -Xmx8G (heap = 1/4 of RAM, max 32GB for compressed oops)
# -XX:+UseG1GC
# -XX:MaxGCPauseMillis=500
```

---

## ScyllaDB

## Shard-Per-Core Architecture

### How It Works
```
ScyllaDB uses the Seastar framework:
1. One thread per CPU core (no context switching)
2. Each shard owns a portion of data (no shared state)
3. Cooperative scheduling (no locks, no mutexes)
4. Shared-nothing I/O (each shard has its own I/O queue)
5. Cross-shard communication via message passing

Benefits:
- Predictable performance (no GC pauses, no lock contention)
- Linear scaling with CPU cores
- Consistent tail latency (p99 close to median)
- 10x fewer nodes than Cassandra for same workload
```

### Seastar Configuration
```yaml
# scylla.yaml
smp: 0                          # 0 = use all cores
memory: "64G"                   # Fixed memory allocation (no swap)
overprovisioned: false          # true for shared environments (cloud VMs)
io-properties-file: /etc/scylla.d/io_properties.yaml
```

## Alternator (DynamoDB API)

```bash
# Enable Alternator
# scylla.yaml
alternator_port: 8000
alternator_https_port: 8043
alternator_enforce_authorization: true

# Use standard AWS SDK against ScyllaDB
aws dynamodb --endpoint-url http://scylla-node:8000 \
  create-table \
  --table-name Users \
  --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=sk,AttributeType=S \
  --billing-mode PAY_PER_REQUEST

# Supports: GetItem, PutItem, Query, Scan, BatchGetItem, BatchWriteItem
# GSI, LSI, Streams, TTL, Conditional expressions
```

## Workload Prioritization

```sql
-- Service levels assign CPU shares to different workload types
CREATE SERVICE LEVEL sl_realtime WITH shares = 1000;
CREATE SERVICE LEVEL sl_analytics WITH shares = 100;
CREATE SERVICE LEVEL sl_batch WITH shares = 10;

-- Attach to roles
ATTACH SERVICE LEVEL sl_realtime TO role_web_app;
ATTACH SERVICE LEVEL sl_analytics TO role_dashboard;
ATTACH SERVICE LEVEL sl_batch TO role_etl;

-- Effect: under contention, realtime gets 10x resources vs analytics
-- Under no contention, all workloads use available resources
```

## CDC (Change Data Capture)

```sql
-- Enable CDC on table
ALTER TABLE ks.orders WITH cdc = {
  'enabled': true,
  'preimage': true,     -- Include old values
  'postimage': true,    -- Include new values
  'ttl': 86400          -- CDC log retention (1 day)
};

-- CDC log table: ks.orders_scylla_cdc_log
-- Contains: cdc$batch_seq_no, cdc$end_of_batch, cdc$operation
-- Operations: 0=pre-image, 1=update, 2=insert, 8=row-delete, 9=partition-delete

-- Read CDC log
SELECT * FROM ks.orders_scylla_cdc_log WHERE "cdc$stream_id" = ? AND "cdc$time" > ?;
```

## ScyllaDB Monitoring Stack

### Components
```bash
# Docker-based monitoring (recommended)
# 1. Prometheus (metrics collection)
# 2. Grafana (dashboards)
# 3. ScyllaDB pre-built dashboards

# Start monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Key dashboards:
# - Cluster Overview: nodes, latency, throughput
# - Per-Node: CPU, memory, disk I/O per shard
# - CQL Dashboard: query latency, errors, timeouts
# - Repair: repair progress, streaming
# - Compaction: pending, in-progress, throughput
```

### Key Metrics
```
# Latency (per shard)
scylla_storage_proxy_coordinator_write_latency
scylla_storage_proxy_coordinator_read_latency

# Throughput
scylla_transport_requests_served
scylla_cql_reads / scylla_cql_inserts

# Compaction
scylla_compaction_manager_compactions
scylla_column_family_pending_compactions

# Cache
scylla_cache_row_hits / scylla_cache_row_misses
scylla_cache_bytes_used

# Scheduler (workload prioritization)
scylla_scheduler_shares
scylla_scheduler_runtime_ms
```

## ScyllaDB Manager

```bash
# Repair orchestration
sctool repair --cluster production \
  --keyspace ecommerce \
  --intensity 1.0 \
  --parallel 0         # 0=auto

# Backup to S3
sctool backup --cluster production \
  --location s3://my-bucket/scylladb-backup \
  --retention 7        # Keep 7 backups

# Schedule recurring tasks
sctool repair --cluster production --keyspace ecommerce \
  --interval 7d --start-date 2024-03-15T02:00:00Z

# Monitor tasks
sctool task list --cluster production
sctool task progress repair/<task-id> --cluster production
```

## ScyllaDB Operator for Kubernetes

```yaml
# ScyllaCluster CRD
apiVersion: scylla.scylladb.com/v1
kind: ScyllaCluster
metadata:
  name: production
spec:
  version: 5.4.0
  agentVersion: 3.2.0
  developerMode: false
  datacenter:
    name: us-east-1
    racks:
      - name: us-east-1a
        members: 3
        storage:
          capacity: 500Gi
          storageClassName: gp3
        resources:
          requests:
            cpu: 8
            memory: 64Gi
          limits:
            cpu: 8
            memory: 64Gi
```

## Migration from Cassandra to ScyllaDB

### Steps
```
1. Schema compatibility check
   - CQL schema is directly compatible
   - Check for unsupported features (counters behave slightly differently)

2. Data migration options:
   a. sstableloader: Load Cassandra SSTables into ScyllaDB
   b. Spark Migrator: Large-scale migration via Spark
   c. Dual-write: Write to both, gradually shift reads
   d. CDC-based: Stream changes from Cassandra to ScyllaDB

3. Application changes:
   - Same CQL drivers (DataStax Java/Python/Go drivers work)
   - Change contact points to ScyllaDB nodes
   - Tune connection pool (ScyllaDB needs fewer connections per node)
   - Remove Cassandra-specific JMX monitoring, add Prometheus

4. Validation:
   - Compare row counts, checksums
   - Run shadow traffic (read from both, compare results)
   - Latency comparison testing

5. Common gotchas:
   - ScyllaDB is faster; may expose bugs hidden by Cassandra latency
   - Memory allocation: ScyllaDB manages its own memory (no JVM heap tuning)
   - Fewer nodes needed (plan for 3-5x reduction)
```

### Performance Comparison
| Metric | Cassandra | ScyllaDB |
|---|---|---|
| p99 read latency | 5-15ms | 1-3ms |
| p99 write latency | 3-10ms | 0.5-2ms |
| Throughput/node | 50K ops/s | 500K ops/s |
| Nodes for 1M ops/s | 20 | 2-3 |
| GC pauses | Yes (JVM) | None (C++) |
| Tail latency | Variable | Predictable |
