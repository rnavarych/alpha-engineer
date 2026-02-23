# Kubernetes Database Operators

## When to load
Load when managing databases on Kubernetes using operators (CloudNativePG, Percona, CrunchyData PGO, Vitess, Redis, Strimzi).

## CloudNativePG (PostgreSQL)

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: myapp-db
spec:
  instances: 3
  imageName: ghcr.io/cloudnative-pg/postgresql:16.2

  storage:
    size: 100Gi
    storageClass: gp3

  postgresql:
    parameters:
      shared_buffers: "4GB"
      effective_cache_size: "12GB"
      work_mem: "64MB"
      shared_preload_libraries: "pg_stat_statements"

  bootstrap:
    initdb:
      database: myapp
      owner: app

  backup:
    barmanObjectStore:
      destinationPath: "s3://myapp-backups/pg/"
      s3Credentials:
        accessKeyId:
          name: s3-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: s3-creds
          key: SECRET_ACCESS_KEY
    retentionPolicy: "14d"

  monitoring:
    enablePodMonitor: true

  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "16Gi"
```

## Operator Comparison

| Operator | Database | Key Features |
|----------|----------|-------------|
| **CrunchyData PGO** | PostgreSQL | Backup, HA, monitoring, connection pooling |
| **Percona Operator for PG** | PostgreSQL | pgBouncer, PMM monitoring |
| **Percona Operator for MySQL** | MySQL | Percona XtraDB Cluster, Group Replication |
| **Percona Operator for MongoDB** | MongoDB | Replica sets, sharding, backup |
| **Vitess Operator** | MySQL (Vitess) | Sharding, MoveTables, schema management |
| **Redis Operator** | Redis | Cluster, Sentinel, failover |
| **Strimzi** | Kafka | Cluster, topics, users, MirrorMaker |
| **MongoDB Community Operator** | MongoDB | Replica sets, basic management |
| **ClickHouse Operator** | ClickHouse | Cluster management, sharding |
