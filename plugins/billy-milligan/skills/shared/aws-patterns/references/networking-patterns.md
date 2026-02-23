# AWS Networking Patterns

## When to load
Load when designing VPC architecture, configuring security groups, or setting up load balancers.

## VPC Architecture

```
VPC: 10.0.0.0/16 (65K addresses)
│
├─ Public Subnets (internet-facing)
│   ├─ 10.0.1.0/24 (AZ-a) — ALB, NAT Gateway, bastion
│   ├─ 10.0.2.0/24 (AZ-b) — ALB, NAT Gateway
│   └─ 10.0.3.0/24 (AZ-c) — ALB, NAT Gateway
│
├─ Private Subnets (application)
│   ├─ 10.0.11.0/24 (AZ-a) — ECS/EKS/EC2 workloads
│   ├─ 10.0.12.0/24 (AZ-b)
│   └─ 10.0.13.0/24 (AZ-c)
│
└─ Isolated Subnets (data)
    ├─ 10.0.21.0/24 (AZ-a) — RDS, ElastiCache
    ├─ 10.0.22.0/24 (AZ-b)
    └─ 10.0.23.0/24 (AZ-c)

Routing:
  Public:   IGW (Internet Gateway) for inbound/outbound
  Private:  NAT Gateway for outbound only
  Isolated: No internet access (VPC endpoints for AWS services)
```

## Security Groups

```
ALB Security Group:
  Inbound:  443 (HTTPS) from 0.0.0.0/0
  Outbound: 3000 to App SG

App Security Group:
  Inbound:  3000 from ALB SG (only from load balancer)
  Outbound: 5432 to DB SG, 6379 to Cache SG, 443 to 0.0.0.0/0

DB Security Group:
  Inbound:  5432 from App SG (only from app instances)
  Outbound: None needed

Cache Security Group:
  Inbound:  6379 from App SG
  Outbound: None needed

Rule: reference security group IDs, not CIDR blocks
  → SG references auto-update when instances change
```

## Application Load Balancer

```
Internet → ALB (public subnets, 3 AZs)
           │
           ├─ /api/*     → Target Group: API (port 3000)
           ├─ /ws/*      → Target Group: WebSocket (port 3001)
           └─ /*         → Target Group: Frontend (port 80)

Key settings:
  - Cross-zone load balancing: enabled
  - Idle timeout: 60s (increase for WebSocket/long-poll)
  - Health check: /health, 10s interval, 2 healthy threshold
  - Stickiness: disabled (stateless apps) or cookie-based
  - WAF: attach AWS WAF for OWASP protection
```

## VPC Endpoints (avoid NAT Gateway costs)

```
NAT Gateway: $0.045/hr + $0.045/GB processed (~$32/mo minimum)

VPC Endpoints (free or per-hour):
  Gateway endpoints (free):
    - S3
    - DynamoDB

  Interface endpoints (~$7.30/mo each):
    - ECR (for container pulls)
    - Secrets Manager
    - CloudWatch Logs
    - SQS, SNS, STS

Cost example: 100GB/mo S3 traffic
  Via NAT Gateway: $32 + $4.50 = $36.50/mo
  Via VPC Endpoint: $0 (gateway endpoint is free)
```

## Multi-Account Networking

```
AWS Organizations:
  Management Account
  ├─ Networking Account (Transit Gateway, VPCs, DNS)
  ├─ Production Account
  ├─ Staging Account
  ├─ Development Account
  └─ Security Account (GuardDuty, Security Hub)

Transit Gateway:
  Hub-and-spoke: all VPCs connect through TGW
  Cross-account: share TGW via Resource Access Manager
  On-premises: VPN or Direct Connect to TGW
```

## Anti-patterns
- Single AZ deployment → no high availability
- Public subnets for databases → direct internet exposure
- CIDR-based security groups → don't auto-update with scaling
- No VPC endpoints → unnecessary NAT Gateway costs
- Overly permissive outbound rules (0.0.0.0/0 on everything) → exfiltration risk
- No flow logs → can't debug networking issues

## Quick reference
```
VPC: /16, 3 AZ minimum, public + private + isolated subnets
Security groups: reference SG IDs, least privilege, stateful
ALB: public subnets, path-based routing, health checks
NAT Gateway: private subnet outbound, expensive — use VPC endpoints
VPC endpoints: gateway (S3, DynamoDB free), interface ($7/mo each)
Subnets: /24 per AZ per tier (254 usable addresses)
DNS: Route 53 private hosted zones for internal service discovery
Multi-account: Transit Gateway for hub-and-spoke networking
```
