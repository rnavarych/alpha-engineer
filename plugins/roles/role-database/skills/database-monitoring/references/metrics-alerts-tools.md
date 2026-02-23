# Key Metrics, Alert Thresholds, and Monitoring Tools

## When to load
Load when defining what metrics to track, setting alert thresholds, choosing monitoring tools (Datadog, PMM, pganalyze, Grafana), configuring Prometheus exporters, or building a minimum viable database dashboard.

## Key Metrics by Category

### Connection Metrics
| Metric | Alert Threshold |
|--------|-----------------|
| Active connections | > 80% of max_connections |
| Idle connections | > 50% of pool |
| Waiting connections | > 0 sustained |
| Connection errors | Any increase |

### Query Performance Metrics
| Metric | Alert |
|--------|-------|
| Slow queries | Increasing trend |
| Query latency p95/p99 | > 500ms (OLTP) |
| Long-running queries | > 30 seconds |

### Storage and Replication Metrics
| Metric | Alert Threshold |
|--------|-----------------|
| Disk usage | > 80% capacity |
| Disk I/O utilization | > 80% sustained |
| Table bloat (PostgreSQL) | > 50% dead tuples |
| Replication lag | > 30 seconds |
| Replication slot lag | > 1 GB unprocessed WAL |
| ISR count (Kafka) | < replication factor |

### Cache Metrics
| Metric | Alert |
|--------|-------|
| Cache hit ratio (all engines) | < 95% |
| Memory usage | > 90% |
| Evictions | Increasing |

## Alert Tiers

### Critical — Page Immediately
- Database unreachable / connection refused
- Replication broken (replica not streaming)
- Disk space > 90%
- Deadlock rate increasing
- Backup job failed

### Warning — Investigate During Business Hours
- Replication lag > 30 seconds
- Cache hit ratio < 95%
- Connection count > 80% of max
- Slow query rate increasing > 20% from baseline
- Table bloat > 50% dead tuples
- Long-running queries > 5 minutes

### Informational — Dashboard Only
- Query latency p50/p95/p99 trends
- Throughput (QPS) trends
- Storage growth rate
- Index usage statistics

## Monitoring Tools

| Tool | Type | Best For | Cost |
|------|------|----------|------|
| **Datadog Database Monitoring** | SaaS | Multi-engine, query-level insights | Per host |
| **Percona PMM** | Open source | MySQL, PostgreSQL, MongoDB | Free |
| **pganalyze** | SaaS | PostgreSQL deep analysis | Per database |
| **New Relic Database** | SaaS | Multi-engine, APM integration | Per host |
| **Prometheus + Grafana** | Open source | Custom metrics, alerting | Free |
| **pg_stat_monitor** | Extension | PostgreSQL (Percona) | Free |
| **Zabbix** | Open source | Infrastructure + database | Free |

### Prometheus Exporters
```yaml
# PostgreSQL
- postgres_exporter (prometheus-community)
  # Key: pg_stat_activity, pg_stat_statements, replication lag

# MySQL
- mysqld_exporter (prometheus-community)
  # Key: mysql_global_status, mysql_slave_status

# MongoDB
- mongodb_exporter (percona)
  # Key: mongodb_mongod_op_counters, mongodb_connections

# Redis
- redis_exporter (oliver006)
  # Key: redis_connected_clients, redis_memory_used_bytes
```

## Minimum Viable Database Dashboard

1. **Connection pool utilization** — are we running out of connections?
2. **Query latency distribution** (p50/p95/p99) — are queries getting slower?
3. **Error rate** — are queries failing?
4. **Replication lag** — is data consistent across replicas?
5. **Disk usage and growth** — when do we need more storage?
6. **Cache hit ratio** — is our buffer/cache working effectively?
7. **Top N slow queries** — what should we optimize?
8. **Lock waits** — are there contention issues?
