# Caching Strategy Checklist

## What to cache

### High-value targets
- [ ] Database query results (read:write ratio > 10:1)
- [ ] API responses from external services (rate-limited or slow)
- [ ] Computed/aggregated data (dashboards, reports, counts)
- [ ] Static assets (JS, CSS, images, fonts)
- [ ] User session data
- [ ] Configuration and feature flags

### Do NOT cache
- [ ] Confirmed: not caching real-time financial transactions
- [ ] Confirmed: not caching frequently-mutated data with strong consistency needs
- [ ] Confirmed: not caching PII without encryption and access controls
- [ ] Confirmed: not caching large blobs (>1MB) in Redis (use S3 + pointer)

## TTL recommendations by data type

| Data type | TTL | Rationale |
|-----------|-----|-----------|
| Static assets (hashed) | 1 year | Immutable, filename changes on update |
| Feature flags | 10s | Need fast rollout, low cost to refetch |
| Search results | 30s | Frequently changing, acceptable staleness |
| API responses (public) | 60s | Balance freshness vs origin load |
| Product listings | 60-300s | Semi-static, event-driven invalidation backup |
| User profiles | 300s | Moderate change frequency |
| Config/settings | 3600s | Rarely changes, manual invalidation on update |
| Session data | 24h | Long-lived, explicit invalidation on logout |
| CDN static | 1 year | Content-hash in URL handles versioning |

## Architecture decisions

### Cache layer selection
- [ ] L1 (in-process LRU): needed for <1ms latency on hot data?
- [ ] L2 (Redis/Memcached): needed for shared cache across instances?
- [ ] L3 (CDN): serving static or semi-static content to end users?

### Pattern selection
- [ ] Pattern chosen: cache-aside / write-through / write-behind / read-through
- [ ] Justification documented for pattern choice
- [ ] Jitter added to TTL values (prevent thundering herd)

### Invalidation strategy
- [ ] Primary invalidation method: explicit delete / event-driven / versioned keys
- [ ] TTL set as safety net on ALL cache keys
- [ ] Stampede prevention: distributed lock or probabilistic early expiry
- [ ] Invalidation happens AFTER DB transaction commit

## Monitoring queries

### Redis monitoring
```bash
# Memory usage
redis-cli INFO memory | grep used_memory_human
redis-cli INFO memory | grep maxmemory

# Hit rate (target: >90%)
redis-cli INFO stats | grep keyspace_hits
redis-cli INFO stats | grep keyspace_misses

# Eviction count (should be 0 normally)
redis-cli INFO stats | grep evicted_keys

# Slow log (commands >10ms)
redis-cli SLOWLOG GET 10

# Key count and TTL distribution
redis-cli DBSIZE
redis-cli INFO keyspace
```

### Key metrics to track
- [ ] Cache hit rate (target: >90% for stable data, >60% for dynamic)
- [ ] Cache miss latency (origin fetch time)
- [ ] Eviction rate (should be ~0 under normal load)
- [ ] Memory utilization (alert at 80% of maxmemory)
- [ ] P99 cache read latency (target: <5ms for Redis)
- [ ] Invalidation lag (time from write to cache update)

### Alerting thresholds
| Metric | Warning | Critical |
|--------|---------|----------|
| Hit rate | <80% | <60% |
| Memory usage | >80% maxmemory | >95% maxmemory |
| Eviction rate | >100/min | >1000/min |
| P99 latency | >10ms | >50ms |
| Connection count | >80% max | >95% max |

## Pre-launch validation
- [ ] Load tested with cache cold-start scenario
- [ ] Verified behavior when cache is completely unavailable (graceful degradation)
- [ ] Confirmed no sensitive data cached without encryption
- [ ] Tested invalidation correctness after writes
- [ ] Verified TTL jitter is applied
- [ ] Monitoring dashboards and alerts configured
