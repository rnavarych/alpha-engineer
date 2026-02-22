---
name: backup-recovery
description: |
  Backup strategies and disaster recovery across all database engines. Full, incremental, differential backups. PITR (Point-in-Time Recovery). PostgreSQL (pg_dump, pgBackRest, Barman, WAL archiving), MySQL (mysqldump, XtraBackup, Clone Plugin), MongoDB (mongodump, Atlas backup), Redis (RDB, AOF). RPO/RTO planning, backup verification, cloud-native backup. Use when designing backup strategies, implementing disaster recovery, or troubleshooting data recovery.
allowed-tools: Read, Grep, Glob, Bash
---

# Backup & Recovery

## Backup Types

| Type | Description | Speed (Backup) | Speed (Restore) | Storage |
|------|-------------|-----------------|------------------|---------|
| **Full** | Complete copy of all data | Slowest | Fastest | Largest |
| **Incremental** | Only changes since last backup (any type) | Fastest | Slowest (needs chain) | Smallest |
| **Differential** | Changes since last full backup | Medium | Medium (needs full + diff) | Medium |
| **Continuous (WAL/Oplog)** | Transaction log shipping | Continuous | Depends on base + replay | Variable |

## RPO/RTO Planning

| Tier | RPO | RTO | Strategy |
|------|-----|-----|----------|
| **Critical** (financial, healthcare) | < 1 minute | < 15 minutes | Sync replication + WAL archiving + hot standby |
| **Important** (e-commerce, SaaS) | < 1 hour | < 1 hour | Async replication + incremental + PITR |
| **Standard** (internal tools) | < 24 hours | < 4 hours | Daily full + WAL/binlog |
| **Archive** (logs, analytics) | < 1 week | < 24 hours | Weekly full backup |

## Engine-Specific Backup

### PostgreSQL

**pg_dump (Logical Backup)**
```bash
# Custom format (compressed, parallel restore)
pg_dump -Fc -j 4 -d mydb -f mydb.dump

# Restore
pg_restore -d mydb -j 4 --clean --if-exists mydb.dump

# Specific tables
pg_dump -Fc -t orders -t customers -d mydb -f partial.dump
```

**pg_basebackup (Physical Backup)**
```bash
# Full physical backup with WAL
pg_basebackup -h primary -D /backup/base -Ft -z -Xs -P

# With replication slot (prevents WAL removal during backup)
pg_basebackup -h primary -D /backup/base -S backup_slot -Xs -P
```

**pgBackRest (Production-Grade)**
```ini
# /etc/pgbackrest/pgbackrest.conf
[main]
pg1-path=/var/lib/postgresql/16/main
repo1-path=/backup/pgbackrest
repo1-retention-full=2
repo1-retention-diff=7
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=secret

# Full backup
pgbackrest --stanza=main backup --type=full
# Differential
pgbackrest --stanza=main backup --type=diff
# Incremental
pgbackrest --stanza=main backup --type=incr

# PITR restore to specific time
pgbackrest --stanza=main restore --target='2024-01-15 14:30:00' --target-action=promote
```

**Barman (Backup and Recovery Manager)**
```bash
# Continuous WAL archiving + periodic base backups
barman backup main
barman recover --target-time "2024-01-15 14:30:00" main latest /restore/path
```

### MySQL

**mysqldump (Logical)**
```bash
# Full database with single transaction (InnoDB consistent snapshot)
mysqldump --single-transaction --routines --triggers --events -u root -p mydb > backup.sql

# All databases
mysqldump --single-transaction --all-databases --source-data=2 > full_backup.sql
```

**Percona XtraBackup (Physical, Hot)**
```bash
# Full backup (no locking for InnoDB)
xtrabackup --backup --target-dir=/backup/full --user=root --password=pass

# Incremental
xtrabackup --backup --target-dir=/backup/incr1 --incremental-basedir=/backup/full

# Prepare and restore
xtrabackup --prepare --target-dir=/backup/full
xtrabackup --prepare --target-dir=/backup/full --incremental-dir=/backup/incr1
xtrabackup --copy-back --target-dir=/backup/full
```

**MySQL Shell Dump/Load (Parallel, Cloud-Ready)**
```javascript
// Dump (parallel, compressed, cloud storage support)
util.dumpInstance("/backup/full", { threads: 4, compression: "zstd" });
util.dumpSchemas(["mydb"], "/backup/schema", { threads: 4 });

// Load
util.loadDump("/backup/full", { threads: 4, progressFile: "load_progress" });
```

### MongoDB

**mongodump/mongorestore**
```bash
# Full backup with oplog for PITR
mongodump --uri="mongodb+srv://..." --oplog --gzip --out=/backup/full

# Restore with oplog replay to specific timestamp
mongorestore --uri="mongodb+srv://..." --oplogReplay --oplogLimit="1705312200:1" --gzip /backup/full
```

**Atlas Backup**
- Continuous backup with PITR (configurable retention)
- Snapshot-based backup (daily, weekly, monthly retention)
- Cloud provider snapshots (EBS, GCP persistent disk)
- Restore to same cluster, different cluster, or download

**Filesystem Snapshots**
```bash
# Lock writes, take LVM/EBS snapshot, unlock
mongosh --eval "db.fsyncLock()"
# Take snapshot...
mongosh --eval "db.fsyncUnlock()"
```

### Redis

**RDB Snapshots**
```
# redis.conf
save 900 1      # Save if 1 key changed in 900 seconds
save 300 10     # Save if 10 keys changed in 300 seconds
save 60 10000   # Save if 10000 keys changed in 60 seconds
dbfilename dump.rdb
```

**AOF (Append-Only File)**
```
# redis.conf
appendonly yes
appendfsync everysec   # Options: always (safest), everysec (recommended), no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

**Hybrid (RDB + AOF) — Recommended for Production**
```
aof-use-rdb-preamble yes  # Redis 4.0+: RDB header + AOF tail for fast load + durability
```

## Backup Verification

### Automated Restore Testing
```bash
#!/bin/bash
# Weekly restore verification script
DATE=$(date +%Y%m%d)

# 1. Restore to test instance
pg_restore -d test_restore -j 4 --clean /backup/latest.dump

# 2. Run integrity checks
psql -d test_restore -c "SELECT count(*) FROM orders;" > /tmp/verify_${DATE}.log
psql -d test_restore -c "SELECT pg_database_size('test_restore');" >> /tmp/verify_${DATE}.log

# 3. Compare row counts with production
PROD_COUNT=$(psql -d production -t -c "SELECT count(*) FROM orders;")
TEST_COUNT=$(psql -d test_restore -t -c "SELECT count(*) FROM orders;")

if [ "$PROD_COUNT" -ne "$TEST_COUNT" ]; then
    echo "ALERT: Row count mismatch! Prod: $PROD_COUNT, Backup: $TEST_COUNT"
    # Send alert...
fi

# 4. Drop test database
dropdb test_restore
```

### Backup Monitoring Checklist
- Backup job success/failure alerts
- Backup size trending (sudden changes = potential issues)
- Backup duration monitoring (increasing = growing data)
- WAL/oplog archiving lag
- Disk space on backup storage
- Restore time estimation (track actual restore durations)

## Cloud-Native Backup

| Service | Provider | Features |
|---------|----------|----------|
| **AWS Backup** | AWS | Centralized, cross-service, cross-region, Vault Lock |
| **Cloud SQL Backup** | GCP | Automated, on-demand, PITR, cross-region |
| **Azure Backup** | Azure | Geo-redundant, long-term retention, soft delete |
| **Atlas Backup** | MongoDB | Continuous PITR, snapshots, download |

## Disaster Recovery Patterns

| Pattern | RPO | RTO | Cost | Description |
|---------|-----|-----|------|-------------|
| **Backup & Restore** | Hours | Hours | Low | Restore from backup storage |
| **Pilot Light** | Minutes | 30-60 min | Medium | Minimal standby, scale up on failover |
| **Warm Standby** | Seconds | Minutes | High | Scaled-down replica, promote on failover |
| **Multi-Site Active** | Zero | Near-zero | Highest | Active-active across regions |

## Anti-Patterns

### Untested Backups
- **Problem**: Backup jobs run successfully but restore has never been tested
- **Fix**: Schedule monthly restore tests to isolated environment

### No Encryption
- **Problem**: Backup files stored unencrypted on shared storage
- **Fix**: Encrypt at rest (pgBackRest cipher, XtraBackup encryption, AWS KMS)

### Single-Region Backups
- **Problem**: Backups in same region as primary — regional outage loses both
- **Fix**: Cross-region replication for backup storage (S3 cross-region, GCS multi-region)

### No Retention Policy
- **Problem**: Infinite retention consuming storage, or too-short retention missing compliance needs
- **Fix**: Define retention: 7 daily + 4 weekly + 12 monthly + N yearly (adjust per compliance)
