# Data Partitioning

## When to load
Load when discussing database sharding strategies, partition key design, consistent hashing, or PostgreSQL native partitioning.

## Patterns

### Sharding strategies

#### By tenant (multi-tenant SaaS)
```typescript
// Each tenant's data in a separate shard/schema
// Routing: tenant_id -> shard mapping in config DB

const shardMap: Record<string, string> = {
  'tenant-acme': 'shard-01.db.example.com',
  'tenant-globex': 'shard-02.db.example.com',
};

function getShardForTenant(tenantId: string): DatabaseConnection {
  const host = shardMap[tenantId];
  if (!host) throw new Error(`No shard for tenant: ${tenantId}`);
  return connectionPools.get(host);
}

// Pros: strong data isolation, per-tenant scaling, easy compliance
// Cons: cross-tenant queries impossible, uneven shard sizes
```

#### By geography
```sql
-- Route data to nearest region for latency + compliance
-- EU users -> eu-west shard (GDPR compliance)
-- US users -> us-east shard
-- APAC users -> ap-southeast shard

CREATE TABLE orders (
  id UUID NOT NULL,
  region TEXT NOT NULL,
  user_id UUID NOT NULL,
  total DECIMAL(10,2),
  PRIMARY KEY (region, id)
);

-- CockroachDB geo-partitioning
ALTER TABLE orders PARTITION BY LIST (region) (
  PARTITION eu VALUES IN ('eu-west-1', 'eu-central-1'),
  PARTITION us VALUES IN ('us-east-1', 'us-west-2'),
  PARTITION apac VALUES IN ('ap-southeast-1', 'ap-northeast-1')
);
ALTER PARTITION eu OF TABLE orders CONFIGURE ZONE USING
  constraints = '[+region=eu-west-1]';
```

#### By hash (even distribution)
```typescript
// Consistent hashing: distribute keys evenly across shards
function getShardIndex(key: string, totalShards: number): number {
  const hash = crypto.createHash('md5').update(key).digest();
  const hashInt = hash.readUInt32BE(0);
  return hashInt % totalShards;
}
```

### Partition key design
```
Good partition keys:
- user_id: even distribution if many users, natural access pattern
- tenant_id: multi-tenant isolation, compliance-friendly
- order_id: high cardinality, no hot spots
- date + random: time-series with even distribution

Bad partition keys:
- status: low cardinality (3-5 values), creates hot partitions
- country: uneven (US >> Liechtenstein)
- boolean: only 2 values, half the data per partition
- sequential ID: all recent writes hit same partition

DynamoDB rule: partition key must have >100 distinct values per shard
PostgreSQL rule: partition by range (date) for time-series, list for tenant
```

### Consistent hashing
```
Traditional hashing: key % N shards
Problem: adding/removing a shard rehashes EVERYTHING

Consistent hashing: keys and shards on a hash ring
Adding a shard: only ~1/N of keys move
Removing a shard: only that shard's keys redistribute

Virtual nodes: each physical shard has 100-200 virtual positions
on the ring for even distribution
```

```typescript
class ConsistentHash {
  private ring: Map<number, string> = new Map();
  private sortedKeys: number[] = [];
  private virtualNodes = 150;

  addNode(node: string) {
    for (let i = 0; i < this.virtualNodes; i++) {
      const hash = this.hash(`${node}:${i}`);
      this.ring.set(hash, node);
      this.sortedKeys.push(hash);
    }
    this.sortedKeys.sort((a, b) => a - b);
  }

  getNode(key: string): string {
    const hash = this.hash(key);
    let idx = this.sortedKeys.findIndex(k => k >= hash);
    if (idx === -1) idx = 0; // wrap around
    return this.ring.get(this.sortedKeys[idx])!;
  }

  private hash(key: string): number {
    return crypto.createHash('md5').update(key).digest().readUInt32BE(0);
  }
}
```

### PostgreSQL native partitioning
```sql
-- Range partitioning (time-series)
CREATE TABLE events (
  id BIGSERIAL,
  created_at TIMESTAMPTZ NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB
) PARTITION BY RANGE (created_at);

-- Monthly partitions
CREATE TABLE events_2024_01 PARTITION OF events
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Auto-create future partitions with pg_partman
CREATE EXTENSION pg_partman;
SELECT partman.create_parent('public.events', 'created_at', 'native', 'monthly');

-- Drop old partitions (data retention)
DROP TABLE events_2023_01;  -- instant, no vacuum needed
```

## Anti-patterns
- Sharding before you need it -> premature complexity (start with read replicas + partitioning)
- Low-cardinality partition key -> hot partitions, uneven load
- Sequential IDs as partition key -> all writes hit one partition

## Decision criteria
- **No sharding**: <500GB data, <10k TPS, single PostgreSQL with partitioning
- **Read replicas**: read-heavy, <50k TPS, can tolerate slight replication lag
- **Application-level sharding**: >500GB, >10k write TPS, need tenant isolation
- **Distributed SQL (CockroachDB)**: multi-region, automatic rebalancing, strong consistency
- **Consistent hashing**: need to add/remove shards without full redistribution

## Quick reference
```
Start: single DB + partitioning -> read replicas -> sharding
Partition key: high cardinality, even distribution, matches access pattern
Consistent hashing: 150 virtual nodes per physical shard
PostgreSQL partitioning: RANGE for time-series, LIST for tenant
DynamoDB: >100 distinct partition key values per shard
```
