---
name: role-devops:aws-expert
description: |
  Deep AWS expertise covering IAM, VPC networking, EKS, ECS, Lambda serverless,
  EC2 and Auto Scaling, RDS and Aurora, DynamoDB, S3, CloudFront, Route 53,
  ALB/NLB, SQS/SNS/EventBridge, ElastiCache, Secrets Manager, KMS, CloudTrail,
  CloudWatch, AWS Config, WAF, Security Hub, Cost Explorer, Savings Plans,
  and multi-account Organizations strategy for production AWS workloads.
allowed-tools: Read, Grep, Glob, Bash
---

# AWS Expert

## When to use
- Designing IAM policies, configuring IRSA/Pod Identity, or setting up Organizations with SCPs
- Building or reviewing VPC architecture, security groups, load balancer configuration
- Working with EC2 Auto Scaling, ECS/Fargate, Lambda, or EKS cluster setup
- Configuring S3, EBS, EFS, RDS, Aurora, DynamoDB, or SQS/SNS/EventBridge
- Security hardening with KMS, Secrets Manager, CloudTrail, GuardDuty, or Security Hub
- Cost optimization with Savings Plans, Reserved Instances, or Cost Explorer governance

## Core principles
1. **Roles over users** — IAM roles for all programmatic access, OIDC for CI/CD
2. **Least privilege always** — no `Action: *` or `Resource: *` in production policies
3. **Private by default** — VPC endpoints for AWS services, no public RDS/S3
4. **Multi-account guardrails** — SCPs at Organizations level, centralized security account
5. **Cost is owned** — tagging enforced, Compute Savings Plans for baseline, Spot for burst

## Reference Files

- `references/iam-security.md` — Least-privilege IAM design, IRSA/Pod Identity, Permission Boundaries, SSO, AWS Config, GuardDuty, Security Hub, KMS envelope encryption, Secrets Manager rotation, CloudTrail, multi-account Organizations and Landing Zone
- `references/networking-compute.md` — VPC multi-tier design, Transit Gateway, PrivateLink, security groups, ALB/NLB, Global Accelerator, EC2 Launch Templates, Spot mixed-instance policy, IMDSv2, ECS Fargate and EC2, Lambda concurrency and SnapStart, EKS managed add-ons, Bottlerocket, CloudWatch Container Insights
- `references/storage-databases-cost.md` — S3 versioning, lifecycle rules, Block Public Access, Object Lock, SSE-KMS, gp3 EBS, EFS, RDS Multi-AZ, Aurora Serverless v2, RDS Proxy, DynamoDB On-Demand, Global Tables, DAX, SQS/SNS/EventBridge, Compute Savings Plans, Cost Explorer, Infracost

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
