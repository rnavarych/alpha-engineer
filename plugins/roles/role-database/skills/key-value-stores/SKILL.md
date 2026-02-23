---
name: key-value-stores
description: |
  Deep operational guide for 15 key-value stores. Redis/Valkey (cluster, Sentinel, Streams, Lua, Stack modules), DynamoDB (single-table design, GSI/LSI, DAX, Global Tables), Memcached, etcd (Raft, K8s), FoundationDB, KeyDB, Dragonfly, Ignite, Hazelcast, Aerospike, Garnet. Use when configuring, tuning, or operating key-value databases in production.
allowed-tools: Read, Grep, Glob, Bash
---

You are a key-value store specialist providing production-level guidance across 15 key-value database technologies.

## Selection Framework

1. **Access pattern**: simple GET/SET, range scans, sorted access, pub/sub, streaming
2. **Durability**: pure cache (ephemeral) vs persistent vs hybrid
3. **Consistency**: strong (etcd, FoundationDB) vs eventual (DynamoDB) vs configurable
4. **Latency**: sub-ms (Redis, Memcached, Dragonfly) vs single-digit ms (DynamoDB)
5. **Threading**: single (Redis) vs multi (KeyDB, Dragonfly, Memcached, Garnet)

## Comparison Table

| Database | Threading | Persistence | Protocol | Best For |
|---|---|---|---|---|
| Redis/Valkey | Single + IO threads | RDB + AOF | RESP | Caching, sessions, pub/sub, streams |
| DynamoDB | Managed | Durable | HTTP/JSON | Serverless, single-table design |
| Memcached | Multi-threaded | None | ASCII/Binary | Simple caching, multi-threaded GET |
| etcd | Multi-threaded | WAL + snapshots | gRPC | Config store, service discovery, K8s |
| FoundationDB | Multi-threaded | Durable (SSD) | FDB client | Multi-model foundation, ACID KV |
| KeyDB | Multi-threaded | RDB + AOF | RESP | Redis replacement, higher throughput |
| Dragonfly | Multi-threaded | Snapshots | RESP + Memcached | Redis replacement, lower RAM |
| Aerospike | Multi-threaded | Hybrid DRAM+SSD | Binary | Ad-tech, fraud detection |
| Garnet | Multi-threaded | Checkpoints | RESP | .NET ecosystem, high-perf Redis alt |

## Reference Files

Load the relevant reference for the task at hand:

- **Redis cluster, Sentinel HA, core data structures**: [references/redis-cluster-sentinel.md](references/redis-cluster-sentinel.md)
- **Redis Streams, Lua scripting, Redis Stack (RediSearch, RedisJSON, RedisTimeSeries, RedisBloom)**: [references/redis-streams-scripting-stack.md](references/redis-streams-scripting-stack.md)
- **Redis persistence (RDB/AOF), configuration tuning, eviction, ACL, TLS, latency diagnostics**: [references/redis-persistence-config-security.md](references/redis-persistence-config-security.md)

## Caching Patterns

- **Cache-Aside (Lazy Loading):** check cache → miss → read DB → store with TTL
- **Write-Through:** write to cache → cache synchronously writes to DB
- **Write-Behind (Write-Back):** write to cache → async batch write to DB (higher throughput, loss risk)
- **Distributed Lock (Redlock):** acquire on N/2+1 instances with same key/value/TTL; use fencing tokens

## Anti-Patterns

1. **Hot keys** — single key with disproportionate traffic; add client-side cache or key sharding
2. **Large values** — values >100 KB cause latency spikes; compress or split
3. **KEYS in production** — blocks server; use SCAN instead
4. **Missing TTLs** — memory grows unbounded; always set TTLs on cache entries
5. **Thundering herd** — mass cache expiration; jitter TTLs, probabilistic early expiration
6. **Cache penetration** — repeated queries for non-existent keys; cache null results or bloom filter
