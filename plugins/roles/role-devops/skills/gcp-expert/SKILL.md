---
name: role-devops:gcp-expert
description: |
  Deep Google Cloud Platform expertise covering IAM and Workload Identity,
  VPC networking, GKE, Cloud Run, Cloud SQL and Spanner, Bigtable, Cloud Storage,
  BigQuery, Pub/Sub, Cloud CDN, Cloud Armor, Cloud Load Balancing, Cloud DNS,
  Logging and Monitoring, Secret Manager, Cloud KMS, Security Command Center,
  Artifact Registry, Cloud Build, and Committed Use Discounts for production GCP workloads.
allowed-tools: Read, Grep, Glob, Bash
---

# GCP Expert

## When to use
- Designing GCP resource hierarchy, IAM roles, or Workload Identity Federation for CI/CD
- Building VPC with Shared VPC, VPC Service Controls, Cloud NAT, or load balancing
- Working with GKE Autopilot/Standard, Cloud Run, or Cloud Functions Gen 2
- Configuring Cloud SQL, Spanner, Bigtable, BigQuery, GCS, or Pub/Sub
- Security hardening with SCC, Cloud Armor, Cloud KMS, or Secret Manager
- Observability with Cloud Logging, Cloud Monitoring SLOs, Cloud Trace, or Cloud Profiler
- Cost optimization with Committed Use Discounts, billing exports, or Recommender API

## Core principles
1. **No JSON key files** — Workload Identity for GKE, Workload Identity Federation for CI/CD
2. **Private IP for all databases** — Cloud SQL Auth Proxy, never public IP
3. **Binary Authorization on GKE** — only signed images in production clusters
4. **VPC Service Controls for sensitive data** — BigQuery, GCS, Spanner behind perimeters
5. **Organization Policy constraints** — disable SA key creation, require Shielded VMs, restrict regions

## Reference Files

- `references/iam-networking.md` — Resource hierarchy and IAM model, Organization Policy constraints, Workload Identity Federation (GitHub Actions/GitLab OIDC), Workload Identity for GKE, service account best practices, Shared VPC, VPC Service Controls, Private Google Access, Cloud NAT, global/regional/internal/network load balancers, Cloud CDN, Cloud DNS routing policies, Traffic Director
- `references/compute-storage-databases.md` — GKE Autopilot/Standard/NAP/Binary Authorization/Dataplane V2/gVisor, Cloud Run VPC egress and IAM invoker, Cloud Functions Gen 2 with eventarc, GCS uniform access and retention, Cloud SQL HA/Auth Proxy/IAM auth, Spanner interleaved tables, Bigtable row key design, BigQuery partitioning and row-level security, Pub/Sub dead letter topics, Cloud Build private pools, Artifact Registry cleanup policies
- `references/security-observability-cost.md` — SCC Standard/Premium with SIEM integration, Cloud Armor WAF and rate limiting with preview mode, Cloud KMS rotation, Cloud HSM, Secret Manager versioning and audit logging, Cloud Logging sinks, log exclusion filters, Cloud Monitoring MQL alerting, SLO burn rate monitoring, Cloud Trace sampling, Cloud Profiler, Cloud Error Reporting, Committed Use Discounts, Billing Export to BigQuery, Budget Alerts, Recommender API

## Best Practices Checklist
1. Organization Policy constraints enforced at folder/org level
2. Workload Identity for GKE — no JSON key files on clusters
3. Workload Identity Federation for CI/CD — no static service account keys in pipelines
4. Shared VPC with centralized network management
5. VPC Service Controls around sensitive data services
6. Private IP for all Cloud SQL instances with Auth Proxy
7. Binary Authorization enabled on GKE production clusters
8. Cloud Armor WAF attached to all external load balancers
9. SCC enabled at organization level with active findings routed to SIEM
10. Secret Manager for all secrets — no plaintext in environment variables
11. Cloud Logging sinks configured for long-term retention and SIEM integration
12. SLO monitoring with burn rate alerting in Cloud Monitoring
13. Artifact Registry vulnerability scanning with deployment policy gates
14. Committed Use Discounts covering baseline GCE and Cloud SQL
15. Cost allocation labels enforced across all resources with Budget Alerts configured
