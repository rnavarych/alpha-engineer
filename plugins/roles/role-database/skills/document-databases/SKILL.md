---
name: document-databases
description: |
  Deep operational guide for 12 document databases. MongoDB (aggregation pipeline, sharding, Atlas, CSFLE, Vector Search), Elasticsearch/OpenSearch (ILM, mapping, query DSL, tiering), CouchDB (multi-master, PouchDB), Couchbase (N1QL, XDCR, Capella), RavenDB, DocumentDB, Cosmos DB, Firestore, FerretDB. Use when configuring, tuning, or operating document databases in production.
allowed-tools: Read, Grep, Glob, Bash
---

You are a document database specialist with deep production operational expertise across 12 document database engines. Provide configuration-level guidance with real-world operational patterns.

## Quick Selection Matrix

| Database | Best For | Query Language | Consistency | Managed | License |
|----------|----------|---------------|-------------|---------|---------|
| MongoDB | General-purpose documents | MQL + Aggregation | Tunable | Atlas | SSPL |
| Elasticsearch | Full-text search, logs, analytics | Query DSL, ES\|QL | Eventual | Elastic Cloud | Elastic License 2.0 |
| OpenSearch | Search/analytics (AWS ecosystem) | Query DSL, SQL, PPL | Eventual | Amazon OpenSearch | Apache 2.0 |
| CouchDB | Offline-first, multi-master sync | MapReduce, Mango | Eventual | Cloudant (IBM) | Apache 2.0 |
| Couchbase | Multi-model with low-latency KV | N1QL (SQL++) | Tunable | Capella | BSL / Apache |
| RavenDB | .NET-native ACID documents | RQL (LINQ-like) | Strong (ACID) | RavenDB Cloud | AGPL / Commercial |
| DocumentDB | MongoDB-compatible (AWS managed) | MongoDB API (subset) | Strong | AWS managed | Proprietary |
| Cosmos DB | Global distribution, multi-model | SQL, MongoDB, Gremlin | 5 levels | Azure managed | Proprietary |
| Firestore | Mobile/web real-time sync | SDK queries | Strong | Firebase/GCP | Proprietary |
| FerretDB | MongoDB protocol on PostgreSQL | MongoDB API | Strong (PG) | Self-hosted | Apache 2.0 |
| ToroDB | MongoDB protocol on PostgreSQL | MongoDB API | Strong (PG) | Self-hosted | Apache 2.0 |
| ArangoDB | Multi-model (doc+graph+KV) | AQL | Tunable | ArangoDB Cloud | Apache 2.0 |

---

## 1. MongoDB

The most widely adopted document database. Flexible schemas, rich query language, comprehensive managed platform (Atlas).

### Data Modeling Patterns

| Pattern | Use Case | Example |
|---------|----------|---------|
| Embedding | 1:1, 1:few, read-together data | User with addresses |
| Referencing | 1:many, many:many, independent entities | Order referencing product catalog |
| Polymorphic | Same collection, different shapes | Events (click, purchase, signup) |
| Bucket | Time-series, IoT, high-frequency data | Sensor readings grouped by hour |
| Outlier | Handle rare large arrays | Product with 1000+ reviews (overflow doc) |
| Subset | Large documents with hot/cold data | Product summary + detailed specs |
| Computed | Pre-computed aggregations | Daily revenue totals |
| Extended Reference | Partial copy of referenced doc | Order with customer name + email (no full JOIN) |

### Aggregation Pipeline

```javascript
// Multi-stage pipeline with optimization
db.orders.aggregate([
  // 1. Filter early (uses indexes)
  { $match: { status: "completed", createdAt: { $gte: ISODate("2024-01-01") } } },

  // 2. Lookup customer details
  { $lookup: {
      from: "customers",
      localField: "customerId",
      foreignField: "_id",
      pipeline: [{ $project: { name: 1, tier: 1 } }],  // Reduce lookup payload
      as: "customer"
  }},
  { $unwind: "$customer" },

  // 3. Group by customer tier
  { $group: {
      _id: "$customer.tier",
      totalRevenue: { $sum: "$total" },
      orderCount: { $sum: 1 },
      avgOrderValue: { $avg: "$total" }
  }},

  // 4. Sort and format
  { $sort: { totalRevenue: -1 } },
  { $project: {
      tier: "$_id",
      totalRevenue: { $round: ["$totalRevenue", 2] },
      orderCount: 1,
      avgOrderValue: { $round: ["$avgOrderValue", 2] }
  }}
]);
```

### Sharding

```javascript
// Enable sharding on database
sh.enableSharding("mydb");

// Shard with hashed key (even distribution)
sh.shardCollection("mydb.events", { userId: "hashed" });

// Shard with range key (locality for range queries)
sh.shardCollection("mydb.logs", { timestamp: 1 });

// Zone sharding (geo-routing)
sh.addShardTag("shard-us-east", "US");
sh.addShardTag("shard-eu-west", "EU");
sh.addTagRange("mydb.users", { region: "US" }, { region: "US\uffff" }, "US");
sh.addTagRange("mydb.users", { region: "EU" }, { region: "EU\uffff" }, "EU");
```

### Atlas Features
- **Atlas Search**: Lucene-based full-text search with facets, autocomplete, highlights.
- **Atlas Vector Search**: kNN search for embeddings. RAG support.
- **Atlas Data Lake**: Query across clusters, S3, and HTTP endpoints.
- **Atlas Online Archive**: Automated tiering of cold data to cheaper storage.
- **Atlas Charts**: Built-in data visualization.
- **Atlas App Services**: Triggers, functions, GraphQL, device sync.

### CSFLE and Queryable Encryption
- **Client-Side Field Level Encryption (CSFLE)**: Encrypt fields before sending to server. Deterministic or random encryption.
- **Queryable Encryption (7.0+)**: Query encrypted data server-side without decryption. Supports equality and range queries on encrypted fields.

### Time-Series Collections

```javascript
db.createCollection("sensor_data", {
  timeseries: {
    timeField: "timestamp",
    metaField: "sensorId",
    granularity: "seconds"  // seconds | minutes | hours
  },
  expireAfterSeconds: 2592000  // 30-day TTL
});
```

**Deep reference**: [reference-mongodb.md](reference-mongodb.md)

---

## 2. Elasticsearch

Distributed search and analytics engine built on Apache Lucene. The standard for full-text search, log analytics, and observability.

### Index Lifecycle Management (ILM)

```json
PUT _ilm/policy/logs_policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": { "max_size": "50gb", "max_age": "1d" },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "searchable_snapshot": { "snapshot_repository": "my_repo" },
          "set_priority": { "priority": 0 }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": { "delete": {} }
      }
    }
  }
}
```

### Mapping Design

```json
PUT /products
{
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "name":        { "type": "text", "analyzer": "standard", "fields": { "keyword": { "type": "keyword" } } },
      "description": { "type": "text", "analyzer": "english" },
      "price":       { "type": "scaled_float", "scaling_factor": 100 },
      "category":    { "type": "keyword" },
      "tags":        { "type": "keyword" },
      "created_at":  { "type": "date" },
      "location":    { "type": "geo_point" },
      "embedding":   { "type": "dense_vector", "dims": 768, "index": true, "similarity": "cosine" },
      "attributes":  {
        "type": "nested",
        "properties": {
          "key":   { "type": "keyword" },
          "value": { "type": "keyword" }
        }
      }
    }
  }
}
```

### Query DSL

```json
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "wireless headphones" } }
      ],
      "filter": [
        { "term": { "category": "electronics" } },
        { "range": { "price": { "gte": 50, "lte": 200 } } }
      ],
      "should": [
        { "term": { "tags": "bestseller" } }
      ],
      "minimum_should_match": 0
    }
  },
  "highlight": { "fields": { "name": {}, "description": {} } },
  "aggs": {
    "price_ranges": {
      "range": { "field": "price", "ranges": [
        { "to": 50 }, { "from": 50, "to": 100 }, { "from": 100 }
      ]}
    },
    "top_categories": { "terms": { "field": "category", "size": 10 } }
  }
}
```

### ES|QL (Elasticsearch Query Language)

```esql
FROM logs-*
| WHERE @timestamp > NOW() - 1 HOUR AND log.level == "ERROR"
| STATS error_count = COUNT(*) BY service.name
| SORT error_count DESC
| KEEP service.name, error_count
| LIMIT 20
```

**Deep reference**: [reference-elasticsearch.md](reference-elasticsearch.md)

---

## 3. OpenSearch

AWS-backed fork of Elasticsearch 7.10. Open-source with built-in security, SQL, and observability plugins.

### Key Differentiators from Elasticsearch
- **Security plugin**: Built-in (no X-Pack license). RBAC, document/field-level security, audit logging.
- **SQL plugin**: SQL queries translated to DSL. JDBC/ODBC drivers.
- **PPL (Piped Processing Language)**: Similar to ES|QL. `search source=logs | where status=500 | stats count() by host`.
- **k-NN plugin**: Vector similarity search with HNSW, IVF, and Faiss engines.
- **Observability**: Trace analytics (OpenTelemetry), metrics, log correlation.
- **Index State Management (ISM)**: OpenSearch equivalent of ILM.
- **OpenSearch Serverless**: Auto-scaling, no cluster management.

### Migration from Elasticsearch

```bash
# Snapshot-based migration (recommended for large datasets)
# 1. Register shared S3 repo in both clusters
# 2. Snapshot from ES
PUT _snapshot/migration_repo/snapshot_1
{ "indices": "my-index-*" }

# 3. Restore in OpenSearch (may need index settings adjustment)
POST _snapshot/migration_repo/snapshot_1/_restore
{ "indices": "my-index-*",
  "index_settings": { "index.number_of_replicas": 1 } }
```

### Breaking Changes from ES 7.10
- No more `_type` field (removed in ES 7.x, OpenSearch follows).
- Some X-Pack APIs not available (use OpenSearch security plugin instead).
- Plugin ecosystem diverging (check OpenSearch-specific versions).

---

## 4. CouchDB

Multi-master document database designed for offline-first applications and reliable replication.

### Architecture
- **HTTP/REST API**: Every operation is an HTTP request. No binary protocol.
- **Multi-Master Replication**: Any node can accept writes. Conflict detection via revision tree.
- **Eventual Consistency**: Conflicts are stored, not rejected. Application resolves.
- **MapReduce Views**: Persistent indexes built from JavaScript map/reduce functions.
- **Mango Queries**: Declarative JSON query language (MongoDB-like).

### Replication Setup

```bash
# Continuous replication between two CouchDB instances
curl -X POST http://localhost:5984/_replicate \
  -H "Content-Type: application/json" \
  -d '{
    "source": "http://source:5984/mydb",
    "target": "http://target:5984/mydb",
    "continuous": true,
    "create_target": true
  }'
```

### PouchDB Sync (Offline-First)

```javascript
const localDB = new PouchDB('mydb');
const remoteDB = new PouchDB('http://couchdb:5984/mydb');

// Bidirectional sync with live updates
localDB.sync(remoteDB, {
  live: true,
  retry: true
}).on('change', (info) => {
  console.log('Sync change:', info);
}).on('error', (err) => {
  console.error('Sync error:', err);
});
```

### Best For
- Offline-first mobile/web applications.
- Multi-region sync with conflict resolution.
- CMS and content management with distributed authoring.
- Edge computing with intermittent connectivity.

---

## 5. Couchbase

Multi-model database combining document store, key-value, full-text search, analytics, and eventing.

### Architecture
- **Memory-first**: All active data in RAM. Asynchronous persistence to disk.
- **Services**: Data, Query, Index, Search, Analytics, Eventing, Backup. Deploy per node.
- **Buckets**: Top-level containers. Types: Couchbase (persistent), Memcached (cache-only), Ephemeral (in-memory).
- **vBuckets**: 1024 virtual partitions for automatic data distribution.

### N1QL (SQL++ for JSON)

```sql
-- Query with JOINs and subqueries
SELECT o.orderId, o.total,
       c.name AS customerName,
       ARRAY_AGG(i.productName) AS products
FROM `orders` o
JOIN `customers` c ON KEYS o.customerId
UNNEST o.items i
WHERE o.status = 'completed'
  AND o.createdAt > '2024-01-01'
GROUP BY o.orderId, o.total, c.name
ORDER BY o.total DESC
LIMIT 20;

-- Upsert with sub-document operations (no full document read)
UPDATE `users` USE KEYS "user::123"
SET loyalty_points = loyalty_points + 100,
    last_activity = NOW_STR();
```

### Sub-Document Operations

```javascript
// Efficient partial updates without reading full document
await collection.mutateIn("user::123", [
  couchbase.MutateInSpec.upsert("profile.lastLogin", new Date().toISOString()),
  couchbase.MutateInSpec.increment("stats.loginCount", 1),
  couchbase.MutateInSpec.arrayAppend("recentActions", "login")
]);

// Partial reads
const result = await collection.lookupIn("user::123", [
  couchbase.LookupInSpec.get("profile.email"),
  couchbase.LookupInSpec.get("stats.loginCount")
]);
```

### XDCR (Cross Data Center Replication)

```bash
# Set up bidirectional XDCR between two clusters
couchbase-cli xdcr-setup --cluster dc1:8091 \
  --xdcr-cluster-name dc2 \
  --xdcr-hostname dc2:8091 \
  --xdcr-username admin --xdcr-password secret

couchbase-cli xdcr-replicate --cluster dc1:8091 \
  --xdcr-cluster-name dc2 \
  --xdcr-from-bucket orders \
  --xdcr-to-bucket orders \
  --xdcr-replication-mode capi
```

### Capella (Managed DBaaS)
- Multi-cloud (AWS, GCP, Azure).
- Columnar Analytics for real-time OLAP.
- App Services for mobile sync (replaces Sync Gateway).
- Automated scaling, backup, and security.

---

## 6. RavenDB

ACID document database with .NET-first design philosophy.

### Key Features
- **ACID transactions**: Full multi-document, multi-collection ACID transactions.
- **Auto-indexes**: RavenDB creates indexes automatically based on query patterns. No manual index creation required (but supported).
- **Subscriptions**: Push-based data change notifications. Reliable, exactly-once delivery.
- **Projections**: Server-side transformations during queries.
- **Attachments**: Binary data stored alongside documents.
- **Counters**: Distributed counters with conflict-free increments.
- **Time-series**: Built-in time-series support with rollups and retention policies.
- **Revisions**: Automatic document versioning with configurable retention.

### RQL (Raven Query Language)

```sql
-- LINQ-like query syntax
from Orders
where Total > 1000 and Status = 'completed'
order by CreatedAt desc
select {
    OrderId: Id,
    CustomerName: load(CustomerId).Name,
    Total: Total,
    Items: Items.length
}
limit 25
```

---

## 7. Amazon DocumentDB

AWS managed document database compatible with MongoDB API (subset).

### Key Limitations vs Real MongoDB
- No client-side field-level encryption.
- No change streams `fullDocument: 'updateLookup'` with sharded collections.
- Limited aggregation pipeline stages (no `$graphLookup`, limited `$merge`).
- No MongoDB Atlas features (Search, Vector Search, Charts).
- Storage architecture is Aurora-based (not MongoDB WiredTiger).

### When to Choose DocumentDB
- Already heavily invested in AWS ecosystem.
- Need Aurora-like storage (6-way replication, auto-scaling storage).
- Simple MongoDB API usage without advanced features.
- Compliance requirements mandate AWS-only services.

---

## 8. Azure Cosmos DB (Core SQL API)

Globally distributed, multi-model database with tunable consistency.

### Consistency Levels

| Level | Guarantee | Latency | Use Case |
|-------|-----------|---------|----------|
| Strong | Linearizable | Highest | Financial transactions |
| Bounded Staleness | Reads lag by K versions or T time | High | Leaderboards, inventory counts |
| Session | Read-your-writes per session | Medium | User profiles, shopping carts |
| Consistent Prefix | Ordered, no gaps | Low | Social feeds, activity logs |
| Eventual | No ordering guarantee | Lowest | Analytics, telemetry |

### Partition Key Selection

```javascript
// Good: High cardinality, even distribution, present in most queries
{ partitionKey: "/tenantId" }    // Multi-tenant SaaS
{ partitionKey: "/userId" }      // User-centric application
{ partitionKey: "/deviceId" }    // IoT telemetry

// Bad: Low cardinality creates hot partitions
{ partitionKey: "/country" }     // Only ~200 values
{ partitionKey: "/status" }      // Only a few values (active/inactive)
```

### RU/s (Request Units) Optimization
- Reads: ~1 RU per 1 KB point read.
- Writes: ~5 RU per 1 KB write.
- Cross-partition queries: Significantly more RUs.
- Use `x-ms-request-charge` header to measure actual RU consumption.

---

## 9. Firebase Firestore

Google's serverless document database designed for mobile and web applications with real-time sync.

### Data Modeling

```javascript
// Hierarchical structure: collections > documents > subcollections
const orderRef = db.collection('users').doc('user123')
                   .collection('orders').doc('order456');

// Composite indexes for complex queries
// Defined in firestore.indexes.json or Firebase console
```

### Real-Time Listeners

```javascript
// Real-time updates with offline support
const unsubscribe = db.collection('messages')
  .where('roomId', '==', 'room123')
  .orderBy('createdAt', 'desc')
  .limit(50)
  .onSnapshot((snapshot) => {
    snapshot.docChanges().forEach((change) => {
      if (change.type === 'added') console.log('New:', change.doc.data());
      if (change.type === 'modified') console.log('Modified:', change.doc.data());
      if (change.type === 'removed') console.log('Removed:', change.doc.data());
    });
  });
```

### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;

      match /orders/{orderId} {
        allow read: if request.auth.uid == userId;
        allow create: if request.auth.uid == userId
                      && request.resource.data.total is number
                      && request.resource.data.total > 0;
      }
    }
  }
}
```

### Limitations
- Maximum document size: 1 MB.
- Maximum subcollection depth: 100 levels.
- Maximum writes per document: 1 per second sustained.
- No server-side JOINs (denormalize or use multiple queries).
- Limited aggregation (count, sum, average added in recent versions).

---

## 10. FerretDB

Open-source MongoDB protocol proxy that stores data in PostgreSQL (or SQLite).

### Architecture
- Translates MongoDB wire protocol to SQL queries.
- Uses PostgreSQL JSONB columns for document storage.
- Full PostgreSQL ACID guarantees and tooling (pg_dump, replication, RLS).
- Drop-in replacement for simple MongoDB workloads.

### Setup

```yaml
# docker-compose.yml
services:
  ferretdb:
    image: ghcr.io/ferretdb/ferretdb:latest
    ports:
      - "27017:27017"
    environment:
      FERRETDB_POSTGRESQL_URL: postgres://user:pass@postgres:5432/ferretdb

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: ferretdb
```

### When to Use FerretDB
- Want MongoDB API but need PostgreSQL guarantees (ACID, backup, replication).
- License concerns with MongoDB SSPL.
- Already have PostgreSQL expertise and infrastructure.
- Simple MongoDB workloads without sharding or advanced aggregation.

---

## 11. ToroDB

MongoDB-compatible database that stores documents in PostgreSQL using a relational schema.

### Key Difference from FerretDB
- ToroDB normalizes JSON documents into relational tables (not JSONB).
- Better query performance for structured documents.
- Full SQL access to the underlying relational data.
- Use case: bi-directional MongoDB-to-SQL bridge.

---

## 12. ArangoDB (Cross-Reference)

Multi-model database combining documents, graphs, and key-value in a single engine. For detailed coverage, see the `multi-model-databases` skill.

### Quick Overview
- **AQL (ArangoDB Query Language)**: Unified query language for documents, graphs, and joins.
- **SmartGraphs**: Enterprise feature for efficient distributed graph traversals.
- **Foxx Microservices**: Run JavaScript services inside the database.
- **Satellite Collections**: Replicate small collections to all shards for efficient JOINs.

---

## Document Database Anti-Patterns

1. **Treating documents like rows**: Over-normalizing into many small collections with extensive `$lookup` / JOINs. Embed related data.
2. **Unbounded arrays**: Arrays that grow without limit (e.g., all comments on a post). Use the bucket or outlier pattern.
3. **No schema validation**: Allowing any shape into a collection. Use JSON Schema validators (MongoDB) or explicit mappings (ES).
4. **Ignoring index design**: Full collection scans on large datasets. Profile queries and create targeted indexes.
5. **Wrong shard key**: Choosing a low-cardinality or monotonically increasing shard key. Results in hot partitions.
6. **Over-denormalization**: Copying the same data to hundreds of documents. Updates become expensive and error-prone.
7. **Ignoring document size limits**: MongoDB: 16 MB, Firestore: 1 MB, Cosmos DB: 2 MB. Design documents within limits.
8. **Not using projections**: Fetching entire large documents when only a few fields are needed.

---

## Operational Comparison

| Aspect | MongoDB | Elasticsearch | Couchbase | CouchDB | Cosmos DB | Firestore |
|--------|---------|--------------|-----------|---------|-----------|-----------|
| Backup | mongodump, Atlas, snapshots | Snapshot API | cbbackupmgr | Replication | Continuous (automatic) | Automatic (managed) |
| Monitoring | Atlas, mongotop, mongostat | _cat APIs, Kibana | Couchbase UI, PMM | Fauxton | Azure Monitor | Firebase Console |
| Scaling | Sharding (manual or Atlas) | Add nodes, rebalance | Auto-rebalance | Add nodes | Auto-scale (RU/s) | Automatic |
| Encryption | TLS, CSFLE, EAR | TLS, EAR | TLS, EAR | TLS | TLS, EAR, CMK | TLS, EAR (managed) |
| Auth | SCRAM, X.509, LDAP | Native, SAML, OIDC | LDAP, PAM, X.509 | Cookie, JWT | AAD, RBAC | Firebase Auth |
| Max Doc Size | 16 MB | ~100 MB (not recommended) | 20 MB | 4 GB (attachments) | 2 MB | 1 MB |

---

For detailed deep-dives, see:
- [reference-mongodb.md](reference-mongodb.md)
- [reference-elasticsearch.md](reference-elasticsearch.md)
