---
name: role-devops:cost-optimization
description: |
  Cloud cost optimization expertise covering instance right-sizing, reserved and
  savings plans, spot/preemptible instances, resource tagging, cost allocation,
  FinOps practices, auto-scaling policies, storage lifecycle, and unused resource cleanup.
allowed-tools: Read, Grep, Glob, Bash
---

# Cost Optimization

## When to use
- Analyzing cloud spend and identifying top cost drivers
- Purchasing or reviewing reserved instances and savings plan commitments
- Configuring spot/preemptible instances for fault-tolerant workloads
- Establishing tagging strategy and cost allocation across teams
- Setting up FinOps practices, monthly review cadence, and unit economics
- Configuring storage lifecycle policies or running unused resource cleanup
- Setting up budget alerts and cost anomaly detection

## Core principles
1. **Measure before committing** — 14-30 days of utilization data before sizing or reserving
2. **Commit to baseline, spot the rest** — on-demand and spot handle variable load above commitments
3. **Tags are mandatory** — untagged resources are unowned resources, unowned resources waste money
4. **Showback before chargeback** — visibility first, then accountability
5. **Cost is a non-functional requirement** — treat it alongside performance and reliability

## Reference Files

- `references/rightsizing-commitments-spot.md` — Instance right-sizing with cloud Recommender tools, 40% utilization threshold, VPA-based K8s right-sizing, Compute Savings Plans vs Reserved Instances vs CUDs per cloud, baseline commitment strategy, spot/preemptible diversification and SIGTERM graceful shutdown, Kubernetes mixed node pool taint/toleration pattern, auto-scaling metric selection and cooldown design
- `references/tagging-finops-cleanup.md` — Mandatory tag taxonomy, tag policy enforcement via Organizations/Azure Policy/OPA, cost allocation showback model, anomaly detection at 20% trailing-average threshold, FinOps lifecycle (Inform/Optimize/Operate), unit economics benchmarking, S3/GCS storage lifecycle transitions, orphaned snapshot and volume cleanup, Cloud Custodian and Komiser tooling, expiry-tag automation pattern, budget alerts at 50/80/100%

## Best Practices Checklist
1. All resources tagged with mandatory cost allocation tags
2. Baseline workloads covered by reservations or savings plans
3. Spot instances used for fault-tolerant workloads
4. Auto-scaling configured with appropriate metrics and limits
5. Storage lifecycle policies active on all buckets
6. Weekly unused resource scan and cleanup
7. Monthly cost review with engineering stakeholders
8. Cost anomaly alerts configured and tested
