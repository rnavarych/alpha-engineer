# AWS Platform, Account Strategy, Networking, and Compute

## When to load
Load when designing AWS landing zones, multi-account strategy, VPC and Transit Gateway networking, hybrid connectivity, ECS/EKS container architecture, Lambda serverless patterns, or EC2 auto-scaling architecture.

## Well-Architected Framework

### Six Pillars
- **Operational Excellence**: Automate operations with CloudFormation/CDK, use SSM Automation for runbooks, implement CloudWatch dashboards and alarms for every production workload. Run operational readiness reviews before launch.
- **Security**: Apply least-privilege IAM policies. Use SCPs at the Organizations level. Enable CloudTrail in all regions with log file validation. Enable GuardDuty, Security Hub, and Config Rules as a baseline. Never use long-lived access keys; prefer IAM roles and Identity Center (SSO).
- **Reliability**: Design for failure at every layer. Use multiple Availability Zones as the minimum. Design for multi-Region if RPO/RTO requires it. Implement health checks, circuit breakers, and retry with exponential backoff.
- **Performance Efficiency**: Right-size instances using Compute Optimizer. Use Graviton (ARM) instances for 20-40% better price/performance. Use Enhanced Networking and Placement Groups for latency-sensitive workloads.
- **Cost Optimization**: Implement tagging strategy from day one. Use Cost Explorer, Budgets, and Cost Anomaly Detection. Use Savings Plans (flexible) over Reserved Instances (rigid) unless specific instance family commitment is justified. Spot Instances for fault-tolerant batch, training, and CI/CD workloads.
- **Sustainability**: Select efficient instance types (Graviton). Use managed services that share infrastructure. Right-size to minimize idle resources. Use S3 Intelligent-Tiering for automatic storage class optimization.

### Well-Architected Reviews
- Conduct lens-specific reviews for specialized workloads: SaaS Lens, Serverless Lens, Data Analytics Lens, Machine Learning Lens, Container Build Lens.
- Use the AWS Well-Architected Tool in the console to track findings and improvement plans. Revisit every quarter or after significant architectural changes.

## Account Strategy and Landing Zones

### Multi-Account Architecture
- Use AWS Organizations with a multi-account strategy. Never run production and development workloads in the same account.
- Minimum accounts: Management (billing and Organizations), Security (centralized logging, GuardDuty delegation), Shared Services (CI/CD, artifact repositories), Network (Transit Gateway, DNS), and per-environment accounts (Dev, Staging, Production).
- Use AWS Control Tower for automated landing zone setup with pre-configured guardrails. Customize with Account Factory for Terraform (AFT) or Customizations for Control Tower (CfCT).
- Implement Service Control Policies (SCPs): deny region usage outside approved regions, deny disabling CloudTrail or GuardDuty, deny creation of IAM users with console access (force SSO), require encryption on S3 buckets and EBS volumes.

### Account Vending
- Automate new account creation. Manual account provisioning does not scale beyond 10 accounts.
- Every new account should automatically receive: CloudTrail, Config, GuardDuty, VPC with standard CIDR block, IAM Identity Center permission sets, and cost allocation tags.

## Networking Architecture

### VPC Design
- Use /16 CIDR blocks for production VPCs. Plan CIDR allocation centrally to avoid overlaps across accounts and regions. Use IPAM (VPC IP Address Manager) for automated CIDR management.
- Subnet strategy: public subnets (load balancers, NAT gateways), private subnets (application instances, containers), isolated subnets (databases, no internet access). Deploy across a minimum of 3 Availability Zones for production.
- Use VPC endpoints (Gateway for S3/DynamoDB, Interface for other services) to keep traffic within the AWS network and avoid NAT Gateway data processing charges.

### Transit Gateway
- Use Transit Gateway as the central hub for inter-VPC and on-premises connectivity. Prefer over VPC Peering when connecting more than 3 VPCs.
- Implement route table segmentation: separate route tables for production, non-production, and shared services. Use Transit Gateway Network Manager for visualization and monitoring.
- For cross-Region connectivity, use Transit Gateway inter-Region peering.

### Hybrid Connectivity
- AWS Direct Connect for consistent, low-latency hybrid connectivity. Use LAG (Link Aggregation Groups) for bandwidth aggregation and resilience. Minimum two Direct Connect connections in different locations for high availability.
- Site-to-Site VPN as backup or primary for lower-bandwidth needs. Use accelerated VPN (over AWS Global Accelerator) for improved performance.
- AWS PrivateLink for exposing services across accounts or to partners without traversing the public internet. Preferred pattern for SaaS provider integrations.

## Compute Architecture

### Container Architecture
- **ECS on Fargate**: Serverless containers without cluster management. Use for microservices, batch processing, and scheduled tasks. Combine with Application Load Balancer and Service Connect for service mesh capabilities.
- **EKS**: Managed Kubernetes for teams with existing Kubernetes expertise. Use EKS Managed Node Groups or Fargate profiles. Deploy Karpenter for intelligent auto-scaling (faster and more cost-effective than Cluster Autoscaler). Use EKS Blueprints for standardized cluster configuration.
- **ECS vs EKS decision**: ECS for simpler operational model and deep AWS integration; EKS for portability, ecosystem tooling (Helm, Argo, Istio), and multi-cloud strategy.

### Serverless Architecture
- **Lambda patterns**: API backend (API Gateway + Lambda), event processing (EventBridge/SQS/SNS + Lambda), data transformation (S3 + Lambda), scheduled tasks (EventBridge Scheduler + Lambda). Use Lambda Layers for shared libraries.
- **Step Functions**: Orchestrate multi-step workflows. Standard Workflows for long-running (up to 1 year) processes; Express Workflows for high-volume, short-duration (up to 5 minutes) event processing. Design for idempotency at every step.
- **Cold start mitigation**: Use Provisioned Concurrency for latency-sensitive Lambdas. Use SnapStart for Java Lambdas. Avoid VPC-attached Lambdas unless necessary. Prefer Lambda Web Adapter for porting existing frameworks.

### EC2 Architecture
- Use Auto Scaling Groups with mixed instance policies (multiple instance types and purchase options) for resilience and cost optimization.
- Use Launch Templates (not Launch Configurations). Use AMI baking with EC2 Image Builder for faster boot times.
- Graviton instances: arm64-based with 20-40% better price/performance. Compatible with most Linux workloads, containers, and managed services. Test workloads on Graviton before committing.
