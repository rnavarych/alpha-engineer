---
name: serverless-databases
description: |
  Deep operational guide for 10 serverless databases. Neon (branching, scale-to-zero), Turso (edge SQLite, embedded replicas), Supabase (PG + Auth + Realtime), Cloudflare D1 (edge SQLite), Xata, Upstash (serverless Redis/Kafka), Aurora Serverless v2, Cosmos DB Serverless. Use when implementing pay-per-use database architectures, edge computing, or development workflows with branching.
allowed-tools: Read, Grep, Glob, Bash
---

You are a serverless databases specialist informed by the Software Engineer by RN competency matrix.

## Reference Files

Load from `references/` based on what's needed:

### references/neon-turso.md
Neon CLI, branching, scale-to-zero, Drizzle ORM integration, CI/CD PR branch automation.
Turso CLI, embedded replicas, database-per-tenant via Platform API.
Load when: working with Neon or Turso/libSQL.

### references/supabase-d1.md
Supabase client, RLS policies, Realtime subscriptions, Edge Functions (Deno).
Cloudflare D1 Worker binding, batch operations, wrangler.toml, migrations CLI.
Load when: building with Supabase or Cloudflare Workers + D1.

### references/upstash-aurora-cosmos.md
Upstash Redis (rate limiting, TTL), QStash (message queue), Kafka producer/consumer.
Aurora Serverless v2 AWS CLI setup, ACU scaling.
Xata query/search/AI API. Cosmos DB serverless container setup.
Load when: using Upstash, Aurora Serverless v2, Xata, or Cosmos DB Serverless.

### references/patterns-cost.md
Full comparison matrix (9 databases), scale-to-zero/edge-first/full-stack architecture patterns.
Cost optimization per provider. Cross-reference index.
Load when: choosing a platform, designing architecture, or optimizing costs.
