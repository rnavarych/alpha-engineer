---
name: role-database:connection-management
description: |
  Connection pooling and management across all engines. PgBouncer (transaction/session/statement mode), pgcat (Rust-based, load balancing, sharding), ProxySQL (MySQL query routing, caching), HikariCP (Java), application-level pooling (Prisma, SQLAlchemy, GORM, database/sql). Serverless connection strategies (Prisma Accelerate, RDS Proxy, Neon pooler). Connection limits, pool sizing, leak detection. Use when configuring connection pools, optimizing connection usage, or troubleshooting connection issues.
allowed-tools: Read, Grep, Glob, Bash
---

# Connection Management

## Why Connection Pooling

- PostgreSQL: ~10 MB per connection (per-process model)
- MySQL: ~1-4 MB per connection (per-thread model)
- Without pooling: N app instances × M connections = N×M database connections
- Pool reuses ~20 persistent connections to serve 100 simultaneous requests

## Reference Files

Load from `references/` based on what's needed:

### references/pgbouncer-proxysql.md
PgBouncer pool modes (transaction/session/statement), full pgbouncer.ini config, admin console monitoring commands.
pgcat Rust-based alternative with read/write routing config.
AWS RDS Proxy overview.
ProxySQL MySQL read/write splitting with hostgroups and query routing rules.
Serverless strategy comparison table (Prisma Accelerate, RDS Proxy, Neon, Supabase, Hyperdrive).
Load when: configuring PgBouncer, pgcat, ProxySQL, or serverless connection proxies.

### references/app-pooling-sizing.md
Application pool configuration: node-postgres, Prisma, SQLAlchemy, HikariCP (Java), database/sql (Go).
Pool sizing formula: (core_count * 2) + spindle_count with worked examples.
Connection leak detection queries for PostgreSQL and MySQL.
Leak prevention checklist.
Load when: configuring pools inside application code or diagnosing connection leaks.
