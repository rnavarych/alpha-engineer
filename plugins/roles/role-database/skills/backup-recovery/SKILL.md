---
name: role-database:backup-recovery
description: |
  Backup strategies and disaster recovery across all database engines. Full, incremental, differential backups. PITR (Point-in-Time Recovery). PostgreSQL (pg_dump, pgBackRest, Barman, WAL archiving), MySQL (mysqldump, XtraBackup, Clone Plugin), MongoDB (mongodump, Atlas backup), Redis (RDB, AOF). RPO/RTO planning, backup verification, cloud-native backup. Use when designing backup strategies, implementing disaster recovery, or troubleshooting data recovery.
allowed-tools: Read, Grep, Glob, Bash
---

# Backup & Recovery

## Reference Files

Load from `references/` based on what's needed:

### references/engine-backup.md
Backup types comparison (full/incremental/differential/continuous) with speed and storage tradeoffs.
RPO/RTO planning tiers (critical/important/standard/archive) with strategies.
PostgreSQL: pg_dump, pg_basebackup, pgBackRest config and commands, Barman.
MySQL: mysqldump, XtraBackup (full + incremental + prepare + restore), MySQL Shell dump/load.
MongoDB: mongodump with oplog, mongorestore with oplog replay, fsync lock for snapshots.
Redis: RDB config, AOF config, hybrid mode recommendation.
Load when: implementing backup for a specific database engine.

### references/verification-dr.md
Automated restore testing bash script with row count comparison and alerting.
Backup monitoring checklist (job alerts, size trends, WAL lag, disk space).
Cloud-native backup services table (AWS Backup, Cloud SQL, Azure Backup, Atlas).
Disaster recovery patterns comparison (backup/restore, pilot light, warm standby, multi-site active).
Anti-patterns: untested backups, no encryption, single-region storage, missing retention policy.
Load when: setting up backup verification, choosing DR patterns, or reviewing backup compliance.
