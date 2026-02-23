---
name: performance
description: Performance optimization — frontend Core Web Vitals, backend profiling, database tuning, load testing
allowed-tools: Read, Grep, Glob, Bash
---

# Performance Skill

## Core Principles
- **Measure before optimizing**: Guessing is expensive; profiling is cheap.
- **Database is usually the bottleneck**: 90% of API latency is DB time.
- **Response time budget**: Break down your 200ms target into components.
- **N+1 kills at scale**: 10 users: unnoticeable. 1000 users: outage.
- **Core Web Vitals are ranking signals**: LCP, CLS, INP affect SEO and conversion.

## References
- `references/frontend-performance.md` — Core Web Vitals, bundle optimization, lazy loading
- `references/backend-performance.md` — Profiling Node/Python/Go, N+1, connection pooling
- `references/database-performance.md` — EXPLAIN ANALYZE, indexing strategies, query optimization, partitioning
- `references/connection-performance.md` — Connection pooling, prepared statements, batch operations, read replicas
- `references/load-testing-reference.md` — k6, Gatling, interpreting results, bottlenecks

## Scripts
- `scripts/run-lighthouse.sh` — Runs Lighthouse audit against a URL
