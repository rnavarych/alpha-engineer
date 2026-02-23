# Engine-Specific Backup and Recovery

## When to load
Load when implementing backup strategies for PostgreSQL (pg_dump, pgBackRest, Barman, pg_basebackup), MySQL (mysqldump, XtraBackup, MySQL Shell), MongoDB (mongodump, Atlas), or Redis (RDB, AOF, hybrid).

## Backup Types

| Type | Speed (Backup) | Speed (Restore) | Storage |
|------|-----------------|------------------|---------|
| **Full** | Slowest | Fastest | Largest |
| **Incremental** | Fastest | Slowest (needs chain) | Smallest |
| **Differential** | Medium | Medium (full + diff) | Medium |
| **Continuous (WAL/Oplog)** | Continuous | Depends on base + replay | Variable |

## RPO/RTO Planning

| Tier | RPO | RTO | Strategy |
|------|-----|-----|----------|
| **Critical** (financial, healthcare) | < 1 minute | < 15 minutes | Sync replication + WAL archiving + hot standby |
| **Important** (e-commerce, SaaS) | < 1 hour | < 1 hour | Async replication + incremental + PITR |
| **Standard** (internal tools) | < 24 hours | < 4 hours | Daily full + WAL/binlog |
| **Archive** (logs, analytics) | < 1 week | < 24 hours | Weekly full backup |

## PostgreSQL

### pg_dump and pg_basebackup
```bash
# Logical backup (custom format, parallel restore)
pg_dump -Fc -j 4 -d mydb -f mydb.dump
pg_restore -d mydb -j 4 --clean --if-exists mydb.dump

# Specific tables
pg_dump -Fc -t orders -t customers -d mydb -f partial.dump

# Physical backup with WAL
pg_basebackup -h primary -D /backup/base -Ft -z -Xs -P
pg_basebackup -h primary -D /backup/base -S backup_slot -Xs -P
```

### pgBackRest (Production-Grade)
```ini
# /etc/pgbackrest/pgbackrest.conf
[main]
pg1-path=/var/lib/postgresql/16/main
repo1-path=/backup/pgbackrest
repo1-retention-full=2
repo1-retention-diff=7
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=secret
```

```bash
pgbackrest --stanza=main backup --type=full
pgbackrest --stanza=main backup --type=diff
pgbackrest --stanza=main backup --type=incr
pgbackrest --stanza=main restore --target='2024-01-15 14:30:00' --target-action=promote
```

### Barman
```bash
barman backup main
barman recover --target-time "2024-01-15 14:30:00" main latest /restore/path
```

## MySQL

```bash
# mysqldump (logical, consistent snapshot)
mysqldump --single-transaction --routines --triggers --events -u root -p mydb > backup.sql
mysqldump --single-transaction --all-databases --source-data=2 > full_backup.sql

# XtraBackup (physical, hot, no locking)
xtrabackup --backup --target-dir=/backup/full --user=root --password=pass
xtrabackup --backup --target-dir=/backup/incr1 --incremental-basedir=/backup/full
xtrabackup --prepare --target-dir=/backup/full
xtrabackup --prepare --target-dir=/backup/full --incremental-dir=/backup/incr1
xtrabackup --copy-back --target-dir=/backup/full
```

```javascript
// MySQL Shell dump/load (parallel, cloud-ready)
util.dumpInstance("/backup/full", { threads: 4, compression: "zstd" });
util.loadDump("/backup/full", { threads: 4, progressFile: "load_progress" });
```

## MongoDB

```bash
# Full backup with oplog for PITR
mongodump --uri="mongodb+srv://..." --oplog --gzip --out=/backup/full

# Restore with oplog replay to specific timestamp
mongorestore --uri="mongodb+srv://..." --oplogReplay \
    --oplogLimit="1705312200:1" --gzip /backup/full

# Filesystem snapshot (lock + snapshot + unlock)
mongosh --eval "db.fsyncLock()"
# Take LVM/EBS snapshot...
mongosh --eval "db.fsyncUnlock()"
```

## Redis

```
# RDB snapshots (redis.conf)
save 900 1      # 1 key changed in 900s
save 300 10     # 10 keys changed in 300s
save 60 10000   # 10000 keys changed in 60s

# AOF (Append-Only File)
appendonly yes
appendfsync everysec   # always (safest), everysec (recommended), no

# Hybrid (recommended for production, Redis 4.0+)
aof-use-rdb-preamble yes  # RDB header + AOF tail: fast load + durability
```
