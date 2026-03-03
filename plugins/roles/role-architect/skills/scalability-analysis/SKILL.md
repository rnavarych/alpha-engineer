---
name: role-architect:scalability-analysis
description: |
  Scalability analysis expertise including horizontal vs vertical scaling,
  sharding strategies, read/write splitting, eventual consistency patterns,
  CQRS for scale, back-of-envelope calculations, and caching layer design.
allowed-tools: Read, Grep, Glob, Bash
---

# Scalability Analysis

## When to use
- Choosing between vertical and horizontal scaling for a workload
- Designing a sharding strategy for a database that is approaching its single-node limit
- Implementing read/write splitting with replication-lag awareness
- Deciding whether CQRS is justified for a given read/write pattern divergence
- Performing back-of-envelope QPS, storage, bandwidth, or memory estimates
- Designing caching layers with appropriate invalidation strategies

## Core principles
1. **Scale vertically first** — distributed coordination has a real cost; delay it until necessary
2. **Shard key determines your fate** — cardinality and query pattern alignment before anything else
3. **Replication lag is not zero** — design read/write splitting with explicit lag tolerance per flow
4. **CQRS only when patterns diverge** — premature CQRS is just complexity you'll regret
5. **Estimate before architecting** — back-of-envelope math prevents over- and under-engineering

## Reference Files
- `references/scaling-strategies-and-sharding.md` — vertical vs horizontal scaling, hybrid approach, hash/range/geo-based sharding, shard key selection, read/write splitting with replication lag handling, eventual consistency patterns (compensating transactions, idempotency), and CQRS write/read model separation
- `references/capacity-math-and-caching.md` — QPS/storage/bandwidth/memory estimation formulas, application-level and distributed cache patterns, database query cache and materialized views, CDN and edge cache, TTL/event-based/write-through/cache-aside invalidation strategies
