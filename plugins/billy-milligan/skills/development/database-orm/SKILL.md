---
name: database-orm
description: |
  ORM patterns: Drizzle schema + type-safe queries, Prisma with eager loading, N+1 detection
  and prevention, long transaction anti-pattern (no HTTP inside transactions), migration
  testing, transaction isolation levels, batch operations. Use when writing DB queries,
  reviewing ORM usage, optimizing data access.
allowed-tools: Read, Grep, Glob
---

# ORM & Database Patterns

## When to Use This Skill
- Writing Drizzle or Prisma queries
- Detecting and fixing N+1 query problems
- Managing transactions correctly
- Running and testing database migrations
- Optimizing slow queries

## Core Principles

1. **N+1 is the silent killer** — always eager-load when fetching related data
2. **No HTTP calls inside transactions** — transactions must be short-lived
3. **Migrations are code** — review them, test them, version them
4. **Select only needed columns** — `SELECT *` wastes bandwidth and memory
5. **Batch operations** — `insertMany` instead of N `insert` calls in a loop

---

## Patterns ✅

### Drizzle ORM Schema and Queries

```typescript
// schema.ts — schema is the source of truth for types
import { pgTable, uuid, text, numeric, integer, timestamp, pgEnum } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

export const orderStatus = pgEnum('order_status', ['pending', 'processing', 'completed', 'cancelled']);

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
});

export const orders = pgTable('orders', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  status: orderStatus('status').notNull().default('pending'),
  total: numeric('total', { precision: 10, scale: 2 }).notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
});

export const orderItems = pgTable('order_items', {
  id: uuid('id').primaryKey().defaultRandom(),
  orderId: uuid('order_id').notNull().references(() => orders.id),
  productId: uuid('product_id').notNull(),
  quantity: integer('quantity').notNull(),
  unitPrice: numeric('unit_price', { precision: 10, scale: 2 }).notNull(),
});

// Relations for eager loading
export const ordersRelations = relations(orders, ({ one, many }) => ({
  user: one(users, { fields: [orders.userId], references: [users.id] }),
  items: many(orderItems),
}));

// TypeScript type inferred from schema
type Order = typeof orders.$inferSelect;
type NewOrder = typeof orders.$inferInsert;
```

```typescript
// queries.ts — type-safe queries with relations
import { db } from './db';
import { orders, orderItems, users } from './schema';
import { eq, desc, and, gte, count } from 'drizzle-orm';

// Fetch order with all related data — ONE query, not N+1
async function getOrderWithDetails(orderId: string) {
  return db.query.orders.findFirst({
    where: eq(orders.id, orderId),
    with: {
      user: { columns: { id: true, name: true, email: true } },
      items: {
        columns: { id: true, quantity: true, unitPrice: true },
      },
    },
  });
}

// Batch insert
async function insertOrderItems(orderId: string, items: NewOrderItem[]) {
  if (items.length === 0) return;
  return db.insert(orderItems).values(
    items.map(item => ({ ...item, orderId }))
  );  // Single INSERT with multiple rows — not N separate INSERTs
}

// Transaction — all or nothing
async function createOrder(input: CreateOrderInput): Promise<Order> {
  return db.transaction(async (tx) => {
    const [order] = await tx.insert(orders).values({
      userId: input.userId,
      total: calculateTotal(input.items),
    }).returning();

    await tx.insert(orderItems).values(
      input.items.map(item => ({
        orderId: order.id,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.price,
      }))
    );

    // Decrement inventory — also in same transaction
    for (const item of input.items) {
      await tx.update(inventory)
        .set({ quantity: sql`quantity - ${item.quantity}` })
        .where(and(eq(inventory.productId, item.productId)));
    }

    return order;
    // No external API calls here! (see anti-patterns)
  });
}
```

### Prisma with Eager Loading

```typescript
// Prisma: always use include/select to avoid N+1
async function getOrders(userId: string, page: number) {
  return prisma.order.findMany({
    where: { userId },
    include: {
      items: {
        include: {
          product: { select: { id: true, name: true, imageUrl: true } }
        }
      },
      _count: { select: { items: true } },
    },
    orderBy: { createdAt: 'desc' },
    skip: (page - 1) * 20,
    take: 20,
  });
  // Generates: 1 query with JOINs — not 1 + N + N*M queries
}

// Use select to fetch only needed fields
async function getOrderSummaries(userId: string) {
  return prisma.order.findMany({
    where: { userId },
    select: {
      id: true,
      status: true,
      total: true,
      createdAt: true,
      _count: { select: { items: true } },
      // Don't include large nested objects when not needed
    },
  });
}
```

### N+1 Detection

```typescript
// N+1 pattern — DO NOT DO THIS
async function getOrdersWithUsersBad(orderIds: string[]) {
  const orders = await db.select().from(ordersTable).where(inArray(ordersTable.id, orderIds));
  // 1 query for orders

  const result = await Promise.all(
    orders.map(async (order) => {
      const user = await db.select().from(users).where(eq(users.id, order.userId)).limit(1);
      // N queries for users — 1 per order!
      return { ...order, user: user[0] };
    })
  );
  return result;
}

// Fixed: single query with JOIN
async function getOrdersWithUsersGood(orderIds: string[]) {
  return db
    .select({
      order: ordersTable,
      user: { id: users.id, name: users.name, email: users.email },
    })
    .from(ordersTable)
    .leftJoin(users, eq(ordersTable.userId, users.id))
    .where(inArray(ordersTable.id, orderIds));
  // 1 query regardless of N orders
}

// Or: batch load users separately (DataLoader pattern)
async function getOrdersWithUsersBatch(orderIds: string[]) {
  const orders = await db.select().from(ordersTable).where(inArray(ordersTable.id, orderIds));
  const userIds = [...new Set(orders.map(o => o.userId))];
  const usersMap = new Map(
    (await db.select().from(users).where(inArray(users.id, userIds)))
    .map(u => [u.id, u])
  );
  return orders.map(o => ({ ...o, user: usersMap.get(o.userId) }));
  // 2 queries total regardless of N
}
```

---

## Anti-Patterns ❌

### HTTP Calls Inside Transactions

```typescript
// Wrong — HTTP call inside transaction holds DB lock for 500ms+
async function createOrderBad(input: CreateOrderInput) {
  return db.transaction(async (tx) => {
    const order = await tx.insert(orders).values(input).returning();

    // NEVER: external HTTP call inside transaction
    const stripeCharge = await stripe.charges.create({
      amount: order.total,
      currency: 'usd',
    });  // Stripe API: 200-2000ms — DB lock held for entire duration!

    await tx.update(orders).set({ chargeId: stripeCharge.id }).where(eq(orders.id, order.id));
    return order;
  });
}

// Correct — HTTP calls outside transaction
async function createOrderGood(input: CreateOrderInput) {
  // Step 1: Create order (fast, in transaction)
  const order = await db.transaction(async (tx) => {
    return tx.insert(orders).values({ ...input, status: 'pending' }).returning().then(r => r[0]);
  });

  // Step 2: External call (outside transaction)
  const stripeCharge = await stripe.charges.create({ amount: order.total, currency: 'usd' });

  // Step 3: Update with result (separate transaction)
  await db.update(orders)
    .set({ chargeId: stripeCharge.id, status: 'paid' })
    .where(eq(orders.id, order.id));

  return order;
}
```

**Why it matters**: Transactions hold row locks. HTTP call inside = locks held for 200ms–2s. Under load, lock contention causes queries to queue → timeout cascade.

### SELECT * in Production Queries

```typescript
// Wrong — fetches all columns including large ones
const orders = await db.select().from(ordersTable);  // Includes 'notes' (TEXT, potentially large)

// Correct — only needed columns
const orders = await db.select({
  id: ordersTable.id,
  status: ordersTable.status,
  total: ordersTable.total,
  createdAt: ordersTable.createdAt,
}).from(ordersTable);
```

**Performance impact**: Table with 1MB average row × 1000 rows = 1GB over network. With column selection: 1KB average × 1000 = 1MB.

---

## Quick Reference

```
N+1 fix: eager load with include/with OR batch-load then Map
Transaction rule: no HTTP calls, no sleeps, no long computations inside
Transaction duration target: <100ms (ideally <10ms)
Batch insert: insertMany([...]) instead of N × insert()
SELECT: always specify columns in production code (never *)
Migration testing: run in a transaction, rollback to test idempotency
Prisma N+1: always use include/select, check generated SQL with logging
Drizzle: use .with() relation queries for joins
```
