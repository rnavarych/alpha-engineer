---
name: cloud-infrastructure
description: |
  Guides on cloud services: AWS, GCP, Azure service selection, multi-cloud strategies,
  serverless vs container trade-offs, managed vs self-hosted decisions, and cost optimization.
  Use when choosing cloud services, designing infrastructure, or comparing cloud providers.
allowed-tools: Read, Grep, Glob, Bash
---

You are a cloud infrastructure specialist informed by the Software Engineer by RN competency matrix.

## Cloud Provider Deep Comparison

### AWS (Market Leader — ~32% market share)
- Broadest service catalog (200+ services), largest community, most certifications
- Best for: enterprise, regulated industries, mature DevOps, broadest workload coverage
- Key services: EC2, Lambda, RDS/Aurora, DynamoDB, S3, EKS/ECS, SQS/SNS, CloudFront, Step Functions
- **Strengths**: Maturity, breadth, ecosystem (CDK, SAM, Amplify), marketplace, compliance certifications (FedRAMP, HIPAA, SOC, PCI)
- **Weaknesses**: Complex pricing, IAM learning curve, console UX, vendor lock-in depth
- **Pricing**: Pay-as-you-go, reserved instances (1yr/3yr), savings plans, spot instances (up to 90% off)

### Google Cloud (GCP — ~12% market share)
- Strongest in data/ML, Kubernetes (GKE), BigQuery, networking (global VPC)
- Best for: data-intensive, ML/AI workloads, Kubernetes-native, multi-cloud via Anthos
- Key services: GKE, Cloud Run, Cloud SQL/AlloyDB, BigQuery, Pub/Sub, Cloud Functions, Vertex AI
- **Strengths**: Best Kubernetes (GKE Autopilot), BigQuery (serverless analytics), global network, competitive pricing (sustained use discounts), Gemini AI ecosystem
- **Weaknesses**: Smaller service catalog, enterprise sales maturity, fewer compliance regions
- **Pricing**: Pay-as-you-go, committed use discounts (CUDs, 1yr/3yr), sustained use discounts (automatic), preemptible/spot VMs

### Azure (~23% market share)
- Best Microsoft/.NET integration, enterprise identity (Entra ID / Azure AD), hybrid cloud (Arc)
- Best for: Microsoft shops, hybrid cloud, enterprise with existing Microsoft EAs, .NET workloads
- Key services: AKS, Azure Functions, Cosmos DB, Azure SQL, Service Bus, Azure DevOps, Azure OpenAI
- **Strengths**: Enterprise identity (Entra ID), hybrid cloud (Azure Arc, Stack), Microsoft 365 integration, Azure OpenAI exclusive access, strong government cloud
- **Weaknesses**: Service naming inconsistency, portal complexity, region availability gaps, support quality variance
- **Pricing**: Pay-as-you-go, reserved instances, savings plans, spot VMs, dev/test pricing, Azure Hybrid Benefit (existing Windows/SQL licenses)

## Compute Decisions

### VMs / Virtual Machines

| Provider | Service | Instance Families | Key Features |
|----------|---------|-------------------|--------------|
| AWS | EC2 | General (M), Compute (C), Memory (R), Storage (I), Accelerated (P, G, Inf) | Nitro hypervisor, EBS-optimized, placement groups |
| GCP | Compute Engine | General (E2, N2), Compute (C2, C3), Memory (M2), Accelerated (A2, G2) | Live migration, sole-tenant nodes, custom machine types |
| Azure | Virtual Machines | General (D), Compute (F), Memory (E, M), Storage (L), GPU (N) | Availability zones, scale sets, Azure Hybrid Benefit |

#### VM Sizing Guidelines
- **Start small, measure, right-size**: Use cloud provider recommendations (AWS Compute Optimizer, GCP Recommender, Azure Advisor)
- **CPU-bound**: Choose compute-optimized (C-family). Watch for CPU steal on shared instances.
- **Memory-bound**: Choose memory-optimized (R/M-family). Monitor RSS, swap usage, OOM kills.
- **Burstable**: T-series (AWS), e2-micro/small (GCP), B-series (Azure) for dev/test and low-utilization workloads. Monitor CPU credits.

#### Auto-Scaling Groups
- Scale on metrics: CPU utilization (target 60-70%), request count, queue depth, custom metrics
- Scaling policies: target tracking (simplest), step scaling (fine control), predictive scaling (ML-based)
- Cooldown periods: 300s default, tune to prevent flapping
- Always set min/max boundaries and use multiple AZs

#### Spot / Preemptible Instance Strategies
- Up to 60-90% cost savings for fault-tolerant workloads
- Use cases: batch processing, CI/CD runners, stateless web workers, ML training, data processing
- **AWS Spot**: Capacity-optimized allocation, Spot Fleet, EC2 Fleet, 2-minute termination notice
- **GCP Spot VMs**: Max 24-hour runtime, 30-second termination notice, no capacity guarantee
- **Azure Spot VMs**: Eviction policies (deallocate or delete), max price setting
- Best practice: Mix spot with on-demand (80/20 ratio), use multiple instance types, implement graceful shutdown handlers

#### GPU Instances
- **AWS**: P5 (H100), P4d (A100), G5 (A10G), Inf2 (Inferentia2), Trn1 (Trainium)
- **GCP**: A3 (H100), A2 (A100), G2 (L4), TPU v5e
- **Azure**: ND H100 v5, NC A100 v4, NV A10 v5
- Consider: NVIDIA MIG for GPU partitioning, spot GPUs for training, reserved for inference

## Container Orchestration

### Managed Kubernetes Comparison

| Feature | EKS (AWS) | GKE (GCP) | AKS (Azure) |
|---------|-----------|-----------|-------------|
| **Control plane cost** | $0.10/hr ($73/mo) | Free (Autopilot: pay per pod) | Free |
| **Autopilot/Serverless** | Fargate profiles | GKE Autopilot | Virtual Nodes (ACI) |
| **Max nodes** | 5,000 per cluster | 15,000 per cluster | 5,000 per cluster |
| **Default CNI** | VPC CNI (AWS IPs) | Calico or Dataplane V2 (Cilium) | Azure CNI or kubenet |
| **Ingress** | ALB Ingress Controller | GKE Ingress (Cloud LB) | Application Gateway Ingress |
| **Service mesh** | App Mesh, Istio add-on | Anthos Service Mesh, Istio | Istio add-on, Open Service Mesh |
| **GPU support** | NVIDIA device plugin | GKE GPU node pools, TPU | NVIDIA device plugin |
| **Multi-cluster** | EKS Anywhere | Anthos, Fleet | Azure Arc, Fleet Manager |
| **Upgrade strategy** | In-place or blue/green | Surge upgrades, maintenance windows | Blue/green, node image upgrades |

### Service Mesh
- **Istio**: Feature-rich, Envoy-based, complex but powerful. mTLS, traffic management, observability, policy enforcement.
- **Linkerd**: Lightweight, Rust-based proxy. Simpler than Istio. CNCF graduated. Automatic mTLS, retries, timeouts.
- **Cilium**: eBPF-based, high-performance L3/L4/L7 networking. Service mesh without sidecars. Hubble observability.
- **Consul Connect**: HashiCorp. Multi-platform (K8s + VMs). Service discovery + mesh. Envoy sidecars.

### Container Registries
- **ECR** (AWS): Integrated with ECS/EKS, image scanning, lifecycle policies, cross-region replication
- **Artifact Registry** (GCP): Multi-format (Docker, Maven, npm, Python), vulnerability scanning, VPC-SC support
- **ACR** (Azure): Geo-replication, Tasks (in-registry builds), Helm chart support, Azure Defender integration
- **Docker Hub**: Public registry, rate limits on free tier (100 pulls/6hr), Docker Scout vulnerability scanning
- **GitHub Container Registry (ghcr.io)**: Free for public images, GitHub Actions integration, OIDC auth

## Serverless In Depth

### Function-as-a-Service Comparison

| Feature | Lambda (AWS) | Cloud Functions (GCP) | Azure Functions |
|---------|-------------|----------------------|-----------------|
| **Max execution** | 15 min | 60 min (2nd gen) | 10 min (consumption), unlimited (premium) |
| **Memory** | 128 MB - 10 GB | 128 MB - 32 GB | 1.5 GB (consumption), 14 GB (premium) |
| **vCPUs** | Proportional to memory | Proportional to memory | Proportional to memory |
| **Cold start** | 100ms - 5s (language-dependent) | 100ms - 10s | 100ms - 10s |
| **Concurrency** | 1000 default (requestable) | 1000 per region | 200 per instance (consumption) |
| **Languages** | Node.js, Python, Java, Go, .NET, Ruby, Rust (custom) | Node.js, Python, Java, Go, .NET, Ruby, PHP | Node.js, Python, Java, .NET, PowerShell, Go, Rust |
| **Container support** | Yes (up to 10 GB image) | Yes (Cloud Run) | Yes (custom handlers) |
| **Pricing** | $0.20/million invocations + duration | $0.40/million invocations + duration | $0.20/million invocations + duration |
| **Event sources** | 200+ (API Gateway, S3, SQS, DynamoDB, EventBridge) | Pub/Sub, Cloud Storage, HTTP, Eventarc | HTTP, Timer, Queue, Blob, Cosmos DB, Event Grid |

### Cold Start Mitigation
- **Provisioned concurrency** (Lambda): Pre-warm instances, pay for idle capacity. Use for latency-sensitive endpoints.
- **Min instances** (Cloud Functions 2nd gen, Cloud Run): Keep N instances warm
- **Premium plan** (Azure Functions): Pre-warmed workers, VNET integration, no cold start
- **General strategies**: Smaller deployment packages, fewer dependencies, lazy initialization, avoid VPC (Lambda) when not needed, use compiled languages (Go, Rust) for fastest cold starts
- **SnapStart** (Lambda, Java): Snapshot/restore of initialized runtime. Reduces Java cold starts from 5s to <200ms.

## Database Managed Services

### Relational

| Feature | RDS/Aurora (AWS) | Cloud SQL/AlloyDB (GCP) | Azure SQL |
|---------|-----------------|------------------------|-----------|
| **Engines** | PostgreSQL, MySQL, MariaDB, Oracle, SQL Server | PostgreSQL, MySQL, SQL Server | SQL Server (Azure SQL DB), PostgreSQL, MySQL |
| **Serverless** | Aurora Serverless v2 (auto-scale ACUs) | AlloyDB Omni (auto-scale) | Azure SQL Serverless (auto-pause) |
| **Max storage** | 128 TB (Aurora), 64 TB (RDS) | 64 TB (Cloud SQL), 128 TB (AlloyDB) | 100 TB (Hyperscale) |
| **HA** | Multi-AZ, Aurora Global Database | Regional HA, cross-region replicas | Zone-redundant, geo-replication |
| **Read replicas** | 15 (Aurora), 5 (RDS) | 10 (Cloud SQL) | 4 geo-replicas (Hyperscale: 30) |

### NoSQL

| Feature | DynamoDB (AWS) | Firestore (GCP) | Cosmos DB (Azure) |
|---------|---------------|-----------------|-------------------|
| **Model** | Key-value + document | Document | Multi-model (doc, KV, graph, columnar, table) |
| **Consistency** | Eventually + strong per-item | Strong (single-region), eventual (multi) | 5 consistency levels (strong to eventual) |
| **Pricing** | On-demand or provisioned RCU/WCU | Per read/write/delete operations | RU/s (provisioned or serverless) |
| **Global** | Global Tables (active-active) | Multi-region (single-writer) | Multi-region write (turnkey global) |
| **Max item** | 400 KB | 1 MB per document | 2 MB per document |
| **Transactions** | TransactWriteItems/TransactGetItems | Batched writes, transactions | ACID transactions per partition |

## Storage Tiers and Lifecycle

### Object Storage Tiers
| Tier | AWS S3 | GCP Cloud Storage | Azure Blob |
|------|--------|-------------------|------------|
| **Hot** | Standard | Standard | Hot |
| **Infrequent** | S3 IA, One Zone-IA | Nearline (30-day min) | Cool (30-day min) |
| **Archive** | Glacier Instant/Flexible/Deep | Coldline (90d), Archive (365d) | Cold (90d), Archive (180d) |
| **Intelligent** | Intelligent-Tiering (auto) | Autoclass (auto) | Access tier change via lifecycle |

### Lifecycle Management
```json
// AWS S3 Lifecycle Rule example
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

## Networking

### VPC Design
- **CIDR planning**: Use /16 for VPC, /24 for subnets. Plan for growth and peering (non-overlapping CIDRs).
- **Subnet tiers**: Public (internet-facing LBs, bastion), Private (application), Data (databases, caches), Management (monitoring, logging)
- **Multi-AZ**: Minimum 2 AZs for HA, 3 for production workloads
- **Subnet sizing**: Calculate IPs needed per AZ (pods, ENIs, load balancers, future growth)

### Security Groups / Firewalls
- **Principle of least privilege**: Only open required ports/protocols
- **Layered security**: Security groups (instance) + NACLs (subnet) + WAF (edge)
- **Common rules**: Allow 443 (HTTPS) inbound to LB, allow app port only from LB SG, allow DB port only from app SG
- **Egress**: Restrict outbound to known destinations where feasible

### Connectivity
- **NAT Gateway**: Private subnet internet access (egress only). Use per-AZ for HA. Cost: ~$32/mo + data processing.
- **VPN**: Site-to-site (AWS VPN, Cloud VPN, Azure VPN) or client VPN for remote access
- **Direct Connect / Interconnect / ExpressRoute**: Dedicated private connection to cloud. 1-100 Gbps. Use for high-throughput, low-latency, or compliance.
- **VPC Peering**: Connect VPCs. No transitive routing. Free within same region.
- **Transit Gateway / Cloud Router**: Hub-and-spoke network topology. Transitive routing. Centralized firewall.
- **PrivateLink / Private Service Connect**: Access cloud services without internet traversal

## Infrastructure as Code In Depth

### Terraform

#### Module Design
```hcl
# modules/ecs-service/main.tf
variable "service_name" { type = string }
variable "container_image" { type = string }
variable "cpu" { type = number, default = 256 }
variable "memory" { type = number, default = 512 }
variable "desired_count" { type = number, default = 2 }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  # ... networking, load balancer, etc.
}

output "service_url" { value = aws_lb.this.dns_name }
```

#### State Management
- **Remote state**: S3 + DynamoDB (locking) for AWS, GCS for GCP, Azure Blob for Azure
- **State locking**: Prevent concurrent modifications. Always enable.
- **State encryption**: Enable at-rest encryption on the backend bucket
- **Sensitive data**: Mark outputs as `sensitive = true`, use `terraform state pull` carefully
- **State split**: Separate state files per environment and per team/domain (blast radius reduction)

#### Workspaces vs. Directory Structure
- **Workspaces**: Same config, different state. Good for dev/staging/prod with identical infrastructure.
- **Directory structure**: Separate directories per environment. Better for environments with different configurations.
- **Recommended**: Directory-based structure for most teams: `environments/{dev,staging,prod}/main.tf` referencing shared modules

#### Drift Detection
- `terraform plan` on a schedule (CI/CD) to detect out-of-band changes
- **Spacelift, env0, Terraform Cloud**: Automated drift detection with notifications
- **AWS Config Rules**: Detect non-compliant resources
- **Policy as Code**: OPA/Rego with Conftest, Sentinel (TF Cloud/Enterprise), Checkov, tfsec

### IaC Tool Comparison

| Feature | Terraform | Pulumi | AWS CDK | CloudFormation |
|---------|-----------|--------|---------|----------------|
| **Language** | HCL | TypeScript, Python, Go, .NET, Java | TypeScript, Python, Java, .NET, Go | JSON/YAML |
| **Multi-cloud** | Yes (primary strength) | Yes | AWS only | AWS only |
| **State** | Remote backend (S3, GCS, etc.) | Pulumi Cloud or self-managed | CloudFormation stacks | CloudFormation stacks |
| **Testing** | Terratest (Go), tftest | Unit tests in native language | CDK assertions, integ tests | cfn-lint, TaskCat |
| **Ecosystem** | Largest provider ecosystem | Growing, Terraform bridge | L2/L3 constructs, Construct Hub | Limited, macro support |
| **Import** | `terraform import` | `pulumi import` | `cdk import` | `--import` |
| **Preview** | `terraform plan` | `pulumi preview` | `cdk diff` | Change sets |
| **Best for** | Multi-cloud, large teams | Developers who prefer real languages | AWS-native shops | AWS-native, simple deployments |

## Multi-Cloud Strategy

### When to Use Multi-Cloud
- **Compliance**: Data residency requiring specific regions only available on certain providers
- **Best-of-breed**: BigQuery for analytics + AWS for everything else
- **Risk mitigation**: Avoid single provider outage impact (rare justification)
- **M&A**: Acquired company on different cloud
- **Vendor negotiation**: Leverage for pricing negotiations

### When to Avoid Multi-Cloud
- Small/medium teams (operational overhead is prohibitive)
- No specific compliance or technical driver
- "Just in case" is not a valid reason (cost of abstraction > benefit)

### Abstraction Layers
- **Kubernetes**: Workload portability across clouds (EKS, GKE, AKS)
- **Terraform**: Infrastructure portability with provider-specific modules
- **Crossplane**: Kubernetes-native infrastructure provisioning across clouds
- **Dapr**: Application runtime abstraction (service invocation, state, pub/sub)

### Data Gravity
- Data is expensive and slow to move. Place compute near your data.
- Consider egress costs: AWS ($0.09/GB), GCP ($0.12/GB), Azure ($0.087/GB) for inter-cloud transfer
- Use cloud-native data services and replicate only what is necessary

## FinOps: Cloud Cost Optimization

### Cost Allocation
- **Tagging strategy**: Enforce tags for `environment`, `team`, `project`, `cost-center`, `owner`
- **Tag policies**: AWS Tag Policies, GCP labels with org policies, Azure Policy for required tags
- **Showback/chargeback**: Allocate costs to teams based on tags. Use CUR (AWS), billing export (GCP), Cost Management (Azure).

### Reserved Instances vs. Savings Plans
| Feature | Reserved Instances | Savings Plans (AWS) | CUDs (GCP) |
|---------|-------------------|---------------------|------------|
| **Commitment** | Specific instance type + region | $/hr spend commitment | vCPU + memory in region |
| **Flexibility** | Low (instance family with convertible) | High (any instance type) | Medium (machine family) |
| **Discount** | Up to 72% (3yr all upfront) | Up to 72% | Up to 57% (3yr) |
| **Payment** | All, partial, or no upfront | All, partial, or no upfront | Monthly or upfront |
| **Best for** | Stable, predictable workloads | Flexible compute spending | Steady-state GCP workloads |

### Right-Sizing Tools
- **AWS Compute Optimizer**: ML-based instance recommendations from CloudWatch metrics
- **GCP Recommender**: VM, disk, and idle resource recommendations
- **Azure Advisor**: Right-size, shutdown, and reserved instance recommendations
- **Third-party**: Spot.io (now NetApp), Cast AI (Kubernetes), Kubecost, Infracost (IaC cost estimation)

### Cost Monitoring
- Set up billing alerts at 50%, 80%, 100% of monthly budget
- Review cost anomaly detection (AWS Cost Anomaly Detection, GCP budgets with alerts)
- Weekly cost review meetings during rapid growth phases
- Use Infracost in CI/CD to estimate cost impact of infrastructure changes before merge

## Compliance

### SOC 2
- All three major clouds support SOC 2 Type II compliance
- Use cloud audit logging (CloudTrail, Cloud Audit Logs, Azure Activity Log)
- Enable encryption at rest and in transit by default
- Implement least-privilege IAM with regular access reviews

### HIPAA-Eligible Services
- **AWS**: 100+ HIPAA-eligible services, BAA required. Key: S3, RDS, Lambda, ECS, SageMaker
- **GCP**: 80+ covered services, BAA required. Key: GKE, Cloud SQL, BigQuery, Vertex AI
- **Azure**: 90+ in-scope services, BAA required. Key: Azure SQL, AKS, Azure OpenAI

### Data Residency
- **AWS**: 33 regions. AWS Outposts for on-premises. Local Zones for low-latency.
- **GCP**: 40 regions. Assured Workloads for compliance. Sovereign Controls.
- **Azure**: 60+ regions. Azure Government (US), Azure China (21Vianet), Confidential Computing.
- Use org policies to restrict resource creation to approved regions
- Consider data sovereignty requirements for EU (GDPR), Australia, Canada, India

For service comparisons, see [reference-services.md](reference-services.md).
