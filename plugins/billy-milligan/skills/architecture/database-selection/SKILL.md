---
name: database-selection
description: |
  Database selection: PostgreSQL as default, Redis for ephemeral, NoSQL comparison,
  specialized databases, polyglot persistence. Use when choosing databases.
allowed-tools: Read, Grep, Glob
---

# Database Selection

## When to use
- Choosing primary database for a new service
- Adding a specialized database (cache, search, analytics, time-series)
- Evaluating polyglot persistence or multi-database architecture

## Core principles
1. **PostgreSQL is the default** — handles 10k TPS, JSONB, full-text search, extensions
2. **Add databases for specific access patterns** — not because it's trendy
3. **Every additional database doubles operational complexity** — worth it only for clear ROI
4. **Consistency model is a product decision** — strong vs eventual affects user experience
5. **Benchmark with YOUR data** — vendor benchmarks are meaningless for your workload

## References available
- `references/relational-comparison.md` — Postgres vs MySQL vs SQLite vs CockroachDB
- `references/nosql-comparison.md` — MongoDB vs DynamoDB vs Cassandra vs Redis use cases
- `references/specialized-databases.md` — TimescaleDB, Neo4j, Pinecone, pgvector, Elasticsearch
- `references/multi-database-patterns.md` — polyglot persistence, CQRS stores, data sync

## Scripts available
- `scripts/analyze-data-model.sh` — reads schema/migration files to suggest database fit

## Assets available
- `assets/database-decision-matrix.md` — fillable template: requirements → recommendation
