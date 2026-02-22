---
name: database-implementation
description: Implements database layers using Prisma, Drizzle ORM, TypeORM, SQLAlchemy 2.0, GORM, Diesel, Entity Framework Core 8, Hibernate/Panache, ActiveRecord, Ecto, Sequelize, Kysely, and Knex. Covers migrations, connection pooling, read replicas, query optimization, transaction management, and database testing with Testcontainers and factories. Use when setting up database access, writing migrations, optimizing queries, or configuring connection pools.
allowed-tools: Read, Grep, Glob, Bash
---

You are a database implementation specialist. You build robust, performant data access layers.

## ORM Selection

### Node.js / TypeScript

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Prisma | Type-safe generated client, declarative schema, Prisma Studio, Accelerate, Pulse | New projects, teams prioritizing DX |
| Drizzle ORM | SQL-like syntax, lightweight, Drizzle Kit migrations, Drizzle Studio | SQL-fluent teams, edge runtimes |
| TypeORM | Decorator entities, Active Record + Data Mapper, mature | Legacy TS projects, NestJS |
| Kysely | Fully type-safe query builder, no ORM magic, composable | Complex queries, migration from raw SQL |
| Knex.js | Query builder + migration runner, database-agnostic | Mixed teams, existing Knex projects |
| Sequelize v7 | Promise-based, associations, hooks | Existing Sequelize codebases |

### Python

| ORM | Strengths | Best For |
|-----|-----------|----------|
| SQLAlchemy 2.0 | Most powerful Python ORM, async, typed, Alembic migrations | Any Python backend |
| Django ORM | Tightly integrated with Django, admin, migrations | Django projects |
| Tortoise ORM | Async-first, familiar Django-style API | FastAPI async projects |
| Peewee | Lightweight, simple API | Small scripts, SQLite |

### Go

| ORM | Strengths | Best For |
|-----|-----------|----------|
| GORM | Most popular Go ORM, hooks, associations, Gen | Standard Go apps |
| sqlx | Thin extension of `database/sql`, struct scanning | SQL-first Go teams |
| sqlc | Generates type-safe Go code from SQL queries | Compile-time SQL safety |
| Ent | Graph-based entity framework, code generation | Complex graph data models |
| Bun | Fast SQL-first ORM, Postgres/MySQL/SQLite | High-performance Go APIs |

### Rust

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Diesel | Compile-time query checking, no runtime errors | Safety-critical Rust services |
| SQLx | Async, compile-time checked queries (macros), no ORM | Rust async services |
| SeaORM | Async, ActiveRecord-style, built on SQLx | Actix/Axum web apps |

### JVM

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Hibernate 6 / JPA | Enterprise standard, caching, criteria API | Spring Boot, Jakarta EE |
| Panache (Quarkus) | Active record: `User.find("email", email)`, simplified API | Quarkus services |
| Spring Data JPA | Repository pattern with derived queries | Spring Boot projects |
| JOOQ | Type-safe SQL DSL generated from schema | SQL-heavy Java apps |
| Exposed (Kotlin) | Type-safe DSL and DAO pattern for Kotlin | Kotlin backend services |

### Ruby

| ORM | Strengths | Best For |
|-----|-----------|----------|
| ActiveRecord 7 | Rails integration, associations, callbacks, migrations | Rails apps |
| Sequel | Flexible DSL, plugins, thread-safe | Non-Rails Ruby apps |
| ROM (Ruby Object Mapper) | Functional, immutable, dry-rb ecosystem | Hanami apps |

### Elixir

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Ecto | Changesets for validation, composable queries, multi-tenancy | All Phoenix/Elixir apps |

### .NET

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Entity Framework Core 8 | LINQ queries, migrations, interceptors, compiled queries | .NET apps |
| Dapper | Micro-ORM, raw SQL with object mapping | Performance-critical .NET |
| NHibernate | Full-featured, mature, enterprise | Legacy .NET apps |

## Prisma Advanced Patterns

### Schema Definition and Relations

```prisma
generator client {
  provider = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "relationJoins"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
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
  id        String      @id @default(cuid())
  userId    String
  status    OrderStatus @default(PENDING)
  total     Decimal     @db.Decimal(12, 2)
  user      User        @relation(fields: [userId], references: [id])
  items     OrderItem[]

  @@index([userId, status])
}

enum OrderStatus { PENDING CONFIRMED SHIPPED DELIVERED CANCELLED }
```

### Transactions and Interactive Transactions

```typescript
// $transaction for sequential operations (atomic)
const [user, _account] = await prisma.$transaction([
  prisma.user.create({ data: { email, name } }),
  prisma.account.create({ data: { userId: user.id, balance: 0 } }), // ❌ user.id not available
])

// Interactive transaction (preferred for dependent operations)
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email, name } })
  const account = await tx.account.create({ data: { userId: user.id, balance: 0 } })
  await tx.auditLog.create({ data: { action: 'USER_CREATED', targetId: user.id } })
  return { user, account }
}, { timeout: 10000, maxWait: 5000, isolationLevel: 'ReadCommitted' })
```

### Raw Queries and Client Extensions

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

### Prisma Accelerate (Connection Pooling + Edge Cache)

```typescript
import { PrismaClient } from '@prisma/client/edge'
import { withAccelerate } from '@prisma/extension-accelerate'

const prisma = new PrismaClient().$extends(withAccelerate())

// Cache query results at the edge
const users = await prisma.user.findMany({
  cacheStrategy: { ttl: 60, swr: 300 }, // 60s TTL, 300s stale-while-revalidate
})
```

### Prisma Pulse (Real-time Change Streams)

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

## Drizzle ORM Patterns

### Schema Definition

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

### Queries and Transactions

```typescript
import { drizzle } from 'drizzle-orm/postgres-js'
import { eq, and, desc, sql } from 'drizzle-orm'

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

### Drizzle Kit Migrations

```bash
# Generate migration from schema changes
npx drizzle-kit generate --dialect=postgresql --schema=./src/schema.ts --out=./drizzle

# Apply migrations
npx drizzle-kit migrate

# Open Drizzle Studio (GUI)
npx drizzle-kit studio
```

## SQLAlchemy 2.0 (Python)

### Async Setup with Alembic

```python
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy import String, Numeric, ForeignKey, Index
from datetime import datetime
import uuid

engine = create_async_engine(settings.DATABASE_URL, pool_size=20, max_overflow=10, pool_pre_ping=True)
async_session = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"
    __table_args__ = (Index("ix_users_tenant_created", "tenant_id", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    tenant_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tenants.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    orders: Mapped[list["Order"]] = relationship(back_populates="user", lazy="selectin")

# Async query
async def get_user_with_orders(session: AsyncSession, user_id: uuid.UUID) -> User | None:
    result = await session.execute(
        select(User).options(selectinload(User.orders)).where(User.id == user_id)
    )
    return result.scalar_one_or_none()

# Transaction
async def transfer_funds(session: AsyncSession, from_id: uuid.UUID, to_id: uuid.UUID, amount: Decimal):
    async with session.begin():
        from_acc = await session.get(Account, from_id, with_for_update=True)
        to_acc = await session.get(Account, to_id, with_for_update=True)
        if from_acc.balance < amount:
            raise InsufficientFundsError()
        from_acc.balance -= amount
        to_acc.balance += amount
```

### Alembic Migration

```python
# alembic/env.py - async setup
from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine

async def run_migrations_online():
    engine = create_async_engine(config.get_main_option("sqlalchemy.url"))
    async with engine.begin() as conn:
        await conn.run_sync(do_run_migrations)
```

## GORM (Go)

### Model Definition with Hooks

```go
type User struct {
    gorm.Model                              // ID, CreatedAt, UpdatedAt, DeletedAt (soft delete)
    Email    string    `gorm:"uniqueIndex;size:255;not null"`
    Name     string    `gorm:"size:100;not null"`
    TenantID uuid.UUID `gorm:"index;not null"`
    Orders   []Order   `gorm:"foreignKey:UserID"`
}

// Hooks
func (u *User) BeforeCreate(tx *gorm.DB) error {
    u.Email = strings.ToLower(strings.TrimSpace(u.Email))
    return nil
}

func (u *User) AfterCreate(tx *gorm.DB) error {
    return tx.Create(&AuditLog{Action: "user.created", TargetID: u.ID.String()}).Error
}

// Associations
db.Preload("Orders", "status = ?", "confirmed").Find(&users)
db.Joins("JOIN orders ON orders.user_id = users.id").Where("orders.total > ?", 1000).Find(&users)

// Transaction
err := db.Transaction(func(tx *gorm.DB) error {
    if err := tx.Create(&user).Error; err != nil { return err }
    if err := tx.Create(&account).Error; err != nil { return err }
    return nil
})
```

### GORM Gen (Type-Safe Query Generation)

```go
// gen.go - run once to generate type-safe query methods
g := gen.NewGenerator(gen.Config{OutPath: "./query", Mode: gen.WithDefaultQuery})
g.UseDB(db)
g.ApplyBasic(model.User{}, model.Order{})
g.Execute()

// Generated usage
user, err := query.User.Where(query.User.Email.Eq(email)).First()
orders, err := query.Order.Where(query.Order.UserID.Eq(userID), query.Order.Status.Eq("confirmed")).Find()
```

## Diesel (Rust)

```rust
// schema.rs (generated by diesel print-schema)
table! {
    users (id) {
        id -> Uuid,
        email -> Varchar,
        name -> Varchar,
        tenant_id -> Uuid,
        created_at -> Timestamptz,
    }
}

// models.rs
#[derive(Queryable, Selectable, Identifiable)]
#[diesel(table_name = users)]
pub struct User { pub id: Uuid, pub email: String, pub name: String }

#[derive(Insertable)]
#[diesel(table_name = users)]
pub struct NewUser<'a> { pub email: &'a str, pub name: &'a str }

// Compile-time checked query - wrong column name = compile error
let user = users::table
    .filter(users::email.eq(&email))
    .select(User::as_select())
    .first(&mut conn)?;

// Transaction
conn.transaction::<_, diesel::result::Error, _>(|conn| {
    diesel::insert_into(users::table).values(&new_user).execute(conn)?;
    diesel::insert_into(accounts::table).values(&new_account).execute(conn)?;
    Ok(())
})?;
```

## Entity Framework Core 8 (.NET)

### Model and DbContext with Interceptors

```csharp
public class User {
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Email { get; set; }
    public required string Name { get; set; }
    public Guid TenantId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<Order> Orders { get; set; } = [];
}

public class AppDbContext(DbContextOptions<AppDbContext> options, ICurrentUser currentUser)
    : DbContext(options) {

    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder b) {
        b.Entity<User>(e => {
            e.HasIndex(u => u.Email).IsUnique();
            e.HasIndex(u => new { u.TenantId, u.CreatedAt });
            // Global query filter for multi-tenancy
            e.HasQueryFilter(u => u.TenantId == currentUser.TenantId);
        });
    }

    // Compiled query for hot paths
    private static readonly Func<AppDbContext, Guid, Task<User?>> GetUserByIdQuery =
        EF.CompileAsyncQuery((AppDbContext ctx, Guid id) =>
            ctx.Users.FirstOrDefault(u => u.Id == id));

    public Task<User?> GetUserByIdAsync(Guid id) => GetUserByIdQuery(this, id);
}

// Value converter example
b.Entity<Money>().Property(m => m.Amount)
    .HasConversion(v => v.Amount, v => new Money(v, Currency.USD));
```

### Interceptors

```csharp
public class AuditInterceptor : SaveChangesInterceptor {
    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData, InterceptionResult<int> result, CancellationToken ct) {
        var entries = eventData.Context!.ChangeTracker.Entries<IAuditable>()
            .Where(e => e.State is EntityState.Added or EntityState.Modified);
        foreach (var entry in entries)
            entry.Entity.UpdatedAt = DateTime.UtcNow;
        return base.SavingChangesAsync(eventData, result, ct);
    }
}
```

## Ecto (Elixir)

### Changesets and Multi-Tenancy

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    belongs_to :tenant, MyApp.Tenants.Tenant
    has_many :orders, MyApp.Orders.Order
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :password])
    |> validate_required([:email, :name, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 12)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%{valid?: true, changes: %{password: pw}} = changeset) do
    change(changeset, password_hash: Argon2.hash_pwd_salt(pw))
  end
  defp put_password_hash(changeset), do: changeset
end

# Multi-tenancy via query prefix (schema-per-tenant)
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres

  def with_tenant(tenant_id) do
    put_dynamic_repo(:"repo_#{tenant_id}")
  end
end

# Ecto.Multi for transactions
Multi.new()
|> Multi.insert(:user, User.changeset(%User{}, attrs))
|> Multi.insert(:account, fn %{user: user} -> Account.changeset(%Account{}, %{user_id: user.id}) end)
|> Multi.run(:send_welcome, fn _repo, %{user: user} -> Mailer.send_welcome(user) end)
|> Repo.transaction()
```

## Exposed (Kotlin)

```kotlin
object Users : UUIDTable("users") {
    val email = varchar("email", 255).uniqueIndex()
    val name = varchar("name", 100)
    val tenantId = uuid("tenant_id").references(Tenants.id)
    val createdAt = datetime("created_at").defaultExpression(CurrentDateTime)
}

class User(id: EntityID<UUID>) : UUIDEntity(id) {
    companion object : UUIDEntityClass<User>(Users)
    var email by Users.email
    var name by Users.name
    val orders by Order referrersOn Orders.userId
}

// DSL query
val users = transaction {
    Users.select { Users.tenantId eq tenantId }
        .orderBy(Users.createdAt to SortOrder.DESC)
        .limit(20)
        .map { User.wrapRow(it) }
}

// Transaction
transaction {
    val user = User.new { email = "user@example.com"; name = "Alice" }
    Account.new { userId = user.id; balance = BigDecimal.ZERO }
}
```

## Migration Best Practices

- Every schema change requires a migration file (never alter production manually)
- Migrations must be idempotent and reversible (up and down)
- Name migrations descriptively: `20240115_add_email_verification_to_users`
- Test migrations against a copy of production data before deploying
- Never modify a migration that has been applied to any shared environment
- Use separate migration for data backfills (not in schema migration)
- Run migrations in a transaction when the database supports transactional DDL
- Zero-downtime migration patterns: add column nullable → backfill → add NOT NULL constraint → remove old column

## Connection Pooling

- Always use connection pooling (never open/close connections per request)
- **Node.js Prisma**: `connection_limit` in connection string; use Prisma Accelerate for serverless
- **Node.js Drizzle**: `postgres-js` with `max` connections or `pg-pool`
- **Python SQLAlchemy**: `pool_size=20, max_overflow=10, pool_recycle=3600, pool_pre_ping=True`
- **Go GORM / sqlx**: `db.SetMaxOpenConns(25); db.SetMaxIdleConns(10); db.SetConnMaxLifetime(5 * time.Minute)`
- **Java HikariCP**: `maximumPoolSize=10, minimumIdle=5, connectionTimeout=30000, idleTimeout=600000`
- **Rust SQLx**: `PgPoolOptions::new().max_connections(20).connect(url).await`
- Set pool size based on: `(core_count * 2) + effective_spindle_count`
- Monitor pool utilization; alert when waiting connections exceed threshold

## Read Replicas

- Route read queries to replicas, write queries to the primary
- Handle replication lag: use primary for reads-after-writes when consistency matters
- Prisma: `datasources` with `readReplicas` extension
- SQLAlchemy: `engines` dict with `execution_options(postgresql_readonly=True)`
- GORM: `plugin/dbresolver` with `Replica()` and `Sources()`
- Spring: `AbstractRoutingDataSource` for read/write splitting

## Query Optimization

- Profile all queries with `EXPLAIN ANALYZE` before and after optimization
- Avoid N+1 queries: use eager loading (`include` in Prisma, `selectinload` in SQLAlchemy, `Preload` in GORM)
- Add indexes for columns in WHERE, JOIN, ORDER BY, and GROUP BY clauses
- Use composite indexes for multi-column filter patterns (leftmost prefix rule)
- Prefer `EXISTS` over `IN` for subqueries with large result sets
- Use cursor-based pagination over offset pagination for large datasets
- Monitor slow query logs and set up alerts for queries exceeding thresholds
- Use `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` in Postgres for full execution plan analysis

## Database Testing

### Testcontainers

```typescript
// Node.js with Testcontainers
import { PostgreSqlContainer } from '@testcontainers/postgresql'

let container: StartedPostgreSqlContainer

beforeAll(async () => {
  container = await new PostgreSqlContainer('postgres:16-alpine').start()
  process.env.DATABASE_URL = container.getConnectionUri()
  await migrate(process.env.DATABASE_URL) // run actual migrations
})

afterAll(() => container.stop())

// Each test in a transaction that rolls back
beforeEach(() => db.$executeRaw`BEGIN`)
afterEach(() => db.$executeRaw`ROLLBACK`)
```

```python
# Python with Testcontainers
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16") as pg:
        run_migrations(pg.get_connection_url())
        yield pg

@pytest.fixture
async def session(postgres):
    async with async_session() as s:
        async with s.begin():
            yield s
            await s.rollback()
```

```go
// Go with Testcontainers
func TestMain(m *testing.M) {
    ctx := context.Background()
    req := testcontainers.ContainerRequest{
        Image: "postgres:16-alpine",
        Env: map[string]string{"POSTGRES_PASSWORD": "test"},
        ExposedPorts: []string{"5432/tcp"},
        WaitingFor: wait.ForListeningPort("5432/tcp"),
    }
    pg, _ := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req, Started: true,
    })
    // run migrations, set DSN, run tests
    os.Exit(m.Run())
}
```

### Database Factories

```typescript
// TypeScript with fishery + faker
import { Factory } from 'fishery'
import { faker } from '@faker-js/faker'

const userFactory = Factory.define<User>(({ sequence }) => ({
  id: faker.string.uuid(),
  email: faker.internet.email(),
  name: faker.person.fullName(),
  tenantId: faker.string.uuid(),
  createdAt: new Date(),
}))

// Usage
const user = userFactory.build({ email: 'specific@example.com' })
const users = userFactory.buildList(10)
const dbUser = await userFactory.create({}, { transientParams: { db } })
```

```python
# Python with factory_boy
import factory
from factory.alchemy import SQLAlchemyModelFactory

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session = db_session

    id = factory.LazyFunction(uuid.uuid4)
    email = factory.Faker('email')
    name = factory.Faker('name')
    tenant_id = factory.LazyFunction(uuid.uuid4)
```

### pg_tmp (Fast Postgres Test Databases)

```bash
# pg_tmp creates a temporary Postgres instance per test suite
# much faster than Testcontainers for local development
eval $(pg_tmp)
createdb myapp_test
DATABASE_URL="$PGURL/myapp_test" go test ./...
```

## Transaction Management

- Use explicit transaction boundaries for multi-step mutations
- Keep transactions short to avoid lock contention
- Handle deadlocks with retry logic (limited retries with backoff)
- Use `READ COMMITTED` isolation level (usually sufficient); use `SERIALIZABLE` for financial operations
- Implement the Unit of Work pattern for complex business operations
- Release connections back to the pool promptly after transaction completion
- Avoid long-running transactions that hold locks across user interactions

## Seeding

- Maintain seed scripts for development and testing environments
- Use factories/fixtures for test data generation
- Never seed production databases with test data
- Make seeds idempotent (safe to run multiple times): use upserts
- Separate reference data seeds (countries, currencies, roles) from test data seeds
- Order seeds to respect foreign key constraints
