# Redis Cluster & Sentinel

## When to load
Load when designing Redis high availability, scaling beyond single instance, or choosing between Sentinel and Cluster.

## Sentinel vs Cluster

| Feature | Sentinel | Cluster |
|---------|----------|---------|
| Purpose | HA (automatic failover) | HA + horizontal scaling |
| Data sharding | No (single master) | Yes (16384 hash slots) |
| Max data size | Single server RAM | Sum of all node RAM |
| Write scaling | Single master | Multiple masters |
| Multi-key operations | All keys | Same hash slot only |
| Complexity | Low | Medium-High |
| When to use | < 25GB, need HA | > 25GB or need write scaling |

## Sentinel Architecture

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Sentinel 1  │  │  Sentinel 2  │  │  Sentinel 3  │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       ▼                 ▼                 ▼
  ┌─────────┐     ┌─────────────┐   ┌─────────────┐
  │ Master  │────→│  Replica 1   │   │  Replica 2   │
  └─────────┘     └─────────────┘   └─────────────┘

Failover: Sentinels detect master down → quorum vote → promote replica
Typical: 3 Sentinels, 1 master, 2 replicas
```

```
# sentinel.conf
sentinel monitor mymaster 10.0.0.1 6379 2    # quorum = 2
sentinel down-after-milliseconds mymaster 5000 # 5s to detect failure
sentinel failover-timeout mymaster 30000       # 30s failover timeout
sentinel parallel-syncs mymaster 1             # 1 replica syncs at a time
```

```typescript
// Node.js connection with ioredis (Sentinel-aware)
import Redis from 'ioredis';

const redis = new Redis({
  sentinels: [
    { host: 'sentinel-1', port: 26379 },
    { host: 'sentinel-2', port: 26379 },
    { host: 'sentinel-3', port: 26379 },
  ],
  name: 'mymaster',        // Sentinel group name
  sentinelPassword: 'xxx', // if Sentinel auth enabled
  password: 'yyy',         // Redis instance password
  db: 0,
  // Automatic failover: ioredis reconnects to new master
});
```

## Cluster Architecture

```
┌──────────────────────────────────────────┐
│            16384 Hash Slots              │
│                                          │
│  Slots 0-5460    │ Slots 5461-10922 │ Slots 10923-16383 │
│  Master A        │ Master B         │ Master C           │
│  └─ Replica A1   │ └─ Replica B1    │ └─ Replica C1      │
│                  │                  │                    │
└──────────────────────────────────────────┘

Key → CRC16(key) % 16384 → slot → node
Minimum: 3 masters + 3 replicas = 6 nodes
```

```typescript
// Node.js Cluster connection
import Redis from 'ioredis';

const cluster = new Redis.Cluster([
  { host: 'node-1', port: 6379 },
  { host: 'node-2', port: 6379 },
  { host: 'node-3', port: 6379 },
], {
  redisOptions: { password: 'xxx' },
  scaleReads: 'slave',     // read from replicas
  maxRedirections: 16,     // handle MOVED/ASK redirects
  retryDelayOnClusterDown: 300,
});

// Hash tags: force keys to same slot
// {user:42}:profile and {user:42}:settings → same slot
await cluster.set('{user:42}:profile', '...');
await cluster.set('{user:42}:settings', '...');
// Now MGET works across both keys
```

## Cluster Operations

```
# Create cluster
redis-cli --cluster create \
  node1:6379 node2:6379 node3:6379 \
  node4:6379 node5:6379 node6:6379 \
  --cluster-replicas 1

# Add node
redis-cli --cluster add-node new-node:6379 existing-node:6379

# Reshard (move slots)
redis-cli --cluster reshard existing-node:6379

# Check cluster health
redis-cli --cluster check node1:6379
```

## Managed Redis (AWS ElastiCache / GCP Memorystore)

```
ElastiCache:
  Cluster Mode Disabled: 1 shard, up to 5 replicas (Sentinel-like)
  Cluster Mode Enabled: up to 500 shards, auto-failover

Sizing guide:
  < 25GB, read-heavy    → Cluster Mode Disabled + replicas
  < 25GB, write-heavy   → Cluster Mode Disabled, scale up instance
  > 25GB                 → Cluster Mode Enabled
  Multi-region           → Global Datastore (async cross-region replication)
```

## Anti-patterns
- Running Sentinel with fewer than 3 nodes → split-brain risk
- Multi-key operations in Cluster without hash tags → CROSSSLOT error
- KEYS/FLUSHALL in Cluster → hits only one node, use per-node
- No persistence (RDB/AOF) with Sentinel → data loss on full cluster restart

## Quick reference
```
Sentinel: HA for single-master, 3+ sentinels, automatic failover
Cluster: HA + sharding, 3+ masters with replicas, 16384 slots
Hash tags: {tag}:key forces same slot for multi-key ops
Sentinel quorum: majority of sentinels must agree on failure
Cluster minimum: 6 nodes (3 masters + 3 replicas)
Scaling reads: replica reads in both Sentinel and Cluster
Managed: ElastiCache Cluster Mode for > 25GB or high writes
Failover time: 5-15s typical (Sentinel), 1-2s (Cluster)
```
