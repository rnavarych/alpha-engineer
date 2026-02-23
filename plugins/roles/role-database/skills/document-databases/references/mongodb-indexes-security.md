# MongoDB — Indexes, Change Streams, Atlas, CSFLE, Transactions, Diagnostics

## When to load
Load when creating MongoDB indexes, working with Atlas Search/Vector Search, implementing CSFLE or Queryable Encryption, writing multi-document transactions, or diagnosing slow queries with the profiler.

## Index Types

```javascript
// Compound index
db.orders.createIndex({ customerId: 1, createdAt: -1, status: 1 });

// Text index with weights
db.articles.createIndex({ title: "text", body: "text" }, { weights: { title: 10, body: 1 } });

// 2dsphere (geospatial)
db.stores.createIndex({ location: "2dsphere" });

// Wildcard index (dynamic schemas)
db.logs.createIndex({ "metadata.$**": 1 });

// Partial index
db.orders.createIndex(
  { customerId: 1, total: 1 },
  { partialFilterExpression: { status: "active", total: { $gt: 100 } } }
);

// TTL index
db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });

// Hidden index (test removal without dropping)
db.orders.hideIndex("idx_old_field");

// Check unused indexes
db.orders.aggregate([{ $indexStats: {} }, { $match: { "accesses.ops": 0 } }]);

// Explain query
db.orders.find({ customerId: "c123", status: "active" })
  .sort({ createdAt: -1 }).explain("executionStats");
// Look for: stage: "IXSCAN" (good), not "COLLSCAN" (bad)
```

## Change Streams

```javascript
const pipeline = [
  { $match: { "operationType": { $in: ["insert", "update"] } } },
  { $match: { "fullDocument.status": "urgent" } }
];
const changeStream = db.collection("tickets").watch(pipeline, {
  fullDocument: "updateLookup",
  fullDocumentBeforeChange: "whenAvailable"  // MongoDB 6.0+
});
changeStream.on("change", (change) => {
  const resumeToken = change._id;
  saveResumeToken(resumeToken);
});
// Resume after restart
const resumedStream = db.collection("tickets").watch(pipeline, { resumeAfter: savedToken });
```

## Atlas Search and Vector Search

```javascript
// Atlas Search query
db.products.aggregate([{ $search: {
    index: "product_search",
    compound: {
      must: [{ text: { query: "wireless headphones", path: "title", fuzzy: { maxEdits: 1 } } }],
      filter: [{ range: { path: "price", gte: 50, lte: 200 } }]
    }
}}, { $limit: 20 }]);

// Atlas Vector Search
db.products.aggregate([{ $vectorSearch: {
    index: "vector_index", path: "embedding",
    queryVector: [0.1, 0.2, /* ... 1536 dims */],
    numCandidates: 100, limit: 10,
    filter: { category: "electronics" }
}}, { $project: { title: 1, score: { $meta: "vectorSearchScore" } } }]);
```

## CSFLE (Client-Side Field Level Encryption)

```javascript
const schemaMap = {
  "mydb.patients": {
    bsonType: "object",
    encryptMetadata: { keyId: [dataKeyId] },
    properties: {
      ssn: { encrypt: { bsonType: "string", algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic" } },
      medicalRecords: { encrypt: { bsonType: "array", algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Random" } }
    }
  }
};
const secureClient = new MongoClient(uri, { autoEncryption: { keyVaultNamespace, kmsProviders, schemaMap } });
```

## Multi-Document Transactions

```javascript
const session = client.startSession();
try {
  session.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
  await orders.insertOne({ customerId: "c1", total: 199.99 }, { session });
  await inventory.updateOne({ productId: "p1" }, { $inc: { quantity: -1 } }, { session });
  await session.commitTransaction();
} catch (error) {
  await session.abortTransaction();
  throw error;
} finally {
  session.endSession();
}
// Transaction limits: 60s default timeout, 16 MB max oplog entry, cross-shard = higher latency
```

## Performance Diagnostics

```javascript
// Current ops (find slow/blocked queries)
db.currentOp({ "secs_running": { $gte: 5 } });
db.killOp(opId);

// Profiler
db.setProfilingLevel(1, { slowms: 100 });
db.system.profile.find().sort({ ts: -1 }).limit(10);

// Server status
db.serverStatus().opcounters;
db.serverStatus().wiredTiger.cache;

// Collection stats in MB
db.orders.stats({ scale: 1024 * 1024 });
```

```bash
mongotop 5
mongostat --rowcount 0 --discover
mongodump --uri="mongodb+srv://cluster.mongodb.net/mydb" --gzip --archive=/backups/mydb.gz
```
