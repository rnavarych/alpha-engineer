# Azure Cosmos DB

## When to load
Load when working with Azure Cosmos DB: partition key design, consistency level selection, Core SQL API, change feed, global distribution, multi-region writes, RU optimization.

## Partition Key Design

```javascript
// Critical design decision: cannot change after creation
// Each partition: max 20 GB, 10,000 RU/s

// Good partition keys (high cardinality, even distribution):
// /tenantId, /userId, /orderId

// Bad partition keys:
// /status (low cardinality → hot partitions)
// /createdAt (sequential → hot partition)
// /country (skewed distribution)

// Hierarchical partition keys (multi-level)
const container = database.containers.create({
    id: "orders",
    partitionKey: {
        paths: ["/tenantId", "/region", "/orderId"],
        kind: "MultiHash",
        version: 2
    }
});
```

## 5 Consistency Levels

```
Strong ←————————————————————————————→ Eventual
  Strong | Bounded Staleness | Session | Consistent Prefix | Eventual

Strong: linearizable reads, 2x RU cost
  → financial transactions, inventory management

Bounded Staleness: reads lag by max K versions or T time
  → leaderboards, analytics with staleness tolerance

Session (default): read-your-own-writes within a session
  → most web/mobile apps, good balance

Consistent Prefix: no out-of-order writes
  → social feeds, activity logs

Eventual: lowest latency, no ordering guarantee
  → counters, non-critical reads, 1x RU baseline
```

## Core SQL API

```javascript
const { CosmosClient } = require("@azure/cosmos");
const client = new CosmosClient({ endpoint, key });

const { resource: order } = await client
    .database("shop").container("orders")
    .items.create({
        id: "order-123",
        partitionKey: "tenant-1",
        amount: 99.99, status: "pending"
    });

// Parameterized query
const { resources: orders } = await client.database("shop").container("orders")
    .items.query({ query: "SELECT * FROM c WHERE c.status = @status AND c.amount > @min",
        parameters: [{ name: "@status", value: "pending" }, { name: "@min", value: 50 }]
    }).fetchAll();
```

## Change Feed

```javascript
// Ordered stream of changes per partition
const iterator = container.items
    .changeFeed("partition-key-1", { startFromBeginning: true });

while (iterator.hasMoreResults) {
    const { resources, continuationToken } = await iterator.fetchNext();
    for (const change of resources) {
        console.log("Changed document:", change);
    }
    // Save continuationToken for resume
}
// Use cases: event sourcing, real-time notifications, search index updates
```

## Global Distribution

```bash
# Add read regions
az cosmosdb update --name myaccount --resource-group mygroup \
  --locations regionName=eastus failoverPriority=0 isZoneRedundant=true \
  --locations regionName=westeurope failoverPriority=1 isZoneRedundant=true

# Multi-region writes (multi-master)
az cosmosdb update --name myaccount --resource-group mygroup \
  --enable-multiple-write-locations true
# Conflict resolution: LastWriterWins (default), Custom, or Manual
```

## RU Provisioning

```
Manual: 400-unlimited RU/s (billed per hour)
Autoscale: 100-max RU/s (auto-adjusts, 10% minimum billed)
Serverless: pay per request (dev/test, sporadic workloads)
```

## Operational Notes

- Choose partition key carefully — migration requires full data rewrite
- Start with Session consistency, upgrade only if required
- Use change feed instead of polling; monitor RU per partition for hot spots
- Autoscale with realistic max RU/s to avoid cost surprises
