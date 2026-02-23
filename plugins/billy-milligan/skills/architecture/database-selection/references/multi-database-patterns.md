# Multi-Database Patterns

## When to load
Load when discussing polyglot persistence, CQRS with separate read/write stores, data synchronization, or change data capture (CDC).

## Patterns

### Polyglot persistence
```
Service architecture with purpose-fit databases:

Users Service      -> PostgreSQL (relational, ACID transactions)
Product Catalog    -> MongoDB (flexible schema, rich queries)
Shopping Cart      -> Redis (fast reads/writes, TTL expiry)
Order History      -> DynamoDB (high-scale, predictable latency)
Search             -> Elasticsearch (full-text, faceted search)
Analytics          -> TimescaleDB (time-series aggregations)
Recommendations    -> Neo4j (graph traversals)
```
Each service owns its database. No shared databases between services. Data exchange via APIs or events.

### CQRS (Command Query Responsibility Segregation)
```typescript
// Write side: normalized, optimized for transactions
// PostgreSQL - source of truth
async function createOrder(cmd: CreateOrderCommand): Promise<Order> {
  return db.transaction(async (tx) => {
    const order = await tx.insert(orders).values(cmd).returning();
    await tx.insert(orderItems).values(
      cmd.items.map(item => ({ orderId: order.id, ...item }))
    );
    // Publish event for read-side projection
    await tx.insert(outboxEvents).values({
      topic: 'orders.created',
      payload: { orderId: order.id, ...cmd },
    });
    return order;
  });
}

// Read side: denormalized, optimized for queries
// MongoDB/Elasticsearch - materialized view
async function handleOrderCreated(event: OrderCreatedEvent) {
  await readDb.collection('order_views').insertOne({
    orderId: event.orderId,
    customerName: event.customerName,  // denormalized
    items: event.items,                // embedded
    totalAmount: event.items.reduce((sum, i) => sum + i.price * i.qty, 0),
    status: 'created',
    searchText: `${event.customerName} ${event.items.map(i => i.name).join(' ')}`,
  });
}

// Query: fast reads from denormalized view
async function getOrdersByCustomer(customerId: string) {
  return readDb.collection('order_views')
    .find({ customerId })
    .sort({ createdAt: -1 })
    .limit(50)
    .toArray();
}
```
Write model handles business rules and consistency. Read model serves display-optimized data. Eventual consistency between them (typically <1s lag).

### Change Data Capture (CDC) with Debezium
```yaml
# docker-compose for Debezium CDC pipeline
# Postgres -> Debezium -> Kafka -> Consumer -> Elasticsearch
services:
  debezium:
    image: debezium/connect:2.5
    environment:
      BOOTSTRAP_SERVERS: kafka:9092
      GROUP_ID: cdc-group
      CONFIG_STORAGE_TOPIC: cdc-configs
      OFFSET_STORAGE_TOPIC: cdc-offsets
      STATUS_STORAGE_TOPIC: cdc-status

# Debezium connector config
# POST /connectors
connector_config:
  name: postgres-source
  config:
    connector.class: io.debezium.connector.postgresql.PostgresConnector
    database.hostname: postgres
    database.port: 5432
    database.dbname: app
    database.server.name: appdb
    table.include.list: public.products,public.orders
    plugin.name: pgoutput
    slot.name: debezium_slot
    publication.name: debezium_pub
    transforms: unwrap
    transforms.unwrap.type: io.debezium.transforms.ExtractNewRecordState
```

```typescript
// CDC consumer: sync Postgres -> Elasticsearch
kafkaConsumer.subscribe({ topics: ['appdb.public.products'] });

await kafkaConsumer.run({
  eachMessage: async ({ message }) => {
    const change = JSON.parse(message.value.toString());
    const { op, after, before } = change;

    switch (op) {
      case 'c': // create
      case 'u': // update
        await esClient.index({
          index: 'products',
          id: after.id,
          document: transformForSearch(after),
        });
        break;
      case 'd': // delete
        await esClient.delete({ index: 'products', id: before.id });
        break;
    }
  },
});
```

### Data sync patterns
```
1. Event-driven sync (preferred)
   Write -> Outbox -> Event Bus -> Consumer updates read store
   Latency: 100ms-2s | Reliability: high (at-least-once)

2. CDC (Change Data Capture)
   Write -> WAL -> Debezium -> Kafka -> Consumer
   Latency: 50ms-1s | Reliability: very high (WAL-based)

3. Dual-write (avoid if possible)
   Write -> DB1 + DB2 in sequence
   Problem: partial failure leaves inconsistent state
   Mitigation: saga or outbox pattern

4. Periodic sync (batch)
   Cron -> Read source -> Update target
   Latency: minutes-hours | Use for: analytics, reporting
```

## Anti-patterns
- Dual-write without outbox pattern -> split-brain on partial failures
- Shared database between services -> coupling, migration nightmare
- CQRS for simple CRUD apps -> unnecessary complexity, use when read/write patterns diverge significantly
- CDC without monitoring -> silent lag goes unnoticed, read store falls behind

## Decision criteria
- **Single DB**: default for new projects, <5 services, same read/write patterns
- **CQRS**: read patterns differ significantly from write (dashboards, search), >10x read:write ratio
- **CDC**: need to sync Postgres to Elasticsearch/analytics without changing write code
- **Polyglot**: mature microservices, each service has genuinely different data needs

## Quick reference
```
Default: single PostgreSQL until proven insufficient
CQRS: separate read/write models, eventual consistency (<1s typical)
CDC: WAL-based (Debezium), most reliable sync method
Outbox: event + data in same transaction, poll-and-publish
Never: shared database between microservices
Never: dual-write without compensation mechanism
CDC lag monitoring: alert if >5s behind
```
