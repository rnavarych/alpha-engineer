---
name: scaling-patterns
description: |
  Scaling patterns: horizontal/vertical scaling, async processing, data partitioning,
  connection pooling, rate limiting, backpressure. Use when scaling services.
allowed-tools: Read, Grep, Glob
---

# Scaling Patterns

## When to use
- Scaling a service beyond current capacity
- Choosing between horizontal and vertical scaling
- Implementing async processing, sharding, or rate limiting

## Core principles
1. **Measure before scaling** — profile first, scale second
2. **Stateless services scale horizontally** — move state to databases/caches
3. **Connection pooling is mandatory** — direct connections exhaust DB limits
4. **Backpressure prevents cascading failure** — reject early rather than queue forever
5. **Rate limiting protects everyone** — including your own services from each other

## References available
- `references/horizontal-scaling.md` — stateless services, load balancing, autoscaling configs
- `references/vertical-scaling.md` — when vertical is enough, instance sizing, connection pool tuning
- `references/resource-optimization.md` — CPU/memory profiling, bottleneck identification, LRU cache, I/O optimization
- `references/async-processing.md` — queues (SQS, RabbitMQ, Kafka), worker patterns, backpressure, circuit breaker
- `references/background-jobs.md` — BullMQ job scheduling, retry with exponential backoff, DLQ management, cron workers
- `references/data-partitioning.md` — sharding strategies, partition key design, consistent hashing, PostgreSQL native partitioning
- `references/shard-management.md` — shard rebalancing, cross-shard queries, scatter-gather, operational concerns

## Scripts available
- `scripts/estimate-capacity.sh` — input RPM and data size, output infra recommendations
