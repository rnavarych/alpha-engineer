# Networking and Infrastructure as Code

## When to load
Load when designing VPC architecture, configuring security groups, choosing connectivity options (Direct Connect, VPN, Transit Gateway), selecting IaC tools, or managing Terraform state.

## VPC Design

- **CIDR planning**: Use /16 for VPC, /24 for subnets. Plan for growth and peering (non-overlapping CIDRs).
- **Subnet tiers**: Public (internet-facing LBs, bastion), Private (application), Data (databases, caches), Management (monitoring, logging)
- **Multi-AZ**: Minimum 2 AZs for HA, 3 for production workloads

### Security Groups / Firewalls

- **Principle of least privilege**: Only open required ports/protocols
- **Layered security**: Security groups (instance) + NACLs (subnet) + WAF (edge)
- **Common rules**: Allow 443 (HTTPS) inbound to LB, allow app port only from LB SG, allow DB port only from app SG
- **Egress**: Restrict outbound to known destinations where feasible

### Connectivity Options

- **NAT Gateway**: Private subnet internet access (egress only). Use per-AZ for HA. Cost: ~$32/mo + data processing.
- **VPN**: Site-to-site (AWS VPN, Cloud VPN, Azure VPN) or client VPN for remote access
- **Direct Connect / Interconnect / ExpressRoute**: Dedicated private connection. 1-100 Gbps. For high-throughput, low-latency, or compliance.
- **VPC Peering**: Connect VPCs. No transitive routing. Free within same region.
- **Transit Gateway / Cloud Router**: Hub-and-spoke topology. Transitive routing. Centralized firewall.
- **PrivateLink / Private Service Connect**: Access cloud services without internet traversal

### Region and AZ Strategy

| Pattern | Description | Complexity | Use Case |
|---------|-------------|------------|----------|
| **Active-Passive** | Primary region serves traffic, standby for failover | Low | DR with RTO < 1 hour |
| **Active-Active** | Both regions serve traffic, data replicated | High | Global latency, near-zero RTO |
| **Pilot Light** | Minimal infra in DR region, scale up on failover | Medium | Cost-effective DR |
| **Warm Standby** | Scaled-down copy in DR region | Medium | RTO < 15 min |

**AZ distribution**: Minimum 2 AZs for production, 3 for critical. No data transfer charges within same AZ.

**Region selection criteria**: latency to users, compliance (data residency), service availability, cost (us-east-1 typically cheapest on AWS), DR geographic distance.

## Infrastructure as Code

### IaC Tool Comparison

| Feature | Terraform | Pulumi | AWS CDK | CloudFormation |
|---------|-----------|--------|---------|----------------|
| **Language** | HCL | TypeScript, Python, Go, .NET, Java | TypeScript, Python, Java, .NET, Go | JSON/YAML |
| **Multi-cloud** | Yes (primary strength) | Yes | AWS only | AWS only |
| **State** | Remote backend (S3, GCS, etc.) | Pulumi Cloud or self-managed | CloudFormation stacks | CloudFormation stacks |
| **Testing** | Terratest (Go), tftest | Unit tests in native language | CDK assertions | cfn-lint, TaskCat |
| **Preview** | `terraform plan` | `pulumi preview` | `cdk diff` | Change sets |
| **Best for** | Multi-cloud, large teams | Developers who prefer real languages | AWS-native shops | AWS-native, simple |

### Terraform Module Design

```hcl
# modules/ecs-service/main.tf
variable "service_name" { type = string }
variable "container_image" { type = string }
variable "cpu" { type = number; default = 256 }
variable "memory" { type = number; default = 512 }
variable "desired_count" { type = number; default = 2 }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
}

output "service_url" { value = aws_lb.this.dns_name }
```

### Terraform State Management

- **Remote state**: S3 + DynamoDB (locking) for AWS, GCS for GCP, Azure Blob for Azure
- **State locking**: Prevent concurrent modifications — always enable
- **State encryption**: Enable at-rest encryption on the backend bucket
- **Sensitive data**: Mark outputs as `sensitive = true`
- **State split**: Separate state files per environment and per team/domain (blast radius reduction)
- **Directory structure** (recommended): `environments/{dev,staging,prod}/main.tf` referencing shared modules
- **Drift detection**: `terraform plan` on a schedule (CI/CD) + tools: Spacelift, env0, Terraform Cloud
- **Policy as Code**: OPA/Rego with Conftest, Sentinel (TF Cloud), Checkov, tfsec
