# MongoDB — Data Modeling and Aggregation Pipeline

## When to load
Load when designing MongoDB document schemas, choosing embedding vs referencing, writing aggregation pipelines, using window functions, $merge materialized views, or optimizing $lookup joins.

## Embedding vs Referencing Decision Matrix

| Factor | Embed | Reference |
|--------|-------|-----------|
| Relationship | 1:1, 1:few | 1:many (large), many:many |
| Read pattern | Read together | Read independently |
| Write pattern | Updated together | Updated independently |
| Document size | Within 16 MB | Exceeds 16 MB if embedded |
| Atomicity needed | Yes (single document) | No (or use transactions) |

## Design Patterns

```javascript
// Polymorphic Pattern: discriminator field
db.events.insertMany([
  { type: "click", url: "/products/123", userId: "u1", ts: new Date() },
  { type: "purchase", orderId: "o456", amount: 99.99, userId: "u1", ts: new Date() }
]);

// Bucket Pattern: group high-frequency data
db.sensor_readings.insertOne({
  sensorId: "temp-001", date: ISODate("2024-03-15"), count: 24,
  readings: [{ ts: ISODate("2024-03-15T00:00:00Z"), value: 21.5 }, ...]
});

// Outlier Pattern: handle large arrays
db.products.insertOne({
  _id: "product-123", name: "Popular Widget",
  reviewCount: 15000, recentReviews: [ /* last 50 */ ], hasOverflow: true
});
db.product_reviews_overflow.insertOne({ productId: "product-123", page: 1, reviews: [...] });

// Subset Pattern: hot data embedded, cold data referenced
db.movies.insertOne({
  _id: "movie-456", title: "Example Movie",
  rating: 8.5, poster: "/images/movie-456.jpg", topCast: ["Actor A", "Actor B"]
  // full cast in separate collection
});
```

## Aggregation Pipeline Optimization

Stage ordering rules:
1. `$match` first — reduces documents early, uses indexes
2. `$project` / `$addFields` early — remove unnecessary fields
3. `$sort` before `$group` — allows sort to use indexes
4. `$limit` after `$sort` — limits downstream volume

```javascript
// Window functions (MongoDB 5.0+)
db.sales.aggregate([{ $setWindowFields: {
    partitionBy: "$region", sortBy: { date: 1 },
    output: {
      runningTotal: { $sum: "$amount", window: { documents: ["unbounded", "current"] } },
      movingAvg7d: { $avg: "$amount", window: { range: [-7, "current"], unit: "day" } },
      rank: { $rank: {} }
    }
}}]);

// Materialized view via $merge
db.orders.aggregate([
  { $match: { status: "completed" } },
  { $group: { _id: { year: { $year: "$createdAt" }, month: { $month: "$createdAt" } },
              revenue: { $sum: "$total" }, count: { $sum: 1 } }},
  { $merge: { into: "monthly_revenue", on: "_id", whenMatched: "replace", whenNotMatched: "insert" }}
]);

// Optimized $lookup with pipeline
{ $lookup: {
    from: "inventory",
    let: { productId: "$productId", minQty: 10 },
    pipeline: [
      { $match: { $expr: { $and: [
        { $eq: ["$productId", "$$productId"] },
        { $gte: ["$quantity", "$$minQty"] }
      ]}}},
      { $project: { warehouse: 1, quantity: 1 } }
    ],
    as: "availableStock"
}}
```

## Sharding

```javascript
// Hashed sharding (write distribution)
sh.shardCollection("mydb.events", { _id: "hashed" });

// Compound shard key (balanced reads and writes)
sh.shardCollection("mydb.orders", { customerId: 1, _id: 1 });

// Zone sharding (geo-routing)
sh.addShardTag("shard-us-east", "US");
sh.addTagRange("mydb.users", { region: "US" }, { region: "US\uffff" }, "US");

// Check chunk distribution
db.getSiblingDB("config").chunks.aggregate([{ $group: { _id: "$shard", count: { $sum: 1 } } }]);
```

## Shard Key Selection

| Criterion | Good | Bad |
|-----------|------|-----|
| Cardinality | userId (millions) | country (hundreds) |
| Frequency | Even distribution | 80% of writes to one value |
| Monotonic | Hashed ObjectId | Raw ObjectId or timestamp |
