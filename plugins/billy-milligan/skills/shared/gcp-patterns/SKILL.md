---
name: gcp-patterns
description: |
  GCP production patterns: Cloud Run with Terraform, Workload Identity Federation (no service
  account keys), Cloud SQL with private IP, Memorystore Redis, BigQuery for analytics,
  Cloud Armor WAF, Secret Manager, VPC Service Controls, IAM least privilege bindings.
  Use when designing GCP architecture, writing Terraform for GCP, reviewing IAM policies.
allowed-tools: Read, Grep, Glob
---

# GCP Production Patterns

## When to Use This Skill
- Deploying containers to Cloud Run
- Setting up Workload Identity Federation (no SA keys)
- Configuring Cloud SQL with private IP
- Writing Terraform for GCP infrastructure
- Querying BigQuery for analytics

## Core Principles

1. **Cloud Run for stateless services** — autoscales to 0, no cluster management, pay per request
2. **Workload Identity Federation, never SA keys** — SA keys are persistent credentials; WIF is token-based and short-lived
3. **Private IP for all data services** — Cloud SQL, Memorystore: no public IP, accessed via VPC
4. **IAM bindings on resources, not members** — bind roles to service accounts scoped to specific resources
5. **BigQuery for analytics over Cloud SQL** — even 1B row aggregations run in <10 seconds on BigQuery

## References available
- `references/compute-patterns.md` — Cloud Run Terraform, Workload Identity Federation for GitHub Actions, IAM least privilege bindings
- `references/data-patterns.md` — Cloud SQL private IP, Memorystore Redis, BigQuery partitioning and clustering, Secret Manager
- `references/networking-patterns.md` — VPC connector, Cloud Armor WAF, VPC Service Controls, load balancer setup
