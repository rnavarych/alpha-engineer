---
name: database-implementation
description: Implements database layers using Prisma, Drizzle ORM, TypeORM, SQLAlchemy 2.0, GORM, Diesel, Entity Framework Core 8, Hibernate/Panache, ActiveRecord, Ecto, Sequelize, Kysely, and Knex. Covers migrations, connection pooling, read replicas, query optimization, transaction management, and database testing with Testcontainers and factories. Use when setting up database access, writing migrations, optimizing queries, or configuring connection pools.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Implementation

## When to use
- Setting up a new data access layer and choosing an ORM or query builder
- Writing migrations for schema changes
- Implementing transactions across multiple tables or services
- Configuring connection pooling for production
- Adding read replica routing for query scaling
- Optimizing slow queries (N+1, missing indexes, full scans)
- Writing database integration tests with Testcontainers
- Setting up factories or seed data

## Core principles
1. **ORM is a tool, SQL is the truth** — know what queries your ORM generates; use EXPLAIN ANALYZE
2. **Migrations are immutable contracts** — never modify a migration applied to any shared environment
3. **Pooling is not optional** — one connection per request = death in production
4. **Transactions stay short** — locks held across network calls cause cascading timeouts
5. **Test against the real database** — in-memory SQLite mocks hide Postgres-specific bugs

## Reference Files

- `references/orm-selection.md` — comparison tables for all ORMs and query builders across Node.js, Python, Go, Rust, JVM, Ruby, Elixir, and .NET; pick before writing any data layer code
- `references/prisma-drizzle-patterns.md` — Prisma schema definition, interactive transactions, raw queries, client extensions, Accelerate caching, Pulse change streams; Drizzle schema, relations, queries, and Kit migrations
- `references/polyglot-orm-patterns.md` — production patterns for SQLAlchemy 2.0 async, GORM with hooks and Gen, Diesel compile-time queries, EF Core 8 with interceptors, Ecto changesets and Multi, and Exposed DSL
- `references/migrations-pooling-replicas.md` — migration rules (zero-downtime patterns, idempotency), connection pool sizing per stack, read replica routing, query optimization checklist, and transaction isolation guidelines
- `references/testing-seeding.md` — Testcontainers setup for Node.js/Python/Go, pg_tmp for fast local tests, fishery/factory_boy database factories, and seed script best practices
