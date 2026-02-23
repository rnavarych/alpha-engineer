# Backup Verification, Cloud-Native Backup, and Disaster Recovery

## When to load
Load when implementing automated restore testing, setting up cloud-native backup services (AWS Backup, Cloud SQL, Atlas), choosing disaster recovery patterns (backup/restore, warm standby, multi-site active), or reviewing backup anti-patterns.

## Backup Verification

### Automated Restore Testing Script
```bash
#!/bin/bash
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

## Cloud-Native Backup Services

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
| **Pilot Light** | Minutes | 30–60 min | Medium | Minimal standby, scale up on failover |
| **Warm Standby** | Seconds | Minutes | High | Scaled-down replica, promote on failover |
| **Multi-Site Active** | Zero | Near-zero | Highest | Active-active across regions |

## Anti-Patterns

### Untested Backups
- **Problem**: Backup jobs succeed but restore has never been tested
- **Fix**: Schedule monthly restore tests to isolated environment

### No Encryption
- **Problem**: Backup files stored unencrypted on shared storage
- **Fix**: Encrypt at rest (pgBackRest cipher, XtraBackup encryption, AWS KMS)

### Single-Region Backups
- **Problem**: Backups in same region as primary — regional outage loses both
- **Fix**: Cross-region replication (S3 cross-region, GCS multi-region)

### No Retention Policy
- **Problem**: Infinite retention consuming storage, or too-short missing compliance needs
- **Fix**: Define retention: 7 daily + 4 weekly + 12 monthly + N yearly (adjust per compliance)
