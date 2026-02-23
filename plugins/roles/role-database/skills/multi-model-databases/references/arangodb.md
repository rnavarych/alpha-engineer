# ArangoDB

## When to load
Load when working with ArangoDB: AQL queries, graph traversal, SmartGraphs sharding, Foxx microservices, ArangoSearch, cluster deployment, or backup/restore.

## AQL Fundamentals

```aql
// Document CRUD
INSERT { _key: "order-123", customer: "alice", amount: 99.99, status: "pending" }
INTO orders RETURN NEW

FOR order IN orders
    FILTER order.status == "pending" AND order.amount > 50
    SORT order.amount DESC LIMIT 10
    RETURN { id: order._key, customer: order.customer, amount: order.amount }

UPSERT { _key: "order-123" }
INSERT { _key: "order-123", customer: "alice", amount: 99.99, status: "pending" }
UPDATE { status: "confirmed", confirmedAt: DATE_NOW() }
IN orders
```

## Graph Traversal

```aql
// Friends-of-friends (depth 2-3)
FOR v, e, p IN 2..3 OUTBOUND 'users/alice' friendships
    OPTIONS { bfs: true, uniqueVertices: 'global' }
    RETURN DISTINCT v

// Shortest path
FOR v, e IN OUTBOUND SHORTEST_PATH 'users/alice' TO 'users/bob' friendships
    RETURN { vertex: v._key, edge: e.type }

// Cross-model: documents + graph
FOR user IN users
    FOR order IN 1..1 OUTBOUND user._id placed_orders
        FOR product IN 1..1 OUTBOUND order._id contains_product
            FILTER product.name == "Widget"
            COLLECT customer = user.name WITH COUNT INTO orderCount
            RETURN { customer, orderCount }
```

## Aggregation and Joins

```aql
// Join documents via DOCUMENT()
FOR order IN orders
    LET customer = DOCUMENT("customers", order.customerId)
    RETURN MERGE(order, { customerName: customer.name })

// Aggregation with COLLECT
FOR order IN orders
    FILTER order.createdAt >= "2024-01-01"
    COLLECT region = order.region
    AGGREGATE totalAmount = SUM(order.amount), orderCount = LENGTH(1)
    SORT totalAmount DESC
    RETURN { region, totalAmount, orderCount }
```

## SmartGraphs (Enterprise)

```javascript
// Co-locate vertices and edges on same shard
const graph = db._createGraph("social", {
  smartGraphAttribute: "communityId",
  numberOfShards: 9,
  replicationFactor: 3
});
// Keys must start with smartGraphAttribute value: "community1:alice"
// EnterpriseGraphs: guaranteed no cross-shard traversals
// SatelliteGraphs: replicate small collections to all shards
```

## Foxx Microservices

```javascript
// Server-side JS inside ArangoDB (HTTP routes + DB operations)
const createRouter = require('@arangodb/foxx/router');
const db = require('@arangodb').db;
const router = createRouter();

router.post('/orders', function(req, res) {
    const meta = db.orders.save(req.body);
    db._query(`
        INSERT { _from: @customer, _to: @order, type: "placed" }
        INTO placed_orders
    `, { customer: `customers/${req.body.customerId}`, order: `orders/${meta._key}` });
    res.status(201).json({ id: meta._key });
});
```

## ArangoSearch

```aql
// BM25 full-text search (create analyzer and view in arangosh first)
FOR doc IN orders_search
    SEARCH ANALYZER(doc.description IN TOKENS("fast delivery shipping", "text_en"), "text_en")
    SORT BM25(doc) DESC LIMIT 20
    RETURN { id: doc._key, score: BM25(doc) }
```

## Cluster Deployment and Backup

```bash
# Docker Compose cluster: 3 Agents (Raft), 3 DBServers (data), 3 Coordinators (routing)
# agent1: --agency.activate true --agency.size 3
# dbserver1: --cluster.my-role DBSERVER
# coordinator1: --cluster.my-role COORDINATOR --port 8529

arangodump --server.endpoint tcp://localhost:8529 --output-directory /backup/2024-01-15 --all-databases
arangorestore --server.endpoint tcp://localhost:8529 --input-directory /backup/2024-01-15 --all-databases
```

## Operational Notes

- SmartGraphs: co-locate vertices and edges on same shard (Enterprise) — guaranteed no cross-shard traversals
- Monitor Foxx service memory; configure `--rocksdb.block-cache-size` based on available RAM
- Use ArangoSearch for full-text queries, never LIKE
