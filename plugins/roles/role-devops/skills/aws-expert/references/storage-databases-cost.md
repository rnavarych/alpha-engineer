# AWS Storage, Databases, Messaging, and Cost Optimization

## When to load
Load when working with S3, EBS, EFS, RDS, Aurora, DynamoDB, SQS/SNS/EventBridge,
Savings Plans, Reserved Instances, or Cost Explorer and governance tooling.

## Storage

### S3
- Enable **S3 Versioning** on all buckets that store important data. Enable **MFA Delete** on critical buckets.
- Use **S3 Lifecycle rules** to transition objects to cheaper storage classes (Intelligent-Tiering, Glacier Instant Retrieval, Glacier Deep Archive) and expire old versions.
- Enable **S3 Block Public Access** at the account level. Never allow public ACLs or public bucket policies unless explicitly required.
- Use **S3 Object Lock** (WORM) for compliance and audit logs that must be immutable for a defined retention period.
- Enable **S3 Server-Side Encryption (SSE-KMS)** with a CMK for data classification requirements. Use bucket policies to enforce encrypted uploads.
- Use **S3 Transfer Acceleration** for global upload acceleration. Use **S3 Batch Operations** for bulk object transformations.
- **S3 Event Notifications** to SQS, SNS, or Lambda for event-driven processing of new objects.
- Enable **S3 Server Access Logging** for audit trails.

### EBS and EFS
- Use **gp3** volumes by default for EBS. Baseline 3,000 IOPS and 125 MiB/s throughput at no extra cost. Provision additional IOPS/throughput as needed without upsizing volume.
- Enable **EBS encryption** by default at the account level.
- Use **EFS** for shared POSIX file systems across multiple EC2/ECS/EKS workloads. Enable EFS encryption at rest and in transit. Use **EFS Intelligent-Tiering** for cost optimization.
- **EFS Access Points** for namespace isolation between applications sharing the same file system.

## Databases

### RDS and Aurora
- Deploy RDS in **Multi-AZ** for production. Aurora is Multi-AZ by default with 6-copy replication across 3 AZs.
- Use **Aurora Serverless v2** for variable workloads that need instant scaling. Scales in fine-grained ACU increments.
- Enable **RDS Proxy** for connection pooling for Lambda and ECS workloads that create many short-lived connections. Proxy also handles failover transparently.
- Use **Performance Insights** and **Enhanced Monitoring** for RDS observability. Set up CloudWatch alarms on `DatabaseConnections`, `FreeStorageSpace`, `CPUUtilization`, and `ReadLatency`/`WriteLatency`.
- Enable **automated backups** with sufficient retention (7-35 days). Test restores regularly. Use **cross-region snapshots** for DR.
- Use **IAM database authentication** for RDS MySQL and PostgreSQL — eliminates static database passwords.
- Enable **DeletionProtection** on all production RDS instances.

### DynamoDB
- Design tables with access patterns first. Choose partition keys with high cardinality and even distribution to avoid hot partitions.
- Use **DynamoDB On-Demand** for unpredictable workloads. Use **Provisioned with Auto Scaling** for predictable workloads with cost savings.
- Use **Global Tables** for multi-region active-active replication.
- Enable **DynamoDB Streams** for change data capture and event-driven processing.
- Use **DynamoDB Accelerator (DAX)** for microsecond read latency for read-heavy workloads.
- Use **Conditional expressions** and **transaction operations** (`TransactWriteItems`) for atomic multi-item updates.
- Enable **Point-in-time recovery (PITR)** and **DynamoDB Backups** for all production tables.

## Messaging and Events

- Use **SQS** for decoupled asynchronous processing. Use **FIFO queues** when ordering and exactly-once processing are required.
- Configure **visibility timeout** to be greater than your consumer's max processing time to prevent duplicate processing.
- Always configure a **Dead Letter Queue** on SQS queues. Set `maxReceiveCount` based on expected transient failure scenarios.
- Use **Long Polling** (`WaitTimeSeconds: 20`) to reduce empty responses and lower cost.
- Use **SNS fan-out** to broadcast messages to multiple SQS queues, Lambda functions, or HTTP endpoints simultaneously.
- **EventBridge** for event-driven architectures with rich content-based routing rules, schema registry, and cross-account/cross-region event bus integration.
- Use **EventBridge Pipes** for point-to-point integrations with filtering and enrichment between source and target without custom code.

## Cost Optimization

### Savings Plans and Reserved Instances
- Use **Compute Savings Plans** (most flexible — covers EC2, Lambda, Fargate regardless of region, family, size, OS) for baseline commitment.
- Use **EC2 Instance Savings Plans** or **Reserved Instances** for predictable, single-region, single-family workloads for additional discount.
- Commit to 70-80% of your baseline compute with 1-year plans. Avoid over-committing — unused reservations still cost money.
- Use **Convertible Reserved Instances** for workloads where future instance type requirements are uncertain.

### Cost Visibility and Governance
- Enable **Cost Allocation Tags** and enforce tagging via SCPs or Config rules. Tag every resource with `team`, `environment`, `cost-center`, `service`.
- Use **AWS Cost Explorer** and **Cost and Usage Reports (CUR)** for granular cost analysis. Export CUR to S3 and query with Athena.
- Set up **AWS Budgets** with alerts for actual and forecasted spend per account and per team.
- Use **AWS Compute Optimizer** recommendations for right-sizing EC2, Lambda, EBS, and ECS/Fargate.
- Implement **Infracost** in Terraform pipelines to show cost deltas on every infrastructure PR.
- Schedule shutdown of non-production resources during off-hours with **AWS Instance Scheduler** or EventBridge + Lambda automation.
