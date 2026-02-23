# Load Testing and Cost Estimation

## When to load
Load when benchmarking database capacity with pgbench, sysbench, YCSB, or HammerDB, or when estimating monthly cloud database costs (RDS, DynamoDB).

## Load Testing Tools

| Tool | Target | Workload Type |
|------|--------|---------------|
| **pgbench** | PostgreSQL | TPC-B (simple transactions) |
| **sysbench** | MySQL, PostgreSQL | OLTP read/write/mixed, custom Lua |
| **YCSB** | Any (NoSQL focus) | Configurable read/write/scan mix |
| **HammerDB** | Oracle, SQL Server, MySQL, PG | TPC-C, TPC-H |
| **redis-benchmark** | Redis | GET/SET/LPUSH/pipeline |
| **cassandra-stress** | Cassandra | Configurable read/write |

### pgbench (PostgreSQL)
```bash
# Initialize benchmark tables (scale 100 ≈ 1.5 GB)
pgbench -i -s 100 mydb

# Run benchmark: 4 clients, 2 threads, 60 seconds, progress every 5s
pgbench -c 4 -j 2 -T 60 -P 5 mydb

# Custom script
pgbench -c 10 -j 2 -T 120 -f custom_workload.sql mydb
# Output: TPS, latency average, stddev
```

### sysbench (MySQL/PostgreSQL)
```bash
# Prepare
sysbench oltp_read_write \
    --mysql-host=db --mysql-db=test \
    --tables=10 --table-size=100000 prepare

# Run
sysbench oltp_read_write \
    --mysql-host=db --mysql-db=test \
    --tables=10 --table-size=100000 \
    --threads=16 --time=300 --report-interval=5 run

# Cleanup
sysbench oltp_read_write --mysql-host=db --mysql-db=test cleanup
```

## Cloud Cost Estimation

### RDS PostgreSQL
```
RDS PostgreSQL (db.r6g.xlarge, Multi-AZ):
  Instance: $0.48/hr × 730 hrs = $350/mo
  Multi-AZ: × 2 = $700/mo
  Storage (gp3, 500 GB): $0.08/GB × 500 = $40/mo
  Backup (100 GB beyond free): $0.095/GB × 100 = $9.50/mo
  Data transfer (100 GB inter-AZ): $0.01/GB × 100 = $1/mo
  Total: ~$750/mo
```

### DynamoDB On-Demand
```
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
