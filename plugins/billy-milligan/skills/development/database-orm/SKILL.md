---
name: database-orm
description: ORM patterns — Drizzle, Prisma, migrations, N+1 prevention, transaction management
allowed-tools: Read, Grep, Glob, Bash
---

# Database & ORM Skill

## Core Principles
- **N+1 is the silent killer**: Always eager-load when fetching related data.
- **No HTTP calls inside transactions**: Transactions must be short-lived (< 100ms).
- **Migrations are code**: Review them, test them, version them.
- **Select only needed columns**: `SELECT *` wastes bandwidth and memory.
- **Batch operations**: `insertMany` instead of N `insert` calls in a loop.

## References
- `references/drizzle-patterns.md` — Schema, queries, relations, migrations, prepared statements
- `references/prisma-patterns.md` — Schema design, client singleton, middleware, migrations
- `references/prisma-performance.md` — N+1 prevention, transactions, raw queries, query logging
- `references/migration-strategies.md` — Zero-downtime, expand-contract, column rename, NOT NULL constraint
- `references/migration-safety.md` — Data backfill patterns, rollback strategies, migration testing, pre-migration checklist
