# Apache Cassandra — nodetool, Repair, Backup, Performance Tuning

## When to load
Load when running nodetool commands, scheduling repairs with Reaper, taking snapshots with Medusa, or tuning cassandra.yaml for memtable, commitlog, thread pools, and caching.

## nodetool Commands

```bash
# Cluster health
nodetool status                          # UN=Up Normal, DN=Down Normal
nodetool describecluster                 # Schema versions, snitch, partitioner
nodetool ring                            # Token assignments
nodetool gossipinfo                      # Raw gossip state

# Add/remove nodes
nodetool decommission                    # Graceful removal (streams data out)
nodetool removenode <host-id>            # Remove dead node
nodetool assassinate <ip>                # Force-remove unresponsive node

# Performance monitoring
nodetool tpstats                         # Thread pool stats (watch blocked/pending)
nodetool proxyhistograms                 # Coordinator-level latency
nodetool tablehistograms <ks>.<tbl>      # Table read/write latency distribution
nodetool tablestats <ks>.<tbl>           # Detailed table metrics
nodetool compactionstats                 # Active compactions
nodetool netstats                        # Streaming operations
nodetool getcompactionthroughput
nodetool setcompactionthroughput 256     # Increase during off-peak

# Maintenance
nodetool flush <ks>                      # Flush memtables to SSTables
nodetool compact <ks> <tbl>              # Force major compaction (use sparingly)
nodetool cleanup <ks>                    # Remove data not owned by node (after scaling)
nodetool scrub <ks> <tbl>               # Fix corrupted SSTables
nodetool upgradesstables <ks>            # Rewrite SSTables to current format
nodetool garbagecollect <ks> <tbl>       # Remove tombstoned data
```

## Anti-Entropy Repair

```bash
nodetool repair -full ks                 # Full repair: compare all replicas
nodetool repair ks                       # Incremental: only check since last repair
nodetool repair -pr ks                   # Primary range only (fastest)
nodetool repair -par ks                  # Parallel: repair multiple ranges concurrently
nodetool repair -dc dc1 ks               # DC-aware repair
```

**Reaper (automated repair orchestration):**

```bash
reaper-cli add-cluster --host cassandra1 --jmx-port 7199
reaper-cli add-schedule --cluster production \
  --keyspace ecommerce \
  --intensity 0.5 \
  --schedule-days-between 7 \
  --segment-count 256
```

## Backup

```bash
# Snapshot (hard links, instant, zero overhead)
nodetool snapshot -t backup_20240315 ks
# Files at: data_dir/ks/table-uuid/snapshots/backup_20240315/
nodetool listsnapshots
nodetool clearsnapshot -t backup_20240315

# Incremental backups (hard links to data_dir/ks/table-uuid/backups/)
# cassandra.yaml: incremental_backups: true

# Medusa (Netflix backup tool: S3, GCS, Azure, local)
medusa backup --backup-name daily-20240315
medusa list-backups
medusa verify --backup-name daily-20240315
medusa restore-cluster --backup-name daily-20240315
```

## Performance Tuning (cassandra.yaml)

```yaml
# Memtable
memtable_heap_space_in_mb: 2048
memtable_offheap_space_in_mb: 2048
memtable_flush_writers: 4

# Commitlog
commitlog_sync: periodic
commitlog_sync_period_in_ms: 10000
commitlog_segment_size_in_mb: 32

# Thread pools
concurrent_reads: 32                  # 16 * num_drives
concurrent_writes: 32                 # 8 * num_cores
concurrent_compactors: 4              # Match number of SSDs

# Networking
native_transport_max_threads: 128

# Compaction
compaction_throughput_mb_per_sec: 64

# Caching
key_cache_size_in_mb: 100
row_cache_size_in_mb: 0               # Disabled by default

# JVM (jvm.options): G1GC recommended for heap > 4GB
# -Xms8G -Xmx8G (heap = 1/4 of RAM, max 32GB for compressed oops)
# -XX:+UseG1GC
# -XX:MaxGCPauseMillis=500
```
