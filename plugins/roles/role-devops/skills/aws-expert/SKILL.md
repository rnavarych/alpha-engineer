---
name: aws-expert
description: |
  Deep AWS expertise covering IAM, VPC networking, EKS, ECS, Lambda serverless,
  EC2 and Auto Scaling, RDS and Aurora, DynamoDB, S3, CloudFront, Route 53,
  ALB/NLB, SQS/SNS/EventBridge, ElastiCache, Secrets Manager, KMS, CloudTrail,
  CloudWatch, AWS Config, WAF, Security Hub, Cost Explorer, Savings Plans,
  and multi-account Organizations strategy for production AWS workloads.
allowed-tools: Read, Grep, Glob, Bash
---

# AWS Expert

## IAM and Identity

### Least-Privilege IAM Design
- Never use `Action: "*"` or `Resource: "*"` in production policies. Scope every statement to exact actions and ARN patterns.
- Prefer **IAM Roles** over IAM Users for all programmatic access. Attach roles to EC2 instances, ECS tasks, Lambda functions, and EKS pods.
- Use **IAM Permission Boundaries** to cap the maximum permissions a delegated admin can grant, enabling safe developer self-service without privilege escalation risk.
- Enable **Service Control Policies (SCPs)** at the AWS Organizations level to enforce guardrails across all accounts: prevent disabling CloudTrail, block non-approved regions, require MFA for sensitive actions.
- Use **IAM Identity Center (SSO)** for centralized human access to multiple accounts. Assign Permission Sets instead of individual account-level IAM users.
- Enforce **MFA** for the root account and all IAM users that exist. Rotate access keys automatically via Secrets Manager or use OIDC-based keyless authentication from CI/CD.

### IRSA (IAM Roles for Service Accounts)
- Bind Kubernetes service accounts to IAM roles via OpenID Connect. Pods assume the role at runtime without static credentials.
- Create the OIDC provider for the EKS cluster, create an IAM role with a trust policy scoped to the specific namespace and service account name.
- Use `eks.amazonaws.com/role-arn` annotation on the Kubernetes ServiceAccount. AWS SDK automatically uses the OIDC token from the pod's projected volume.
- Scope trust policies tightly: `StringEquals sts:ExternalId` or `StringLike` on the service account subject to prevent role assumption from unintended pods.

### AWS Config and Compliance
- Enable AWS Config in all regions and accounts to track resource configuration history and detect non-compliant states.
- Use managed Config rules: `restricted-ssh`, `s3-bucket-public-read-prohibited`, `iam-root-access-key-check`, `cloudtrail-enabled`.
- Use **AWS Security Hub** to aggregate findings from Config, GuardDuty, Inspector, Macie, and third-party tools into a single compliance dashboard.
- Enable **Amazon GuardDuty** in every account and region for threat detection (unusual API calls, crypto mining, compromised credentials, exfiltration signals).

---

## Networking (VPC)

### VPC Design Patterns
- Use a **multi-tier subnet** model: public subnets for load balancers and NAT gateways, private subnets for application workloads, isolated/database subnets with no internet route.
- Size CIDRs for growth: `/16` VPC, `/24` subnets per AZ per tier. Reserve IP space — EKS assigns one IP per pod (VPC CNI), so large clusters need large subnets.
- Deploy across **3 AZs** minimum for production. Ensure equal subnet counts per tier per AZ for AZ-affine resources (RDS Multi-AZ, ELB, EKS).
- Use **Transit Gateway** to connect multiple VPCs and on-premises via a hub-and-spoke topology. Avoid VPC peering webs — they don't scale and lack transitive routing.
- Use **AWS PrivateLink** (VPC Endpoints) for S3, DynamoDB, ECR, Secrets Manager, and other AWS services to keep traffic within the AWS network, off the public internet.

### Security Groups and NACLs
- Security Groups are stateful and the primary traffic control mechanism. Use them for service-to-service access rules.
- NACLs are stateless and operate at the subnet level. Use them as a secondary layer for broad deny rules (block known malicious CIDRs, enforce inter-tier isolation).
- Never open `0.0.0.0/0` on security groups for any port other than 80/443 on load balancers. Reference security group IDs in rules instead of CIDR blocks for pod/service-level rules.

### Load Balancers
- **Application Load Balancer (ALB)** for HTTP/HTTPS traffic. Native path-based and host-based routing. WebSockets, HTTP/2, gRPC support. Use with AWS WAF.
- **Network Load Balancer (NLB)** for TCP/UDP/TLS traffic requiring static IPs, ultra-low latency, or Elastic IP attachment. Required for PrivateLink services.
- Use the **AWS Load Balancer Controller** in EKS to provision ALBs and NLBs from Kubernetes Ingress and Service annotations.
- Enable **ALB Access Logs** to S3 for request-level auditing. Enable **NLB Flow Logs** via VPC Flow Logs.
- Use **Global Accelerator** for latency-based routing of TCP/UDP traffic to the nearest healthy regional endpoint.

---

## Compute

### EC2 and Auto Scaling
- Use **Launch Templates** (not Launch Configurations) for all Auto Scaling Groups. Templates support versioning, mixed instance policies, and spot configuration.
- **Mixed Instances Policy**: combine On-Demand base capacity with Spot instances for the remainder. Use `capacity-optimized` allocation strategy for Spot to minimize interruptions.
- Use **Spot Instance Advisor** and instance type diversification across 5+ families to maximize Spot availability. Handle `instance-action` termination notices with graceful drain.
- Enable **Instance Metadata Service v2 (IMDSv2)** on all instances. IMDSv2 requires a session-oriented request, blocking SSRF-based metadata theft. Set `HttpTokens: required` in Launch Templates.
- Use **EC2 Image Builder** for automated, tested, hardened AMI pipelines. Pin AMI IDs in Launch Templates; never use `latest`.
- **Graviton (ARM64)** instances: up to 40% better price/performance for compute-intensive workloads. EKS supports mixed amd64/arm64 node pools via Karpenter.

### ECS (Elastic Container Service)
- Use **ECS Fargate** for serverless container workloads — no node management, per-second billing, task-level IAM roles.
- Use **ECS EC2** when you need GPU access, custom kernel parameters, Windows containers, or need to optimize for cost with Reserved Instances.
- Define **Task Definitions** with explicit CPU/memory, task role (for AWS API access), execution role (for ECR pull and Secrets Manager), and logging configuration.
- Use **ECS Service Connect** or **AWS Cloud Map** for service discovery between ECS services. Prefer Service Connect for new workloads — it provides built-in mTLS and observability.
- Deploy with **ECS rolling updates** or **Blue/Green via CodeDeploy** for zero-downtime releases.
- Use **ECS Exec** (SSM-based) for secure container shell access without SSH or exposed ports.

### Lambda (Serverless)
- Set **reserved concurrency** to cap function scaling and protect downstream dependencies. Set **provisioned concurrency** for latency-sensitive functions to eliminate cold starts.
- Use **Lambda Layers** for shared dependencies and runtime utilities. Version layers and pin function configurations to specific layer versions.
- Configure **Dead Letter Queues (DLQ)** (SQS or SNS) for async invocations to capture and replay failed events.
- Use **Lambda Power Tuning** (Step Functions state machine) to find the optimal memory/performance/cost configuration for functions.
- Enable **SnapStart** for Java functions for up to 10x cold start improvement.
- Use **Function URLs** for simple HTTP endpoints without API Gateway. Use API Gateway for routing, auth, throttling, and response transformation.
- Set `POWERTOOLS_LOG_LEVEL`, structured logging with AWS Lambda Powertools for consistent observability.

---

## Managed Kubernetes (EKS)

- Use **EKS managed node groups** for simplified lifecycle management or **Karpenter** for dynamic, optimal instance selection.
- Enable **EKS control plane logging** (API server, audit, authenticator, controller manager, scheduler) to CloudWatch Logs.
- Use **EKS Pod Identity** (newer, preferred over IRSA for new workloads) or IRSA for pod-level AWS API access without static credentials.
- Deploy the **AWS Load Balancer Controller**, **EBS CSI driver**, **EFS CSI driver**, and **VPC CNI** as managed EKS add-ons.
- Use **VPC CNI prefix delegation** for large clusters: each ENI gets `/28` prefixes, dramatically increasing pod density per node.
- Enable **EKS security groups for pods** to apply fine-grained security group rules at the pod level for compliance-sensitive workloads.
- Use **Bottlerocket** as the node OS for minimal attack surface, faster updates, and dm-verity-based integrity verification.
- Set up **EKS cluster access management** with Access Entries to manage Kubernetes RBAC without modifying the `aws-auth` ConfigMap.

---

## Storage

### S3
- Enable **S3 Versioning** on all buckets that store important data. Enable **MFA Delete** on critical buckets.
- Use **S3 Lifecycle rules** to transition objects to cheaper storage classes (Intelligent-Tiering, Glacier Instant Retrieval, Glacier Deep Archive) and expire old versions.
- Enable **S3 Block Public Access** at the account level. Never allow public ACLs or public bucket policies unless explicitly required (static websites with CloudFront are better handled via OAC).
- Use **S3 Object Lock** (WORM) for compliance and audit logs that must be immutable for a defined retention period.
- Enable **S3 Server-Side Encryption (SSE-KMS)** with a CMK for data classification requirements. Use bucket policies to enforce encrypted uploads.
- Use **S3 Transfer Acceleration** for global upload acceleration. Use **S3 Batch Operations** for bulk object transformations.
- **S3 Event Notifications** to SQS, SNS, or Lambda for event-driven processing of new objects.
- Enable **S3 Access Logs** and **S3 Server Access Logging** for audit trails.

### EBS and EFS
- Use **gp3** volumes by default for EBS. Baseline 3,000 IOPS and 125 MiB/s throughput at no extra cost. Provision additional IOPS/throughput as needed without upsizing volume.
- Enable **EBS encryption** by default at the account level.
- Use **EFS** for shared POSIX file systems across multiple EC2/ECS/EKS workloads. Enable EFS encryption at rest and in transit. Use **EFS Intelligent-Tiering** for cost optimization.
- **EFS Access Points** for namespace isolation between applications sharing the same file system.

---

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

---

## Messaging and Events

### SQS, SNS, EventBridge
- Use **SQS** for decoupled asynchronous processing. Use **FIFO queues** when ordering and exactly-once processing are required (note: lower throughput limit).
- Configure **visibility timeout** to be greater than your consumer's max processing time to prevent duplicate processing.
- Always configure a **Dead Letter Queue** on SQS queues. Set `maxReceiveCount` based on expected transient failure scenarios.
- Use **Long Polling** (`WaitTimeSeconds: 20`) to reduce empty responses and lower cost.
- Use **SNS fan-out** to broadcast messages to multiple SQS queues, Lambda functions, or HTTP endpoints simultaneously.
- **EventBridge** for event-driven architectures with rich content-based routing rules, schema registry, and cross-account/cross-region event bus integration.
- Use **EventBridge Pipes** for point-to-point integrations with filtering and enrichment between source and target without custom code.

---

## Security Services

### KMS
- Use **Customer Managed Keys (CMKs)** for envelope encryption of sensitive data. Rotate CMKs annually (automatic rotation supported).
- Use `kms:GenerateDataKey` + local symmetric encryption (envelope encryption) for large payloads. Never encrypt large data directly with KMS.
- Restrict KMS key access via **Key Policies** and IAM policies in combination. Key policies are the primary access control for CMKs.
- Use **KMS Key Aliases** for human-readable key references in application configuration.
- Enable **CloudTrail** logging for all KMS API calls — every encrypt/decrypt/sign operation is recorded.

### Secrets Manager and Parameter Store
- Use **Secrets Manager** for passwords, API keys, and certificates that require rotation. Enable **automatic rotation** using the built-in Lambda rotation function.
- Use **SSM Parameter Store SecureString** (backed by KMS) for configuration values that don't need rotation — cheaper than Secrets Manager.
- Access secrets at runtime via SDK or sidecar injection. Never embed secrets in environment variables baked into container images or Launch Templates.
- Use **Secrets Manager resource-based policies** for cross-account secret sharing without duplicating secrets.

### CloudTrail
- Enable **CloudTrail** in all regions with **multi-region trail**. Deliver to a dedicated S3 bucket in a centralized security account.
- Enable **CloudTrail Insights** for anomaly detection on write API activity.
- Enable **CloudTrail log file validation** to detect log tampering.
- Apply **S3 Object Lock** on the CloudTrail bucket with a retention period matching compliance requirements.

---

## Observability (CloudWatch)

- Use **CloudWatch Container Insights** for ECS and EKS cluster, service, task, and pod level metrics with minimal setup.
- Use **CloudWatch Logs Insights** for ad-hoc log analysis. Create **Metric Filters** on log groups to generate custom CloudWatch metrics from log patterns.
- Design **CloudWatch Dashboards** with cross-account, cross-region views via CloudWatch Dashboard sharing.
- Define **CloudWatch Alarms** on error budget burn rate metrics rather than raw thresholds. Use **Composite Alarms** to reduce noise.
- Use **CloudWatch Evidently** for A/B testing and feature flagging. Use **CloudWatch RUM** for real user monitoring of web applications.
- Set **CloudWatch Log Group retention** explicitly on all log groups (avoid the default never-expire setting for cost control).
- Use **AWS Distro for OpenTelemetry (ADOT)** for standardized metrics, traces, and logs collection from applications.
- Use **X-Ray** or **AWS Managed Grafana with Tempo** for distributed tracing. Instrument with ADOT collector.

---

## Multi-Account Strategy (AWS Organizations)

- Maintain a **Landing Zone** with separate accounts per environment (dev, staging, prod) and per function (security tooling, logging, networking, shared services).
- Use **Control Tower** to automate account provisioning with guardrails, identity, and logging baseline.
- Apply **Service Control Policies** for preventive guardrails: require MFA, restrict regions, prevent public S3 buckets, block root account usage.
- Centralize **CloudTrail**, **Security Hub**, **GuardDuty**, and **Config** in a dedicated security account as a log archive.
- Use **AWS RAM (Resource Access Manager)** to share VPC subnets across accounts in the same organization (shared VPC model). Central networking team manages the Transit Gateway.
- Set up **AWS IAM Identity Center** with an identity provider (Okta, Azure AD) for centralized SSO to all accounts.

---

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

---

## Best Practices Checklist

1. All accounts under AWS Organizations with SCPs enforcing guardrails
2. CloudTrail enabled in all regions, delivered to immutable centralized bucket
3. GuardDuty and Security Hub enabled in all accounts and regions
4. IMDSv2 required on all EC2 Launch Templates
5. IRSA or Pod Identity for all EKS pod AWS API access
6. No long-lived IAM user access keys — use roles and OIDC
7. VPC endpoints for S3, DynamoDB, ECR, Secrets Manager, STS
8. RDS Multi-AZ and encryption enabled for all production databases
9. S3 Block Public Access enabled at account level
10. KMS CMKs for sensitive data encryption with key rotation enabled
11. Cost allocation tags enforced on all resources
12. Compute Savings Plans covering baseline workload
13. CloudWatch Alarms on burn rate metrics, not raw thresholds
14. EKS managed add-ons (LBC, EBS CSI, VPC CNI) version-pinned and updated
15. Bottlerocket or Amazon Linux 2023 for EKS/EC2 node OS
