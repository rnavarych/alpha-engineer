---
name: role-architect:gcp-architect
description: |
  GCP architecture expertise including Google Cloud Architecture Framework,
  project and organization structure, VPC and networking design, data and analytics
  architecture, Kubernetes and serverless patterns, AI/ML platform design,
  security architecture, and cost optimization strategies.
  Use proactively when designing systems on GCP, evaluating GCP services,
  planning GCP organization structure, or architecting for GCP-specific capabilities.
allowed-tools: Read, Grep, Glob, Bash
---

# GCP Architect

## When to use
- Designing GCP organization, folder, and project structure for a new workload
- Selecting between GKE Autopilot, GKE Standard, and Cloud Run for container workloads
- Architecting Shared VPC, global load balancing, or hybrid connectivity with Cloud Interconnect
- Choosing between BigQuery, Spanner, AlloyDB, Firestore, and Bigtable for data storage
- Designing Vertex AI training and serving pipelines or generative AI architectures
- Configuring BeyondCorp, VPC Service Controls, or Security Command Center
- Optimizing costs with Committed Use Discounts, Sustained Use Discounts, and FinOps practices

## Core principles
1. **Shared VPC by default** — centralize network management, decentralize compute
2. **Organization policies as guardrails** — enforce at folder level before projects are created
3. **Workload Identity everywhere** — no service account keys on compute resources
4. **Global load balancing** — GCP's network is global; use it for traffic management
5. **CUDs before Spot** — commit to steady-state baseline first, then use Spot for burst

## Reference Files
- `references/gcp-platform-and-compute.md` — Architecture Framework five pillars, organization/project structure, Landing Zone, Shared VPC design, VPC Flow Logs, global load balancing, Cloud Armor, Cloud Interconnect, GKE Autopilot vs Standard, multi-cluster Fleet, Cloud Run, and Compute Engine MIGs
- `references/gcp-data-aiml-security-cost.md` — BigQuery architecture patterns, Pub/Sub and Dataflow streaming pipeline, Cloud Spanner and AlloyDB, Firestore and Bigtable, Vertex AI training and serving, TPU architecture, generative AI with Vector Search; BeyondCorp and IAP, VPC Service Controls, Security Command Center, Cloud KMS and DLP; CUDs, Sustained Use Discounts, and FinOps with billing export to BigQuery
