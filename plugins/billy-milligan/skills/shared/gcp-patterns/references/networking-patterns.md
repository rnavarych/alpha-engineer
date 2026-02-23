# GCP Networking Patterns

## When to load
Load when designing VPC networks, configuring Cloud Load Balancing, or setting up Cloud CDN.

## VPC Architecture

```
VPC Network: my-project-vpc (global resource in GCP)
│
├─ Subnet: us-central1 (10.0.0.0/20, 4K addresses)
│   ├─ Primary range: GKE nodes / Compute Engine
│   ├─ Secondary range: 10.1.0.0/16 (pods)
│   └─ Secondary range: 10.2.0.0/20 (services)
│
├─ Subnet: europe-west1 (10.0.16.0/20)
│
└─ Subnet: asia-east1 (10.0.32.0/20)

GCP difference from AWS:
  - VPC is global (subnets are regional)
  - No NAT Gateway per AZ needed (Cloud NAT is regional)
  - Firewall rules are VPC-level (not subnet-level)
```

## Firewall Rules

```bash
# Allow internal communication
gcloud compute firewall-rules create allow-internal \
  --network my-vpc \
  --allow tcp,udp,icmp \
  --source-ranges 10.0.0.0/8 \
  --priority 1000

# Allow health checks from Google LB
gcloud compute firewall-rules create allow-health-check \
  --network my-vpc \
  --allow tcp:3000 \
  --source-ranges 130.211.0.0/22,35.191.0.0/16 \
  --target-tags api-server \
  --priority 1000

# Allow SSH via IAP (no public IP needed)
gcloud compute firewall-rules create allow-iap-ssh \
  --network my-vpc \
  --allow tcp:22 \
  --source-ranges 35.235.240.0/20 \
  --target-tags allow-ssh \
  --priority 1000
```

## Cloud Load Balancing

```
External HTTP(S) Load Balancer (global):
  Internet → Google Front End (GFE)
           → URL Map (path-based routing)
           → Backend Service (Cloud Run / GKE / Instance Groups)
           → Health Checks

Setup:
  1. Backend Service: serverless NEG (Cloud Run) or instance group
  2. URL Map: route /api/* to API backend, /* to frontend
  3. SSL Certificate: managed by Google (auto-renew)
  4. Cloud CDN: enable for static content
  5. Cloud Armor: WAF rules (OWASP, rate limiting, geo-blocking)
```

```bash
# Cloud Run with custom domain via LB
gcloud compute network-endpoint-groups create api-neg \
  --region us-central1 \
  --network-endpoint-type serverless \
  --cloud-run-service api-server

gcloud compute backend-services create api-backend \
  --global \
  --load-balancing-scheme EXTERNAL_MANAGED

gcloud compute backend-services add-backend api-backend \
  --global \
  --network-endpoint-group api-neg \
  --network-endpoint-group-region us-central1
```

## Cloud NAT (outbound internet for private instances)

```bash
# Create Cloud NAT (regional, no instance needed unlike AWS)
gcloud compute routers create my-router \
  --network my-vpc \
  --region us-central1

gcloud compute routers nats create my-nat \
  --router my-router \
  --region us-central1 \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges

# Pricing: ~$0.044/hr + $0.045/GB (similar to AWS NAT Gateway)
```

## Private Google Access

```bash
# Access Google APIs without public IP (free)
gcloud compute networks subnets update my-subnet \
  --region us-central1 \
  --enable-private-google-access

# Private Service Connect (dedicated endpoint for Google APIs)
# Provides private IP for specific Google services
# Better security: no internet exposure, no NAT needed
```

## Cloud Armor (WAF)

```bash
# Create security policy
gcloud compute security-policies create my-policy

# Rate limiting
gcloud compute security-policies rules create 1000 \
  --security-policy my-policy \
  --action throttle \
  --rate-limit-threshold-count 100 \
  --rate-limit-threshold-interval-sec 60 \
  --conform-action allow \
  --exceed-action deny-429

# OWASP top 10 protection
gcloud compute security-policies rules create 2000 \
  --security-policy my-policy \
  --action deny-403 \
  --expression "evaluatePreconfiguredExpr('sqli-v33-stable')"
```

## Anti-patterns
- Public IPs on all instances → use IAP for SSH, Cloud NAT for outbound
- No Cloud Armor on public LB → exposed to DDoS and OWASP attacks
- VPC peering for everything → use Shared VPC for multi-project
- No Private Google Access → unnecessary NAT costs for API calls

## Quick reference
```
VPC: global (unlike AWS), subnets are regional
Firewall: VPC-level rules with tags/service accounts
LB: global HTTP(S) LB, regional for TCP/UDP
Cloud NAT: regional, managed (no instance), same pricing as AWS
Private Google Access: free, no NAT needed for Google APIs
Cloud CDN: enable on LB backend for static content caching
Cloud Armor: WAF + DDoS, rate limiting, OWASP rules
IAP: SSH/RDP without public IPs, identity-based access
Shared VPC: multi-project networking (vs VPC peering)
```
