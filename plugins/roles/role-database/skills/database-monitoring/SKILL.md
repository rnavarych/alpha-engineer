---
name: database-monitoring
description: |
  Database monitoring, alerting, and observability across all engines. PostgreSQL (pg_stat_statements, pg_stat_activity, pg_stat_user_tables), MySQL (Performance Schema, sys schema, slow query log), MongoDB (mongostat, mongotop, profiler), Redis (INFO, SLOWLOG, LATENCY). Monitoring tools (Datadog, PMM, pganalyze, Grafana). Key metrics, alert thresholds, dashboard templates. Use when setting up database monitoring, troubleshooting performance, or configuring alerting.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Monitoring

## Reference Files

Load from `references/` based on what's needed:

### references/engine-metrics.md
PostgreSQL: pg_stat_statements top queries, pg_stat_activity session view, pg_stat_user_tables bloat, table/index size queries.
MySQL: Performance Schema digest analysis, InnoDB status sections, sys schema helpers (full table scans, unused indexes).
MongoDB: serverStatus key sections, profiler setup and query, mongostat/mongotop commands.
Redis: INFO sections (memory, stats, replication, clients), SLOWLOG, LATENCY, bigkeys, memkeys.
Load when: running live diagnostic queries against a specific database engine.

### references/metrics-alerts-tools.md
Key metrics tables with alert thresholds for connections, query performance, storage, replication, and cache.
Three-tier alert classification (critical/warning/informational) with specific conditions.
Monitoring tool comparison (Datadog, PMM, pganalyze, Prometheus+Grafana, Zabbix).
Prometheus exporter list for all four engines.
Minimum viable database dashboard (8 panels).
Load when: setting up monitoring infrastructure, configuring alerts, or building dashboards.
