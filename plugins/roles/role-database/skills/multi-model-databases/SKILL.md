---
name: multi-model-databases
description: |
  Deep operational guide for 8 multi-model databases. ArangoDB (AQL, SmartGraphs, Foxx), SurrealDB (SurrealQL, LIVE SELECT), FaunaDB (FQL v10, distributed ACID), Cosmos DB (5 consistency levels, multi-API), OrientDB, MarkLogic, InterSystems IRIS. Use when a single database must support document, graph, key-value, or relational access patterns simultaneously.
allowed-tools: Read, Grep, Glob, Bash
---

You are a multi-model databases specialist informed by the Software Engineer by RN competency matrix.

## Multi-Model Database Comparison

| Database | Models Supported | Query Language | Consistency | Deployment | Best For |
|----------|-----------------|---------------|-------------|------------|----------|
| ArangoDB | Document, Graph, KV, Search | AQL | ACID (single-server), tunable (cluster) | Self-hosted, ArangoGraph | Mixed document/graph workloads |
| SurrealDB | Document, Graph, KV, Relational | SurrealQL | ACID | Self-hosted, SurrealDB Cloud | Real-time apps, graph relations |
| FaunaDB/Fauna | Document-Relational | FQL v10 | Distributed ACID (Calvin) | Fully managed | Serverless, global ACID |
| Azure Cosmos DB | Document, Graph, KV, Column, Table | Multi-API | 5 tunable levels | Azure-managed | Global distribution, multi-API |
| OrientDB | Document, Graph, KV, Object | Extended SQL | ACID | Self-hosted | Document-graph hybrid |
| MarkLogic | Document, Graph, Search, Semantic | XQuery, SPARQL, SQL | ACID | Enterprise license | Enterprise content, semantic |
| InterSystems IRIS | Relational, Document, KV, Object | ObjectScript, SQL | ACID | Enterprise license | Healthcare, interoperability |
| Couchbase | Document, KV, Search, Analytics | N1QL (SQL++) | Tunable | Self-hosted, Capella | High-perf document + search |

## Data Modeling Across Paradigms

### When to Use Multi-Model vs. Polyglot Persistence

```
Multi-Model (single database):
+ Simplified operations (one system to manage)
+ Cross-model queries in single transaction
+ Reduced data synchronization complexity
+ Lower infrastructure cost for smaller teams
- May not excel at any single model
- Vendor lock-in to proprietary query languages

Polyglot Persistence (specialized databases):
+ Best-in-class for each data model
+ Independent scaling per workload
+ More ecosystem/tooling choices
- Complex data synchronization (CDC, ETL)
- Higher operational overhead
- Distributed transaction challenges
```

### Use Case Matrix

| Use Case | Recommended | Reasoning |
|----------|-------------|-----------|
| Social network with content | ArangoDB, SurrealDB | Graph traversal + document storage |
| Global e-commerce | Cosmos DB, FaunaDB | Global distribution, multi-region ACID |
| IoT with relationships | ArangoDB | Time-series documents + device graph |
| Content management | MarkLogic | Document + full-text + semantic |
| Healthcare integration | InterSystems IRIS | HL7/FHIR interoperability |
| Startup MVP (multiple models) | SurrealDB | All-in-one, simple setup |
| Enterprise multi-API migration | Cosmos DB | Gradual migration with multiple APIs |

## ArangoDB

### AQL (ArangoDB Query Language)

```aql
// Document operations
INSERT { _key: "order-123", customer: "alice", amount: 99.99, status: "pending" }
INTO orders
RETURN NEW

FOR order IN orders
    FILTER order.status == "pending" AND order.amount > 50
    SORT order.amount DESC
    LIMIT 10
    RETURN { id: order._key, customer: order.customer, amount: order.amount }

// Update with UPSERT
UPSERT { _key: "order-123" }
INSERT { _key: "order-123", customer: "alice", amount: 99.99, status: "pending" }
UPDATE { status: "confirmed", confirmedAt: DATE_NOW() }
IN orders

// Graph traversal: find friends-of-friends
FOR v, e, p IN 2..3 OUTBOUND 'users/alice' friendships
    OPTIONS { bfs: true, uniqueVertices: 'global' }
    RETURN DISTINCT v

// Shortest path
FOR v, e IN OUTBOUND SHORTEST_PATH 'users/alice' TO 'users/bob' friendships
    RETURN { vertex: v._key, edge: e.type }

// Pattern matching: find users who ordered a specific product
FOR user IN users
    FOR order IN 1..1 OUTBOUND user._id placed_orders
        FOR product IN 1..1 OUTBOUND order._id contains_product
            FILTER product.name == "Widget"
            COLLECT customer = user.name WITH COUNT INTO orderCount
            RETURN { customer, orderCount }

// Join documents (no graph needed)
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

### SmartGraphs (Enterprise Sharding)

```javascript
// SmartGraphs: co-locate vertices and edges on same shard
// Reduces cross-shard queries for graph traversals

// Create SmartGraph
const graph = db._createGraph("social", {
  smartGraphAttribute: "communityId",  // shard by community
  numberOfShards: 9,
  replicationFactor: 3
});

// Vertices with smartGraphAttribute
db.users.save({
  _key: "community1:alice",  // must start with smartGraphAttribute value
  communityId: "community1",
  name: "Alice"
});

// EnterpriseGraphs (disjoint SmartGraphs): guaranteed no cross-shard traversals
// SatelliteGraphs: replicate small collections to all shards
```

### Foxx Microservices

```javascript
// Foxx: server-side JavaScript microservices inside ArangoDB
// routes/orders.js
const createRouter = require('@arangodb/foxx/router');
const joi = require('joi');
const db = require('@arangodb').db;

const router = createRouter();
module.context.use(router);

router.post('/orders', function(req, res) {
    const order = req.body;
    const meta = db.orders.save(order);

    // Graph operation in same transaction
    db._query(`
        INSERT { _from: @customer, _to: @order, type: "placed" }
        INTO placed_orders
    `, { customer: `customers/${order.customerId}`, order: `orders/${meta._key}` });

    res.status(201).json({ id: meta._key });
})
.body(joi.object({
    customerId: joi.string().required(),
    items: joi.array().required(),
    amount: joi.number().required()
}).required())
.response(201, joi.object({ id: joi.string() }));
```

### ArangoSearch and ArangoML

```aql
// ArangoSearch: integrated full-text search with BM25 ranking
// Create analyzer
// arangosh> db._createAnalyzer("text_en", "text", { locale: "en", stemming: true })

// Create search view
// arangosh> db._createView("orders_search", "arangosearch", {
//   links: { orders: { analyzers: ["text_en"], fields: { description: {} } } }
// })

// Search query with BM25 ranking
FOR doc IN orders_search
    SEARCH ANALYZER(doc.description IN TOKENS("fast delivery shipping", "text_en"), "text_en")
    SORT BM25(doc) DESC
    LIMIT 20
    RETURN { id: doc._key, description: doc.description, score: BM25(doc) }

// ArangoML: graph-based ML with NetworkX integration
// Train graph neural networks on ArangoDB graphs
// pip install arangoml
```

### Cluster Deployment

```yaml
# Docker Compose: ArangoDB Cluster
# 3 Agents (Raft consensus), 3 DBServers (data), 3 Coordinators (query routing)
services:
  agent1:
    image: arangodb/arangodb:3.12
    command: --agency.activate true --agency.size 3 --agency.supervision true
    environment:
      ARANGO_ROOT_PASSWORD: secret

  dbserver1:
    image: arangodb/arangodb:3.12
    command: --cluster.my-role DBSERVER

  coordinator1:
    image: arangodb/arangodb:3.12
    command: --cluster.my-role COORDINATOR
    ports:
      - "8529:8529"
```

```bash
# Backup and restore
arangodump --server.endpoint tcp://localhost:8529 \
  --output-directory /backup/2024-01-15 \
  --all-databases --include-system-collections

arangorestore --server.endpoint tcp://localhost:8529 \
  --input-directory /backup/2024-01-15 \
  --all-databases
```

## SurrealDB

### SurrealQL

```sql
-- SurrealDB: multi-model with SQL-like syntax + graph relations
-- Connect: surreal start --user root --pass root --bind 0.0.0.0:8000 file:mydb.db

-- Define schema (schemaful mode)
DEFINE TABLE orders SCHEMAFULL;
DEFINE FIELD customer ON TABLE orders TYPE record<customers>;
DEFINE FIELD amount ON TABLE orders TYPE decimal;
DEFINE FIELD status ON TABLE orders TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'confirmed', 'shipped', 'cancelled'];
DEFINE FIELD items ON TABLE orders TYPE array<object>;
DEFINE FIELD createdAt ON TABLE orders TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_status ON TABLE orders FIELDS status;

-- Record links (graph-like relations without separate edge table)
CREATE orders:order1 SET
    customer = customers:alice,
    amount = 99.99,
    items = [{ product: products:widget, qty: 2 }];

-- Graph-style traversal via record links
SELECT ->placed->orders->contains->products FROM customers:alice;

-- RELATE: create graph edges
RELATE customers:alice->purchased->products:widget SET
    quantity = 2,
    purchasedAt = time::now();

-- Traverse graph
SELECT <-purchased<-customers FROM products:widget;
SELECT ->purchased->products.*.name FROM customers:alice;

-- Subqueries and nested selects
SELECT *, (SELECT VALUE count() FROM orders WHERE customer = $parent.id) AS order_count
FROM customers;
```

### LIVE SELECT (Real-Time Subscriptions)

```javascript
// WebSocket real-time queries
const db = new Surreal();
await db.connect('ws://localhost:8000/rpc');
await db.signin({ username: 'root', password: 'root' });
await db.use({ namespace: 'myapp', database: 'production' });

// Live query: receive updates in real-time
const queryUuid = await db.live('orders', (action, result) => {
    switch (action) {
        case 'CREATE':
            console.log('New order:', result);
            break;
        case 'UPDATE':
            console.log('Order updated:', result);
            break;
        case 'DELETE':
            console.log('Order deleted:', result);
            break;
    }
});

// Live query with filter
const liveQuery = await db.live(
    'SELECT * FROM orders WHERE status = "pending"',
    (action, result) => { /* handle changes */ }
);

// Kill live query when done
await db.kill(queryUuid);
```

### Built-in Authentication

```sql
-- Define scopes and access control
DEFINE SCOPE account SESSION 24h
    SIGNUP (
        CREATE user SET email = $email, pass = crypto::argon2::generate($pass)
    )
    SIGNIN (
        SELECT * FROM user WHERE email = $email AND crypto::argon2::compare(pass, $pass)
    );

-- Table-level permissions
DEFINE TABLE orders SCHEMAFULL
    PERMISSIONS
        FOR select WHERE customer = $auth.id
        FOR create WHERE $auth.id != NONE
        FOR update WHERE customer = $auth.id AND status = 'pending'
        FOR delete NONE;

-- Embedded vs server mode
-- Embedded: use library directly in Rust/Python/Node.js
-- Server: HTTP/WebSocket API on port 8000
```

## FaunaDB / Fauna

### FQL v10

```typescript
import { Client, fql } from 'fauna';

const client = new Client({ secret: 'fn...' });

// Define collection with constraints
await client.query(fql`
  Collection.create({
    name: "orders",
    indexes: {
      byCustomer: {
        terms: [{ field: "customer" }],
        values: [{ field: "createdAt", order: "desc" }]
      },
      byStatus: {
        terms: [{ field: "status" }]
      }
    },
    constraints: [
      { unique: ["orderNumber"] }
    ]
  })
`);

// Create document
const order = await client.query(fql`
  orders.create({
    customer: customers.byId("123"),
    amount: 99.99,
    status: "pending",
    items: [
      { product: products.byId("widget"), quantity: 2 }
    ]
  })
`);

// Query with index
const pending = await client.query(fql`
  orders.byStatus("pending")
    .pageSize(20)
    .map(order => {
      let customer = order.customer
      {
        id: order.id,
        amount: order.amount,
        customerName: customer.name
      }
    })
`);

// Transaction (distributed ACID via Calvin protocol)
const result = await client.query(fql`
  let order = orders.byId("order-123")
  let inventory = inventory.byProduct(order.items[0].product)

  if (inventory.quantity < order.items[0].quantity) {
    abort("Insufficient inventory")
  }

  // Both operations are atomic, globally
  order.update({ status: "confirmed" })
  inventory.update({ quantity: inventory.quantity - order.items[0].quantity })
`);

// Temporal queries (query data at a point in time)
const historicalOrder = await client.query(fql`
  orders.byId("order-123").at("2024-06-15T10:00:00Z")
`);

// Streaming (real-time event feeds)
const stream = client.stream(fql`orders.all().eventSource()`);
for await (const event of stream) {
    console.log(event.type, event.data);
}
```

## Azure Cosmos DB

### Partition Key Design

```javascript
// Partition key: most critical design decision
// - Determines data distribution across physical partitions
// - Cannot be changed after creation (requires migration)
// - Each partition: max 20 GB, 10,000 RU/s

// Good partition keys:
// - /tenantId (multi-tenant apps)
// - /userId (user-scoped data)
// - /orderId (high cardinality, even distribution)

// Bad partition keys:
// - /status (low cardinality, hot partitions)
// - /createdAt (sequential, creates hot partition)
// - /country (skewed distribution)

// Hierarchical partition keys (preview)
const container = database.containers.create({
    id: "orders",
    partitionKey: {
        paths: ["/tenantId", "/region", "/orderId"],
        kind: "MultiHash",
        version: 2
    }
});
```

### 5 Consistency Levels

```
Strong ←——————————————————————————————→ Eventual
  |        |           |          |         |
Strong   Bounded    Session  Consistent  Eventual
         Staleness           Prefix

Strong: Linearizable reads (highest latency, highest cost)
  - Use for: financial transactions, inventory management
  - RU cost: 2x eventual

Bounded Staleness: Reads lag by at most K versions or T time
  - Use for: leaderboards, analytics with staleness tolerance
  - Configure: maxStalenessPrefix, maxIntervalInSeconds

Session (default): Read-your-own-writes within a session
  - Use for: most web/mobile apps (user sees their own changes)
  - Most popular choice, good balance

Consistent Prefix: Reads never see out-of-order writes
  - Use for: social feeds, activity logs
  - Guarantees causal ordering

Eventual: No ordering guarantee, lowest latency
  - Use for: counters, non-critical reads
  - RU cost: 1x (baseline)
```

### Multi-API Surface

```javascript
// Core (SQL) API (recommended for new projects)
const { CosmosClient } = require("@azure/cosmos");
const client = new CosmosClient({ endpoint, key });

const { resource: order } = await client
    .database("shop")
    .container("orders")
    .items.create({
        id: "order-123",
        partitionKey: "tenant-1",
        amount: 99.99,
        status: "pending"
    });

// SQL query with parameterized queries
const { resources: orders } = await client
    .database("shop")
    .container("orders")
    .items.query({
        query: "SELECT * FROM c WHERE c.status = @status AND c.amount > @minAmount",
        parameters: [
            { name: "@status", value: "pending" },
            { name: "@minAmount", value: 50 }
        ]
    })
    .fetchAll();

// RU/s provisioning
// Manual: 400-unlimited RU/s (billed per hour)
// Autoscale: 100-max RU/s (auto-adjusts, 10% minimum)
// Serverless: pay per request (dev/test, sporadic workloads)
```

### Change Feed

```javascript
// Change feed: ordered stream of changes within a partition
const iterator = container.items
    .changeFeed("partition-key-1", { startFromBeginning: true });

while (iterator.hasMoreResults) {
    const { resources, continuationToken } = await iterator.fetchNext();
    for (const change of resources) {
        console.log("Changed document:", change);
    }
    // Save continuationToken for resume
}

// Change feed processor (manages leases, parallelism)
const changeFeedProcessor = container.items
    .getChangeFeedIteratorOptions({
        changeFeedStartFrom: ChangeFeedStartFrom.Beginning(),
        maxItemCount: 100
    });

// Use cases:
// - Event sourcing / materialized views
// - Real-time notifications
// - Data synchronization to other systems
// - Search index updates
```

### Global Distribution

```bash
# Add regions (automatic replication)
az cosmosdb update --name myaccount --resource-group mygroup \
  --locations regionName=eastus failoverPriority=0 isZoneRedundant=true \
  --locations regionName=westeurope failoverPriority=1 isZoneRedundant=true \
  --locations regionName=southeastasia failoverPriority=2

# Multi-region writes (multi-master)
az cosmosdb update --name myaccount --resource-group mygroup \
  --enable-multiple-write-locations true

# Conflict resolution policies:
# - LastWriterWins (default, by _ts timestamp)
# - Custom (stored procedure)
# - Manual (application-level)
```

## OrientDB

```sql
-- OrientDB: document + graph with SQL-like syntax
-- Connect: console.sh> CONNECT remote:localhost/mydb admin admin

-- Create class (like table, but with inheritance)
CREATE CLASS Order EXTENDS V;
CREATE PROPERTY Order.customerId STRING (MANDATORY TRUE);
CREATE PROPERTY Order.amount DECIMAL (MANDATORY TRUE);
CREATE PROPERTY Order.status STRING (DEFAULT 'pending');

-- Create edge class
CREATE CLASS PlacedOrder EXTENDS E;

-- Insert document
INSERT INTO Order SET customerId = 'alice', amount = 99.99, status = 'pending';

-- Create graph edge
CREATE EDGE PlacedOrder FROM (SELECT FROM Customer WHERE name = 'Alice')
    TO (SELECT FROM Order WHERE customerId = 'alice');

-- Graph traversal with SQL
SELECT expand(out('PlacedOrder')) FROM Customer WHERE name = 'Alice';
SELECT shortestPath(#12:0, #14:5, 'BOTH');

-- Distributed multi-master deployment
-- orientdb-server-config.xml: <distributed> enabled, auto-deploy
```

## MarkLogic

```xquery
(: MarkLogic: enterprise multi-model (document + graph + search + semantic) :)

(: Insert JSON document :)
xdmp:document-insert("/orders/order-123.json",
    object-node {
        "orderId": "order-123",
        "customer": "alice",
        "amount": 99.99,
        "status": "pending"
    },
    map:map()
        => map:with("permissions", (xdmp:permission("readers", "read")))
        => map:with("collections", ("orders", "pending-orders"))
)

(: Full-text search with relevance ranking :)
cts:search(
    fn:collection("orders"),
    cts:and-query((
        cts:json-property-range-query("amount", ">", 50),
        cts:json-property-word-query("notes", "urgent delivery")
    ))
)

(: SPARQL query (semantic/graph) :)
(: MarkLogic stores RDF triples alongside documents :)
sem:sparql('
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    SELECT ?name ?email
    WHERE {
        ?person foaf:name ?name .
        ?person foaf:mbox ?email .
    }
')

(: Optic API (relational-style joins on documents) :)
op:from-view("orders", "orders")
    => op:join-inner(
        op:from-view("customers", "customers"),
        op:on(op:view-col("orders", "customerId"), op:view-col("customers", "id"))
    )
    => op:where(op:gt(op:view-col("orders", "amount"), 100))
    => op:result()
```

## InterSystems IRIS

```objectscript
// InterSystems IRIS: multi-model data platform
// ObjectScript + SQL + Document + Interoperability

// ObjectScript class (object + relational mapping)
Class MyApp.Order Extends %Persistent {
    Property OrderId As %String [ Required ];
    Property Customer As MyApp.Customer;
    Property Amount As %Numeric(SCALE = 2);
    Property Status As %String [ InitialExpression = "pending" ];
    Property Items As list Of MyApp.OrderItem;

    Index StatusIdx On Status;

    // Embedded SQL
    ClassMethod GetPendingOrders() As %Status {
        &sql(
            DECLARE C1 CURSOR FOR
            SELECT OrderId, Amount FROM MyApp.Order WHERE Status = 'pending'
        )
        &sql(OPEN C1)
        While (1) {
            &sql(FETCH C1 INTO :orderId, :amount)
            If SQLCODE '= 0 Quit
            Write orderId, ": $", amount, !
        }
        &sql(CLOSE C1)
        Quit $$$OK
    }
}

// Document store (JSON)
Set doc = {"orderId": "123", "amount": 99.99}
Do ##class(%DocDB.Database).%CreateDatabase("orders")
Set db = ##class(%DocDB.Database).%GetDatabase("orders")
Do db.%SaveDocument(doc)

// Interoperability (HL7/FHIR for healthcare)
// Built-in message routing, transformations, and adapters
// FHIR R4 server endpoint: /csp/healthshare/fhirserver/fhir/r4
```

## Multi-Model Design Patterns

### Pattern 1: Document with Graph Relations (ArangoDB, SurrealDB)

```
Store entities as documents, relationships as edges.
Query documents for CRUD, traverse graph for relationships.

Orders (document) --[placed_by]--> Customers (document)
                  --[contains]--> Products (document)
```

### Pattern 2: Document-Relational (FaunaDB)

```
Define collections with indexes and constraints.
Use references between documents (like foreign keys).
ACID transactions across collections.
```

### Pattern 3: Multi-API Surface (Cosmos DB)

```
Single database, multiple access patterns:
- Core SQL API for document CRUD
- Gremlin API for graph traversals
- Table API for simple KV lookups
- Change feed for event streaming
```

### Pattern 4: Polyglot within Single Engine (MarkLogic, IRIS)

```
Store documents, derive triples, create relational views.
Single source of truth, multiple query paradigms.
Document -> extract RDF triples -> SPARQL
Document -> create SQL view -> SQL queries
```

## Operational Best Practices

### ArangoDB
- Use SmartGraphs for sharded graph traversals
- Monitor Foxx service memory usage
- Configure `--rocksdb.block-cache-size` based on available RAM
- Use ArangoSearch for full-text queries (not LIKE)

### SurrealDB
- Define schemas (SCHEMAFULL) for production tables
- Use namespaces and databases for multi-tenancy
- Enable authentication scopes for row-level security
- Monitor WebSocket connections for LIVE SELECT

### Cosmos DB
- Choose partition key carefully (cannot change later)
- Start with Session consistency (upgrade only if needed)
- Monitor RU consumption per partition (hot partition alerts)
- Use change feed instead of polling for real-time updates
- Configure autoscale with appropriate max RU/s

### FaunaDB
- Use indexes for all query patterns (no full scans)
- Leverage temporal queries for audit/compliance
- Use streaming for real-time features
- Monitor compute operations for cost control

For cross-references, see:
- Couchbase details in the document-databases skill
- Graph-specific patterns in the graph-databases skill
