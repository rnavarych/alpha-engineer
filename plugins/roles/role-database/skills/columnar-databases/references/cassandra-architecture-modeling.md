# Apache Cassandra — Architecture, Data Modeling, Compaction, Consistency

## When to load
Load when designing Cassandra keyspaces and tables, choosing partition keys and clustering columns, selecting compaction strategies, configuring consistency levels, or understanding gossip/snitch/vnodes.

## Ring Topology and Virtual Nodes

```yaml
# cassandra.yaml
num_tokens: 256    # Default; some prefer 16-32 for larger clusters
# Cassandra 4.0+: allocate_tokens_for_local_replication_factor for optimal placement
```

Consistent hashing distributes data across nodes. Partitioner (default: Murmur3Partitioner) hashes partition keys to tokens. Gossip protocol: nodes exchange state every second using Phi Accrual Failure Detector.

```yaml
endpoint_snitch: GossipingPropertyFileSnitch    # Production recommended
# cassandra-rackdc.properties
dc=us-east-1
rack=rack1

seed_provider:
  - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:
      - seeds: "10.0.1.1,10.0.2.1,10.0.3.1"
# 2-3 seeds per DC; used for gossip bootstrap only
```

## Replication

```sql
-- Production (multi-DC)
CREATE KEYSPACE production WITH replication = {
  'class': 'NetworkTopologyStrategy', 'dc1': 3, 'dc2': 3
};

-- Dev/test (single DC only)
CREATE KEYSPACE development WITH replication = {
  'class': 'SimpleStrategy', 'replication_factor': 3
};
```

## Data Modeling Rules

```sql
-- Rule 1: One table per query pattern
-- Rule 2: Denormalize aggressively
-- Rule 3: Partition key = equality predicates
-- Rule 4: Clustering columns = range/order predicates
-- Rule 5: Partition size < 100MB (ideal < 10MB), < 100K rows

-- Composite partition key (for even distribution)
PRIMARY KEY ((tenant_id, date), event_id)

-- Multi-column clustering with mixed order
CREATE TABLE messages (
  channel_id UUID, sent_at TIMESTAMP, message_id TIMEUUID,
  sender TEXT, body TEXT,
  PRIMARY KEY (channel_id, sent_at, message_id)
) WITH CLUSTERING ORDER BY (sent_at DESC, message_id DESC);
```

## Compaction Strategies

| Strategy | Best For | Notes |
|---|---|---|
| SizeTieredCompactionStrategy (STCS) | Write-heavy, general | Groups similarly-sized SSTables; high space amplification |
| LeveledCompactionStrategy (LCS) | Read-heavy, space-constrained | Fixed-size levels; higher write amplification |
| TimeWindowCompactionStrategy (TWCS) | Time-series, TTL data | Groups by time window; efficient for time-bucketed data |
| UnifiedCompactionStrategy (UCS) | Cassandra 5.0+, adaptive | Auto-tunes between tiered and leveled |

```sql
ALTER TABLE ks.metrics WITH compaction = {
  'class': 'TimeWindowCompactionStrategy',
  'compaction_window_unit': 'HOURS',
  'compaction_window_size': 1
} AND default_time_to_live = 604800;

ALTER TABLE ks.data WITH compaction = {
  'class': 'UnifiedCompactionStrategy', 'scaling_parameters': 'T4'
};
```

## Consistency Levels

| Level | Nodes Contacted | Pattern |
|---|---|---|
| ONE / LOCAL_ONE | 1 (local DC) | Eventual, fastest |
| QUORUM | RF/2+1 across all DCs | Strong across DCs |
| LOCAL_QUORUM | RF/2+1 in local DC | Strong within DC (production standard) |
| EACH_QUORUM | RF/2+1 in each DC | Strong write in every DC |
| ALL | All replicas | Highest durability, slowest |
| SERIAL / LOCAL_SERIAL | Paxos round | Lightweight transactions |

```
# Standard production:
Write: LOCAL_QUORUM, Read: LOCAL_QUORUM

# Lightweight transactions (compare-and-set):
INSERT INTO users (id, name) VALUES (1, 'Alice') IF NOT EXISTS;
# Uses Paxos — 4 round-trips, significantly slower
```

## Tombstone Management

```yaml
tombstone_warn_threshold: 1000
tombstone_failure_threshold: 100000
gc_grace_seconds: 864000    # 10 days default
```

Tombstones cannot be GC'd until data is consistent across replicas. Run repair before `gc_grace_seconds` expires. Avoid range deletes on wide partitions; use TTL instead of explicit DELETE when possible.

## SAI (Storage-Attached Indexing) — Cassandra 5.0

```sql
CREATE CUSTOM INDEX ON ks.orders (status) USING 'StorageAttachedIndex';
CREATE CUSTOM INDEX ON ks.orders (total) USING 'StorageAttachedIndex';

-- Query with SAI (no ALLOW FILTERING needed)
SELECT * FROM ks.orders WHERE status = 'shipped' AND total > 100;
```
