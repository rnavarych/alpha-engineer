---
name: capacity-planning
description: |
  Database capacity and growth planning. Storage growth estimation, IOPS requirements, memory sizing (buffer pool, shared_buffers), connection count estimation, sharding triggers, read replica scaling, cost estimation per cloud provider. Load testing (pgbench, sysbench, YCSB, HammerDB). When to shard vs scale up vs read replicas. Use when planning database capacity, sizing infrastructure, or evaluating scaling strategies.
allowed-tools: Read, Grep, Glob, Bash
---

# Capacity Planning

## Storage Estimation

### Row Size Calculation
```sql
-- PostgreSQL: Estimate row size
SELECT pg_column_size(ROW(
    1::bigint,                    -- id: 8 bytes
    gen_random_uuid(),            -- uuid: 16 bytes
    'example@email.com'::text,    -- email: ~20 bytes + overhead
    now()::timestamptz,           -- created_at: 8 bytes
    'active'::text                -- status: ~8 bytes + overhead
)) AS estimated_row_bytes;
-- Result: ~80 bytes per row (includes tuple header ~23 bytes + alignment)

-- Actual table size per row
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
Monthly: 32 × 30 = 960 MB/month ≈ 1 GB/month
Annual: 12 GB/year

With WAL, temp files, bloat overhead (2x safety): 24 GB/year
```

### Storage Rule of Thumb
- **Data size**: Estimated row size × expected row count
- **Index size**: 30-80% of data size (depends on number and type of indexes)
- **WAL/logs**: 2-5x the write throughput window
- **Bloat headroom**: 20-50% for dead tuples between VACUUMs
- **Safety margin**: 2x total for growth + operational headroom

## Memory Sizing

### PostgreSQL
```
# shared_buffers: 25% of total RAM (max ~8 GB for most workloads)
shared_buffers = 4GB

# effective_cache_size: 50-75% of total RAM (helps planner estimate)
effective_cache_size = 12GB

# work_mem: RAM / (max_connections × 2) — per-operation sort/hash memory
work_mem = 64MB

# maintenance_work_mem: for VACUUM, CREATE INDEX (can be larger)
maintenance_work_mem = 1GB

# Total RAM formula:
# shared_buffers + (max_connections × work_mem) + maintenance_work_mem + OS cache
# Example: 4GB + (100 × 64MB) + 1GB + OS ≈ 12GB minimum for 100 connections
```

### MySQL
```ini
# InnoDB buffer pool: 70-80% of total RAM
innodb_buffer_pool_size = 12G

# Buffer pool instances (1 per GB, max 64)
innodb_buffer_pool_instances = 12

# Key buffer (MyISAM only, keep small)
key_buffer_size = 32M

# Sort/join buffers (per-connection)
sort_buffer_size = 4M
join_buffer_size = 4M
read_buffer_size = 2M
```

### MongoDB
```yaml
# WiredTiger cache: 50% of RAM - 1GB (default)
# Or set explicitly:
storage:
    wiredTiger:
        engineConfig:
            cacheSizeGB: 8  # For 16 GB server
```

### Redis
```
# maxmemory: Set explicit limit
maxmemory 4gb

# Memory estimation:
# Strings: ~90 bytes overhead per key + value size
# Hashes (small): ~70 bytes overhead + field sizes (ziplist encoding)
# Sets (small): ~70 bytes overhead + member sizes
# Sorted Sets (small): ~70 bytes overhead + member + score sizes
# Large collections: ~120 bytes per entry
```

## Connection Sizing

### Connection Pool Formula
```
Pool size = (core_count * 2) + effective_spindle_count

# For SSD-backed databases:
# Pool size ≈ core_count * 2 (spindle count is less relevant)

# Example: 8-core server with SSD
# Recommended pool size: 16-20 connections

# Total connections across all app instances:
# max_connections ≈ pool_size × app_instance_count + admin_reserve
# Example: 20 × 5 instances + 10 admin = 110
```

### PgBouncer Sizing
```ini
# pgbouncer.ini
[pgbouncer]
pool_mode = transaction          # share connections between transactions
default_pool_size = 20           # connections per user/database pair
max_client_conn = 1000           # total client connections allowed
reserve_pool_size = 5            # extra connections for burst
reserve_pool_timeout = 3         # seconds before using reserve pool
server_idle_timeout = 300        # close idle server connections
```

## IOPS Estimation

| Workload Type | IOPS per 1K TPS | Storage Recommendation |
|---------------|-----------------|----------------------|
| **Read-heavy** (90/10) | ~500 read IOPS | SSD, larger buffer pool |
| **Balanced** (60/40) | ~800 mixed IOPS | SSD, WAL on separate volume |
| **Write-heavy** (20/80) | ~1200 write IOPS | NVMe SSD, RAID 10 |
| **OLAP** (batch) | Throughput > IOPS | Large sequential reads, HDDs acceptable |

### Cloud IOPS by Instance Type

| AWS Instance | Max IOPS | Max Throughput | Use Case |
|-------------|----------|----------------|----------|
| db.t3.medium | 3,000 | 87.5 MB/s | Dev/test |
| db.r6g.large | 12,000 | 340 MB/s | Small production |
| db.r6g.xlarge | 20,000 | 680 MB/s | Medium production |
| db.r6g.4xlarge | 40,000 | 1,360 MB/s | Large production |
| db.r6g.16xlarge | 80,000 | 2,720 MB/s | High-performance |
| io2 Block Express | 256,000 | 4,000 MB/s | Extreme |

## Scaling Decision Framework

### When to Scale Up (Vertical)
- CPU consistently > 70% utilization
- Memory pressure (cache hit ratio < 95%)
- Simple architecture, single-primary workload
- Cost of downtime for migration > cost of larger instance

### When to Add Read Replicas
- Read/write ratio > 80/20
- Reporting queries competing with OLTP
- Geographic read latency requirements
- Predictable read scaling needs

### When to Shard (Horizontal)
- Write throughput exceeds single node capacity
- Dataset size exceeds single node storage/memory
- Require geographic data distribution
- **Sharding triggers**: > 1TB dataset, > 10K writes/sec, > 80% CPU sustained

### Scaling Decision Matrix

| Signal | Scale Up | Read Replica | Shard |
|--------|----------|-------------|-------|
| CPU high, reads heavy | Maybe | **Yes** | No |
| CPU high, writes heavy | **Yes** | No | Maybe |
| Memory pressure | **Yes** | No | No |
| Storage full | **Yes** | No | **Yes** |
| Read latency high | Maybe | **Yes** | No |
| Write latency high | **Yes** | No | **Yes** |
| Global distribution needed | No | **Yes** (multi-region) | **Yes** |

## Load Testing Tools

| Tool | Target | Workload Type |
|------|--------|---------------|
| **pgbench** | PostgreSQL | TPC-B (simple transactions) |
| **sysbench** | MySQL, PostgreSQL | OLTP read/write/mixed, custom Lua |
| **YCSB** | Any (NoSQL focus) | Configurable read/write/scan mix |
| **HammerDB** | Oracle, SQL Server, MySQL, PG | TPC-C, TPC-H |
| **redis-benchmark** | Redis | GET/SET/LPUSH/pipeline |
| **mongoshell benchmark** | MongoDB | Custom operations |
| **cassandra-stress** | Cassandra | Configurable read/write |

### pgbench Example
```bash
# Initialize benchmark tables
pgbench -i -s 100 mydb  # scale factor 100 = ~1.5 GB data

# Run benchmark (4 clients, 2 threads, 60 seconds)
pgbench -c 4 -j 2 -T 60 -P 5 mydb
# -P 5: report progress every 5 seconds
# Output: TPS, latency average, stddev

# Custom script
pgbench -c 10 -j 2 -T 120 -f custom_workload.sql mydb
```

### sysbench Example
```bash
# Prepare
sysbench oltp_read_write --mysql-host=db --mysql-db=test --tables=10 --table-size=100000 prepare

# Run
sysbench oltp_read_write --mysql-host=db --mysql-db=test --tables=10 --table-size=100000 \
    --threads=16 --time=300 --report-interval=5 run

# Cleanup
sysbench oltp_read_write --mysql-host=db --mysql-db=test cleanup
```

## Cost Estimation

### Cloud Database Monthly Cost Estimate
```
RDS PostgreSQL (db.r6g.xlarge, Multi-AZ):
  Instance: $0.48/hr × 730 hrs = $350/mo
  Multi-AZ: × 2 = $700/mo
  Storage (gp3, 500 GB): $0.08/GB × 500 = $40/mo
  Backup (100 GB beyond free): $0.095/GB × 100 = $9.50/mo
  Data transfer (100 GB inter-AZ): $0.01/GB × 100 = $1/mo
  Total: ~$750/mo

DynamoDB (On-Demand, 1M reads + 250K writes/day):
  Reads: 1M × $0.25/M = $0.25/day
  Writes: 250K × $1.25/M = $0.31/day
  Storage (50 GB): $0.25/GB = $12.50/mo
  Total: ~$30/mo
```

## Capacity Planning Checklist

1. **Estimate data volume**: Row size × growth rate × retention period
2. **Size memory**: Buffer pool/shared_buffers based on working set size
3. **Size connections**: Pool size × instances + admin reserve
4. **Estimate IOPS**: Based on write throughput and read pattern
5. **Plan storage**: Data + indexes + WAL + bloat + 2x safety margin
6. **Load test**: Use pgbench/sysbench/YCSB with realistic workload
7. **Set alerts**: CPU, memory, disk, connections, latency thresholds
8. **Review quarterly**: Compare actual vs predicted growth
