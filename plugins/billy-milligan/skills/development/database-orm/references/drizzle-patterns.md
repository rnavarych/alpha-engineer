# Drizzle Patterns

## Schema Definition

```typescript
import { pgTable, uuid, text, numeric, integer, timestamp, pgEnum } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

export const orderStatus = pgEnum('order_status', [
  'pending', 'processing', 'completed', 'cancelled',
]);

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
  orderId: uuid('order_id').notNull().references(() => orders.id, { onDelete: 'cascade' }),
  productId: uuid('product_id').notNull(),
  quantity: integer('quantity').notNull(),
  unitPrice: numeric('unit_price', { precision: 10, scale: 2 }).notNull(),
});

// Relations for eager loading via .with()
export const ordersRelations = relations(orders, ({ one, many }) => ({
  user: one(users, { fields: [orders.userId], references: [users.id] }),
  items: many(orderItems),
}));

export const orderItemsRelations = relations(orderItems, ({ one }) => ({
  order: one(orders, { fields: [orderItems.orderId], references: [orders.id] }),
}));

// Inferred types from schema
type Order = typeof orders.$inferSelect;
type NewOrder = typeof orders.$inferInsert;
```

## Queries with Relations

```typescript
import { eq, desc, and, gte, sql, inArray } from 'drizzle-orm';

// Fetch with eager-loaded relations — single optimized query
async function getOrderWithDetails(orderId: string) {
  return db.query.orders.findFirst({
    where: eq(orders.id, orderId),
    with: {
      user: { columns: { id: true, name: true, email: true } },
      items: { columns: { id: true, quantity: true, unitPrice: true } },
    },
  });
}

// Filtered list with pagination
async function listOrders(filters: { userId?: string; status?: string; page: number }) {
  const conditions = [];
  if (filters.userId) conditions.push(eq(orders.userId, filters.userId));
  if (filters.status) conditions.push(eq(orders.status, filters.status));

  return db.query.orders.findMany({
    where: conditions.length ? and(...conditions) : undefined,
    with: { items: true },
    orderBy: [desc(orders.createdAt)],
    limit: 20,
    offset: (filters.page - 1) * 20,
  });
}

// Aggregate query
async function getOrderStats(userId: string) {
  const [result] = await db
    .select({
      totalOrders: sql<number>`count(*)`,
      totalRevenue: sql<number>`sum(${orders.total})`,
      avgOrder: sql<number>`avg(${orders.total})`,
    })
    .from(orders)
    .where(eq(orders.userId, userId));
  return result;
}
```

## Transactions

```typescript
async function createOrder(input: CreateOrderInput): Promise<Order> {
  return db.transaction(async (tx) => {
    const [order] = await tx.insert(orders).values({
      userId: input.userId,
      total: calculateTotal(input.items),
    }).returning();

    // Batch insert — single INSERT for all items
    await tx.insert(orderItems).values(
      input.items.map((item) => ({
        orderId: order.id,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.price,
      }))
    );

    return order;
    // NO external API calls here — keep transactions short
  });
}
```

## Prepared Statements

```typescript
// Prepared statement — parsed once, executed many times
const getOrderById = db.query.orders
  .findFirst({
    where: eq(orders.id, sql.placeholder('id')),
    with: { items: true },
  })
  .prepare('get_order_by_id');

// Execute with parameter
const order = await getOrderById.execute({ id: orderId });
// ~20% faster for repeated queries — skips query planning
```

## Migrations

```bash
# Generate migration from schema diff
npx drizzle-kit generate

# Push schema directly (dev only — no migration file)
npx drizzle-kit push

# Apply migrations
npx drizzle-kit migrate

# Open Drizzle Studio (visual DB browser)
npx drizzle-kit studio
```

```typescript
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

## Anti-Patterns
- Fetching relations in a loop — use `.with()` for eager loading
- `INSERT` in a loop — use batch `.values([...])` for multiple rows
- External API calls inside `db.transaction()` — holds locks
- Missing `returning()` on insert/update — requires extra SELECT

## Quick Reference
```
Schema: pgTable + relations() — types inferred automatically
Relations: .with() for eager loading (prevents N+1)
Filters: eq, and, gte, sql — composable conditions
Batch insert: .values([...]) — single INSERT for N rows
Transaction: db.transaction(async (tx) => { ... })
Prepared: .prepare('name') — 20% faster for repeated queries
Migrations: drizzle-kit generate / push / migrate
Types: $inferSelect (read), $inferInsert (write)
```
