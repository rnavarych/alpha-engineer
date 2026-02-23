# AWS Data Architecture, Security, and Cost

## When to load
Load when selecting AWS databases (Aurora, DynamoDB, ElastiCache), designing analytics pipelines (Kinesis, Athena, Redshift), configuring security posture (GuardDuty, Security Hub, IAM), or optimizing costs with Savings Plans, Spot, Graviton, and data transfer strategies.

## Data Architecture

### Database Selection
- **Aurora**: Default choice for relational workloads on AWS. PostgreSQL or MySQL-compatible. Use Aurora Serverless v2 for variable workloads (scales in seconds). Use Aurora Global Database for cross-Region disaster recovery (< 1 second replication lag) and read scaling.
- **DynamoDB**: Single-digit millisecond performance at any scale. Design for single-table design with composite keys for efficient access patterns. Use DynamoDB Streams for event-driven architectures and cross-Region replication with Global Tables. Use on-demand capacity for unpredictable workloads; provisioned with auto-scaling for predictable workloads.
- **ElastiCache**: Redis for caching, session management, leaderboards, and real-time analytics. Use cluster mode for horizontal scaling. Use Global Datastore for cross-Region caching.

### Analytics Architecture
- **Lake Formation**: Centralized data lake governance. Define data permissions at the column level. Integrate with Glue for ETL and Athena for ad-hoc querying.
- **Redshift**: Columnar data warehouse. Use RA3 instances for compute-storage separation. Use Redshift Serverless for variable analytical workloads. Use Redshift Spectrum to query data directly in S3 without loading.
- **Kinesis**: Real-time data streaming. Kinesis Data Streams for ingestion, Kinesis Data Firehose for delivery to S3/Redshift/OpenSearch. Use Enhanced Fan-Out for multiple consumers reading at full throughput.
- **Athena**: Serverless SQL queries on S3 data. Use Parquet/ORC columnar formats with partition projection for optimal query performance and cost. Federated queries connect to RDS, DynamoDB, and other sources.

### Event-Driven Architecture
- **EventBridge**: Central event bus for decoupled architectures. Use schema registry for event schema discovery and code generation. Use EventBridge Pipes for point-to-point integrations with filtering and transformation. Archive and replay events for debugging and recovery.
- **SQS + SNS**: SQS for durable message queuing with exactly-once processing (FIFO queues). SNS for fan-out pub/sub. Combine SNS + SQS for reliable fan-out to multiple consumers with independent processing rates and retry policies.
- **MSK (Managed Kafka)**: For high-throughput event streaming when Kinesis partition limits are insufficient or when Kafka ecosystem compatibility is required. Use MSK Serverless to eliminate broker management.

## Security Architecture

### Identity Architecture
- **IAM Identity Center (SSO)**: Single sign-on for all AWS accounts. Integrate with corporate IdP (Okta, Azure AD, Google Workspace). Define permission sets that map to job functions. Never use IAM users for human access.
- **IAM Roles Everywhere**: Use IAM roles for all machine-to-machine access: EC2 instance profiles, ECS task roles, Lambda execution roles, and IAM Roles Anywhere for on-premises workloads. Eliminate long-lived access keys.
- **Resource-based policies**: Use S3 bucket policies, KMS key policies, and SQS queue policies to grant cross-account access. Combine with Organizations conditions for organization-wide access patterns.

### Data Protection
- **Encryption**: Enable encryption at rest by default on all services (S3, EBS, RDS, DynamoDB, SQS). Use AWS-managed keys (SSE-S3, SSE-SQS) for simplicity; customer-managed KMS keys (CMK) when you need key rotation control or cross-account access.
- **Secrets Management**: Use Secrets Manager for database credentials, API keys, and certificates with automatic rotation. Use Parameter Store (SecureString) for non-rotating configuration values. Never store secrets in environment variables, code, or plain text.
- **Data classification**: Tag resources with data classification levels (public, internal, confidential, restricted). Use Macie for automated PII/sensitive data discovery in S3.

### Threat Detection
- **GuardDuty**: Enable in all accounts and all regions. Covers VPC Flow Logs, CloudTrail, DNS logs, S3 data events, EKS audit logs, and Lambda network activity. Use delegated administrator in the Security account.
- **Security Hub**: Aggregate findings from GuardDuty, Inspector, Macie, Config, and Firewall Manager. Enable CIS AWS Foundations Benchmark. Automate remediation with EventBridge + Lambda or Systems Manager Automation.
- **AWS Config**: Continuous compliance monitoring. Deploy conformance packs for industry standards (PCI-DSS, HIPAA, NIST). Use custom Config Rules for organization-specific policies.

## Cost Architecture

### Savings Plans and Reserved Capacity
- **Compute Savings Plans**: Up to 66% discount. Flexible across instance families, sizes, OS, tenancy, and Regions within EC2, Fargate, and Lambda. Commit based on steady-state spend analysis from Cost Explorer (3-6 months of data minimum).
- **EC2 Instance Savings Plans**: Up to 72% discount but locked to instance family and Region. Use when instance family is stable and workload is predictable.
- **Reserved Instances**: Still relevant for RDS, ElastiCache, Redshift, and OpenSearch where Savings Plans do not apply. Match RI term and payment option (All Upfront for maximum discount) to budget flexibility.

### Spot and Graviton Strategy
- Use Spot Instances for fault-tolerant workloads: CI/CD runners, batch processing, ML training, test environments. Use Spot Fleet or EC2 Auto Scaling with capacity-optimized allocation strategy for best availability.
- Combine Spot with On-Demand in mixed instance Auto Scaling Groups. Set base capacity with On-Demand and burst with Spot.
- Migrate to Graviton progressively. Start with non-production environments. Validate application compatibility. Graviton offers ~20% lower cost and ~20% better performance across compute-intensive workloads.

### Data Transfer Optimization
- Data transfer is the hidden cost in AWS architectures. S3 to internet: $0.09/GB. Cross-Region: $0.02/GB. Cross-AZ: $0.01/GB. Same-AZ: free.
- Minimize cross-AZ traffic by using AZ-aware routing in ECS/EKS (topology-aware hints) and ElastiCache/RDS read replicas in the same AZ as application instances.
- Use S3 Transfer Acceleration for global uploads. Use CloudFront for content delivery (first 1 TB/month free). Use VPC endpoints to avoid NAT Gateway data processing charges for S3 and DynamoDB traffic.

## AWS-Specific Patterns

### Multi-Region Architecture
- **Active-Passive**: Primary Region handles all traffic; secondary Region has replicated data and standby infrastructure. Use Route 53 health checks with failover routing. Aurora Global Database for cross-Region replication. RTO: minutes to hours.
- **Active-Active**: Both Regions serve traffic. Use Route 53 latency-based routing. DynamoDB Global Tables for multi-Region writes. RTO: near-zero. Higher cost and complexity.
- **Pilot Light**: Minimal infrastructure in secondary Region (database replication only). Scale up compute on failover. Cost-effective for infrequent disaster recovery needs. RTO: tens of minutes.

### Observability Stack
- **CloudWatch**: Metrics, logs, alarms, dashboards, and synthetics. Use Contributor Insights for top-N analysis. Use Metric Math for derived metrics. Set up Composite Alarms to reduce alarm noise.
- **X-Ray**: Distributed tracing across Lambda, ECS, EKS, API Gateway, and SQS. Use X-Ray Groups and sampling rules to control cost. Integrate with CloudWatch ServiceLens for unified observability.
- Consider **AWS Distro for OpenTelemetry (ADOT)** for vendor-neutral instrumentation that can send to CloudWatch, X-Ray, and third-party backends simultaneously.
