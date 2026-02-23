---
name: replication-ha
description: |
  High availability and replication topologies across all database engines. Synchronous/asynchronous/semi-synchronous replication, primary-secondary, multi-primary, quorum-based. PostgreSQL streaming/logical replication, MySQL GTID/Group Replication, MongoDB replica sets, Redis Sentinel/Cluster, Cassandra multi-DC. Consensus protocols (Raft, Paxos, Gossip). Failover automation, split-brain prevention. Use when designing HA architectures, configuring replication, or troubleshooting failover.
allowed-tools: Read, Grep, Glob, Bash
---

# Replication & High Availability

## Reference Files

Load from `references/` based on what's needed:

### references/engine-replication.md
Replication modes comparison (synchronous/semi-sync/async) with durability and latency tradeoffs.
PostgreSQL: streaming replication config, logical replication publications/subscriptions, replication slot warnings.
MySQL: GTID setup, semi-synchronous plugin config, Group Replication overview.
MongoDB: write concern levels, read preference options, replica set architecture.
Redis: Sentinel config (quorum, timeouts), Cluster mode hash slots overview.
Cassandra: NetworkTopologyStrategy, LOCAL_QUORUM vs EACH_QUORUM vs LOCAL_ONE.
Consensus protocols table (Raft, Paxos, Gossip, ISR).
Load when: configuring replication for a specific engine or choosing a topology.

### references/failover-monitoring.md
Failover types (automatic, manual, semi-automatic) and Patroni overview.
Split-brain prevention techniques (quorum, STONITH, watchdog, min replica count).
Topology reference (primary-secondary, multi-primary, quorum-based) with supported engines.
Replication monitoring metrics table with alert thresholds for all engines.
PostgreSQL replication lag queries (pg_stat_replication, pg_replication_slots).
MySQL SHOW REPLICA STATUS key fields.
Load when: setting up failover automation, monitoring replication health, or building incident runbooks.
