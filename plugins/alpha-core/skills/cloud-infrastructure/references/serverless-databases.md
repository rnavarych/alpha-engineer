# Serverless Functions, Managed Databases, and Storage

## When to load
Load when comparing Lambda/Cloud Functions/Azure Functions, choosing managed relational or NoSQL databases, configuring object storage tiers, or setting up lifecycle policies.

## Function-as-a-Service Comparison

| Feature | Lambda (AWS) | Cloud Functions (GCP) | Azure Functions |
|---------|-------------|----------------------|-----------------|
| **Max execution** | 15 min | 60 min (2nd gen) | 10 min (consumption), unlimited (premium) |
| **Memory** | 128 MB - 10 GB | 128 MB - 32 GB | 1.5 GB (consumption), 14 GB (premium) |
| **Cold start** | 100ms - 5s (language-dependent) | 100ms - 10s | 100ms - 10s |
| **Concurrency** | 1000 default (requestable) | 1000 per region | 200 per instance |
| **Container support** | Yes (up to 10 GB image) | Yes (Cloud Run) | Yes (custom handlers) |
| **Pricing (per million)** | $0.20 | $0.40 | $0.20 |
| **Event sources** | 200+ (API Gateway, S3, SQS, EventBridge) | Pub/Sub, Cloud Storage, HTTP, Eventarc | HTTP, Timer, Queue, Blob, Cosmos DB, Event Grid |
| **Local development** | SAM CLI, LocalStack | Functions Framework | Azure Functions Core Tools |

### Cold Start Mitigation

- **Provisioned concurrency** (Lambda): Pre-warm instances, pay for idle capacity
- **Min instances** (Cloud Functions 2nd gen, Cloud Run): Keep N instances warm
- **Premium plan** (Azure Functions): Pre-warmed workers, VNET integration, no cold start
- **SnapStart** (Lambda, Java): Snapshot/restore of initialized runtime — Java cold starts from 5s to <200ms
- General: Smaller deployment packages, fewer dependencies, lazy initialization, use compiled languages (Go, Rust)

## Managed Relational Databases

| Feature | RDS/Aurora (AWS) | Cloud SQL/AlloyDB (GCP) | Azure SQL |
|---------|-----------------|------------------------|-----------|
| **Engines** | PostgreSQL, MySQL, MariaDB, Oracle, SQL Server | PostgreSQL, MySQL, SQL Server | SQL Server, PostgreSQL, MySQL |
| **Serverless** | Aurora Serverless v2 (auto-scale ACUs) | AlloyDB Omni | Azure SQL Serverless (auto-pause) |
| **Max storage** | 128 TB (Aurora), 64 TB (RDS) | 128 TB (AlloyDB), 64 TB (Cloud SQL) | 100 TB (Hyperscale) |
| **HA** | Multi-AZ, Aurora Global Database | Regional HA, cross-region replicas | Zone-redundant, geo-replication |
| **Read replicas** | 15 (Aurora), 5 (RDS) | 10 (Cloud SQL) | 4 geo-replicas (Hyperscale: 30) |
| **Monthly estimate** | ~$280 (db.m6g.xlarge, 4vCPU/16GB) | ~$230 (db-custom-4-16384) | ~$330 (GP_Gen5_4) |

## Managed NoSQL Databases

| Feature | DynamoDB (AWS) | Firestore (GCP) | Cosmos DB (Azure) |
|---------|---------------|-----------------|-------------------|
| **Model** | Key-value + document | Document | Multi-model (doc, KV, graph, columnar, table) |
| **Consistency** | Eventually + strong per-item | Strong (single-region) | 5 consistency levels |
| **Pricing** | On-demand or provisioned RCU/WCU | Per read/write/delete | RU/s (provisioned or serverless) |
| **Global** | Global Tables (active-active) | Multi-region (single-writer) | Multi-region write (turnkey) |
| **Max item** | 400 KB | 1 MB per document | 2 MB per document |
| **Transactions** | TransactWriteItems/TransactGetItems | Batched writes, transactions | ACID transactions per partition |

## Object Storage Tiers and Pricing

| Tier | S3 (AWS) | Cloud Storage (GCP) | Blob Storage (Azure) |
|------|----------|---------------------|----------------------|
| **Hot** | Standard — $0.023/GB | Standard — $0.020/GB | Hot — $0.018/GB |
| **Infrequent** | S3 IA — $0.0125/GB | Nearline (30-day min) — $0.010/GB | Cool (30-day min) — $0.010/GB |
| **Archive** | Glacier IR — $0.004/GB | Coldline (90d) — $0.004/GB | Cold (90d) — $0.002/GB |
| **Deep Archive** | Deep Archive — $0.00099/GB | Archive (365d) — $0.0012/GB | Archive — $0.00099/GB |
| **Intelligent** | Intelligent-Tiering (auto) | Autoclass (auto) | Lifecycle-based |
| **Egress** | $0.09/GB | $0.12/GB | $0.087/GB |

### S3 Lifecycle Rule Example

```json
{
  "Rules": [{
    "ID": "archive-old-logs",
    "Status": "Enabled",
    "Filter": { "Prefix": "logs/" },
    "Transitions": [
      { "Days": 30, "StorageClass": "STANDARD_IA" },
      { "Days": 90, "StorageClass": "GLACIER_IR" },
      { "Days": 365, "StorageClass": "DEEP_ARCHIVE" }
    ],
    "Expiration": { "Days": 730 }
  }]
}
```

## Cloud Services Quick Reference

| Category | AWS | GCP | Azure |
|----------|-----|-----|-------|
| VMs | EC2 | Compute Engine | Virtual Machines |
| PaaS | Elastic Beanstalk | App Engine | App Service |
| Queue | SQS | Cloud Tasks | Queue Storage |
| Pub/Sub | SNS | Pub/Sub | Service Bus |
| Streaming | Kinesis | Dataflow | Event Hubs |
| CDN | CloudFront | Cloud CDN | Azure CDN |
| DNS | Route 53 | Cloud DNS | Azure DNS |
| Load Balancer | ALB/NLB | Cloud LB | Azure LB |
| IAM | IAM | Cloud IAM | Entra ID |
| Secrets | Secrets Manager | Secret Manager | Key Vault |
| KMS | KMS | Cloud KMS | Key Vault |
| WAF | WAF | Cloud Armor | Azure WAF |
| Monitoring | CloudWatch | Cloud Monitoring | Azure Monitor |
| Tracing | X-Ray | Cloud Trace | App Insights |
| ML Platform | SageMaker | Vertex AI | Azure ML |
| Foundation Models | Bedrock (multi-model) | Vertex AI (Gemini) | Azure OpenAI |
| CI/CD Pipeline | CodePipeline + CodeBuild | Cloud Build | Azure Pipelines |
| Data Warehouse | Redshift | BigQuery | Synapse Analytics |
