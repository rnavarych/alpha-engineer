---
name: role-backend:caching-strategies
description: |
  Implements caching solutions using Redis patterns (cache-aside, write-through, write-behind),
  Memcached, cache invalidation strategies, TTL design, cache stampede prevention, CDN
  configuration, and distributed caching. Use when optimizing read performance, reducing
  database load, designing cache layers, or configuring CDN rules.
allowed-tools: Read, Grep, Glob, Bash
---

# Caching Strategies

## When to use
- Choosing a caching pattern for a new feature (cache-aside, write-through, read-through)
- Designing Redis key naming and data structure selection
- Building cache invalidation logic that stays consistent under writes
- Setting TTLs that balance freshness with database load
- Preventing cache stampede on high-traffic cache misses
- Configuring CDN headers for static assets and versioned files
- Evaluating whether to use Redis vs Memcached
- Setting up cache hit rate monitoring and eviction alerts

## Core principles
1. **Pattern before implementation** — cache-aside, write-through, and write-behind have different consistency trade-offs; pick deliberately
2. **TTL jitter is mandatory at scale** — synchronized expiration = thundering herd; add 10-30% random variance
3. **Hit rate is the only real metric** — target >90%; anything lower means either wrong keys or wrong TTLs
4. **Stale is often fine** — serve stale data while revalidating in background rather than blocking on a miss
5. **Cache is not storage** — set `maxmemory-policy allkeys-lru` and accept eviction; anything that can't be lost belongs in the database

## Reference Files

- `references/patterns-redis-invalidation.md` — four caching pattern descriptions (cache-aside, write-through, write-behind, read-through), Redis data structure selection guide, connection management, key naming conventions, and cache invalidation strategies with TTL design
- `references/stampede-cdn-monitoring.md` — cache stampede prevention techniques (mutex, probabilistic expiration, stale-while-revalidate) with Node.js code examples, Memcached use cases, CDN Cache-Control header configuration, and Redis monitoring and operations
