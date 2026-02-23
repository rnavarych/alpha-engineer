# Relational and Document Data Modeling

## When to load
Load when designing entity-relationship models for relational databases, deciding between embedding vs referencing in MongoDB, or applying document design patterns (polymorphic, bucket, outlier, subset, computed).

## Relational Data Modeling

### Entity-Relationship Notation Systems

| Notation | Origin | Key Feature |
|----------|--------|-------------|
| **Chen** | Peter Chen (1976) | Diamonds for relationships, circles for attributes |
| **Crow's Foot** | Gordon Everest | Fork symbol for "many", most popular in industry |
| **UML Class Diagram** | OMG | Software engineering style, multiplicity labels |
| **IDEF1X** | US DoD | Formal, identifying vs non-identifying relationships |

### Relationship Types

| Type | Example | Implementation |
|------|---------|----------------|
| **1:1** | User ↔ Profile | FK with UNIQUE constraint, or same table |
| **1:N** | Customer → Orders | FK on the "many" side |
| **M:N** | Students ↔ Courses | Junction/bridge table with composite FK |
| **Self-referential** | Employee → Manager | FK referencing same table |
| **Polymorphic** | Comment → Post/Photo | Separate FKs per type (not commentable_type + commentable_id) |

### Normalization Decision Guide

| Scenario | Target Normal Form | Reason |
|----------|-------------------|--------|
| OLTP, simple queries | 3NF/BCNF | Balance integrity and performance |
| High-throughput writes | 3NF | Minimize update anomalies |
| Read-heavy reporting | 2NF with denormalization | Fewer joins, faster reads |
| Data warehouse | 1NF (dimensional model) | Optimized for analytical queries |

## Document Data Modeling (MongoDB)

### Embedding vs Referencing

| Factor | Embed | Reference |
|--------|-------|-----------|
| Relationship | 1:1, 1:few | 1:many, M:N |
| Access pattern | Always read together | Read independently |
| Update frequency | Rarely updated | Frequently updated |
| Data size | Small subdocument | Large or growing |

### Document Design Patterns

**Polymorphic Pattern:**
```javascript
{ _id: 1, type: "book", title: "...", author: "...", isbn: "..." }
{ _id: 2, type: "movie", title: "...", director: "...", runtime: 120 }
// Common fields indexed, type-specific fields vary
```

**Bucket Pattern (Time-Series):**
```javascript
{
    sensor_id: "temp-001",
    bucket_start: ISODate("2024-01-15T00:00:00Z"),
    count: 60,
    measurements: [
        { ts: ISODate("2024-01-15T00:00:00Z"), value: 22.5 },
        // ...60 measurements per document
    ],
    summary: { min: 22.1, max: 23.4, avg: 22.7 }
}
```

**Outlier Pattern:**
```javascript
// Normal: embed followers
{ _id: 1, name: "Alice", followers: ["user2", "user3", ...] }

// Outlier: overflow document
{ _id: 2, name: "Celebrity", followers: ["user1", ...], has_overflow: true }
{ _id: "2_overflow_1", base_user: 2, followers: [/* more */] }
```

**Subset Pattern:**
```javascript
// Product: embed only top 10 reviews
{
    _id: 1, name: "Widget", price: 29.99,
    recent_reviews: [/* top 10 reviews */],
    review_count: 15234
}
// Full reviews in separate reviews collection
```

**Computed Pattern:**
```javascript
{
    _id: "movie-123", title: "...",
    rating_count: 45000, rating_sum: 180000,
    rating_avg: 4.0  // pre-computed: sum/count
}
// Update atomically: { $inc: { rating_count: 1, rating_sum: 5 }, $set: { rating_avg: ... } }
```
