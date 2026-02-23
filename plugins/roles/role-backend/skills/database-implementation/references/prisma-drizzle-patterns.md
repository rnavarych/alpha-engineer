# Prisma and Drizzle ORM Patterns

## When to load
Load when implementing the data layer with Prisma or Drizzle in a Node.js / TypeScript project. Covers schema definition, transactions, raw queries, client extensions, Accelerate, Pulse, and Drizzle Kit migrations.

## Prisma — Schema Definition and Relations

```prisma
generator client {
  provider = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "relationJoins"]
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL") // for Prisma Accelerate
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  tenantId  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  orders    Order[]
  profile   Profile?
  tenant    Tenant   @relation(fields: [tenantId], references: [id])

  @@index([tenantId, createdAt])
  @@map("users")
}

model Order {
  id     String      @id @default(cuid())
  userId String
  status OrderStatus @default(PENDING)
  total  Decimal     @db.Decimal(12, 2)
  user   User        @relation(fields: [userId], references: [id])
  items  OrderItem[]

  @@index([userId, status])
}

enum OrderStatus { PENDING CONFIRMED SHIPPED DELIVERED CANCELLED }
```

## Prisma — Transactions

```typescript
// Interactive transaction (preferred for dependent operations)
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email, name } })
  const account = await tx.account.create({ data: { userId: user.id, balance: 0 } })
  await tx.auditLog.create({ data: { action: 'USER_CREATED', targetId: user.id } })
  return { user, account }
}, { timeout: 10000, maxWait: 5000, isolationLevel: 'ReadCommitted' })
```

## Prisma — Raw Queries and Client Extensions

```typescript
// Raw query with tagged template (safe, parameterized)
const users = await prisma.$queryRaw<User[]>`
  SELECT * FROM users
  WHERE tenant_id = ${tenantId}
  AND created_at > ${startDate}
  ORDER BY created_at DESC
  LIMIT ${limit}
`

// Client extensions for reusable logic
const xprisma = prisma.$extends({
  model: {
    user: {
      async findByEmail(email: string) {
        return prisma.user.findUnique({ where: { email: email.toLowerCase() } })
      },
    },
  },
  query: {
    // Soft delete: filter out deleted records automatically
    $allModels: {
      async findMany({ model, operation, args, query }) {
        if ('deletedAt' in prisma[model].fields) {
          args.where = { ...args.where, deletedAt: null }
        }
        return query(args)
      },
    },
  },
})
```

## Prisma Accelerate (Connection Pooling + Edge Cache)

```typescript
import { PrismaClient } from '@prisma/client/edge'
import { withAccelerate } from '@prisma/extension-accelerate'

const prisma = new PrismaClient().$extends(withAccelerate())

// Cache query results at the edge
const users = await prisma.user.findMany({
  cacheStrategy: { ttl: 60, swr: 300 }, // 60s TTL, 300s stale-while-revalidate
})
```

## Prisma Pulse (Real-time Change Streams)

```typescript
import { withPulse } from '@prisma/extension-pulse'
const prisma = new PrismaClient().$extends(withPulse({ apiKey: process.env.PULSE_API_KEY }))

const subscription = await prisma.order.subscribe({
  create: { after: { status: 'CONFIRMED' } },
})
for await (const event of subscription) {
  await notificationService.sendOrderConfirmation(event.created)
}
```

## Drizzle ORM — Schema Definition

```typescript
import { pgTable, text, timestamp, decimal, uuid, index, pgEnum } from 'drizzle-orm/pg-core'
import { relations } from 'drizzle-orm'

export const orderStatusEnum = pgEnum('order_status', ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'])

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => ({
  tenantCreatedIdx: index('users_tenant_created_idx').on(table.tenantId, table.createdAt),
}))

export const usersRelations = relations(users, ({ many, one }) => ({
  orders: many(orders),
  tenant: one(tenants, { fields: [users.tenantId], references: [tenants.id] }),
}))
```

## Drizzle ORM — Queries and Transactions

```typescript
import { drizzle } from 'drizzle-orm/postgres-js'
import { eq, and, desc } from 'drizzle-orm'

const db = drizzle(sql, { schema })

// Type-safe query with relations
const user = await db.query.users.findFirst({
  where: eq(users.email, email),
  with: { orders: { orderBy: [desc(orders.createdAt)], limit: 10 } },
})

// Transaction
await db.transaction(async (tx) => {
  const [user] = await tx.insert(users).values({ email, name }).returning()
  await tx.insert(accounts).values({ userId: user.id, balance: '0' })
})
```

## Drizzle Kit Migrations

```bash
# Generate migration from schema changes
npx drizzle-kit generate --dialect=postgresql --schema=./src/schema.ts --out=./drizzle

# Apply migrations
npx drizzle-kit migrate

# Open Drizzle Studio (GUI)
npx drizzle-kit studio
```
