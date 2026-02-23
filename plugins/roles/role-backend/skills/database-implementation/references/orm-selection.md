# ORM and Query Builder Selection

## When to load
Load when choosing a database access library for any language. Covers Node.js, Python, Go, Rust, JVM, Ruby, Elixir, and .NET with strengths and best-fit guidance.

## Node.js / TypeScript

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Prisma | Type-safe generated client, declarative schema, Prisma Studio, Accelerate, Pulse | New projects, teams prioritizing DX |
| Drizzle ORM | SQL-like syntax, lightweight, Drizzle Kit migrations, Drizzle Studio | SQL-fluent teams, edge runtimes |
| TypeORM | Decorator entities, Active Record + Data Mapper, mature | Legacy TS projects, NestJS |
| Kysely | Fully type-safe query builder, no ORM magic, composable | Complex queries, migration from raw SQL |
| Knex.js | Query builder + migration runner, database-agnostic | Mixed teams, existing Knex projects |
| Sequelize v7 | Promise-based, associations, hooks | Existing Sequelize codebases |

## Python

| ORM | Strengths | Best For |
|-----|-----------|----------|
| SQLAlchemy 2.0 | Most powerful Python ORM, async, typed, Alembic migrations | Any Python backend |
| Django ORM | Tightly integrated with Django, admin, migrations | Django projects |
| Tortoise ORM | Async-first, familiar Django-style API | FastAPI async projects |
| Peewee | Lightweight, simple API | Small scripts, SQLite |

## Go

| ORM | Strengths | Best For |
|-----|-----------|----------|
| GORM | Most popular Go ORM, hooks, associations, Gen | Standard Go apps |
| sqlx | Thin extension of `database/sql`, struct scanning | SQL-first Go teams |
| sqlc | Generates type-safe Go code from SQL queries | Compile-time SQL safety |
| Ent | Graph-based entity framework, code generation | Complex graph data models |
| Bun | Fast SQL-first ORM, Postgres/MySQL/SQLite | High-performance Go APIs |

## Rust

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Diesel | Compile-time query checking, no runtime errors | Safety-critical Rust services |
| SQLx | Async, compile-time checked queries (macros), no ORM | Rust async services |
| SeaORM | Async, ActiveRecord-style, built on SQLx | Actix/Axum web apps |

## JVM (Java / Kotlin)

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Hibernate 6 / JPA | Enterprise standard, caching, criteria API | Spring Boot, Jakarta EE |
| Panache (Quarkus) | Active record: `User.find("email", email)`, simplified API | Quarkus services |
| Spring Data JPA | Repository pattern with derived queries | Spring Boot projects |
| JOOQ | Type-safe SQL DSL generated from schema | SQL-heavy Java apps |
| Exposed (Kotlin) | Type-safe DSL and DAO pattern for Kotlin | Kotlin backend services |

## Ruby

| ORM | Strengths | Best For |
|-----|-----------|----------|
| ActiveRecord 7 | Rails integration, associations, callbacks, migrations | Rails apps |
| Sequel | Flexible DSL, plugins, thread-safe | Non-Rails Ruby apps |
| ROM (Ruby Object Mapper) | Functional, immutable, dry-rb ecosystem | Hanami apps |

## Elixir

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Ecto | Changesets for validation, composable queries, multi-tenancy | All Phoenix/Elixir apps |

## .NET

| ORM | Strengths | Best For |
|-----|-----------|----------|
| Entity Framework Core 8 | LINQ queries, migrations, interceptors, compiled queries | .NET apps |
| Dapper | Micro-ORM, raw SQL with object mapping | Performance-critical .NET |
| NHibernate | Full-featured, mature, enterprise | Legacy .NET apps |
