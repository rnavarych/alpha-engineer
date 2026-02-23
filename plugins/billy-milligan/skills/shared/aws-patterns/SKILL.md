---
name: aws-patterns
description: |
  AWS production patterns: ECS Fargate with Terraform, VPC 3-tier architecture, IAM least
  privilege with OIDC (no long-lived credentials), ALB + target groups, RDS Multi-AZ,
  ElastiCache cluster, S3 lifecycle policies, CloudWatch alarms, Secrets Manager rotation.
  Use when designing AWS architecture, writing Terraform for AWS, reviewing IAM policies.
allowed-tools: Read, Grep, Glob
---

# AWS Production Patterns

## When to Use This Skill
- Designing VPC and network architecture
- Writing Terraform for ECS/RDS/ElastiCache
- Setting up IAM with least privilege
- Configuring ALB and target groups
- Managing secrets with AWS Secrets Manager

## Core Principles

1. **VPC 3-tier: public/private/data** — load balancers in public, app in private, databases in data subnet; no DB in public
2. **IAM least privilege** — no wildcard `*` resources in production policies; scope to specific ARNs
3. **No long-lived credentials** — use IAM roles for EC2/ECS/Lambda; OIDC for GitHub Actions
4. **Multi-AZ everything** — RDS Multi-AZ, ElastiCache replication group, ALB spans 3 AZs
5. **Secrets Manager over Parameter Store for secrets** — automatic rotation, versioning, cross-account access

## References available
- `references/compute-patterns.md` — ECS Fargate Terraform, task definitions, service with circuit breaker, GitHub Actions OIDC, IAM least privilege
- `references/storage-patterns.md` — RDS Multi-AZ, ElastiCache replication group, S3 lifecycle policies, Secrets Manager rotation
- `references/networking-patterns.md` — VPC 3-tier Terraform, ALB + target groups, security groups, NAT gateway HA
