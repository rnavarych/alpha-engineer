# Engine-Specific Replication Configuration

## When to load
Load when configuring replication for PostgreSQL (streaming, logical, slots), MySQL (GTID, Group Replication, semi-synchronous), MongoDB replica sets (write concern, read preference), Redis Sentinel/Cluster, or Cassandra multi-DC.

## Replication Modes

| Mode | Durability | Latency | Use Case |
|------|-----------|---------|----------|
| **Synchronous** | Zero data loss (RPO=0) | Higher | Financial transactions, compliance |
| **Semi-synchronous** | Near-zero data loss | Medium | Important data, balanced performance |
| **Asynchronous** | Possible data loss on failover | Lowest | Read scaling, analytics, DR |

## PostgreSQL

### Streaming Replication (Physical)
```
# Primary: postgresql.conf
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB
synchronous_standby_names = 'first 1 (standby1, standby2)'

# Standby: recovery config
primary_conninfo = 'host=primary port=5432 user=replicator'
primary_slot_name = 'standby1_slot'
```

### Logical Replication (Table-Level)
```sql
-- Publisher (primary)
CREATE PUBLICATION my_pub FOR TABLE orders, customers;

-- Subscriber (secondary)
CREATE SUBSCRIPTION my_sub
    CONNECTION 'host=primary dbname=mydb'
    PUBLICATION my_pub;
```

**Key differences:** Streaming = entire database, byte-level, cannot filter. Logical = selective tables/columns, cross-version, allows writes on subscriber.

**Replication Slots:** Prevent WAL removal before replica consumption. Inactive slots accumulate WAL — monitor disk usage with `pg_replication_slots`.

## MySQL

### GTID Replication
```
# my.cnf (both primary and replica)
gtid_mode = ON
enforce_gtid_consistency = ON
server_id = 1  # unique per server
```

```sql
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'primary',
    SOURCE_USER = 'repl_user',
    SOURCE_AUTO_POSITION = 1;
START REPLICA;
```

### Semi-Synchronous
```sql
INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
SET GLOBAL rpl_semi_sync_master_enabled = 1;
SET GLOBAL rpl_semi_sync_master_wait_for_slave_count = 1;
SET GLOBAL rpl_semi_sync_master_timeout = 10000;  -- ms, fallback to async
```

**Group Replication (InnoDB Cluster):** Paxos-based consensus, single-primary or multi-primary, automatic member management, MySQL Router for client routing.

## MongoDB Replica Sets

```javascript
// Write concern: majority = acknowledged by majority of data-bearing members
db.orders.insertOne({...}, { writeConcern: { w: "majority", wtimeout: 5000 } });
// w: 1 = primary only (faster, less durable)
// j: true = wait for journal flush

// Read preference for read scaling
db.collection.find().readPref("secondaryPreferred");
// Options: primary, primaryPreferred, secondary, secondaryPreferred, nearest
// Tag sets for geo-routing: readPref("nearest", [{ region: "us-east" }])
```

**Architecture:** Odd number of voting members (3, 5, 7 — max 7 voters). Priority-based elections. Avoid arbiters — prefer full data members.

## Redis

### Sentinel (HA for Standalone Redis)
```
# sentinel.conf
sentinel monitor mymaster 192.168.1.1 6379 2    # quorum=2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
```

### Cluster Mode
- 16384 hash slots distributed across nodes
- Each master has 1+ replicas, automatic failover within slot range
- Client must support cluster protocol (MOVED/ASK redirections)

## Cassandra Multi-DC

```sql
CREATE KEYSPACE production WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'dc1': 3,
    'dc2': 3
};
-- LOCAL_QUORUM: quorum within local DC (recommended)
-- EACH_QUORUM: quorum in every DC (strong, high latency)
-- LOCAL_ONE: one node in local DC (fastest, weakest)
```

## Consensus Protocols

| Protocol | Used By | Properties |
|----------|---------|------------|
| **Raft** | etcd, CockroachDB, TiDB | Leader-based, log replication |
| **Paxos** | Google Spanner, MySQL Group Replication | Proven correctness, complex |
| **Gossip** | Cassandra, ScyllaDB | Eventually consistent, epidemic |
| **ISR** | Kafka | Leader-follower with in-sync replica set |
