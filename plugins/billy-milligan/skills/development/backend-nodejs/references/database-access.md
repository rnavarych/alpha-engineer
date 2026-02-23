# Database Access Patterns

## Connection Pooling

```typescript
// db.ts — singleton, created ONCE at startup
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                       // Rule: CPU cores x 2 + 1
  min: 2,                        // Keep minimum alive
  idleTimeoutMillis: 30_000,     // Close idle after 30s
  connectionTimeoutMillis: 5_000, // Fail fast if can't connect
  application_name: process.env.SERVICE_NAME,
});

export const db = drizzle(pool);

// Health check — verify pool connectivity
export async function healthCheck(): Promise<boolean> {
  try {
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    return true;
  } catch {
    return false;
  }
}
```

## Drizzle ORM

```typescript
import { eq, and, desc, sql } from 'drizzle-orm';
import { orders, orderItems } from './schema';

// Type-safe query with relations
async function getOrderWithItems(orderId: string) {
  return db.query.orders.findFirst({
    where: eq(orders.id, orderId),
    with: {
      items: { columns: { id: true, quantity: true, unitPrice: true } },
      user: { columns: { id: true, name: true, email: true } },
    },
  });
}

// Transaction — all or nothing
async function createOrder(input: CreateOrderInput) {
  return db.transaction(async (tx) => {
    const [order] = await tx.insert(orders).values({
      userId: input.userId,
      total: input.total,
    }).returning();

    await tx.insert(orderItems).values(
      input.items.map((item) => ({ orderId: order.id, ...item }))
    );

    return order;
  });
}

// Batch insert — single INSERT, not N separate ones
await db.insert(orderItems).values(items); // 1 query for N rows
```

## Prisma

```typescript
// Eager loading — prevents N+1
const orders = await prisma.order.findMany({
  where: { userId },
  include: {
    items: {
      include: { product: { select: { id: true, name: true } } },
    },
    _count: { select: { items: true } },
  },
  orderBy: { createdAt: 'desc' },
  take: 20,
  skip: (page - 1) * 20,
});

// Transaction with isolation
await prisma.$transaction(
  async (tx) => {
    const order = await tx.order.create({ data: orderData });
    await tx.orderItem.createMany({ data: items });
    return order;
  },
  { isolationLevel: 'Serializable', timeout: 5000 }
);
```

## Knex Query Builder

```typescript
import knex from 'knex';

const db = knex({
  client: 'pg',
  connection: process.env.DATABASE_URL,
  pool: { min: 2, max: 20 },
});

const orders = await db('orders')
  .join('users', 'orders.user_id', 'users.id')
  .where('orders.status', 'pending')
  .select('orders.*', 'users.name as user_name')
  .orderBy('orders.created_at', 'desc')
  .limit(50);
```

## Anti-Patterns
- Creating pool per request — exhausts DB connections in seconds under load
- Missing `idleTimeoutMillis` — zombie connections accumulate
- No transaction for multi-table writes — partial writes on failure
- `SELECT *` in production — fetches unnecessary columns, wastes bandwidth

## Quick Reference
```
Pool max: CPU cores x 2 + 1 (default 20)
Connection timeout: 5000ms — fail fast
Idle timeout: 30000ms — release unused
Drizzle: .with() for relations, .transaction() for atomicity
Prisma: include/select to prevent N+1
Batch: insertMany/createMany — never loop insert
Health check: pool.connect() + SELECT 1
```
