---
name: caching-strategies
description: |
  Caching patterns: cache-aside, write-through, stampede prevention, CDN headers,
  multi-level L1/L2/L3, cache invalidation. Use when designing caches or CDN strategy.
allowed-tools: Read, Grep, Glob
---

# Caching Strategies

## When to use
- Designing cache layers for high-traffic systems
- Preventing cache stampede / thundering herd
- Setting CDN/HTTP cache headers or cache invalidation strategy

## Core principles
1. **Cache-aside is the default** — application controls all cache interactions
2. **Always add jitter to TTL** — ±10% prevents synchronized expiry stampedes
3. **Cache invalidation is harder than caching** — design invalidation FIRST, then TTL
4. **Multi-level cache reduces latency multiplicatively** — L1 (in-memory) → L2 (Redis) → L3 (DB)
5. **A cache miss should never cascade to DB overload** — use lock-based prevention

## References available
- `references/caching-patterns.md` — cache-aside, write-through, write-behind, multi-level with code
- `references/redis-deep-dive.md` — data structures for caching, eviction policies, cluster mode
- `references/cdn-edge-caching.md` — Cache-Control headers, stale-while-revalidate, purge strategies
- `references/cache-invalidation.md` — stampede prevention, event-driven invalidation, versioned keys

## Assets available
- `assets/caching-checklist.md` — what to cache, TTL recommendations, monitoring queries
