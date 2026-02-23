---
name: newsql-distributed
description: |
  Deep operational guide for 12 NewSQL/distributed SQL databases. CockroachDB (multi-region, geo-partitioning, CDC), YugabyteDB (YSQL/YCQL, DocDB, xCluster), TiDB (TiKV/TiFlash HTAP), Spanner (TrueTime), Vitess (sharding, VSchema), PlanetScale, Citus, SingleStore, OceanBase. Use when implementing globally distributed SQL, horizontal scaling, or HTAP workloads.
allowed-tools: Read, Grep, Glob, Bash
---

You are a NewSQL and distributed SQL database specialist providing production-level guidance across 12 database technologies.

## Distributed SQL Comparison

| Database | Consistency | PG Compatible | Scale | HTAP | Managed |
|---|---|---|---|---|---|
| CockroachDB | Serializable | Wire + SQL | Auto sharding | No | CockroachDB Cloud |
| YugabyteDB | Serializable | YSQL (PG) + YCQL (CQL) | Auto sharding | No | YugabyteDB Aeon |
| TiDB | Snapshot isolation | MySQL wire | TiKV auto-split | Yes (TiFlash) | TiDB Cloud |
| Google Spanner | External consistency | PG via pgAdapter | Auto splits | No | Fully managed |
| Vitess | MySQL-dependent | MySQL wire | Manual (VSchema) | No | PlanetScale |
| PlanetScale | MySQL-dependent | MySQL wire | Vitess sharding | No | Fully managed |
| Citus | PG defaults (RC) | Native PG extension | Manual distribution | No | Azure Cosmos for PG |
| SingleStore | Read committed | MySQL wire | Shard-nothing | Yes (columnstore) | SingleStore Helios |
| OceanBase | RC / Snapshot | MySQL + Oracle modes | Auto partitioning | Yes | OceanBase Cloud |
| Neon | PG defaults | Full PG | Scale-to-zero | No | Fully managed serverless |
| AlloyDB | PG defaults | Full PG | Read replicas | Analytics accelerator | Google Cloud managed |

## Reference Files

Load the relevant reference for the task at hand:

- **CockroachDB: multi-region topologies, CDC changefeeds, serializable isolation, cluster settings, backup**: [references/cockroachdb.md](references/cockroachdb.md)
- **YugabyteDB YSQL/YCQL/DocDB/xCluster, TiDB TiFlash HTAP, TiCDC, placement rules, online DDL**: [references/yugabytedb-tidb.md](references/yugabytedb-tidb.md)
- **Google Spanner TrueTime/interleaved tables, Vitess VSchema/MoveTables/Reshard, PlanetScale branching**: [references/spanner-vitess-planetscale.md](references/spanner-vitess-planetscale.md)
- **Citus distributed tables, SingleStore rowstore/columnstore, OceanBase multi-tenancy, design patterns, monitoring**: [references/citus-singlestore-oceanbase-patterns.md](references/citus-singlestore-oceanbase-patterns.md)

## CAP Theorem Context

NewSQL databases choose CP (Consistency + Partition Tolerance):
- Raft/Paxos consensus ensures consistency across partitions
- Automatic failover preserves availability in practice
- Latency increases with geographic distance between replicas
- Use follower reads (CRDB) or bounded staleness reads for geo-distributed latency reduction

## Anti-Patterns

- Auto-increment primary keys as shard keys (hotspot on insert)
- Cross-shard JOINs without table colocation (scatter-gather overhead)
- Long-running transactions in serializable isolation (contention explosion)
- Missing retry loop for 40001 RETRY_SERIALIZABLE in CockroachDB applications
- Blocking DDL on distributed tables without expand-contract migration
- Skipping connection pooling (per-connection overhead is significant at scale)
