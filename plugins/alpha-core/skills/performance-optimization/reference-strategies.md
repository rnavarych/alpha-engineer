# Performance Optimization Strategies Reference

## Frontend Performance
- **Core Web Vitals**: LCP < 2.5s, FID < 100ms, CLS < 0.1
- **Bundle size**: Tree shaking, code splitting, dynamic imports
- **Image optimization**: WebP/AVIF, responsive images, lazy loading
- **Font loading**: `font-display: swap`, preload critical fonts, subset fonts
- **Critical CSS**: Inline above-the-fold CSS, defer non-critical
- **Prefetch/Preload**: `<link rel="prefetch">` for likely next navigations

## Backend Performance
- **Connection pooling**: Reuse DB connections, HTTP keep-alive
- **Async I/O**: Non-blocking operations for I/O-bound work
- **Worker threads**: CPU-bound work off main thread
- **Streaming**: Stream large responses instead of buffering
- **Pagination**: Never return unbounded result sets
- **Rate limiting**: Protect against abuse, fair resource allocation

## Database Optimization
- **Index design**: Composite indexes matching query patterns, partial indexes
- **Query analysis**: EXPLAIN plans, slow query logs, query profiling
- **Denormalization**: Materialized views, computed columns for read-heavy
- **Partitioning**: Time-based, range-based for large tables
- **Read replicas**: Offload read traffic from primary
- **Connection management**: Pool sizing, timeout configuration

## Profiling Tools
- **Node.js**: clinic.js, 0x, node --inspect, Async Hooks
- **Python**: cProfile, py-spy, memory_profiler, line_profiler
- **Java**: JProfiler, async-profiler, JFR (Java Flight Recorder)
- **Go**: pprof, trace, benchmarks
- **Browser**: Lighthouse, Chrome DevTools Performance tab, WebPageTest
- **APM**: Datadog, New Relic, Dynatrace

## Memory Optimization
- Identify memory leaks with heap snapshots
- Weak references for caches
- Stream processing instead of loading entire datasets
- Object pooling for frequently allocated objects
- Monitor GC pauses and tune GC settings
