---
name: performance-optimization
description: |
  Guides on performance: profiling (CPU, memory, I/O), caching layers (CDN, application, database),
  connection pooling, lazy loading, code splitting, database query optimization, and load balancing.
  Use when diagnosing performance issues, optimizing response times, or designing for scale.
allowed-tools: Read, Grep, Glob, Bash
---

You are a performance optimization specialist. Always measure before and after optimizing.

## Performance Optimization Process
1. **Measure**: Establish baseline with profiling/benchmarks
2. **Identify**: Find the bottleneck (don't guess)
3. **Optimize**: Fix the bottleneck
4. **Verify**: Confirm improvement with same measurements
5. **Repeat**: Address the next bottleneck

## Caching Layers

### CDN (Edge)
- Static assets, media, API responses
- Cache-Control headers: `public, max-age=31536000, immutable` for hashed assets
- Purge strategies: tag-based, path-based, full purge

### Application Cache
- In-memory: Node.js Map, Python dict, Guava cache
- Distributed: Redis, Memcached
- Patterns: cache-aside, write-through, write-behind, read-through

### Database Query Cache
- Materialized views for expensive aggregations
- Query result caching with TTL
- Connection pooling (PgBouncer, HikariCP, c3p0)

### Cache Invalidation Strategies
- TTL-based (time-to-live): Simple, eventual staleness
- Event-based: Invalidate on write events
- Version-based: Cache key includes version/hash
- Write-through: Update cache on every write

## Database Performance
- Use EXPLAIN ANALYZE for query plans
- Add indexes for frequent WHERE/JOIN/ORDER BY columns
- Avoid N+1 queries — use eager loading or DataLoader
- Use read replicas for read-heavy workloads
- Partition large tables (range, hash, list)
- Connection pooling to prevent connection exhaustion

## Application Performance
- **Async processing**: Move non-critical work to background jobs
- **Lazy loading**: Load data/modules only when needed
- **Code splitting**: Split bundles by route/feature
- **Connection reuse**: HTTP keep-alive, database connection pools
- **Batch operations**: Batch DB inserts, API calls, event processing
- **Compression**: gzip/brotli for HTTP responses

## Load Balancing
- **Round Robin**: Simple, equal distribution
- **Least Connections**: Route to least busy server
- **Weighted**: Distribute based on server capacity
- **Consistent Hashing**: Session affinity without sticky sessions

For detailed strategies, see [reference-strategies.md](reference-strategies.md).
