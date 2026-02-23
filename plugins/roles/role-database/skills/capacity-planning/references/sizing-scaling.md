# Storage, Memory, and Scaling Decisions

## When to load
Load when estimating storage growth, sizing memory (shared_buffers, buffer pool, WiredTiger cache), deciding between vertical scaling vs read replicas vs sharding, or estimating IOPS requirements.

## Storage Estimation

### Row Size Calculation
```sql
-- PostgreSQL: estimate row size
SELECT pg_column_size(ROW(
    1::bigint,                    -- id: 8 bytes
    gen_random_uuid(),            -- uuid: 16 bytes
    'example@email.com'::text,    -- email: ~20 bytes + overhead
    now()::timestamptz,           -- created_at: 8 bytes
    'active'::text                -- status: ~8 bytes + overhead
)) AS estimated_row_bytes;
-- Result: ~80 bytes per row (includes tuple header ~23 bytes + alignment)

-- Actual bytes per row for existing table
SELECT pg_total_relation_size('orders') / NULLIF(reltuples, 0) AS bytes_per_row
FROM pg_class WHERE relname = 'orders';
```

### Growth Projection
```
Daily new rows: 100,000
Average row size: 200 bytes
Index overhead: ~60% of data size (for 3-4 indexes)

Daily data growth: 100,000 × 200 bytes = 20 MB/day
Daily total (with indexes): 20 MB × 1.6 = 32 MB/day
Monthly: ~1 GB/month
Annual: 12 GB/year
With WAL, temp files, bloat headroom (2x safety): 24 GB/year
```

### Storage Rule of Thumb
- Index size: 30–80% of data size
- WAL/logs: 2–5x the write throughput window
- Bloat headroom: 20–50% for dead tuples between VACUUMs
- Safety margin: 2x total for growth + operational headroom

## Memory Sizing

### PostgreSQL
```
shared_buffers = 25% of total RAM (max ~8 GB for most workloads)
effective_cache_size = 50–75% of total RAM (helps planner estimate)
work_mem = RAM / (max_connections × 2)   # per-operation sort/hash memory
maintenance_work_mem = 1GB               # for VACUUM, CREATE INDEX

# Total RAM formula:
# shared_buffers + (max_connections × work_mem) + maintenance_work_mem + OS cache
# Example: 4GB + (100 × 64MB) + 1GB ≈ 12GB minimum for 100 connections
```

### MySQL
```ini
innodb_buffer_pool_size = 70–80% of total RAM
innodb_buffer_pool_instances = 1 per GB (max 64)
sort_buffer_size = 4M
join_buffer_size = 4M
```

### MongoDB and Redis
```yaml
# MongoDB WiredTiger: 50% of RAM - 1GB (default) or explicit:
storage.wiredTiger.engineConfig.cacheSizeGB: 8  # for 16 GB server

# Redis:
maxmemory 4gb
# ~90 bytes overhead per string key, ~70 bytes per small hash/set
```

## IOPS Estimation

| Workload Type | IOPS per 1K TPS | Storage Recommendation |
|---------------|-----------------|----------------------|
| Read-heavy (90/10) | ~500 read IOPS | SSD, larger buffer pool |
| Balanced (60/40) | ~800 mixed IOPS | SSD, WAL on separate volume |
| Write-heavy (20/80) | ~1200 write IOPS | NVMe SSD, RAID 10 |
| OLAP (batch) | Throughput > IOPS | Large sequential reads, HDDs acceptable |

### AWS RDS IOPS Reference

| Instance | Max IOPS | Max Throughput | Use Case |
|-------------|----------|----------------|----------|
| db.t3.medium | 3,000 | 87.5 MB/s | Dev/test |
| db.r6g.large | 12,000 | 340 MB/s | Small production |
| db.r6g.xlarge | 20,000 | 680 MB/s | Medium production |
| db.r6g.4xlarge | 40,000 | 1,360 MB/s | Large production |

## Scaling Decision Framework

### When to Scale Up (Vertical)
- CPU consistently > 70% utilization
- Memory pressure (cache hit ratio < 95%)
- Simple single-primary workload

### When to Add Read Replicas
- Read/write ratio > 80/20
- Reporting queries competing with OLTP
- Geographic read latency requirements

### When to Shard (Horizontal)
- Write throughput exceeds single node capacity
- Dataset > 1TB, > 10K writes/sec, > 80% CPU sustained
- Require geographic data distribution

### Scaling Decision Matrix

| Signal | Scale Up | Read Replica | Shard |
|--------|----------|-------------|-------|
| CPU high, reads heavy | Maybe | **Yes** | No |
| CPU high, writes heavy | **Yes** | No | Maybe |
| Memory pressure | **Yes** | No | No |
| Storage full | **Yes** | No | **Yes** |
| Write latency high | **Yes** | No | **Yes** |
| Global distribution needed | No | **Yes** (multi-region) | **Yes** |
