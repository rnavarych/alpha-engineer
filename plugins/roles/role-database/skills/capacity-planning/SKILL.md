---
name: capacity-planning
description: |
  Database capacity and growth planning. Storage growth estimation, IOPS requirements, memory sizing (buffer pool, shared_buffers), connection count estimation, sharding triggers, read replica scaling, cost estimation per cloud provider. Load testing (pgbench, sysbench, YCSB, HammerDB). When to shard vs scale up vs read replicas. Use when planning database capacity, sizing infrastructure, or evaluating scaling strategies.
allowed-tools: Read, Grep, Glob, Bash
---

# Capacity Planning

## Reference Files

Load from `references/` based on what's needed:

### references/sizing-scaling.md
Row size calculation queries (pg_column_size, bytes_per_row from pg_class).
Storage growth projection formula with worked example.
Memory sizing rules: PostgreSQL (shared_buffers, work_mem formula), MySQL (innodb_buffer_pool), MongoDB (WiredTiger cache), Redis (maxmemory).
IOPS estimation by workload type. AWS RDS IOPS reference table.
Scaling decision framework: when to scale up vs read replicas vs shard. Decision matrix.
Load when: sizing infrastructure, estimating growth, or choosing a scaling strategy.

### references/load-testing-cost.md
Load testing tool comparison (pgbench, sysbench, YCSB, HammerDB, cassandra-stress).
pgbench and sysbench command examples with key output metrics.
Cloud cost estimation examples for RDS PostgreSQL Multi-AZ and DynamoDB On-Demand.
Capacity planning checklist (8 steps).
Load when: benchmarking database capacity or estimating cloud infrastructure costs.
