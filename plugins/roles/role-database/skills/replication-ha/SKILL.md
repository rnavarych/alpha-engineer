---
name: replication-ha
description: |
  High availability and replication topologies across all database engines. Synchronous/asynchronous/semi-synchronous replication, primary-secondary, multi-primary, quorum-based. PostgreSQL streaming/logical replication, MySQL GTID/Group Replication, MongoDB replica sets, Redis Sentinel/Cluster, Cassandra multi-DC. Consensus protocols (Raft, Paxos, Gossip). Failover automation, split-brain prevention. Use when designing HA architectures, configuring replication, or troubleshooting failover.
allowed-tools: Read, Grep, Glob, Bash
---

# Replication & High Availability

## Replication Modes

| Mode | Durability | Latency | Use Case |
|------|-----------|---------|----------|
| **Synchronous** | Zero data loss (RPO=0) | Higher (waits for replica ACK) | Financial transactions, compliance |
| **Semi-synchronous** | Near-zero data loss | Medium (waits for 1 replica ACK) | Important data, balanced performance |
| **Asynchronous** | Possible data loss on failover | Lowest | Read scaling, analytics, DR |

## Topologies

### Primary-Secondary (Master-Replica)
- One writable primary, N read-only secondaries
- Simple, well-understood, most common
- Failover requires promoting a secondary
- **Engines**: PostgreSQL, MySQL, MongoDB, Redis Sentinel, SQL Server AG

### Multi-Primary (Master-Master)
- Multiple writable nodes, conflict resolution required
- Higher write availability, complex conflict handling
- **Engines**: MySQL Group Replication (single-primary or multi-primary), Galera Cluster, CouchDB, Cassandra, CockroachDB, YugabyteDB

### Quorum-Based
- Write requires majority acknowledgment (W > N/2)
- Read consistency depends on R + W > N
- **Engines**: MongoDB (replica set elections), Cassandra (tunable consistency), etcd (Raft)

## Engine-Specific Replication

### PostgreSQL

**Streaming Replication (Physical)**
```
# Primary: postgresql.conf
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB
synchronous_standby_names = 'first 1 (standby1, standby2)'  # sync mode

# Standby: recovery config
primary_conninfo = 'host=primary port=5432 user=replicator'
primary_slot_name = 'standby1_slot'
```

**Logical Replication (Table-Level)**
```sql
-- Publisher (primary)
CREATE PUBLICATION my_pub FOR TABLE orders, customers;

-- Subscriber (secondary)
CREATE SUBSCRIPTION my_sub
    CONNECTION 'host=primary dbname=mydb'
    PUBLICATION my_pub;
```

**Key Differences:**
- Streaming: entire database, byte-level, cannot filter tables
- Logical: selective tables/columns, cross-version, allows writes on subscriber

**Replication Slots:**
- Prevent WAL removal before replica consumption
- Monitor with `pg_stat_replication` and `pg_replication_slots`
- Inactive slots accumulate WAL — monitor disk usage!

### MySQL

**GTID Replication**
```
# my.cnf (both primary and replica)
gtid_mode = ON
enforce_gtid_consistency = ON
server_id = 1  # unique per server

# Replica setup
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'primary',
    SOURCE_USER = 'repl_user',
    SOURCE_AUTO_POSITION = 1;
START REPLICA;
```

**Group Replication (InnoDB Cluster)**
- Paxos-based consensus for synchronous replication
- Single-primary (default) or multi-primary mode
- Automatic member management, conflict detection
- MySQL Router for transparent client routing
- MySQL Shell for cluster administration

**Semi-Synchronous**
```sql
-- Primary
INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
SET GLOBAL rpl_semi_sync_master_enabled = 1;
SET GLOBAL rpl_semi_sync_master_wait_for_slave_count = 1;
SET GLOBAL rpl_semi_sync_master_timeout = 10000;  -- ms, fallback to async
```

### MongoDB Replica Sets

**Architecture:**
- Odd number of voting members (3, 5, 7 — max 7 voters)
- Priority-based elections (highest priority wins primary)
- Arbiter: votes but holds no data (use sparingly, prefer full data members)

**Write Concern:**
```javascript
// Majority: acknowledged by majority of replica set
db.orders.insertOne({...}, { writeConcern: { w: "majority", wtimeout: 5000 } });

// w: 1 — primary only (default, faster, less durable)
// w: "majority" — majority of data-bearing members
// w: <number> — specific number of members
// j: true — wait for journal flush
```

**Read Preference:**
```javascript
// Read from secondaries for read scaling
db.collection.find().readPref("secondaryPreferred");

// Options: primary, primaryPreferred, secondary, secondaryPreferred, nearest
// Tag sets for geo-routing: readPref("nearest", [{ region: "us-east" }])
```

### Redis

**Sentinel (HA for standalone Redis)**
```
# sentinel.conf
sentinel monitor mymaster 192.168.1.1 6379 2    # quorum=2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
```

**Cluster Mode**
- 16384 hash slots distributed across nodes
- Each master has 1+ replicas
- Automatic failover within slot range
- Client must support cluster protocol (MOVED/ASK redirections)

### Cassandra

**Multi-DC Replication**
```yaml
# Keyspace with NetworkTopologyStrategy
CREATE KEYSPACE production WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'dc1': 3,
    'dc2': 3
};
```

**Consistency Levels for Multi-DC:**
- `LOCAL_QUORUM`: Quorum within local DC (recommended for most use cases)
- `EACH_QUORUM`: Quorum in every DC (strong, high latency)
- `LOCAL_ONE`: One node in local DC (fastest, weakest)

## Consensus Protocols

| Protocol | Used By | Properties |
|----------|---------|------------|
| **Raft** | etcd, CockroachDB, TiDB, Consul | Leader-based, easy to understand, log replication |
| **Paxos** | Google Spanner, MySQL Group Replication | Proven correctness, complex implementation |
| **Gossip** | Cassandra, ScyllaDB, DynamoDB | Eventually consistent, epidemic protocol, ring topology |
| **Zab** | ZooKeeper | Atomic broadcast, total order, crash recovery |
| **ISR (In-Sync Replicas)** | Kafka | Leader-follower with ISR set, min.insync.replicas |

## Failover Automation

### Failover Types
- **Automatic**: System detects failure, promotes replica (Sentinel, AG, Patroni)
- **Manual**: DBA triggers promotion (pg_promote, CHANGE REPLICATION SOURCE)
- **Semi-automatic**: System detects, alerts, human approves

### PostgreSQL with Patroni
- DCS-backed (etcd/Consul/ZooKeeper) leader election
- Automatic failover with configurable policies
- REST API for health checks and switchover
- Integrates with HAProxy/PgBouncer for client routing

### Split-Brain Prevention
1. **Quorum requirement**: Majority of nodes must agree on leader
2. **Fencing**: STONITH (Shoot The Other Node In The Head) to stop old primary
3. **Watchdog timers**: Kernel-level process to ensure node shutdown
4. **Network partitioning**: Use minimum replica count before accepting writes

## Monitoring Replication

### Key Metrics to Alert On

| Metric | Engine | Alert Threshold |
|--------|--------|-----------------|
| **Replication lag** | PostgreSQL: `pg_stat_replication.replay_lag` | > 30 seconds |
| **Replication lag** | MySQL: `Seconds_Behind_Source` | > 30 seconds |
| **Replication lag** | MongoDB: `rs.printReplicationInfo()` | > 10 seconds |
| **Replication lag** | Redis: `INFO replication → master_last_io_seconds_ago` | > 10 seconds |
| **WAL retention** | PostgreSQL: slot lag bytes | > 1 GB |
| **ISR count** | Kafka: `UnderReplicatedPartitions` | < replication factor |
| **Replica state** | All: replica connected and applying | Not in sync |

## Quick Reference

1. **Default choice**: Async replication with promotion for read scaling + DR
2. **Financial/compliance**: Synchronous replication with RPO=0
3. **Global distribution**: Multi-region with local reads, cross-region async writes
4. **Always test failover**: Schedule regular failover drills in staging
5. **Monitor replication lag**: Alert before lag exceeds business RPO
6. **Document runbooks**: Step-by-step failover procedures for on-call engineers
