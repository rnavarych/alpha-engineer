# ScyllaDB — Shard-Per-Core, Alternator, CDC, Workload Prioritization, Kubernetes

## When to load
Load when deploying ScyllaDB, configuring shard-per-core tuning, using the DynamoDB-compatible Alternator API, setting up CDC (Change Data Capture), prioritizing workloads via Service Levels, or running the Kubernetes operator.

## Shard-Per-Core Architecture

ScyllaDB uses the Seastar framework: one thread per CPU core, no context switching, no locks, shared-nothing I/O. Each shard owns a portion of data and communicates via message passing. Result: predictable tail latency (p99 close to median), linear CPU scaling, 10x fewer nodes vs Cassandra for same workload.

```yaml
# scylla.yaml
smp: 0                          # 0 = use all cores
memory: "64G"                   # Fixed memory allocation (no swap)
overprovisioned: false          # true for shared cloud VMs
io-properties-file: /etc/scylla.d/io_properties.yaml
```

## Alternator (DynamoDB-Compatible API)

```yaml
# scylla.yaml
alternator_port: 8000
alternator_https_port: 8043
alternator_enforce_authorization: true
```

```bash
# Use standard AWS SDK against ScyllaDB endpoint
aws dynamodb --endpoint-url http://scylla-node:8000 \
  create-table \
  --table-name Users \
  --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=sk,AttributeType=S \
  --billing-mode PAY_PER_REQUEST
# Supports: GetItem, PutItem, Query, Scan, BatchGetItem, BatchWriteItem, GSI, LSI, Streams, TTL
```

## CDC (Change Data Capture)

```sql
ALTER TABLE ks.orders WITH cdc = {
  'enabled': true,
  'preimage': true,     -- Include old values
  'postimage': true,    -- Include new values
  'ttl': 86400          -- CDC log retention (1 day)
};

-- CDC log table: ks.orders_scylla_cdc_log
-- Operations: 0=pre-image, 1=update, 2=insert, 8=row-delete, 9=partition-delete
SELECT * FROM ks.orders_scylla_cdc_log
WHERE "cdc$stream_id" = ? AND "cdc$time" > ?;
```

## Workload Prioritization (Service Levels)

```sql
CREATE SERVICE LEVEL sl_realtime WITH shares = 1000;
CREATE SERVICE LEVEL sl_analytics WITH shares = 100;
CREATE SERVICE LEVEL sl_batch WITH shares = 10;

ATTACH SERVICE LEVEL sl_realtime TO role_web_app;
ATTACH SERVICE LEVEL sl_analytics TO role_dashboard;
ATTACH SERVICE LEVEL sl_batch TO role_etl;
-- Under contention: realtime gets 10x resources vs analytics
```

## ScyllaDB Manager

```bash
sctool repair --cluster production --keyspace ecommerce --intensity 1.0 --parallel 0
sctool backup --cluster production --location s3://my-bucket/scylladb-backup --retention 7
sctool repair --cluster production --keyspace ecommerce --interval 7d --start-date 2024-03-15T02:00:00Z
sctool task list --cluster production
```

## Kubernetes Operator

```yaml
apiVersion: scylla.scylladb.com/v1
kind: ScyllaCluster
metadata:
  name: production
spec:
  version: 5.4.0
  agentVersion: 3.2.0
  developerMode: false
  datacenter:
    name: us-east-1
    racks:
      - name: us-east-1a
        members: 3
        storage:
          capacity: 500Gi
          storageClassName: gp3
        resources:
          requests: { cpu: 8, memory: 64Gi }
          limits: { cpu: 8, memory: 64Gi }
```

## Key Metrics (Prometheus)

```
scylla_storage_proxy_coordinator_write_latency
scylla_storage_proxy_coordinator_read_latency
scylla_transport_requests_served
scylla_compaction_manager_compactions
scylla_cache_row_hits / scylla_cache_row_misses
scylla_scheduler_shares
```

## Cassandra to ScyllaDB Migration

| Metric | Cassandra | ScyllaDB |
|---|---|---|
| p99 read latency | 5-15ms | 1-3ms |
| p99 write latency | 3-10ms | 0.5-2ms |
| Throughput/node | 50K ops/s | 500K ops/s |
| Nodes for 1M ops/s | 20 | 2-3 |
| GC pauses | Yes (JVM) | None (C++) |

Migration paths: `sstableloader` (SSTable import), Spark Migrator, dual-write, or CDC-based. CQL schema is directly compatible; tune connection pool down (fewer connections per node needed).
