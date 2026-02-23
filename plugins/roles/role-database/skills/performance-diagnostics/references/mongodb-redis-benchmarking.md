# MongoDB, Redis Diagnostics, and Benchmarking

## When to load
Load when diagnosing slow queries or memory issues in MongoDB or Redis, or when benchmarking database performance with pgbench, sysbench, or redis-benchmark.

## MongoDB Diagnostics

### Slow Query Analysis
```javascript
// Enable profiler for queries > 50ms
db.setProfilingLevel(1, { slowms: 50 });

// Analyze slow queries
db.system.profile.find({
    millis: { $gt: 100 },
    op: { $in: ["query", "update", "remove"] }
}).sort({ ts: -1 }).limit(10);

// Explain with execution stats
db.orders.find({ status: "pending", customer_id: ObjectId("...") })
    .explain("executionStats");
// Key metrics:
// totalDocsExamined vs nReturned (should approach 1:1)
// totalKeysExamined
// executionTimeMillis
// stage: COLLSCAN = bad, IXSCAN = good

// Find and kill long-running operations
db.currentOp({
    "active": true,
    "secs_running": { "$gt": 5 },
    "op": { "$ne": "none" }
});
db.killOp(opId);
```

## Redis Diagnostics

### Latency Analysis
```bash
# Continuous latency measurement
redis-cli --latency
# Output: min: 0, max: 15, avg: 0.12 (2038 samples)

redis-cli --latency-history -i 10  # 10-second windows
redis-cli --intrinsic-latency 5    # system baseline

redis-cli LATENCY LATEST
redis-cli LATENCY HISTORY <event-name>
```

### Memory Analysis
```bash
redis-cli INFO memory
# used_memory, used_memory_rss
# mem_fragmentation_ratio: RSS/used (>1.5 = fragmentation problem)
# used_memory_peak

redis-cli --bigkeys              # sampled scan, safe for production
redis-cli MEMORY USAGE mykey
redis-cli MEMORY DOCTOR
```

### Slowlog
```bash
redis-cli SLOWLOG GET 25
# Each entry: id, timestamp, duration (microseconds), command + args

redis-cli CONFIG SET slowlog-log-slower-than 5000  # 5ms threshold
# Common slow commands: KEYS *, SORT, SMEMBERS on large sets
# Fix: SCAN instead of KEYS, paginate with SSCAN/HSCAN/ZSCAN
```

## Common Issues and Fixes

| Symptom | Likely Cause | Diagnostic | Fix |
|---------|-------------|-----------|-----|
| High CPU | Missing indexes, bad queries | EXPLAIN, pg_stat_statements | Add indexes, rewrite queries |
| High I/O | Table scans, insufficient cache | EXPLAIN BUFFERS, cache hit ratio | Increase shared_buffers, add indexes |
| Lock waits | Long transactions, hot rows | pg_locks, InnoDB status | Shorter transactions, advisory locks |
| Deadlocks | Inconsistent lock ordering | Deadlock logs | Consistent access ordering, retry logic |
| Connection exhaustion | No pooling, leaks | Connection count monitoring | PgBouncer, fix leaks |
| Memory pressure | Large queries, sorts | work_mem, sort method | Increase work_mem, add indexes |
| Replication lag | Heavy writes, slow replica | Replication monitoring | Faster replica, parallel apply |
| Disk full | WAL accumulation, bloat | Disk monitoring, slot lag | VACUUM, fix stuck replication slots |

## Benchmarking

### pgbench (PostgreSQL)
```bash
pgbench -i -s 100 mydb          # initialize (scale 100 ≈ 1.5 GB)
pgbench -c 20 -j 4 -T 300 -S mydb  # read-heavy test
pgbench -c 20 -j 4 -T 300 mydb     # read-write test
# Key output: TPS, latency average and stddev
```

### sysbench (MySQL/PostgreSQL)
```bash
sysbench oltp_read_write --db-driver=pgsql --pgsql-host=host --pgsql-db=test \
    --tables=10 --table-size=1000000 --threads=16 --time=300 run
```

### redis-benchmark
```bash
redis-benchmark -h host -p 6379 -c 50 -n 100000
redis-benchmark -h host -p 6379 -c 50 -n 100000 -P 16 -t set,get  # pipeline mode
```
