---
name: aws-architect
description: |
  AWS architecture expertise including Well-Architected Framework, account strategy,
  VPC and networking design, compute and serverless patterns, data architecture,
  security architecture, and cost optimization strategies.
  Use proactively when designing systems on AWS, evaluating AWS services,
  planning AWS landing zones, or architecting for AWS-specific capabilities.
allowed-tools: Read, Grep, Glob, Bash
---

# AWS Architect

## Well-Architected Framework

### Six Pillars
- **Operational Excellence**: Automate operations with CloudFormation/CDK, use SSM Automation for runbooks, implement CloudWatch dashboards and alarms for every production workload. Run operational readiness reviews before launch. Use AWS Health Dashboard integration for proactive issue awareness.
- **Security**: Apply least-privilege IAM policies. Use SCPs at the Organizations level to enforce guardrails. Enable CloudTrail in all regions with log file validation. Enable GuardDuty, Security Hub, and Config Rules as a baseline. Never use long-lived access keys; prefer IAM roles and Identity Center (SSO).
- **Reliability**: Design for failure at every layer. Use multiple Availability Zones as the minimum. Design for multi-Region if RPO/RTO requires it. Implement health checks, circuit breakers, and retry with exponential backoff. Use Route 53 health checks for DNS-level failover.
- **Performance Efficiency**: Right-size instances using Compute Optimizer recommendations. Use Graviton (ARM) instances for 20-40% better price/performance on compatible workloads. Profile application behavior before selecting instance families. Use Enhanced Networking and Placement Groups for latency-sensitive workloads.
- **Cost Optimization**: Implement tagging strategy from day one. Use Cost Explorer, Budgets, and Cost Anomaly Detection. Right-size with Compute Optimizer. Use Savings Plans (flexible) over Reserved Instances (rigid) unless specific instance family commitment is justified. Spot Instances for fault-tolerant batch, training, and CI/CD workloads.
- **Sustainability**: Select efficient instance types (Graviton). Use managed services that share infrastructure. Right-size to minimize idle resources. Use S3 Intelligent-Tiering for automatic storage class optimization. Deploy in regions powered by renewable energy when latency permits.

### Well-Architected Reviews
- Conduct lens-specific reviews for specialized workloads: SaaS Lens, Serverless Lens, Data Analytics Lens, Machine Learning Lens, Container Build Lens.
- Use the AWS Well-Architected Tool in the console to track findings and improvement plans. Revisit every quarter or after significant architectural changes.

## Account Strategy and Landing Zones

### Multi-Account Architecture
- Use AWS Organizations with a multi-account strategy. Never run production and development workloads in the same account. Minimum accounts: Management (billing and Organizations), Security (centralized logging, GuardDuty delegation), Shared Services (CI/CD, artifact repositories), Network (Transit Gateway, DNS), and per-environment accounts (Dev, Staging, Production).
- Use AWS Control Tower for automated landing zone setup with pre-configured guardrails. Customize with Account Factory for Terraform (AFT) or Customizations for Control Tower (CfCT).
- Implement Service Control Policies (SCPs) at the OU level: deny region usage outside approved regions, deny disabling CloudTrail or GuardDuty, deny creation of IAM users with console access (force SSO), require encryption on S3 buckets and EBS volumes.

### Account Vending
- Automate new account creation. Manual account provisioning does not scale beyond 10 accounts.
- Use Account Factory (Control Tower) or custom automation with Organizations API + CloudFormation StackSets for baseline configuration.
- Every new account should automatically receive: CloudTrail, Config, GuardDuty, VPC with standard CIDR block, IAM Identity Center permission sets, and cost allocation tags.

## Networking Architecture

### VPC Design
- Use /16 CIDR blocks for production VPCs. Plan CIDR allocation centrally to avoid overlaps across accounts and regions. Use IPAM (VPC IP Address Manager) for automated CIDR management.
- Subnet strategy: public subnets (load balancers, NAT gateways), private subnets (application instances, containers), isolated subnets (databases, no internet access). Deploy across a minimum of 3 Availability Zones for production.
- Use VPC endpoints (Gateway for S3/DynamoDB, Interface for other services) to keep traffic within the AWS network and avoid NAT Gateway data processing charges.

### Transit Gateway
- Use Transit Gateway as the central hub for inter-VPC and on-premises connectivity. Prefer Transit Gateway over VPC Peering when connecting more than 3 VPCs.
- Implement route table segmentation: separate route tables for production, non-production, and shared services. Use Transit Gateway Network Manager for visualization and monitoring.
- For cross-Region connectivity, use Transit Gateway inter-Region peering. For hybrid connectivity, attach VPN or Direct Connect gateways to Transit Gateway.

### Hybrid Connectivity
- AWS Direct Connect for consistent, low-latency hybrid connectivity. Use LAG (Link Aggregation Groups) for bandwidth aggregation and resilience. Minimum: two Direct Connect connections in different locations for high availability.
- Site-to-Site VPN as backup or primary for lower-bandwidth needs. Use accelerated VPN (over AWS Global Accelerator) for improved performance over public internet.
- AWS PrivateLink for exposing services across accounts or to partners without traversing the public internet. Preferred pattern for SaaS provider integrations.

## Compute Architecture

### Container Architecture
- **ECS on Fargate**: Serverless containers without cluster management. Best for teams that want container benefits without Kubernetes complexity. Use for microservices, batch processing, and scheduled tasks. Combine with Application Load Balancer and Service Connect for service mesh capabilities.
- **EKS**: Managed Kubernetes for teams with existing Kubernetes expertise. Use EKS Managed Node Groups or Fargate profiles. Deploy Karpenter for intelligent auto-scaling (faster and more cost-effective than Cluster Autoscaler). Use EKS Blueprints for standardized cluster configuration.
- **ECS vs EKS decision**: ECS for simpler operational model and deep AWS integration; EKS for portability, ecosystem tooling (Helm, Argo, Istio), and multi-cloud strategy.

### Serverless Architecture
- **Lambda patterns**: API backend (API Gateway + Lambda), event processing (EventBridge/SQS/SNS + Lambda), data transformation (S3 + Lambda), scheduled tasks (EventBridge Scheduler + Lambda). Use Lambda Layers for shared libraries. Use Lambda Extensions for observability sidecars.
- **Step Functions**: Orchestrate multi-step workflows with visual state machines. Use Standard Workflows for long-running (up to 1 year) processes; Express Workflows for high-volume, short-duration (up to 5 minutes) event processing. Design for idempotency at every step.
- **Cold start mitigation**: Use Provisioned Concurrency for latency-sensitive Lambda functions. Use SnapStart for Java Lambdas (reduces cold start from seconds to milliseconds). Avoid VPC-attached Lambdas unless necessary (they add cold start latency). Prefer Lambda Web Adapter for porting existing frameworks.

### EC2 Architecture
- Use Auto Scaling Groups with mixed instance policies (multiple instance types and purchase options) for resilience and cost optimization.
- Use Launch Templates (not Launch Configurations). Include user data scripts for bootstrapping or use AMI baking with EC2 Image Builder for faster boot times.
- Graviton instances: arm64-based instances with 20-40% better price/performance. Compatible with most Linux workloads, containers, and managed services. Test workloads on Graviton before committing.

## Data Architecture

### Database Selection
- **Aurora**: Default choice for relational workloads on AWS. Aurora PostgreSQL or MySQL-compatible. Use Aurora Serverless v2 for variable workloads (scales in seconds). Use Aurora Global Database for cross-Region disaster recovery (< 1 second replication lag) and read scaling.
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
- **IAM Roles Everywhere**: Use IAM roles for all machine-to-machine access. EC2 instance profiles, ECS task roles, Lambda execution roles, and IAM Roles Anywhere for on-premises workloads. Eliminate long-lived access keys.
- **Resource-based policies**: Use S3 bucket policies, KMS key policies, and SQS queue policies to grant cross-account access without creating IAM roles in every account. Combine with Organizations conditions for organization-wide access patterns.

### Data Protection
- **Encryption**: Enable encryption at rest by default on all services (S3, EBS, RDS, DynamoDB, SQS). Use AWS-managed keys (SSE-S3, SSE-SQS) for simplicity; customer-managed KMS keys (CMK) when you need key rotation control, cross-account access, or audit via CloudTrail.
- **Secrets Management**: Use Secrets Manager for database credentials, API keys, and certificates. Enable automatic rotation. Use Parameter Store (SecureString) for non-rotating configuration values. Never store secrets in environment variables, code, or SSM Parameter Store as plain text.
- **Data classification**: Tag resources with data classification levels (public, internal, confidential, restricted). Use Macie for automated PII/sensitive data discovery in S3.

### Threat Detection
- **GuardDuty**: Enable in all accounts and all regions. Covers VPC Flow Logs, CloudTrail, DNS logs, S3 data events, EKS audit logs, and Lambda network activity. Use delegated administrator in the Security account.
- **Security Hub**: Aggregate findings from GuardDuty, Inspector, Macie, Config, and Firewall Manager. Enable CIS AWS Foundations Benchmark and AWS Foundational Security Best Practices standards. Automate remediation with EventBridge + Lambda or Systems Manager Automation.
- **AWS Config**: Continuous compliance monitoring. Deploy conformance packs for industry standards (PCI-DSS, HIPAA, NIST). Use custom Config Rules for organization-specific policies. Remediate automatically with SSM Automation documents.

## Cost Architecture

### Savings Plans and Reserved Capacity
- **Compute Savings Plans**: Up to 66% discount. Flexible across instance families, sizes, OS, tenancy, and Regions within EC2, Fargate, and Lambda. Commit based on steady-state spend analysis from Cost Explorer (3-6 months of data minimum).
- **EC2 Instance Savings Plans**: Up to 72% discount but locked to instance family and Region. Use when instance family is stable and workload is predictable.
- **Reserved Instances**: Still relevant for RDS, ElastiCache, Redshift, and OpenSearch where Savings Plans do not apply. Match RI term (1-year or 3-year) and payment option (All Upfront for maximum discount) to budget flexibility.

### Spot and Graviton Strategy
- Use Spot Instances for fault-tolerant workloads: CI/CD runners, batch processing, ML training, data processing, test environments. Use Spot Fleet or EC2 Auto Scaling with capacity-optimized allocation strategy for best availability.
- Combine Spot with On-Demand in mixed instance Auto Scaling Groups. Set base capacity with On-Demand and burst with Spot for cost-optimized scaling.
- Migrate to Graviton progressively. Start with non-production environments. Validate application compatibility. Graviton instances offer ~20% lower cost and ~20% better performance across compute-intensive workloads.

### Data Transfer Optimization
- Data transfer is the hidden cost in AWS architectures. S3 to internet: $0.09/GB. Cross-Region: $0.02/GB. Cross-AZ: $0.01/GB. Same-AZ: free.
- Minimize cross-AZ traffic by using AZ-aware routing in ECS/EKS (topology-aware hints) and ElastiCache/RDS read replicas in the same AZ as application instances.
- Use S3 Transfer Acceleration for global uploads. Use CloudFront for content delivery (first 1 TB/month free). Use VPC endpoints to avoid NAT Gateway data processing charges for S3 and DynamoDB traffic.

## AWS-Specific Patterns

### Multi-Region Architecture
- **Active-Passive**: Primary Region handles all traffic; secondary Region has replicated data and standby infrastructure. Use Route 53 health checks with failover routing. Aurora Global Database for cross-Region database replication. RTO: minutes to hours depending on infrastructure readiness.
- **Active-Active**: Both Regions serve traffic. Use Route 53 latency-based routing. DynamoDB Global Tables for multi-Region writes. Design for conflict resolution (last-writer-wins or application-level). RTO: near-zero. Higher cost and complexity.
- **Pilot Light**: Minimal infrastructure in secondary Region (database replication only). Scale up compute on failover. Cost-effective for infrequent disaster recovery needs. RTO: tens of minutes.

### Observability Stack
- **CloudWatch**: Metrics, logs, alarms, dashboards, and synthetics (canary testing). Use CloudWatch Contributor Insights for top-N analysis. Use Metric Math for derived metrics. Set up Composite Alarms to reduce alarm noise.
- **X-Ray**: Distributed tracing across Lambda, ECS, EKS, API Gateway, and SQS. Use X-Ray Groups and sampling rules to control cost. Integrate with CloudWatch ServiceLens for unified observability.
- **CloudWatch Logs Insights**: Query log data with a purpose-built query language. Use for ad-hoc investigation and dashboarding. Cheaper than exporting to OpenSearch for most log analysis needs.
- Consider **AWS Distro for OpenTelemetry (ADOT)** for vendor-neutral instrumentation that can send to CloudWatch, X-Ray, and third-party backends simultaneously.
