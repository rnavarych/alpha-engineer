# Prisma Patterns

## Schema Definition

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum OrderStatus {
  PENDING
  PROCESSING
  COMPLETED
  CANCELLED
}

model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String
  orders    Order[]
  createdAt DateTime @default(now()) @map("created_at")

  @@map("users")
}

model Order {
  id        String      @id @default(uuid())
  user      User        @relation(fields: [userId], references: [id])
  userId    String      @map("user_id")
  status    OrderStatus @default(PENDING)
  total     Decimal     @db.Decimal(10, 2)
  items     OrderItem[]
  createdAt DateTime    @default(now()) @map("created_at")

  @@index([userId, createdAt(sort: Desc)])
  @@index([status, createdAt(sort: Desc)])
  @@map("orders")
}

model OrderItem {
  id        String  @id @default(uuid())
  order     Order   @relation(fields: [orderId], references: [id], onDelete: Cascade)
  orderId   String  @map("order_id")
  productId String  @map("product_id")
  quantity  Int
  unitPrice Decimal @db.Decimal(10, 2) @map("unit_price")

  @@map("order_items")
}
```

## Client Generation and Setup

```bash
# Generate Prisma Client (run after schema changes)
npx prisma generate

# Create and apply migration
npx prisma migrate dev --name add_orders

# Apply migrations in production
npx prisma migrate deploy

# Open Prisma Studio
npx prisma studio
```

```typescript
// db.ts — singleton client
import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development'
    ? ['query', 'error', 'warn']
    : ['error'],
});

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
// Prevents multiple instances in Next.js dev (hot reload)
```

## Middleware (Soft Delete, Logging)

```typescript
// Soft delete middleware — intercept delete, convert to update
prisma.$use(async (params, next) => {
  if (params.action === 'delete' && params.model === 'Order') {
    params.action = 'update';
    params.args.data = { deletedAt: new Date() };
  }
  if (params.action === 'findMany' && params.model === 'Order') {
    params.args.where = { ...params.args.where, deletedAt: null };
  }
  return next(params);
});
```

## Anti-Patterns
- Multiple Prisma Client instances — use singleton pattern
- Missing `include`/`select` — default fetches only scalar fields, then N+1 for relations
- `$transaction` with external API calls — holds DB lock for duration
- Not running `prisma generate` after schema changes — types are stale

## Quick Reference
```
Schema: model + @relation + @@index + @@map
Client: singleton, log queries in dev
Migrate: dev (create + apply), deploy (apply only)
Generate: npx prisma generate — after every schema change
Middleware: $use() — soft delete, audit logs, multi-tenant filters
```

## When to load
Load when designing a Prisma schema, setting up the client singleton, configuring middleware for soft delete or audit logging, or running migrations.
