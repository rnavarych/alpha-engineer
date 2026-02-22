---
name: key-value-stores
description: |
  Deep operational guide for 15 key-value stores. Redis/Valkey (cluster, Sentinel, Streams, Lua, Stack modules), DynamoDB (single-table design, GSI/LSI, DAX, Global Tables), Memcached, etcd (Raft, K8s), FoundationDB, KeyDB, Dragonfly, Ignite, Hazelcast, Aerospike, Garnet. Use when configuring, tuning, or operating key-value databases in production.
allowed-tools: Read, Grep, Glob, Bash
---

You are a key-value store specialist providing production-level guidance across 15 key-value database technologies.

## Key-Value Store Selection Framework

When recommending a key-value store, evaluate:
1. **Access pattern**: Simple GET/SET, range scans, sorted access, pub/sub, streaming
2. **Durability requirements**: Pure cache (ephemeral) vs persistent store vs hybrid
3. **Consistency model**: Strong (etcd, FoundationDB) vs eventual (DynamoDB) vs configurable
4. **Latency requirements**: Sub-millisecond (Redis, Memcached, Dragonfly) vs single-digit milliseconds (DynamoDB)
5. **Data size**: In-memory only vs hybrid memory+SSD (Aerospike) vs disk-based (RocksDB)
6. **Operational model**: Managed (ElastiCache, DynamoDB, Memorystore) vs self-hosted
7. **Protocol compatibility**: RESP (Redis), Memcached ASCII/binary, DynamoDB API, gRPC (etcd)
8. **Multi-threading**: Single-threaded (Redis) vs multi-threaded (KeyDB, Dragonfly, Memcached, Garnet)

## Comparison Table

| Database | Threading | Persistence | Cluster | Protocol | Memory Model | Best For |
|---|---|---|---|---|---|---|
| Redis/Valkey | Single + IO threads | RDB + AOF | Hash slots (16384) | RESP | In-memory | Caching, sessions, pub/sub, streams |
| DynamoDB | Managed | Durable | Managed | HTTP/JSON | SSD-backed | Serverless, single-table design |
| Memcached | Multi-threaded | None | Client-side | ASCII/Binary | In-memory (slab) | Simple caching, multi-threaded GET |
| etcd | Multi-threaded | WAL + snapshots | Raft | gRPC + HTTP | In-memory + disk | Config store, service discovery, K8s |
| FoundationDB | Multi-threaded | Durable (SSD) | Distributed | FDB client | SSD-optimized | Multi-model foundation, ACID KV |
| KeyDB | Multi-threaded | RDB + AOF | Hash slots | RESP | In-memory | Redis replacement, higher throughput |
| Dragonfly | Multi-threaded | Snapshots | Cluster | RESP + Memcached | In-memory (shared-nothing) | Redis/Memcached replacement, lower RAM |
| ElastiCache | Managed | Optional | Managed | RESP/Memcached | In-memory | AWS managed Redis/Memcached |
| Azure Cache | Managed | Optional | Managed | RESP | In-memory | Azure managed Redis |
| Memorystore | Managed | Optional | Managed | RESP/Memcached | In-memory | GCP managed Redis/Memcached |
| Apache Ignite | Multi-threaded | Optional | Distributed | Binary/REST/SQL | In-memory + disk | Compute grid, distributed SQL, caching |
| Hazelcast | Multi-threaded | Optional | Distributed | Binary/REST | In-memory | Data grid, event streaming, caching |
| Aerospike | Multi-threaded | Hybrid DRAM+SSD | Distributed | Binary | Hybrid memory | Ad-tech, fraud detection, high-perf |
| Garnet | Multi-threaded | Checkpoints | Cluster | RESP | In-memory + tiered | .NET ecosystem, high-perf Redis alt |
| RocksDB | Multi-threaded | LSM-tree (SSD) | Embedded | C++ API | Disk-optimized | Embedded KV engine, storage foundation |

## Redis / Valkey (Primary)

Redis is the most widely deployed key-value store. Valkey is the Linux Foundation fork maintaining full RESP compatibility.

### Core Capabilities
- **Data structures**: Strings, Lists, Sets, Sorted Sets, Hashes, Streams, HyperLogLog, Bitmaps, Bitfields, Geospatial indexes
- **Cluster mode**: 16384 hash slots distributed across masters, automatic failover
- **Sentinel**: HA monitoring, automatic failover, configuration provider
- **Persistence**: RDB snapshots, AOF (append-only file), hybrid AOF+RDB
- **Pub/Sub**: Channel-based and pattern-based message broadcasting
- **Streams**: Append-only log with consumer groups (Kafka-like semantics)
- **Lua scripting**: Atomic server-side scripting with EVAL/EVALSHA
- **Redis Stack**: RediSearch, RedisJSON, RedisTimeSeries, RedisBloom, RedisGraph (deprecated)

### Common Patterns
```bash
# Caching with TTL
SET user:1001 '{"name":"Alice"}' EX 3600

# Rate limiting (sliding window)
MULTI
ZADD ratelimit:user:1001 <now_ms> <request_id>
ZREMRANGEBYSCORE ratelimit:user:1001 0 <now_ms - window>
ZCARD ratelimit:user:1001
EXPIRE ratelimit:user:1001 <window_seconds>
EXEC

# Distributed lock (Redlock pattern)
SET lock:resource <unique_id> NX PX 30000

# Sorted set leaderboard
ZADD leaderboard 1500 "player:42"
ZREVRANGE leaderboard 0 9 WITHSCORES

# Stream consumer group
XGROUP CREATE mystream mygroup $ MKSTREAM
XREADGROUP GROUP mygroup consumer1 COUNT 10 BLOCK 2000 STREAMS mystream >
XACK mystream mygroup <message_id>
```

### Operational Commands
```bash
# Cluster management
redis-cli --cluster create host1:6379 host2:6379 host3:6379 --cluster-replicas 1
redis-cli --cluster info host1:6379
redis-cli --cluster reshard host1:6379
redis-cli --cluster add-node new_host:6379 existing_host:6379

# Memory diagnostics
redis-cli INFO memory
redis-cli MEMORY DOCTOR
redis-cli MEMORY USAGE key_name
redis-cli --bigkeys
redis-cli --memkeys

# Latency diagnostics
redis-cli --latency
redis-cli LATENCY LATEST
redis-cli LATENCY HISTORY event_name
redis-cli SLOWLOG GET 25
redis-cli CLIENT LIST
```

**For deep Redis/Valkey reference, see [reference-redis.md](reference-redis.md)**

## Amazon DynamoDB

### Architecture
- Fully managed, serverless, single-digit millisecond latency
- Partition key (hash) + optional sort key (range)
- Automatic partitioning based on throughput and storage
- Two capacity modes: On-Demand (pay-per-request) and Provisioned (with auto-scaling)

### Single-Table Design
The recommended pattern for DynamoDB: model all entities in one table using composite keys.

```
# Single-table design example (e-commerce)
PK                  | SK                    | Entity     | Data
USER#alice          | PROFILE               | User       | {name, email, ...}
USER#alice          | ORDER#2024-001        | Order      | {total, status, ...}
USER#alice          | ORDER#2024-001#ITEM#1 | OrderItem  | {product, qty, ...}
PRODUCT#sku-42      | METADATA              | Product    | {name, price, ...}
PRODUCT#sku-42      | REVIEW#2024-03-15#u1  | Review     | {rating, text, ...}
```

### GSI / LSI Patterns
```
# GSI: Query orders by status across all users
GSI1PK = "ORDER_STATUS#shipped"
GSI1SK = "2024-03-15T10:30:00Z"  (timestamp for range queries)

# GSI overloading: Multiple access patterns on same GSI
GSI1PK = entity-specific key
GSI1SK = entity-specific sort key

# LSI: Alternate sort within same partition (must be defined at table creation)
LSI1SK = "total_amount"  (sort orders by amount within a user)
```

### Key Operations
```bash
# Create table
aws dynamodb create-table \
  --table-name Orders \
  --attribute-definitions \
    AttributeName=PK,AttributeType=S \
    AttributeName=SK,AttributeType=S \
  --key-schema \
    AttributeName=PK,KeyType=HASH \
    AttributeName=SK,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

# Query with begins_with
aws dynamodb query \
  --table-name Orders \
  --key-condition-expression "PK = :pk AND begins_with(SK, :sk)" \
  --expression-attribute-values '{":pk":{"S":"USER#alice"},":sk":{"S":"ORDER#"}}'

# PartiQL
aws dynamodb execute-statement \
  --statement "SELECT * FROM Orders WHERE PK='USER#alice' AND begins_with(SK, 'ORDER#')"

# Enable Streams
aws dynamodb update-table \
  --table-name Orders \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES
```

### DAX (DynamoDB Accelerator)
- In-memory cache in front of DynamoDB
- Microsecond read latency for cached items
- Write-through caching, eventual consistency for reads
- Drop-in replacement (same API, change endpoint)

### Global Tables
- Multi-region, multi-active replication
- Last-writer-wins conflict resolution
- All replicas accept reads and writes
- Replication typically under 1 second

## Memcached

### Architecture
- Multi-threaded, simple key-value cache
- Slab allocator: memory divided into slab classes (chunk sizes)
- No persistence, no replication (client-side sharding)
- Maximum key size: 250 bytes, maximum value size: 1 MB (configurable)

### Slab Allocation
```
# Slab classes: 96B, 120B, 152B, 192B, ... (growth factor 1.25)
# Monitor slab usage
echo "stats slabs" | nc localhost 11211
echo "stats items" | nc localhost 11211

# Slab rebalancing (automove)
-o slab_reassign,slab_automove=1
```

### Consistent Hashing
- Client-side key distribution across nodes
- Libraries: libmemcached, pylibmc, spymemcached
- mcrouter (Facebook): connection pooling, failover routing, warm-up, shadowing, prefix routing

### Operations
```bash
# Start with tuned settings
memcached -m 4096 -c 10000 -t 8 -p 11211 \
  -o modern,slab_reassign,slab_automove=1 \
  -I 2m  # max item size 2MB

# Stats
echo "stats" | nc localhost 11211
echo "stats settings" | nc localhost 11211

# Key metrics to monitor
# - get_hits / (get_hits + get_misses) = hit ratio (target >95%)
# - evictions (should be low for well-sized cache)
# - curr_connections vs max_connections
```

## etcd

### Architecture
- Distributed KV store using Raft consensus
- Strong consistency (linearizable reads, serializable watches)
- Kubernetes backing store for all cluster state
- gRPC API with HTTP/JSON gateway
- Flat key-value with prefix-based key hierarchies

### Key Operations
```bash
# Basic KV operations
etcdctl put /config/db/host "db.example.com"
etcdctl get /config/db/host
etcdctl get /config/ --prefix          # Range query
etcdctl del /config/db/host

# Watch for changes
etcdctl watch /config/ --prefix

# Lease management (TTL-based keys)
etcdctl lease grant 60                  # 60-second lease
etcdctl put /service/web1 "alive" --lease=<lease_id>
etcdctl lease keep-alive <lease_id>     # Heartbeat

# Cluster management
etcdctl member list
etcdctl endpoint status --cluster -w table
etcdctl endpoint health --cluster

# Defragmentation (reclaim space after compaction)
etcdctl defrag --cluster
etcdctl compact <revision>

# Snapshot for backup
etcdctl snapshot save backup.db
etcdctl snapshot restore backup.db --data-dir /var/lib/etcd-restore
```

### Kubernetes Integration
- Stores all K8s objects (pods, services, configmaps, secrets)
- Performance: target <10ms p99 latency for K8s API server
- Recommended: dedicated SSD, 8GB+ RAM, separate from worker nodes
- Monitor: `etcd_server_has_leader`, `etcd_disk_wal_fsync_duration_seconds`, `etcd_network_peer_round_trip_time_seconds`

## FoundationDB

### Architecture
- Ordered key-value store with full ACID transactions
- Transaction processing: sequencer + resolvers + storage servers + log servers
- Layer architecture: build any data model on top (Record Layer, Document Layer)
- Used by Apple (iCloud), Snowflake, Tigris

### Record Layer (by Apple)
- Structured records on top of FoundationDB
- Protobuf-defined schemas, secondary indexes
- Query planning and execution engine
- Used for CloudKit (iCloud)

### Transactions
```python
# Python API example
import fdb
fdb.api_version(730)
db = fdb.open()

@fdb.transactional
def transfer(tr, from_acct, to_acct, amount):
    from_bal = int(tr[fdb.tuple.pack(('accounts', from_acct))])
    to_bal = int(tr[fdb.tuple.pack(('accounts', to_acct))])
    if from_bal < amount:
        raise Exception("Insufficient funds")
    tr[fdb.tuple.pack(('accounts', from_acct))] = str(from_bal - amount)
    tr[fdb.tuple.pack(('accounts', to_acct))] = str(to_bal + amount)
```

### Operations
```bash
# Cluster status
fdbcli --exec "status details"
fdbcli --exec "status json"

# Configuration
fdbcli --exec "configure double ssd"      # Replication mode
fdbcli --exec "coordinators auto"          # Auto-select coordinators
```

## Amazon ElastiCache

### Redis Mode
- Managed Redis with cluster mode enabled/disabled
- Cluster mode: up to 500 shards, 250 nodes per cluster
- Global Datastore: cross-region replication, <1s lag
- Serverless: auto-scaling, pay-per-use (eCPUs + data storage)
- Data tiering: hot data in memory, warm data on SSD (r6gd instances)

### Memcached Mode
- Managed Memcached with auto-discovery
- Up to 300 nodes per cluster
- Multi-threaded, simple caching

### Operations
```bash
# Create Redis cluster (cluster mode enabled)
aws elasticache create-replication-group \
  --replication-group-id my-redis \
  --replication-group-description "Production Redis" \
  --num-node-groups 3 \
  --replicas-per-node-group 2 \
  --cache-node-type cache.r7g.xlarge \
  --engine redis \
  --engine-version 7.1 \
  --at-rest-encryption-enabled \
  --transit-encryption-enabled \
  --automatic-failover-enabled

# Create serverless cache
aws elasticache create-serverless-cache \
  --serverless-cache-name my-serverless \
  --engine redis \
  --cache-usage-limits 'DataStorage={Maximum=100,Unit=GB},ECPUPerSecond={Maximum=15000}'
```

## Azure Cache for Redis

### Tiers
- **Basic**: Single node, no SLA (dev/test)
- **Standard**: Replicated, 99.9% SLA
- **Premium**: Clustering, persistence, VNet, geo-replication
- **Enterprise**: Redis Stack modules (RediSearch, RedisJSON, RedisTimeSeries, RedisBloom), active geo-replication, 99.999% SLA
- **Enterprise Flash**: SSD-backed for large datasets

### Geo-Replication
- Passive (Premium): async replication, manual failover
- Active (Enterprise): multi-region active-active, conflict-free replicated data types (CRDTs)

## Google Memorystore

### Redis Mode
- Managed Redis (Basic and Standard tiers)
- Standard: cross-zone replication, 99.9% SLA
- Redis Cluster: horizontal scaling, up to 250 nodes
- Read replicas for read scaling

### Memcached Mode
- Managed Memcached, auto-discovery
- Up to 20 nodes per instance

## KeyDB

### Differentiators from Redis
- Multi-threaded: uses all CPU cores (vs Redis single-threaded)
- MVCC: non-blocking reads during writes
- Active replication: all replicas accept writes, conflict resolution via timestamps
- FLASH: tiered storage (RAM + SSD) for larger-than-memory datasets
- Subkey expires: TTL on individual hash fields
- RESP compatible, drop-in Redis replacement

### Configuration
```bash
# keydb.conf
server-threads 4                # Match CPU cores
active-replica yes              # Enable active-active
multi-master yes                # Multi-master replication
storage-provider flash /data/flash  # Tiered storage
```

## Dragonfly

### Differentiators
- Multi-threaded, shared-nothing architecture
- RESP and Memcached protocol compatible
- 25x lower memory usage than Redis for certain workloads (via dashtable)
- Single binary, no modules needed
- Snapshot without fork (no memory doubling during persistence)

### Configuration
```bash
# Run Dragonfly
dragonfly --logtostderr --cache_mode=true \
  --maxmemory=8G --dbfilename=dump --dir=/data \
  --proactor_threads=8
```

## Apache Ignite

### Capabilities
- In-memory computing platform: distributed cache + SQL + compute + ML
- ANSI SQL support with distributed joins
- Compute grid: execute code on data nodes (collocated processing)
- Persistence: optional native persistence or 3rd-party (RDBMS, HDFS)
- Thin clients: Java, .NET, C++, Python, Node.js

### Configuration
```xml
<!-- Cache configuration -->
<bean class="org.apache.ignite.configuration.CacheConfiguration">
  <property name="name" value="myCache"/>
  <property name="cacheMode" value="PARTITIONED"/>
  <property name="backups" value="1"/>
  <property name="atomicityMode" value="TRANSACTIONAL"/>
  <property name="writeSynchronizationMode" value="FULL_SYNC"/>
</bean>
```

### Operations
```bash
# Cluster management via control script
control.sh --state
control.sh --baseline
control.sh --activate
```

## Hazelcast

### Capabilities
- In-memory data grid: distributed Map, Queue, Topic, Set, List, MultiMap
- Near cache for low-latency reads
- WAN replication for multi-DC deployments
- Jet: stream processing engine (now integrated)
- SQL engine for distributed queries
- Tiered storage: overflow from memory to disk

### Configuration
```yaml
# hazelcast.yaml
hazelcast:
  cluster-name: production
  network:
    join:
      multicast:
        enabled: false
      kubernetes:
        enabled: true
        service-dns: hazelcast.default.svc.cluster.local
  map:
    sessions:
      backup-count: 1
      time-to-live-seconds: 3600
      eviction:
        eviction-policy: LRU
        max-size-policy: USED_HEAP_PERCENTAGE
        size: 80
```

## Aerospike

### Architecture
- Hybrid memory: index in DRAM, data on SSD (or all DRAM)
- Strong consistency mode (AP or CP configurable)
- Smart client: cluster-aware, direct node access
- Cross-datacenter replication (XDR)
- Sub-millisecond reads on SSD

### Namespaces
```
# aerospike.conf
namespace production {
  replication-factor 2
  memory-size 8G
  default-ttl 0               # No expiration
  storage-engine device {
    device /dev/sdb
    write-block-size 1M
    defrag-lwm-pct 50
  }
}

namespace cache {
  replication-factor 1
  memory-size 4G
  default-ttl 3600             # 1 hour TTL
  storage-engine memory         # Pure in-memory
}
```

### Operations
```bash
# Admin commands
asadm -e "info"
asadm -e "show stat"
asadm -e "show config"
aql -c "SELECT * FROM production.users WHERE PK='user:1001'"
```

## Garnet (Microsoft)

### Differentiators
- Written in C#/.NET, high-performance RESP server
- Multi-threaded with FASTER storage engine (Microsoft Research)
- Tiered storage: memory + SSD seamlessly
- Raw string and object store operations
- Cluster mode support with hash slot migration
- TLS, ACL support

### Performance Characteristics
- Better throughput than Redis on multi-core machines
- Lower tail latency under contention
- Efficient memory usage via FASTER log-structured store

## RocksDB (Embedded)

### Overview
- Embeddable, persistent key-value store
- LSM-tree architecture optimized for SSD
- Foundation for: CockroachDB, TiKV (TiDB), YugabyteDB, Kafka Streams state stores

### Key Tuning
```
# Key configuration options
max_background_jobs=8
max_write_buffer_number=4
write_buffer_size=128MB
target_file_size_base=128MB
max_bytes_for_level_base=1GB
compression=lz4                 # L0-L1
bottommost_compression=zstd     # Bottom level
bloom_bits_per_key=10
block_cache_size=4GB
```

**Cross-reference**: For embedded database details, see the embedded-databases skill.

## Data Model Patterns

### Cache-Aside (Lazy Loading)
```
1. Application checks cache
2. Cache miss -> read from database
3. Store result in cache with TTL
4. Subsequent reads hit cache
```

### Write-Through
```
1. Application writes to cache
2. Cache synchronously writes to database
3. Both cache and database always consistent
```

### Write-Behind (Write-Back)
```
1. Application writes to cache
2. Cache asynchronously writes to database (batched)
3. Higher write throughput, risk of data loss on crash
```

### Distributed Lock
```
# Redis/Valkey Redlock algorithm
1. Acquire lock on N/2+1 instances with same key, value, TTL
2. If majority acquired within TTL, lock is held
3. Release by deleting key on all instances
4. Use fencing tokens for correctness
```

### Session Store
```
# Key design: session:<session_id>
# Value: serialized session data
# TTL: session timeout (e.g., 30 minutes)
# Use HASH type for partial reads/writes
HSET session:abc123 user_id 1001 role admin last_access 1710500000
EXPIRE session:abc123 1800
```

## Monitoring Essentials

### Key Metrics (All KV Stores)
| Metric | Target | Action if Breached |
|---|---|---|
| Hit ratio | >95% | Increase memory, review TTL strategy |
| Latency p99 | <5ms | Check network, memory pressure, slow commands |
| Memory usage | <80% maxmemory | Scale out, tune eviction, reduce TTLs |
| Evictions/sec | Low/zero for persistent | Increase memory or shard count |
| Connected clients | <80% max | Connection pooling, increase limits |
| Replication lag | <1s | Check network, replica resources |
| CPU usage | <70% | Scale out, optimize hot keys |

### Anti-Patterns to Avoid
1. **Hot keys**: Single key receiving disproportionate traffic (add client-side cache or key sharding)
2. **Large values**: Values >100KB cause latency spikes (compress or split)
3. **KEYS command in production**: Blocks server (use SCAN instead)
4. **Missing TTLs**: Memory grows unbounded (always set TTLs on cache entries)
5. **Thundering herd**: Mass cache expiration causes database spike (jitter TTLs, probabilistic early expiration)
6. **Cache penetration**: Repeated queries for non-existent keys (cache null results, bloom filter)

For detailed Redis/Valkey reference, see [reference-redis.md](reference-redis.md).
