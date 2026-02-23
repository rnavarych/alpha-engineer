# AWS Networking and Compute

## When to load
Load when designing VPC architecture, configuring load balancers, working with EC2 Auto Scaling,
ECS/Fargate, Lambda, or EKS cluster setup and add-on configuration.

## Networking (VPC)

### VPC Design Patterns
- Use a **multi-tier subnet** model: public subnets for load balancers and NAT gateways, private subnets for application workloads, isolated/database subnets with no internet route.
- Size CIDRs for growth: `/16` VPC, `/24` subnets per AZ per tier. Reserve IP space — EKS assigns one IP per pod (VPC CNI), so large clusters need large subnets.
- Deploy across **3 AZs** minimum for production. Ensure equal subnet counts per tier per AZ for AZ-affine resources (RDS Multi-AZ, ELB, EKS).
- Use **Transit Gateway** to connect multiple VPCs and on-premises via a hub-and-spoke topology. Avoid VPC peering webs — they don't scale and lack transitive routing.
- Use **AWS PrivateLink** (VPC Endpoints) for S3, DynamoDB, ECR, Secrets Manager, and other AWS services to keep traffic within the AWS network, off the public internet.

### Security Groups and NACLs
- Security Groups are stateful and the primary traffic control mechanism. Use them for service-to-service access rules.
- NACLs are stateless and operate at the subnet level. Use them as a secondary layer for broad deny rules.
- Never open `0.0.0.0/0` on security groups for any port other than 80/443 on load balancers. Reference security group IDs in rules instead of CIDR blocks.

### Load Balancers
- **Application Load Balancer (ALB)** for HTTP/HTTPS traffic. Native path-based and host-based routing. WebSockets, HTTP/2, gRPC support. Use with AWS WAF.
- **Network Load Balancer (NLB)** for TCP/UDP/TLS traffic requiring static IPs, ultra-low latency, or Elastic IP attachment. Required for PrivateLink services.
- Use the **AWS Load Balancer Controller** in EKS to provision ALBs and NLBs from Kubernetes Ingress and Service annotations.
- Enable **ALB Access Logs** to S3 for request-level auditing. Enable **NLB Flow Logs** via VPC Flow Logs.
- Use **Global Accelerator** for latency-based routing of TCP/UDP traffic to the nearest healthy regional endpoint.

## Compute

### EC2 and Auto Scaling
- Use **Launch Templates** (not Launch Configurations) for all Auto Scaling Groups. Templates support versioning, mixed instance policies, and spot configuration.
- **Mixed Instances Policy**: combine On-Demand base capacity with Spot instances for the remainder. Use `capacity-optimized` allocation strategy for Spot to minimize interruptions.
- Use **Spot Instance Advisor** and instance type diversification across 5+ families to maximize Spot availability. Handle `instance-action` termination notices with graceful drain.
- Enable **Instance Metadata Service v2 (IMDSv2)** on all instances. IMDSv2 requires a session-oriented request, blocking SSRF-based metadata theft. Set `HttpTokens: required` in Launch Templates.
- Use **EC2 Image Builder** for automated, tested, hardened AMI pipelines. Pin AMI IDs in Launch Templates; never use `latest`.
- **Graviton (ARM64)** instances: up to 40% better price/performance for compute-intensive workloads.

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
- Use **Lambda Power Tuning** to find the optimal memory/performance/cost configuration for functions.
- Enable **SnapStart** for Java functions for up to 10x cold start improvement.
- Use **Function URLs** for simple HTTP endpoints without API Gateway. Use API Gateway for routing, auth, throttling, and response transformation.

### Managed Kubernetes (EKS)
- Use **EKS managed node groups** for simplified lifecycle management or **Karpenter** for dynamic, optimal instance selection.
- Enable **EKS control plane logging** (API server, audit, authenticator, controller manager, scheduler) to CloudWatch Logs.
- Use **EKS Pod Identity** (newer, preferred over IRSA for new workloads) or IRSA for pod-level AWS API access without static credentials.
- Deploy the **AWS Load Balancer Controller**, **EBS CSI driver**, **EFS CSI driver**, and **VPC CNI** as managed EKS add-ons.
- Use **VPC CNI prefix delegation** for large clusters: each ENI gets `/28` prefixes, dramatically increasing pod density per node.
- Enable **EKS security groups for pods** for fine-grained security group rules at the pod level.
- Use **Bottlerocket** as the node OS for minimal attack surface, faster updates, and dm-verity-based integrity verification.
- Set up **EKS cluster access management** with Access Entries to manage Kubernetes RBAC without modifying the `aws-auth` ConfigMap.

## Observability (CloudWatch)

- Use **CloudWatch Container Insights** for ECS and EKS cluster, service, task, and pod level metrics with minimal setup.
- Use **CloudWatch Logs Insights** for ad-hoc log analysis. Create **Metric Filters** on log groups to generate custom CloudWatch metrics from log patterns.
- Define **CloudWatch Alarms** on error budget burn rate metrics rather than raw thresholds. Use **Composite Alarms** to reduce noise.
- Use **CloudWatch Evidently** for A/B testing and feature flagging. Use **CloudWatch RUM** for real user monitoring of web applications.
- Set **CloudWatch Log Group retention** explicitly on all log groups (avoid the default never-expire setting for cost control).
- Use **AWS Distro for OpenTelemetry (ADOT)** for standardized metrics, traces, and logs collection from applications.
- Use **X-Ray** or **AWS Managed Grafana with Tempo** for distributed tracing. Instrument with ADOT collector.
