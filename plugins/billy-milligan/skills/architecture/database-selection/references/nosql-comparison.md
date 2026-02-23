# NoSQL Database Comparison

## When to load
Load when choosing between MongoDB, DynamoDB, Cassandra, or Redis for non-relational data storage.

## Patterns

### MongoDB (document store, default NoSQL choice)
```typescript
// Flexible schema with validation
db.createCollection('products', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'price', 'category'],
      properties: {
        name: { bsonType: 'string' },
        price: { bsonType: 'decimal' },
        variants: {
          bsonType: 'array',
          items: { bsonType: 'object' }
        }
      }
    }
  }
});

// Aggregation pipeline
db.orders.aggregate([
  { $match: { status: 'completed', createdAt: { $gte: thirtyDaysAgo } } },
  { $group: { _id: '$customerId', total: { $sum: '$amount' }, count: { $sum: 1 } } },
  { $sort: { total: -1 } },
  { $limit: 100 }
]);
```
Scale: replica sets for HA, sharding for horizontal scale. Atlas handles 1M+ ops/sec. Good for: variable schemas, rapid prototyping, content management. Use `{ w: 'majority', readConcern: 'majority' }` for consistency.

### DynamoDB (managed, serverless-friendly)
```typescript
// Single-table design pattern
const params = {
  TableName: 'AppTable',
  KeySchema: [
    { AttributeName: 'PK', KeyType: 'HASH' },  // partition key
    { AttributeName: 'SK', KeyType: 'RANGE' },  // sort key
  ],
  // PK=USER#123 SK=PROFILE        -> user profile
  // PK=USER#123 SK=ORDER#2024-001 -> user's order
  // PK=ORDER#2024-001 SK=ITEM#1   -> order line item
};

// Query: all orders for a user
await dynamodb.query({
  TableName: 'AppTable',
  KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
  ExpressionAttributeValues: { ':pk': 'USER#123', ':sk': 'ORDER#' }
});
```
Scale: virtually unlimited with proper partition key design. On-demand: pay per request. Provisioned: reserve capacity. Single-digit ms latency. GSI for access pattern flexibility. DAX for sub-ms caching.

### Cassandra (wide-column, write-heavy)
```cql
-- Designed for write-heavy, time-series workloads
CREATE TABLE sensor_readings (
  sensor_id UUID,
  reading_time TIMESTAMP,
  temperature DECIMAL,
  humidity DECIMAL,
  PRIMARY KEY (sensor_id, reading_time)
) WITH CLUSTERING ORDER BY (reading_time DESC)
  AND default_time_to_live = 7776000;  -- 90 days

-- Tunable consistency per query
-- ONE: fastest, eventual consistency
-- QUORUM: balance of speed and consistency
-- ALL: strongest, highest latency
SELECT * FROM sensor_readings
  WHERE sensor_id = ? AND reading_time > ?;
```
Scale: linear horizontal scaling, handles 100k+ writes/sec per node. Multi-DC replication built-in. No single point of failure. Best for: IoT, time-series, audit logs, messaging.

### Redis (as primary store, not just cache)
```typescript
// Redis Streams for event log
await redis.xadd('events:orders', '*',
  'type', 'order.created',
  'orderId', '123',
  'amount', '99.99'
);

// Consumer group for reliable processing
await redis.xreadgroup('GROUP', 'processors', 'worker-1',
  'COUNT', 10, 'BLOCK', 5000, 'STREAMS', 'events:orders', '>'
);

// Redis as session store
await redis.hset('session:abc', { userId: '123', role: 'admin', expiresAt: ttl });
await redis.expire('session:abc', 86400);
```
Scale: ~100k ops/sec single node, Redis Cluster for horizontal. Use for: sessions, queues, pub/sub, rate limiting, real-time leaderboards. Not for: >25GB datasets, complex queries, durability-critical data.

## Anti-patterns
- MongoDB without schema validation -> data quality degrades over time
- DynamoDB with scan operations on large tables -> expensive and slow
- Cassandra for read-heavy with complex queries -> use Postgres instead
- Redis as sole data store for critical data -> no durability guarantees by default

## Decision criteria
| Factor | MongoDB | DynamoDB | Cassandra | Redis |
|--------|---------|----------|-----------|-------|
| Best for | Variable schema, aggregation | Serverless, predictable scale | Write-heavy, time-series | Real-time, sub-ms latency |
| Consistency | Tunable (majority) | Strong or eventual | Tunable per query | Strong (single node) |
| Scale ceiling | Millions ops/sec (sharded) | Virtually unlimited | Linear, multi-DC | ~100k ops/sec/node |
| Operational complexity | Medium (Atlas: low) | Low (managed) | High | Low |
| Cost model | Storage + compute | Per request or provisioned | Node-based | Memory-based |
| Query flexibility | Rich (aggregation) | Limited (key-based) | Limited (partition key) | Data-structure specific |

## Quick reference
```
Default NoSQL: MongoDB (flexible, rich queries)
Serverless/AWS-native: DynamoDB (single-table design)
Write-heavy/time-series: Cassandra (linear scale)
Sub-ms/real-time: Redis (in-memory)
DynamoDB partition key: high cardinality, even distribution
Cassandra: model tables around query patterns (1 table per query)
MongoDB: embed related data, reference only for many-to-many
Redis: always set maxmemory and eviction policy
```
