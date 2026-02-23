# Shard Management

## When to load
Load when discussing shard rebalancing, cross-shard queries, scatter-gather patterns, or operational concerns around running a sharded database in production.

## Patterns

### Rebalancing shards
```
When you need to rebalance:
- One shard is significantly larger than others (hot tenant)
- Adding capacity by introducing new shards
- Removing a shard to consolidate underused capacity

Consistent hashing rebalancing:
- Adding a shard: only ~1/N of keys move to the new node
- Removing a shard: only that node's keys redistribute clockwise
- Always rebalance during low-traffic window

Manual shard split (tenant-based):
1. Identify oversized shard
2. Export hot tenant's data
3. Provision new shard
4. Import data to new shard
5. Update routing table (tenant_id -> new shard)
6. Verify reads/writes on new shard
7. Delete data from old shard
```

```typescript
// Hot shard detection: monitor row count and query latency per shard
async function detectHotShards(threshold = 2.0): Promise<string[]> {
  const stats = await Promise.all(
    ALL_SHARDS.map(async (shard) => ({
      shard,
      rowCount: await shard.query('SELECT COUNT(*) FROM orders').then(r => r.rows[0].count),
      p95Latency: await shard.query(
        `SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY duration_ms)
         FROM pg_stat_statements WHERE query ILIKE '%orders%'`
      ).then(r => r.rows[0].percentile_cont),
    }))
  );

  const avgCount = stats.reduce((sum, s) => sum + s.rowCount, 0) / stats.length;
  return stats
    .filter(s => s.rowCount > avgCount * threshold)
    .map(s => s.shard);
}
```

### Cross-shard queries
```typescript
// Scatter-gather pattern (expensive, avoid in hot paths)
async function searchAllShards(query: SearchQuery): Promise<Result[]> {
  const shards = getAllShardConnections();
  const results = await Promise.all(
    shards.map(shard => shard.query(
      'SELECT * FROM products WHERE name ILIKE $1 LIMIT $2',
      [`%${query.term}%`, query.limit]
    ))
  );
  // Merge and re-sort across shards
  return results
    .flat()
    .sort((a, b) => b.relevance - a.relevance)
    .slice(0, query.limit);
}

// Better: maintain a search index (Elasticsearch) that spans all shards
// Write to shard + publish event -> consumer indexes in Elasticsearch
// Search queries hit Elasticsearch, detail queries hit specific shard
```

```typescript
// Cross-shard aggregation with fan-out
async function getTotalRevenue(dateRange: DateRange): Promise<number> {
  const shardTotals = await Promise.all(
    ALL_SHARDS.map(shard =>
      shard.query(
        'SELECT SUM(total_cents) as total FROM orders WHERE created_at BETWEEN $1 AND $2',
        [dateRange.from, dateRange.to]
      ).then(r => Number(r.rows[0].total) || 0)
    )
  );
  return shardTotals.reduce((sum, t) => sum + t, 0);
}

// Cache aggregated results — re-querying all shards on every request is expensive
// Use a dedicated analytics DB (read replicas + materialized views) instead
```

### Operational concerns
```
Routing table management:
- Store tenant-to-shard mapping in a config DB (not in app config files)
- Cache routing table in application memory (refresh every 60s)
- Never hard-code shard assignments in application code

Connection management:
- Maintain connection pools per shard (not one giant pool)
- Monitor pool exhaustion per shard independently
- Set statement_timeout per shard (same as single-DB setup)

Backup strategy:
- Back up each shard independently on staggered schedule
- Test restore per shard — restoring all shards simultaneously strains infrastructure
- Point-in-time recovery must be consistent across shards for distributed transactions

Monitoring per shard:
- Row count growth rate
- Query latency p50/p95/p99
- Connection pool utilization
- Replication lag (if using read replicas per shard)
```

```typescript
// Routing table with in-memory cache
class ShardRouter {
  private cache: Map<string, string> = new Map();
  private cacheExpiry = 0;
  private TTL = 60_000; // 60s

  async getShardForTenant(tenantId: string): Promise<string> {
    if (Date.now() > this.cacheExpiry) {
      const rows = await configDb.query('SELECT tenant_id, shard_host FROM tenant_shard_map');
      this.cache = new Map(rows.map(r => [r.tenant_id, r.shard_host]));
      this.cacheExpiry = Date.now() + this.TTL;
    }

    const host = this.cache.get(tenantId);
    if (!host) throw new Error(`No shard for tenant: ${tenantId}`);
    return host;
  }
}
```

## Anti-patterns
- Cross-shard joins in hot path -> latency multiplied by shard count
- Sharding without considering rebalancing -> stuck with bad distribution forever
- One connection pool for all shards -> pool exhaustion on one shard affects all
- Routing table in application config -> requires redeploy to move a tenant

## Quick reference
```
Hot shard detection: monitor row count and p95 latency per shard
Rebalancing: consistent hashing moves only ~1/N keys
Cross-shard: scatter-gather (expensive) or search index (preferred)
Routing table: config DB + in-memory cache (60s TTL), never in app config
Connection pools: one pool per shard, monitor independently
Backups: staggered per shard, test restore per shard
```
