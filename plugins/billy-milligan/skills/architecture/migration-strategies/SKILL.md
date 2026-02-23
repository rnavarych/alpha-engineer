---
name: migration-strategies
description: |
  Migration strategies: zero-downtime deployments, expand-contract schema changes,
  database migrations, framework migrations. Use when planning system migrations.
allowed-tools: Read, Grep, Glob
---

# Migration Strategies

## When to use
- Planning zero-downtime schema changes or deployments
- Migrating from one framework/database to another
- Executing large-scale data migrations safely

## Core principles
1. **Never big bang** — incremental migration with rollback at every step
2. **Expand-contract for schema changes** — add new, migrate, remove old
3. **Batch data migrations** — 1000 rows at a time, 50ms delay between batches
4. **Test migration on production-size data** — 100 rows works, 10M rows breaks differently
5. **Rollback plan before migration plan** — if you can't roll back, you can't ship

## References available
- `references/zero-downtime-migration.md` — blue-green, canary, rolling with rollback procedures
- `references/database-migration-patterns.md` — expand-contract, schema versioning tools (Flyway, golang-migrate, Prisma), safe migration rules
- `references/data-migration-patterns.md` — dual-write between databases, batch ETL with cursor pagination, migration validation
- `references/framework-migration.md` — strangler fig pattern: CRA→Next.js, Express→Fastify, REST→GraphQL
- `references/incremental-migration.md` — step-by-step migration rules, rollback plans, shadow mode, monitoring during migration
