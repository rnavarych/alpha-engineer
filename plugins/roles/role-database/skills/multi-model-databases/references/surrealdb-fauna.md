# SurrealDB and FaunaDB

## When to load
Load when working with SurrealDB (SurrealQL, LIVE SELECT, built-in auth, graph relations) or FaunaDB/Fauna (FQL v10, distributed ACID, temporal queries, streaming).

## SurrealDB — Schema and CRUD

```sql
-- Define schema (SCHEMAFULL enforces types)
DEFINE TABLE orders SCHEMAFULL;
DEFINE FIELD customer ON TABLE orders TYPE record<customers>;
DEFINE FIELD amount ON TABLE orders TYPE decimal;
DEFINE FIELD status ON TABLE orders TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'confirmed', 'shipped', 'cancelled'];
DEFINE FIELD createdAt ON TABLE orders TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_status ON TABLE orders FIELDS status;

-- Create record with links
CREATE orders:order1 SET
    customer = customers:alice,
    amount = 99.99,
    items = [{ product: products:widget, qty: 2 }];
```

## SurrealDB — Graph Relations

```sql
-- RELATE creates graph edges
RELATE customers:alice->purchased->products:widget SET
    quantity = 2, purchasedAt = time::now();

-- Traverse graph
SELECT ->purchased->products.*.name FROM customers:alice;
SELECT <-purchased<-customers FROM products:widget;
```

## SurrealDB — LIVE SELECT

```javascript
const db = new Surreal();
await db.connect('ws://localhost:8000/rpc');
await db.signin({ username: 'root', password: 'root' });
await db.use({ namespace: 'myapp', database: 'production' });

// Real-time updates on table changes
const queryUuid = await db.live('orders', (action, result) => {
    if (action === 'CREATE') console.log('New order:', result);
    if (action === 'UPDATE') console.log('Order updated:', result);
    if (action === 'DELETE') console.log('Order deleted:', result);
});

const liveQuery = await db.live(
    'SELECT * FROM orders WHERE status = "pending"',
    (action, result) => { /* handle */ }
);

await db.kill(queryUuid);
```

## SurrealDB — Built-in Authentication

```sql
DEFINE SCOPE account SESSION 24h
    SIGNUP (CREATE user SET email = $email, pass = crypto::argon2::generate($pass))
    SIGNIN (SELECT * FROM user WHERE email = $email AND crypto::argon2::compare(pass, $pass));
-- Table-level permissions (row security built in)
DEFINE TABLE orders SCHEMAFULL
    PERMISSIONS FOR select WHERE customer = $auth.id
                FOR create WHERE $auth.id != NONE
                FOR update WHERE customer = $auth.id AND status = 'pending'
                FOR delete NONE;
```

## FaunaDB / Fauna — FQL v10

```typescript
import { Client, fql } from 'fauna';
const client = new Client({ secret: 'fn...' });

// Create collection with indexes — all queries require an index (no full scans)
await client.query(fql`Collection.create({ name: "orders", indexes: {
  byCustomer: { terms: [{ field: "customer" }], values: [{ field: "createdAt", order: "desc" }] },
  byStatus: { terms: [{ field: "status" }] }
}, constraints: [{ unique: ["orderNumber"] }] })`);

// Query with index + map
const pending = await client.query(fql`
  orders.byStatus("pending").pageSize(20)
    .map(o => { id: o.id, amount: o.amount, customerName: o.customer.name })`);
```

## FaunaDB — Distributed ACID Transactions

```typescript
// Calvin protocol: globally distributed, serializable
await client.query(fql`
  let order = orders.byId("order-123")
  let inventory = inventory.byProduct(order.items[0].product)
  if (inventory.quantity < order.items[0].quantity) { abort("Insufficient inventory") }
  order.update({ status: "confirmed" })
  inventory.update({ quantity: inventory.quantity - order.items[0].quantity })
`);
// Temporal query + streaming
await client.query(fql`orders.byId("order-123").at("2024-06-15T10:00:00Z")`);
const stream = client.stream(fql`orders.all().eventSource()`);
for await (const event of stream) { console.log(event.type, event.data); }
```

## Operational Notes

**SurrealDB**:
- Define schemas (SCHEMAFULL) for production tables
- Use namespaces and databases for multi-tenancy
- Monitor WebSocket connections for LIVE SELECT load

**FaunaDB**:
- Use indexes for all query patterns (no full scans)
- Leverage temporal queries for audit/compliance
- Monitor compute operations for cost control
