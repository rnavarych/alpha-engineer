# Prisma Performance

## Preventing N+1

```typescript
// GOOD — include for eager loading (single query with JOINs)
const orders = await prisma.order.findMany({
  where: { userId },
  include: {
    items: {
      include: {
        product: { select: { id: true, name: true, imageUrl: true } },
      },
    },
    _count: { select: { items: true } },
  },
  orderBy: { createdAt: 'desc' },
  take: 20,
  skip: (page - 1) * 20,
});

// GOOD — select for partial fields (smaller payload)
const summaries = await prisma.order.findMany({
  where: { userId },
  select: {
    id: true,
    status: true,
    total: true,
    createdAt: true,
    _count: { select: { items: true } },
  },
});

// BAD — N+1 pattern
const orders = await prisma.order.findMany({ where: { userId } });
for (const order of orders) {
  const items = await prisma.orderItem.findMany({ where: { orderId: order.id } });
  // 1 + N queries!
}
```

## Transactions

```typescript
// Interactive transaction — multiple operations, rollback on error
const order = await prisma.$transaction(async (tx) => {
  const order = await tx.order.create({
    data: {
      userId: input.userId,
      total: input.total,
      items: {
        createMany: {
          data: input.items.map((item) => ({
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.price,
          })),
        },
      },
    },
    include: { items: true },
  });

  // Decrement inventory within same transaction
  for (const item of input.items) {
    await tx.product.update({
      where: { id: item.productId },
      data: { stock: { decrement: item.quantity } },
    });
  }

  return order;
}, {
  timeout: 5000,                          // 5s timeout
  isolationLevel: 'Serializable',         // Strongest isolation
});

// Batch transaction — all or nothing, single round trip
const [order, updatedUser] = await prisma.$transaction([
  prisma.order.create({ data: orderData }),
  prisma.user.update({ where: { id: userId }, data: { orderCount: { increment: 1 } } }),
]);
```

## Raw Queries

```typescript
// Type-safe raw queries with Prisma.sql
const orders = await prisma.$queryRaw<Order[]>`
  SELECT o.id, o.status, o.total, u.name as user_name
  FROM orders o
  JOIN users u ON u.id = o.user_id
  WHERE o.status = ${status}
    AND o.created_at > ${startDate}
  ORDER BY o.created_at DESC
  LIMIT ${limit}
`;

// Raw execute for DDL or complex updates
await prisma.$executeRaw`
  UPDATE orders
  SET status = 'cancelled'
  WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '7 days'
`;
```

## Query Logging and Analysis

```typescript
// Enable query logging to find slow queries in dev
const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
    { level: 'error', emit: 'stdout' },
  ],
});

prisma.$on('query', (e) => {
  if (e.duration > 100) {
    logger.warn({
      query: e.query,
      params: e.params,
      duration: e.duration,
    }, 'Slow Prisma query');
  }
});

// findRaw for complex aggregations (MongoDB)
// For PostgreSQL: prefer $queryRaw for complex window functions,
// CTEs, and queries that Prisma's query builder can't express
const ranked = await prisma.$queryRaw`
  WITH ranked AS (
    SELECT
      user_id,
      SUM(total) as total_spend,
      RANK() OVER (ORDER BY SUM(total) DESC) as rank
    FROM orders
    WHERE created_at > NOW() - INTERVAL '30 days'
    GROUP BY user_id
  )
  SELECT * FROM ranked WHERE rank <= 10
`;
```

## Anti-Patterns
- `findMany` without `select` on tables with wide rows — fetches unused columns
- Nested `include` more than 3 levels deep — generates complex JOINs, often slower than two separate queries
- `$transaction` containing HTTP calls or long computations — holds connection lock
- Using `count()` in a loop — use `_count` in select instead
- Skipping `take`/`limit` on list queries — full table scan returned to application

## Quick Reference
```
Include: eager load relations — prevents N+1
Select: fetch only needed fields — smaller payload
Transaction: $transaction(async (tx) => { ... }) for multi-step
Batch: $transaction([...]) for independent operations, single round trip
Raw: $queryRaw`...` with template literals — SQL injection safe
Slow query log: $on('query') + duration threshold in dev
_count: aggregate count inside select — one query not two
```

## When to load
Load when fixing N+1 query problems, writing multi-step transactions, using raw SQL with Prisma, or diagnosing slow Prisma queries with query logging.
