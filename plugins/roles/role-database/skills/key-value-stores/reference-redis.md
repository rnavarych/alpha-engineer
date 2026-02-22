# Redis / Valkey Deep Reference

## Cluster Mode

### Architecture
- 16384 hash slots distributed across master nodes
- Each master holds a subset of hash slots; each master can have N replicas
- Clients use `CLUSTER SLOTS` or `CLUSTER SHARDS` to discover topology
- Hash slot = `CRC16(key) mod 16384`
- Hash tags: `{user:1001}.profile` and `{user:1001}.sessions` map to same slot (multi-key operations)

### Cluster Setup
```bash
# Create cluster with 3 masters, 1 replica each (6 nodes total)
redis-cli --cluster create \
  node1:6379 node2:6379 node3:6379 \
  node4:6379 node5:6379 node6:6379 \
  --cluster-replicas 1

# Check cluster health
redis-cli --cluster check node1:6379
redis-cli --cluster info node1:6379
redis-cli CLUSTER INFO
redis-cli CLUSTER NODES
redis-cli CLUSTER SHARDS
```

### Resharding (Slot Migration)
```bash
# Interactive resharding
redis-cli --cluster reshard node1:6379

# Move specific slots from source to target
redis-cli --cluster reshard node1:6379 \
  --cluster-from <source-node-id> \
  --cluster-to <target-node-id> \
  --cluster-slots 1000 \
  --cluster-yes

# Manual slot migration (advanced)
# On target: CLUSTER SETSLOT <slot> IMPORTING <source-id>
# On source: CLUSTER SETSLOT <slot> MIGRATING <target-id>
# Migrate keys: MIGRATE target_host target_port key 0 5000
# Finalize: CLUSTER SETSLOT <slot> NODE <target-id> (on all nodes)
```

### Adding / Removing Nodes
```bash
# Add master node
redis-cli --cluster add-node new_host:6379 existing_host:6379

# Add replica node
redis-cli --cluster add-node new_host:6379 existing_host:6379 \
  --cluster-slave --cluster-master-id <master-node-id>

# Remove node (move slots first, then delete)
redis-cli --cluster del-node existing_host:6379 <node-id>

# Forget a node from all cluster members
redis-cli CLUSTER FORGET <node-id>

# Meet a new node
redis-cli CLUSTER MEET <host> <port>
```

### Cluster Configuration
```
# redis.conf for cluster mode
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-migration-barrier 1          # Min replicas before migration
cluster-allow-reads-when-down yes    # Serve reads even if cluster is down
cluster-allow-pubsubshard-when-down yes
```

## Sentinel High Availability

### Architecture
- Monitors master/replica topology, handles automatic failover
- Requires minimum 3 Sentinel instances for quorum
- Publishes failover events via pub/sub
- Clients connect to Sentinel to discover current master

### Configuration
```
# sentinel.conf
sentinel monitor mymaster 10.0.0.1 6379 2    # quorum=2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel auth-pass mymaster <password>

# Notification script (called on failover events)
sentinel notification-script mymaster /opt/scripts/notify.sh

# Client reconfiguration script (called when master changes)
sentinel client-reconfig-script mymaster /opt/scripts/reconfig.sh
```

### Failover Behavior
```
1. Sentinel detects master is unreachable (+sdown = subjective down)
2. Quorum agrees: +odown (objective down)
3. Leader election among Sentinels (Raft-like)
4. Leader selects best replica (priority, replication offset, runid)
5. Promotes replica to master, reconfigures other replicas
6. Publishes +switch-master event
```

### Safety Configuration
```
# Require minimum replicas before accepting writes
min-replicas-to-write 1
min-replicas-max-lag 10    # Max replication lag in seconds

# Sentinel commands
redis-cli -p 26379 SENTINEL masters
redis-cli -p 26379 SENTINEL master mymaster
redis-cli -p 26379 SENTINEL replicas mymaster
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
redis-cli -p 26379 SENTINEL failover mymaster    # Force failover
redis-cli -p 26379 SENTINEL reset mymaster        # Reset state
```

## Data Structures

### Strings
```bash
SET key value [EX seconds | PX ms | EXAT timestamp | PXAT ms-timestamp] [NX|XX] [GET]
GET key
MSET k1 v1 k2 v2         # Atomic multi-set
MGET k1 k2               # Multi-get
INCR counter              # Atomic increment
INCRBY counter 10
INCRBYFLOAT counter 1.5
APPEND key " suffix"
GETRANGE key 0 10
SETRANGE key 6 "world"
STRLEN key
GETDEL key                # Get and delete atomically
GETEX key EX 100          # Get and set new expiry
```

### Lists
```bash
LPUSH list val1 val2      # Push to head
RPUSH list val1 val2      # Push to tail
LPOP list [count]         # Pop from head
RPOP list [count]         # Pop from tail
LRANGE list 0 -1          # Get all elements
LINDEX list 3             # Get by index
LLEN list                 # Length
LPOS list value           # Find position
LMOVE src dst LEFT RIGHT  # Move between lists
BLPOP list 5              # Blocking pop (5s timeout)
BRPOP list 5
```

### Sets
```bash
SADD set member1 member2
SREM set member1
SISMEMBER set member1
SMEMBERS set              # All members
SCARD set                 # Cardinality
SINTER set1 set2          # Intersection
SUNION set1 set2          # Union
SDIFF set1 set2           # Difference
SRANDMEMBER set 3         # Random members
SPOP set                  # Remove random
SMISMEMBER set m1 m2 m3   # Multi-member check
```

### Sorted Sets
```bash
ZADD zset [NX|XX|GT|LT] score member
ZRANGE zset 0 -1 [WITHSCORES] [REV]
ZRANGEBYSCORE zset min max [WITHSCORES] [LIMIT offset count]
ZRANGEBYLEX zset "[a" "[z"    # Lexicographic range
ZRANK zset member             # Rank (0-based)
ZREVRANK zset member          # Reverse rank
ZSCORE zset member
ZINCRBY zset 5 member
ZCARD zset
ZCOUNT zset min max
ZREM zset member
ZPOPMIN zset [count]
ZPOPMAX zset [count]
BZPOPMIN zset 5               # Blocking pop
ZUNIONSTORE dest 2 zset1 zset2 WEIGHTS 1 2 AGGREGATE SUM
ZINTERSTORE dest 2 zset1 zset2
ZRANDMEMBER zset 3
```

### Hashes
```bash
HSET hash field1 val1 field2 val2
HGET hash field1
HMGET hash field1 field2
HGETALL hash
HDEL hash field1
HEXISTS hash field1
HKEYS hash
HVALS hash
HLEN hash
HINCRBY hash field 10
HSETNX hash field value       # Set only if not exists
HRANDFIELD hash 3 WITHVALUES  # Random fields
HSCAN hash 0 MATCH "user:*"   # Cursor-based iteration
```

### HyperLogLog
```bash
PFADD hll element1 element2   # Add elements
PFCOUNT hll                   # Approximate cardinality (0.81% error)
PFMERGE dest hll1 hll2        # Merge sets
# Use case: count unique visitors with 12KB per counter
```

### Bitmaps and Bitfields
```bash
SETBIT bitmap 1000 1          # Set bit at offset
GETBIT bitmap 1000
BITCOUNT bitmap [start end]
BITOP AND dest bm1 bm2       # Bitwise operations
BITPOS bitmap 1 [start end]   # First set bit position

# Bitfields: store multiple integers in a string
BITFIELD bf SET u8 0 200      # Set 8-bit unsigned at offset 0
BITFIELD bf GET u8 0          # Get value
BITFIELD bf INCRBY u8 0 10    # Increment
```

### Geospatial
```bash
GEOADD geo -122.42 37.77 "San Francisco"
GEOADD geo -73.94 40.73 "New York"
GEODIST geo "San Francisco" "New York" km
GEOSEARCH geo FROMLONLAT -122.42 37.77 BYRADIUS 100 km ASC COUNT 10
GEOSEARCHSTORE dest geo FROMLONLAT -122.42 37.77 BYRADIUS 50 km
GEOPOS geo "San Francisco"
GEOHASH geo "San Francisco"
```

## Redis Streams

### Producing Messages
```bash
XADD mystream * field1 value1 field2 value2          # Auto-generated ID
XADD mystream 1710000000000-0 field1 value1          # Explicit ID
XADD mystream MAXLEN ~ 100000 * field1 value1        # Trimmed stream (approx)
XADD mystream MINID ~ 1710000000000-0 * field1 value1  # Trim by ID
XLEN mystream
```

### Consuming (Direct)
```bash
XRANGE mystream - +                    # All entries
XRANGE mystream 1710000000000-0 +      # From specific ID
XRANGE mystream - + COUNT 10           # Limited
XREVRANGE mystream + - COUNT 10        # Reverse
XREAD COUNT 10 BLOCK 5000 STREAMS mystream $  # Blocking tail read
XREAD COUNT 10 STREAMS mystream otherstream 0-0 0-0  # Multi-stream
```

### Consumer Groups
```bash
# Create consumer group
XGROUP CREATE mystream mygroup $ MKSTREAM    # Start from latest
XGROUP CREATE mystream mygroup 0             # Start from beginning

# Read as consumer in group
XREADGROUP GROUP mygroup consumer1 COUNT 10 BLOCK 2000 STREAMS mystream >

# Acknowledge processed messages
XACK mystream mygroup 1710000000000-0

# Check pending entries (unacknowledged)
XPENDING mystream mygroup - + 10
XPENDING mystream mygroup IDLE 60000 - + 10    # Idle >60s

# Claim idle messages (consumer recovery)
XAUTOCLAIM mystream mygroup consumer2 60000 0-0 COUNT 10
XCLAIM mystream mygroup consumer2 60000 1710000000000-0

# Consumer group info
XINFO STREAM mystream
XINFO GROUPS mystream
XINFO CONSUMERS mystream mygroup

# Delete consumer / group
XGROUP DELCONSUMER mystream mygroup consumer1
XGROUP DESTROY mystream mygroup
```

### Streams vs Pub/Sub
| Feature | Streams | Pub/Sub |
|---|---|---|
| Persistence | Yes (stored in stream) | No (fire-and-forget) |
| Consumer groups | Yes | No |
| Message acknowledgment | Yes (XACK) | No |
| Replay/history | Yes | No |
| Backpressure | Yes (blocking reads) | No (drops if slow) |
| Use case | Event sourcing, task queues | Real-time notifications |

## Lua Scripting

### EVAL / EVALSHA
```bash
# Atomic counter with conditional logic
EVAL "
  local current = redis.call('GET', KEYS[1])
  if current and tonumber(current) >= tonumber(ARGV[1]) then
    return redis.error_reply('Limit exceeded')
  end
  return redis.call('INCR', KEYS[1])
" 1 rate:user:1001 100

# Load script and call by SHA
redis-cli SCRIPT LOAD "return redis.call('GET', KEYS[1])"
# Returns SHA hash
EVALSHA <sha> 1 mykey

# Script management
SCRIPT EXISTS <sha1> <sha2>
SCRIPT FLUSH [ASYNC|SYNC]

# Functions (Redis 7.0+) - persistent, named
FUNCTION LOAD "#!lua name=mylib\nredis.register_function('myfunc', function(keys, args) return redis.call('GET', keys[1]) end)"
FCALL myfunc 1 mykey
```

### Scripting Best Practices
- Scripts are atomic (no other commands execute during script)
- Access only keys passed as KEYS[] (cluster compatibility)
- Avoid long-running scripts (blocks server, replication delays)
- Use EVALSHA to avoid sending script text repeatedly
- Maximum execution time controlled by `lua-time-limit` (default 5s; produces BUSY error)
- Use `redis.log()` for debugging in script

## Redis Stack Modules

### RediSearch
```bash
# Create search index
FT.CREATE idx:products ON HASH PREFIX 1 product: SCHEMA
  name TEXT WEIGHT 2.0
  description TEXT
  price NUMERIC SORTABLE
  category TAG
  location GEO
  embedding VECTOR FLAT 6 TYPE FLOAT32 DIM 768 DISTANCE_METRIC COSINE

# Search
FT.SEARCH idx:products "@name:laptop @price:[500 1500]" SORTBY price ASC LIMIT 0 10
FT.SEARCH idx:products "@category:{electronics|computers}"
FT.SEARCH idx:products "(@name:laptop) => [KNN 5 @embedding $vec AS score]" PARAMS 2 vec <blob> DIALECT 2

# Aggregation
FT.AGGREGATE idx:products "*"
  GROUPBY 1 @category
  REDUCE COUNT 0 AS count
  REDUCE AVG 1 @price AS avg_price
  SORTBY 2 @count DESC
  LIMIT 0 10
```

### RedisJSON
```bash
JSON.SET user:1001 $ '{"name":"Alice","age":30,"address":{"city":"NYC"},"tags":["admin","vip"]}'
JSON.GET user:1001 $.name $.age
JSON.SET user:1001 $.age 31
JSON.NUMINCRBY user:1001 $.age 1
JSON.ARRAPPEND user:1001 $.tags '"editor"'
JSON.TYPE user:1001 $.address
JSON.DEL user:1001 $.address.city
JSON.MGET user:1001 user:1002 $.name
```

### RedisTimeSeries
```bash
TS.CREATE sensor:temp:1 RETENTION 86400000 LABELS location "datacenter1" type "temperature"
TS.ADD sensor:temp:1 * 23.5
TS.ADD sensor:temp:1 1710000000000 24.1
TS.RANGE sensor:temp:1 - + COUNT 100
TS.RANGE sensor:temp:1 - + AGGREGATION avg 60000    # 1-min averages
TS.MRANGE - + FILTER location=datacenter1
TS.CREATERULE sensor:temp:1 sensor:temp:1:hourly AGGREGATION avg 3600000
TS.REVRANGE sensor:temp:1 - + COUNT 10              # Latest first
```

### RedisBloom
```bash
# Bloom filter (probabilistic membership)
BF.ADD filter:emails "user@example.com"
BF.EXISTS filter:emails "user@example.com"    # Returns 1
BF.EXISTS filter:emails "other@example.com"   # Returns 0 (definitely not in set)
BF.RESERVE filter:ips 0.001 1000000           # 0.1% error rate, 1M capacity

# Cuckoo filter (supports deletion)
CF.ADD cuckoo:sessions "session123"
CF.EXISTS cuckoo:sessions "session123"
CF.DEL cuckoo:sessions "session123"

# Count-Min Sketch (frequency estimation)
CMS.INITBYDIM sketch:pageviews 2000 5
CMS.INCRBY sketch:pageviews "/home" 1 "/about" 3
CMS.QUERY sketch:pageviews "/home"

# Top-K
TOPK.RESERVE popular:pages 10
TOPK.ADD popular:pages "/home" "/about" "/products"
TOPK.LIST popular:pages
```

## Persistence

### RDB Snapshots
```
# redis.conf
save 3600 1          # Snapshot every 3600s if >= 1 key changed
save 300 100         # Snapshot every 300s if >= 100 keys changed
save 60 10000        # Snapshot every 60s if >= 10000 keys changed
dbfilename dump.rdb
dir /data/redis

rdbcompression yes
rdbchecksum yes
stop-writes-on-bgsave-error yes

# Manual snapshot
redis-cli BGSAVE
redis-cli LASTSAVE
```

### AOF (Append-Only File)
```
appendonly yes
appendfilename "appendonly.aof"
appenddirname "appendonlydir"     # Redis 7.0+ multi-part AOF

# fsync policies
appendfsync always       # Every write (safest, slowest)
appendfsync everysec     # Every second (recommended)
appendfsync no           # OS decides (fastest, least safe)

# AOF rewrite (compact the AOF)
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
redis-cli BGREWRITEAOF

# Hybrid persistence (Redis 7.0+): RDB preamble + AOF tail
aof-use-rdb-preamble yes
```

### Fork Overhead
- BGSAVE / BGREWRITEAOF uses fork() (copy-on-write)
- Peak memory can double during fork if high write rate
- Monitor: `latest_fork_usec` in INFO stats
- Mitigation: use jemalloc, avoid huge instances, use `io-threads` for IO offloading

## Latency Diagnostics

```bash
# Built-in latency monitoring
redis-cli --latency                          # Continuous ping test
redis-cli --latency-history --interval 15    # Historical (15s buckets)
redis-cli --latency-dist                     # Distribution

# Latency monitoring framework
CONFIG SET latency-monitor-threshold 100     # Track events >100ms
LATENCY LATEST                               # Latest latency events
LATENCY HISTORY command                      # History for event type
LATENCY RESET                                # Clear history

# Slow log
CONFIG SET slowlog-log-slower-than 10000     # Log commands >10ms
CONFIG SET slowlog-max-len 128
SLOWLOG GET 25                               # Get last 25 slow commands
SLOWLOG RESET
SLOWLOG LEN

# Client analysis
CLIENT LIST                                  # All connected clients
CLIENT INFO                                  # Current client info
CLIENT GETNAME
CLIENT NO-EVICT ON                           # Protect critical connections

# Memory analysis
INFO memory
MEMORY USAGE key_name [SAMPLES count]
MEMORY DOCTOR
MEMORY STATS
MEMORY MALLOC-STATS
redis-cli --bigkeys                          # Find large keys (uses SCAN)
redis-cli --memkeys                          # Memory per key analysis
```

## Configuration Tuning

### Memory
```
maxmemory 8gb
maxmemory-policy allkeys-lfu     # Eviction policy

# Eviction policies:
# noeviction          - Return errors when memory limit reached
# allkeys-lru         - Evict any key using LRU
# allkeys-lfu         - Evict any key using LFU (recommended for cache)
# allkeys-random      - Evict any key randomly
# volatile-lru        - Evict keys with TTL using LRU
# volatile-lfu        - Evict keys with TTL using LFU
# volatile-random     - Evict keys with TTL randomly
# volatile-ttl        - Evict keys with shortest TTL

# LFU tuning
lfu-log-factor 10        # Logarithmic counter factor
lfu-decay-time 1         # Counter decay time in minutes
```

### Performance
```
# IO threads (Redis 6.0+)
io-threads 4                  # Number of IO threads
io-threads-do-reads yes       # Also use threads for reads

# Event loop frequency
hz 10                          # Default (10-100, higher = more CPU, lower latency)
dynamic-hz yes                 # Adjust based on client connections

# Connection handling
timeout 300                    # Close idle connections after 300s
tcp-keepalive 300             # TCP keepalive interval
tcp-backlog 511               # TCP listen backlog

# Lazy freeing (async deletion)
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
lazyfree-lazy-user-del yes
lazyfree-lazy-user-flush yes
```

### Memory Optimization Thresholds
```
# Compact encodings for small structures
hash-max-listpack-entries 128       # Use listpack if <= 128 entries
hash-max-listpack-value 64          # Use listpack if values <= 64 bytes
list-max-listpack-size -2           # -2 = 8KB per node
list-max-ziplist-size -2            # Legacy name
set-max-intset-entries 512          # Use intset if all integers <= 512
set-max-listpack-entries 128        # Use listpack for small string sets
zset-max-listpack-entries 128       # Use listpack for small sorted sets
zset-max-listpack-value 64
```

## Security

### ACL (Access Control Lists)
```bash
# Create user with specific permissions
ACL SETUSER appuser on >strongpassword ~app:* +@read +@write -@admin
ACL SETUSER readonly on >readpass ~* +@read -@write -@admin +ping
ACL SETUSER admin on >adminpass ~* +@all

# Key patterns
ACL SETUSER user1 ~cache:* ~session:*     # Only specific prefixes
ACL SETUSER user2 ~* &channel:*           # Key + pub/sub patterns

# Manage
ACL LIST
ACL GETUSER appuser
ACL DELUSER appuser
ACL SAVE                                   # Persist to aclfile
ACL LOAD                                   # Reload from aclfile
ACL LOG [count]                            # Failed auth log

# File-based ACL
aclfile /etc/redis/users.acl
```

### TLS
```
# redis.conf
tls-port 6380
port 0                           # Disable non-TLS
tls-cert-file /path/redis.crt
tls-key-file /path/redis.key
tls-ca-cert-file /path/ca.crt
tls-auth-clients optional        # or "yes" for mutual TLS
tls-protocols "TLSv1.2 TLSv1.3"
tls-ciphersuites TLS_AES_256_GCM_SHA384

# Replication TLS
tls-replication yes

# Cluster TLS
tls-cluster yes
```

### Additional Security
```
# Protected mode (default on: rejects external connections without auth)
protected-mode yes

# Rename dangerous commands (legacy approach, prefer ACL)
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG "CONFIG_SECRET_CMD"
rename-command DEBUG ""
```

## Valkey Migration

### Compatibility
- Valkey is a fork of Redis 7.2.4 under Linux Foundation governance
- Full RESP protocol compatibility
- Drop-in replacement for Redis (same commands, same configuration)
- Valkey-specific additions: multi-threaded improvements, community-driven features

### Migration Steps
```bash
# 1. Test compatibility with existing clients/libraries
# 2. Replace redis-server binary with valkey-server
# 3. Rename config: redis.conf -> valkey.conf (optional, both work)
# 4. Update systemd/supervisord service files
# 5. Update monitoring (metrics names unchanged)
# 6. Update client library if Valkey-specific client exists

# Valkey CLI
valkey-cli -h localhost -p 6379 INFO server
# "redis_version" field still present for compatibility
```

### Fork Differences
- Governance: Linux Foundation (open) vs Redis Ltd (dual license)
- License: BSD 3-Clause (Valkey) vs RSALv2/SSPL (Redis 7.4+)
- Community: AWS, Google, Oracle, Ericsson contributors
- Roadmap: Community-driven feature development, multi-threading focus
