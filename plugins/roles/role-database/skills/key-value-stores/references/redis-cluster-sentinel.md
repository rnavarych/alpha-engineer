# Redis / Valkey — Cluster Mode, Sentinel, Data Structures

## When to load
Load when setting up Redis cluster, configuring Sentinel HA, working with hash tags, resharding slots, or using core data structures (Strings, Lists, Sets, Sorted Sets, Hashes, HyperLogLog, Bitmaps, Geospatial).

## Cluster Architecture

- 16384 hash slots distributed across master nodes
- Hash tags: `{user:1001}.profile` and `{user:1001}.sessions` map to same slot
- Clients use `CLUSTER SLOTS` or `CLUSTER SHARDS` to discover topology

```bash
# Create cluster (3 masters, 1 replica each)
redis-cli --cluster create \
  node1:6379 node2:6379 node3:6379 node4:6379 node5:6379 node6:6379 \
  --cluster-replicas 1

redis-cli --cluster check node1:6379
redis-cli CLUSTER INFO
redis-cli CLUSTER NODES

# Reshard slots
redis-cli --cluster reshard node1:6379 \
  --cluster-from <source-id> --cluster-to <target-id> --cluster-slots 1000 --cluster-yes

# Add / remove nodes
redis-cli --cluster add-node new_host:6379 existing_host:6379
redis-cli --cluster del-node existing_host:6379 <node-id>
```

```
# redis.conf for cluster mode
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-migration-barrier 1
cluster-allow-reads-when-down yes
```

## Sentinel High Availability

```
# sentinel.conf
sentinel monitor mymaster 10.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel auth-pass mymaster <password>
```

```bash
redis-cli -p 26379 SENTINEL masters
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
redis-cli -p 26379 SENTINEL failover mymaster

# Safety: require minimum replicas before accepting writes
min-replicas-to-write 1
min-replicas-max-lag 10
```

## Core Data Structures

```bash
# Strings
SET key value EX 3600 NX
INCR counter
GETDEL key
GETEX key EX 100

# Lists
LPUSH list val1 val2
RPOP list [count]
LRANGE list 0 -1
BLPOP list 5

# Sets
SADD set member1 member2
SISMEMBER set member1
SINTER set1 set2
SUNION set1 set2
SMISMEMBER set m1 m2 m3

# Sorted Sets
ZADD zset [NX|XX|GT|LT] score member
ZRANGE zset 0 -1 WITHSCORES REV
ZRANGEBYSCORE zset min max WITHSCORES LIMIT offset count
ZRANK zset member
ZINCRBY zset 5 member
BZPOPMIN zset 5
ZUNIONSTORE dest 2 zset1 zset2 WEIGHTS 1 2 AGGREGATE SUM

# Hashes
HSET hash field1 val1 field2 val2
HMGET hash field1 field2
HGETALL hash
HINCRBY hash field 10
HSCAN hash 0 MATCH "user:*"

# HyperLogLog
PFADD hll element1 element2
PFCOUNT hll
PFMERGE dest hll1 hll2

# Bitmaps / Bitfields
SETBIT bitmap 1000 1
BITCOUNT bitmap
BITOP AND dest bm1 bm2
BITFIELD bf SET u8 0 200

# Geospatial
GEOADD geo -122.42 37.77 "San Francisco"
GEODIST geo "San Francisco" "New York" km
GEOSEARCH geo FROMLONLAT -122.42 37.77 BYRADIUS 100 km ASC COUNT 10
```

## Valkey Migration

Valkey is a Linux Foundation fork of Redis 7.2.4 — full RESP compatibility, drop-in replacement. License: BSD 3-Clause vs Redis RSALv2/SSPL (7.4+). Replace `redis-server` binary with `valkey-server`; config, commands, and metrics names are unchanged.
