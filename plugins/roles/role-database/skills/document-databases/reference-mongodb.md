# MongoDB Deep-Dive Reference

## Data Modeling

### Embedding vs Referencing Decision Matrix

| Factor | Embed | Reference |
|--------|-------|-----------|
| Relationship | 1:1, 1:few | 1:many (large), many:many |
| Read pattern | Read together | Read independently |
| Write pattern | Updated together | Updated independently |
| Document size | Within 16 MB | Exceeds 16 MB if embedded |
| Data duplication | Acceptable | Unacceptable |
| Atomicity needed | Yes (single document) | No (or use transactions) |

### Design Patterns

```javascript
// Polymorphic Pattern: Different shapes in same collection
// Unified "events" collection with discriminator field
db.events.insertMany([
  { type: "click", url: "/products/123", userId: "u1", ts: new Date() },
  { type: "purchase", orderId: "o456", amount: 99.99, userId: "u1", ts: new Date() },
  { type: "signup", email: "user@example.com", source: "google", ts: new Date() }
]);
// Single index on { type: 1, ts: -1 } serves all event types

// Bucket Pattern: Group high-frequency data
db.sensor_readings.insertOne({
  sensorId: "temp-001",
  date: ISODate("2024-03-15"),
  count: 24,
  sum: 528.0,
  readings: [
    { ts: ISODate("2024-03-15T00:00:00Z"), value: 21.5 },
    { ts: ISODate("2024-03-15T01:00:00Z"), value: 22.1 },
    // ... hourly readings grouped into daily buckets
  ]
});

// Outlier Pattern: Handle documents with abnormally large arrays
db.products.insertOne({
  _id: "product-123",
  name: "Popular Widget",
  reviewCount: 15000,
  recentReviews: [ /* last 50 reviews */ ],
  hasOverflow: true  // Flag indicating overflow documents exist
});
// Overflow reviews in separate collection
db.product_reviews_overflow.insertOne({
  productId: "product-123",
  page: 1,
  reviews: [ /* reviews 51-500 */ ]
});

// Subset Pattern: Hot data embedded, cold data referenced
db.movies.insertOne({
  _id: "movie-456",
  title: "Example Movie",
  year: 2024,
  // Hot data (shown on listing page)
  rating: 8.5,
  poster: "/images/movie-456.jpg",
  topCast: ["Actor A", "Actor B"],
  // Cold data in separate collection: full cast, trivia, goofs, etc.
});
```

---

## Aggregation Pipeline Optimization

### Stage Ordering Rules
1. **`$match` first**: Reduces documents early. Uses indexes.
2. **`$project` / `$addFields` early**: Remove unnecessary fields to reduce memory.
3. **`$sort` before `$group`**: Allows sort to use indexes.
4. **`$limit` after `$sort`**: Limits data flowing through pipeline.
5. **Avoid `$unwind` on large arrays**: Consider `$filter` or array operators instead.

### Pipeline Examples

```javascript
// Window functions (MongoDB 5.0+)
db.sales.aggregate([
  { $setWindowFields: {
      partitionBy: "$region",
      sortBy: { date: 1 },
      output: {
        runningTotal: { $sum: "$amount", window: { documents: ["unbounded", "current"] } },
        movingAvg7d: { $avg: "$amount", window: { range: [-7, "current"], unit: "day" } },
        rank: { $rank: {} }
      }
  }}
]);

// Materialized view via $merge
db.orders.aggregate([
  { $match: { status: "completed" } },
  { $group: {
      _id: { year: { $year: "$createdAt" }, month: { $month: "$createdAt" } },
      revenue: { $sum: "$total" },
      count: { $sum: 1 }
  }},
  { $merge: {
      into: "monthly_revenue",
      on: "_id",
      whenMatched: "replace",
      whenNotMatched: "insert"
  }}
]);

// Fill gaps in time-series data (MongoDB 5.3+)
db.metrics.aggregate([
  { $densify: {
      field: "timestamp",
      range: { step: 1, unit: "hour", bounds: "full" }
  }},
  { $fill: {
      sortBy: { timestamp: 1 },
      output: {
        value: { method: "linear" },
        category: { method: "locf" }  // Last observation carried forward
      }
  }}
]);
```

### $lookup Optimization

```javascript
// Optimized $lookup with pipeline (reduces data before join)
{ $lookup: {
    from: "inventory",
    let: { productId: "$productId", minQty: 10 },
    pipeline: [
      { $match: { $expr: {
        $and: [
          { $eq: ["$productId", "$$productId"] },
          { $gte: ["$quantity", "$$minQty"] }
        ]
      }}},
      { $project: { warehouse: 1, quantity: 1 } }
    ],
    as: "availableStock"
}}
// Ensure index exists on inventory.productId for performance
```

---

## Sharding

### Shard Key Selection Criteria

| Criterion | Good Key | Bad Key |
|-----------|----------|---------|
| Cardinality | userId (millions) | country (hundreds) |
| Frequency | Even distribution | 80% of writes to one value |
| Monotonic increase | Hashed ObjectId | Raw ObjectId or timestamp |
| Query isolation | Matches most query filters | Rarely in query filters |

### Shard Key Strategies

```javascript
// Hashed sharding (best for write distribution)
sh.shardCollection("mydb.events", { _id: "hashed" });

// Compound shard key (balanced reads and writes)
sh.shardCollection("mydb.orders", { customerId: 1, _id: 1 });

// Refining shard key (MongoDB 4.4+, add suffix to existing key)
db.adminCommand({
  refineCollectionShardKey: "mydb.orders",
  key: { customerId: 1, _id: 1, createdAt: 1 }
});
```

### Chunk Migration and Balancer

```javascript
// Check balancer status
sh.getBalancerState();
sh.isBalancerRunning();

// Set balancer window (avoid peak hours)
db.adminCommand({
  balancerStart: 1,
  _secondaryThrottle: true
});

// Check chunk distribution
db.getSiblingDB("config").chunks.aggregate([
  { $group: { _id: "$shard", count: { $sum: 1 } } }
]);

// Manual chunk splitting
sh.splitAt("mydb.orders", { customerId: NumberLong("500000") });
```

---

## Indexes

### Index Types and Usage

```javascript
// Compound index (multi-field, order matters)
db.orders.createIndex({ customerId: 1, createdAt: -1, status: 1 });

// Multikey index (automatic for arrays)
db.products.createIndex({ tags: 1 });

// Text index (full-text search)
db.articles.createIndex({ title: "text", body: "text" }, { weights: { title: 10, body: 1 } });

// 2dsphere index (geospatial)
db.stores.createIndex({ location: "2dsphere" });

// Wildcard index (dynamic schemas)
db.logs.createIndex({ "metadata.$**": 1 });

// Partial index (index subset of documents)
db.orders.createIndex(
  { customerId: 1, total: 1 },
  { partialFilterExpression: { status: "active", total: { $gt: 100 } } }
);

// TTL index (automatic expiration)
db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });

// Hidden index (test removal without dropping)
db.orders.hideIndex("idx_old_field");
// If no performance regression:
db.orders.dropIndex("idx_old_field");

// Clustered index (MongoDB 5.3+, co-locate documents by key)
db.createCollection("timeseries_data", { clusteredIndex: {
  key: { _id: 1 }, unique: true
}});
```

### Index Analysis

```javascript
// Check index usage statistics
db.orders.aggregate([{ $indexStats: {} }]);

// Identify unused indexes (no ops since last restart)
db.orders.aggregate([
  { $indexStats: {} },
  { $match: { "accesses.ops": 0 } }
]);

// Explain query to verify index usage
db.orders.find({ customerId: "c123", status: "active" })
  .sort({ createdAt: -1 })
  .explain("executionStats");
// Look for: stage: "IXSCAN" (good), not "COLLSCAN" (bad)
```

---

## Change Streams

```javascript
// Watch collection for changes
const pipeline = [
  { $match: { "operationType": { $in: ["insert", "update"] } } },
  { $match: { "fullDocument.status": "urgent" } }
];

const changeStream = db.collection("tickets").watch(pipeline, {
  fullDocument: "updateLookup",           // Include full document on updates
  fullDocumentBeforeChange: "whenAvailable"  // Pre-image (MongoDB 6.0+)
});

changeStream.on("change", (change) => {
  console.log("Operation:", change.operationType);
  console.log("Document:", change.fullDocument);
  console.log("Before:", change.fullDocumentBeforeChange);

  // Save resume token for fault tolerance
  const resumeToken = change._id;
  saveResumeToken(resumeToken);
});

// Resume from saved token after restart
const savedToken = loadResumeToken();
const resumedStream = db.collection("tickets").watch(pipeline, {
  resumeAfter: savedToken
});
```

---

## Atlas Features

### Atlas Search

```javascript
// Create search index (via Atlas UI or API)
{
  "mappings": {
    "dynamic": false,
    "fields": {
      "title": { "type": "string", "analyzer": "lucene.english" },
      "description": { "type": "string", "analyzer": "lucene.english" },
      "category": { "type": "stringFacet" },
      "price": { "type": "number" }
    }
  }
}

// Search query in aggregation pipeline
db.products.aggregate([
  { $search: {
      index: "product_search",
      compound: {
        must: [{ text: { query: "wireless headphones", path: "title", fuzzy: { maxEdits: 1 } } }],
        filter: [{ range: { path: "price", gte: 50, lte: 200 } }]
      },
      highlight: { path: "title" }
  }},
  { $project: { title: 1, price: 1, score: { $meta: "searchScore" }, highlights: { $meta: "searchHighlights" } } },
  { $limit: 20 }
]);
```

### Atlas Vector Search

```javascript
// Vector search index definition
{
  "fields": [{
    "type": "vector",
    "path": "embedding",
    "numDimensions": 1536,
    "similarity": "cosine"
  }]
}

// kNN query
db.products.aggregate([
  { $vectorSearch: {
      index: "vector_index",
      path: "embedding",
      queryVector: [0.1, 0.2, ...],  // 1536 dimensions
      numCandidates: 100,
      limit: 10,
      filter: { category: "electronics" }
  }},
  { $project: { title: 1, score: { $meta: "vectorSearchScore" } } }
]);
```

---

## CSFLE and Queryable Encryption

### Client-Side Field Level Encryption

```javascript
const { MongoClient, ClientEncryption } = require('mongodb');

// Key vault configuration
const keyVaultNamespace = "encryption.__keyVault";
const kmsProviders = {
  aws: { accessKeyId: "...", secretAccessKey: "..." }
  // Or: local, azure, gcp, kmip
};

// Create data encryption key
const encryption = new ClientEncryption(client, { keyVaultNamespace, kmsProviders });
const dataKeyId = await encryption.createDataKey("aws", {
  masterKey: { key: "arn:aws:kms:...", region: "us-east-1" }
});

// Schema map for automatic encryption
const schemaMap = {
  "mydb.patients": {
    bsonType: "object",
    encryptMetadata: { keyId: [dataKeyId] },
    properties: {
      ssn: {
        encrypt: { bsonType: "string", algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic" }
      },
      medicalRecords: {
        encrypt: { bsonType: "array", algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Random" }
      }
    }
  }
};

// Auto-encrypting client
const secureClient = new MongoClient(uri, {
  autoEncryption: { keyVaultNamespace, kmsProviders, schemaMap }
});
```

---

## Transactions

```javascript
const session = client.startSession();
try {
  session.startTransaction({
    readConcern: { level: "snapshot" },
    writeConcern: { w: "majority" },
    readPreference: "primary"
  });

  const orders = client.db("mydb").collection("orders");
  const inventory = client.db("mydb").collection("inventory");

  await orders.insertOne({ customerId: "c1", items: [...], total: 199.99 }, { session });
  await inventory.updateOne(
    { productId: "p1", quantity: { $gte: 1 } },
    { $inc: { quantity: -1 } },
    { session }
  );

  await session.commitTransaction();
} catch (error) {
  await session.abortTransaction();
  throw error;
} finally {
  session.endSession();
}
```

### Transaction Limits
- Default timeout: 60 seconds (configurable).
- Max oplog entry: 16 MB per transaction.
- Cross-shard transactions: Higher latency, use sparingly.
- Lock: Documents modified in a transaction are locked until commit/abort.

---

## Performance Diagnostics

```javascript
// Current operations (find slow/blocked queries)
db.currentOp({ "secs_running": { $gte: 5 } });

// Kill long-running operation
db.killOp(opId);

// Profiler (log slow queries)
db.setProfilingLevel(1, { slowms: 100 });  // Level 1: slow queries only
db.system.profile.find().sort({ ts: -1 }).limit(10);

// Server status
db.serverStatus().opcounters;        // Read/write counts
db.serverStatus().connections;        // Connection stats
db.serverStatus().wiredTiger.cache;   // Cache hit ratios

// Collection stats
db.orders.stats({ scale: 1024 * 1024 });  // Size in MB

// Explain with execution stats
db.orders.find({ status: "pending" }).explain("executionStats");
// Key metrics: totalDocsExamined, totalKeysExamined, executionTimeMillis
// Goal: totalDocsExamined ~= nReturned (no excess scanning)
```

### mongotop and mongostat

```bash
# Top operations by collection (every 5 seconds)
mongotop 5

# Real-time server statistics
mongostat --rowcount 0 --discover
# Key columns: query, insert, update, delete, getmore, command, dirty%, used%, qrw, arw
```

---

## Backup

```bash
# mongodump (logical backup)
mongodump --uri="mongodb+srv://cluster.mongodb.net/mydb" \
  --gzip --archive=/backups/mydb-$(date +%Y%m%d).gz

# mongorestore (with drop existing)
mongorestore --uri="mongodb+srv://cluster.mongodb.net/mydb" \
  --gzip --archive=/backups/mydb-20240315.gz --drop

# Atlas continuous backup (managed)
# Configured via Atlas UI: continuous backup with point-in-time restore
# Retention: configurable from 1 day to 1 year

# Filesystem snapshots (self-managed)
# 1. Lock writes:
db.fsyncLock();
# 2. Take LVM/EBS snapshot
# 3. Unlock:
db.fsyncUnlock();
```

---

## Security

### Authentication Methods

| Method | Use Case | Config |
|--------|----------|--------|
| SCRAM-SHA-256 | Default, username/password | `--auth` |
| X.509 | Certificate-based | `net.tls.clusterAuthX509` |
| LDAP | Enterprise directory | `security.ldap.servers` |
| Kerberos | Enterprise SSO | `authenticationMechanisms: GSSAPI` |

### Network Security

```yaml
# mongod.conf
net:
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb.pem
    CAFile: /etc/ssl/ca.pem
  bindIp: 0.0.0.0

security:
  authorization: enabled
  clusterAuthMode: x509
```

### Audit Log (Enterprise)

```yaml
auditLog:
  destination: file
  format: JSON
  path: /var/log/mongodb/audit.json
  filter: '{ atype: { $in: ["createCollection","dropCollection","createUser","dropUser","authenticate"] } }'
```
