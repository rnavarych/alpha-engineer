# Failover Automation, Split-Brain Prevention, and Replication Monitoring

## When to load
Load when setting up automated failover (Patroni, Sentinel, AG), preventing split-brain, monitoring replication lag across all engines, or building runbooks for failover drills.

## Failover Automation

### Failover Types
- **Automatic**: System detects failure, promotes replica (Sentinel, AG, Patroni)
- **Manual**: DBA triggers promotion (`pg_promote`, `CHANGE REPLICATION SOURCE`)
- **Semi-automatic**: System detects and alerts, human approves promotion

### PostgreSQL with Patroni
- DCS-backed (etcd/Consul/ZooKeeper) leader election
- Automatic failover with configurable policies
- REST API for health checks and switchover
- Integrates with HAProxy/PgBouncer for client routing

### Split-Brain Prevention
1. **Quorum requirement**: Majority of nodes must agree on leader
2. **Fencing (STONITH)**: Shoot The Other Node In The Head — stop old primary before promoting new one
3. **Watchdog timers**: Kernel-level process ensures node shutdown
4. **Minimum replica count**: Require N replicas before accepting writes

## Topologies Reference

### Primary-Secondary (Most Common)
- One writable primary, N read-only secondaries
- Failover requires promoting a secondary
- Engines: PostgreSQL, MySQL, MongoDB, Redis Sentinel, SQL Server AG

### Multi-Primary
- Multiple writable nodes, conflict resolution required
- Engines: MySQL Group Replication, Galera Cluster, CockroachDB, YugabyteDB, Cassandra

### Quorum-Based
- Write requires majority acknowledgment (W > N/2)
- Read consistency: R + W > N
- Engines: MongoDB replica sets, Cassandra (tunable), etcd (Raft)

## Replication Monitoring

### Key Metrics and Alert Thresholds

| Metric | Engine | How to Check | Alert Threshold |
|--------|--------|-------------|-----------------|
| Replication lag | PostgreSQL | `pg_stat_replication.replay_lag` | > 30 seconds |
| Replication lag | MySQL | `Seconds_Behind_Source` | > 30 seconds |
| Replication lag | MongoDB | `rs.printReplicationInfo()` | > 10 seconds |
| Replication lag | Redis | `INFO replication → master_last_io_seconds_ago` | > 10 seconds |
| WAL slot lag | PostgreSQL | `pg_replication_slots.confirmed_flush_lsn` | > 1 GB |
| ISR count | Kafka | `UnderReplicatedPartitions` | < replication factor |
| Replica state | All | replica connected and applying | Not in sync |

### PostgreSQL Replication Queries
```sql
-- Check streaming replication status
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
       write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

-- Check replication slot lag
SELECT slot_name, active, pg_size_pretty(
    pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)
) AS lag_size
FROM pg_replication_slots;
```

### MySQL Replication Status
```sql
SHOW REPLICA STATUS\G
-- Key fields: Replica_IO_Running, Replica_SQL_Running, Seconds_Behind_Source
-- Seconds_Behind_Source = NULL means replication is broken
```

## Quick Reference

1. **Default choice**: Async replication with promotion for read scaling + DR
2. **Financial/compliance**: Synchronous replication with RPO=0
3. **Global distribution**: Multi-region with local reads, cross-region async writes
4. **Always test failover**: Schedule regular failover drills in staging
5. **Monitor replication lag**: Alert before lag exceeds business RPO
6. **Document runbooks**: Step-by-step failover procedures for on-call engineers
