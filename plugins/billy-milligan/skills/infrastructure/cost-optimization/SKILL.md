---
name: cost-optimization
description: |
  Cloud cost optimization patterns. AWS reserved instances, spot instances, Savings Plans, right-sizing, S3 tiers, GCP committed use, preemptible VMs, caching strategies, CDN for egress, autoscaling tuning.
allowed-tools: Read, Grep, Glob
---

# Cost Optimization

## When to use

Use when reviewing cloud bills, planning cost reduction, setting up cost governance, or evaluating pricing models across AWS, GCP, or multi-cloud. Covers compute, storage, network, and operational cost patterns.

## Core principles

1. Measure before cutting — rightsizing requires utilization data, not guesses
2. Tag everything — cannot optimize what cannot be attributed
3. Right-size before committing — buying reservations for wrong size locks in waste
4. Dev/staging should sleep — idle non-production is the largest hidden cost
5. Egress costs are silent killers — always put CDN in front of public content

## References available

- `references/aws-cost-patterns.md` — Reserved instances, spot (up to 90% savings), Savings Plans, right-sizing, S3 tiers
- `references/gcp-cost-patterns.md` — Committed use, preemptible VMs, BigQuery slot pricing, egress optimization
- `references/general-optimization.md` — Caching to reduce compute, CDN for egress, autoscaling tuning, unused resource detection
- `references/cost-monitoring.md` — Budget alerts, anomaly detection, dev auto-stop, showback/chargeback, FinOps maturity
