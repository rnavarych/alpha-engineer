---
name: redis-deep
description: |
  Redis deep-dive: 8 data structures with use cases, Redlock distributed locking algorithm,
  sliding window rate limiter with sorted sets, pub/sub patterns, streams for event log,
  pipeline batching, keyspace notifications, memory eviction policies, Redis Cluster vs Sentinel.
  Use when implementing caching, distributed locks, rate limiting, real-time features.
allowed-tools: Read, Grep, Glob
---

# Redis Deep Dive

## When to Use This Skill
- Implementing distributed locking (Redlock)
- Building rate limiters with sliding windows
- Designing pub/sub for real-time features
- Using Redis Streams for event log
- Choosing memory eviction policy

## Core Principles

1. **Redis is not a database for data you cannot afford to lose** — AOF/RDB persistence is best-effort; design for Redis to be empty
2. **One connection per operation is wasteful** — use pipelining for batch operations (10× throughput improvement)
3. **Key naming convention is critical** — `resource:id:field` prevents collisions and enables pattern scanning
4. **TTL everything** — unbounded keys accumulate until OOM; if no TTL makes sense, use a large one (7 days)
5. **Redlock requires majority quorum** — N/2+1 nodes must confirm; never use single-node lock for distributed coordination

## References available
- `references/data-structures.md` — 8 data structures with TypeScript examples, Redlock, sliding window rate limiter, pub/sub
- `references/caching-patterns.md` — eviction policies, pipeline batching, keyspace notifications, cache-aside pattern
- `references/cluster-sentinel.md` — Redis Cluster vs Sentinel, topology decisions, failover behavior
