# Serverless Database Patterns and Cost Optimization

## When to load
Load when choosing a serverless database platform, designing edge-first or scale-to-zero architectures, or optimizing costs across Neon, Turso, Supabase, D1, and Upstash.

## Comparison Matrix

| Database | Base Engine | Pricing Model | Cold Start | Edge Support | Branching | Best For |
|----------|-----------|---------------|------------|-------------|-----------|----------|
| Neon | PostgreSQL | Compute-time + storage | ~500ms | No | Yes (instant) | Dev workflows, scale-to-zero PG |
| Turso/libSQL | SQLite (libSQL) | Rows read/written | None (embedded) | Yes (global) | Yes (groups) | Edge apps, embedded replicas |
| Supabase | PostgreSQL | Compute + storage + bandwidth | ~2s (paused) | Edge Functions | Yes (preview) | Full-stack BaaS |
| PlanetScale | MySQL (Vitess) | Rows read/written | None | No | Yes (non-blocking) | MySQL at scale |
| Cloudflare D1 | SQLite | Rows read/written | None (Workers) | Yes (edge-native) | No | Workers ecosystem |
| Xata | PostgreSQL | Storage + AI + search | ~1s | No | Yes | PG + search + AI |
| Upstash | Redis / Kafka | Per-request | ~5ms | Yes (global) | No | Serverless caching/messaging |
| Aurora Serverless v2 | MySQL/PostgreSQL | ACU-hours | ~1s | No | No | AWS-native auto-scaling |
| Cosmos DB Serverless | Cosmos DB | Request Units | ~10ms | Global distrib | No | Azure-native, pay-per-request |

## Architecture Patterns

### Scale-to-Zero Development
```
Production: Always-on with auto-scaling
Staging: Scale-to-zero (resume on request)
Preview: Branch per PR, auto-destroy on merge
Development: Local or scale-to-zero branch
```

### Edge-First Architecture
```
User -> CDN/Edge -> Edge Database (Turso/D1) -> Origin Database
                         |
                    Embedded Replica (local SQLite)
                         |
                    Sync to Primary (async)
```

### Serverless Full-Stack
```
Frontend (Vercel/Netlify) -> API (Edge Functions) -> Serverless DB (Neon/Turso)
                                |
                         Serverless Cache (Upstash Redis)
                                |
                         Serverless Queue (Upstash Kafka)
```

## Cost Optimization by Provider

### Neon
- Use scale-to-zero for non-production branches (suspend-timeout 60s dev, 300s staging)
- Delete preview branches after PR merge (automate in CI/CD)
- Use connection pooling to reduce compute endpoint wake-ups

### Turso
- Use embedded replicas for read-heavy workloads (free local reads)
- Group databases by region to share infrastructure
- Database-per-tenant shares group replicas

### Supabase
- Pause unused projects (free tier auto-pauses after 7 days)
- Use RLS instead of server-side filtering (reduces data transfer)
- Filter Realtime subscriptions at database level

### Cloudflare D1
- Batch write operations (single transaction for multiple writes)
- Use D1 read replicas for global read performance
- Time travel instead of manual backups

### Upstash
- Use pipeline/multi for batch operations
- Set TTLs on all cache keys
- Use Upstash rate limiting to protect downstream services

### General Serverless
- Monitor cold starts, set minimum compute where cold starts hurt
- Use HTTP-based clients for edge (no persistent TCP connections)
- Implement caching layers to reduce database requests
- Track per-request costs with observability tools

## Cross-References
- PlanetScale and CockroachDB Serverless: see newsql-distributed skill
- Turso/libSQL deeper details: see embedded-databases skill
