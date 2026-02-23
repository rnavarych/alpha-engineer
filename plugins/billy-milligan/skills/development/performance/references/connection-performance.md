# Connection Performance

## Connection Pooling

```
Why pooling matters:
  - Opening a PostgreSQL connection costs ~3ms + 1–10MB RAM on the server
  - At 100 req/s with 50ms avg query time, you need 5 concurrent connections
  - Without pooling: 100 connections/sec * 3ms = wasted before query even runs
  - Rule of thumb: pool size = (CPU cores * 2) + number of disks

PgBouncer modes:
  - session:     connection held for entire client session (least efficient)
  - transaction: connection returned after each transaction (recommended)
  - statement:   connection returned after each statement (breaks transactions)
```

```typescript
// Node.js — pg connection pool
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                    // Max connections in pool
  idleTimeoutMillis: 30_000,  // Release idle connections after 30s
  connectionTimeoutMillis: 2_000, // Fail fast if no connection available
});

// Always release connections
async function query<T>(sql: string, params: unknown[]): Promise<T[]> {
  const client = await pool.connect();
  try {
    const result = await client.query(sql, params);
    return result.rows;
  } finally {
    client.release(); // ALWAYS release — even on error
  }
}

// Pool health monitoring
pool.on('error', (err) => {
  logger.error({ err }, 'Unexpected pool error');
});

// Expose pool stats for metrics
export function poolStats() {
  return {
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount,
  };
}
```

## Prepared Statements

```typescript
// Prepared statements: parse once, execute many times
// Saves ~0.1–1ms per query on complex SQL (parsing + planning)

// pg driver — named prepared statement
const client = await pool.connect();

await client.query({
  name: 'get-user-orders',
  text: 'SELECT id, status, total FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2',
  values: [userId, limit],
});

// Subsequent calls with same 'name' skip parsing phase

// Prisma — automatically uses prepared statements for findMany/findUnique
// Raw queries with Prisma.sql template literals are also parameterized
const orders = await prisma.$queryRaw`
  SELECT id, status, total FROM orders
  WHERE user_id = ${userId}
  LIMIT ${limit}
`;
// Template literal values are automatically parameterized — SQL injection safe
```

## Batch Operations

```typescript
// BAD: N separate INSERT statements
for (const item of items) {
  await db.query('INSERT INTO order_items (order_id, product_id, quantity) VALUES ($1, $2, $3)', [
    item.orderId, item.productId, item.quantity,
  ]);
}
// 1000 items = 1000 round trips

// GOOD: single multi-row INSERT
const values = items.map((_, i) => `($${i * 3 + 1}, $${i * 3 + 2}, $${i * 3 + 3})`).join(', ');
const params = items.flatMap((item) => [item.orderId, item.productId, item.quantity]);
await db.query(`INSERT INTO order_items (order_id, product_id, quantity) VALUES ${values}`, params);
// 1 round trip regardless of item count

// Prisma createMany — single INSERT
await prisma.orderItem.createMany({
  data: items.map((item) => ({
    orderId: item.orderId,
    productId: item.productId,
    quantity: item.quantity,
  })),
  skipDuplicates: true,
});

// Drizzle insert many
await db.insert(orderItems).values(
  items.map((item) => ({
    orderId: item.orderId,
    productId: item.productId,
    quantity: item.quantity,
  })),
);
```

## Read Replicas

```typescript
// Route reads to replica, writes to primary
class DatabaseRouter {
  constructor(
    private primary: Pool,
    private replica: Pool,
  ) {}

  // Writes always go to primary
  async write<T>(sql: string, params: unknown[]): Promise<T> {
    return this.primary.query(sql, params);
  }

  // Reads can go to replica (accepts slight replication lag)
  async read<T>(sql: string, params: unknown[]): Promise<T[]> {
    return this.replica.query(sql, params).then((r) => r.rows);
  }

  // Reads that need fresh data stay on primary
  async readFresh<T>(sql: string, params: unknown[]): Promise<T[]> {
    return this.primary.query(sql, params).then((r) => r.rows);
  }
}

// When replication lag matters:
// - After a write, read the same record: use primary (read-your-writes)
// - Reporting queries, dashboards: replica is fine
// - Inventory checks before purchase: primary required
```

## Anti-Patterns
- New connection per request — cold connect overhead on every req
- Pool too large — PostgreSQL max_connections exceeded, connections queue
- No connection timeout — requests hang forever when pool is exhausted
- Batch size too large — single INSERT with 100K rows locks table for seconds
- Using session pooling mode (PgBouncer) with transactions — connection not released mid-transaction

## Quick Reference
```
Pool size: (CPU cores * 2) + disks — start here, tune from metrics
PgBouncer: transaction mode — connection returned after each transaction
Prepared statements: name your queries — skip parse/plan on repeat calls
Batch insert: createMany / multi-row VALUES — 1 round trip not N
Read replica: reports and list views; primary for read-your-writes
Pool timeout: 2s connectionTimeout — fail fast, surface overload early
Monitor: pool.totalCount, idleCount, waitingCount — alert on waitingCount > 0
```

## When to load
Load when configuring connection pools, diagnosing connection exhaustion, implementing batch inserts, routing reads to replicas, or optimizing query throughput with prepared statements.
