# GCP Cost Patterns

## Committed Use Discounts (CUDs)

```
Equivalent to AWS Reserved Instances:
  - Commit to specific vCPU and memory for 1 or 3 years
  - Applies automatically to matching VMs

Savings:
  1-year commitment: 37% discount
  3-year commitment: 55% discount

Types:
  - Compute-optimized CUD: specific machine family (N2, E2, etc.)
  - General-purpose CUD: applies to any general-purpose VM
  - Spend-based CUD: commit to $/hour (most flexible)

Best approach:
  1. Review Committed Use recommendations in Billing Console
  2. Start with spend-based CUDs (most flexible)
  3. Cover baseline usage only, use on-demand for peaks
```

## Preemptible VMs / Spot VMs

```
Savings: 60-91% vs on-demand

Preemptible (legacy):
  - Max lifetime: 24 hours
  - 30-second termination notice
  - Fixed price (60-91% discount)

Spot VMs (recommended):
  - No max lifetime (but can still be preempted)
  - 30-second termination notice
  - Dynamic pricing

Best for:
  - Batch processing, data pipelines
  - CI/CD build runners
  - Fault-tolerant workloads with checkpointing
  - GKE node pools for non-critical workloads
```

```yaml
# GKE: Spot VM node pool
gcloud container node-pools create spot-pool \
  --cluster=my-cluster \
  --spot \
  --num-nodes=3 \
  --machine-type=e2-standard-4 \
  --enable-autoscaling \
  --min-nodes=0 \
  --max-nodes=10
```

## BigQuery Cost Optimization

```
Pricing models:
  On-demand:  $6.25/TB scanned (pay per query)
  Editions:   Slot-based pricing (commit to compute capacity)

Cost reduction strategies:
  1. Partition tables by date (scan only needed partitions)
  2. Cluster tables by frequently filtered columns
  3. Use SELECT specific columns, never SELECT *
  4. Set query byte limits to prevent expensive mistakes
  5. Use materialized views for repeated expensive queries
  6. Move cold data to BigQuery BI Engine cache
```

```sql
-- Before: scans entire table ($6.25/TB)
SELECT * FROM orders WHERE created_at > '2024-01-01';

-- After: scans only January partition ($0.50)
SELECT order_id, amount, status
FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-01-31';
```

```bash
# Check query cost before running (dry run)
bq query --use_legacy_sql=false --dry_run \
  'SELECT order_id, amount FROM orders WHERE created_at > "2024-01-01"'
# Output: "This query will process X bytes"
```

## Sustained Use Discounts (Automatic)

```
GCP automatically applies discounts based on monthly usage:
  25-50% of month:  20% discount
  50-75% of month:  40% discount
  75-100% of month: 60% discount (max)

No action needed: applied automatically to all eligible VMs.
Applies to: N1, N2, N2D, C2, M1, M2 machine types.
Does NOT apply to: E2, Spot/Preemptible VMs, sole-tenant nodes.
```

## Egress Cost Optimization

```
GCP egress pricing:
  Within same zone:           Free
  Between zones (same region): $0.01/GB
  Between regions:             $0.01-0.08/GB
  To internet:                 $0.12/GB (first 1TB)

Optimization strategies:
  1. Keep services in same zone when possible
  2. Use Cloud CDN for public content ($0.02-0.08/GB)
  3. Use Private Google Access for GCP API traffic
  4. Compress data before transfer
  5. Use Cloud Interconnect for high-volume on-prem transfer
```

## GKE-Specific Optimization

```yaml
# Vertical Pod Autoscaler: right-size pod resources
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  updatePolicy:
    updateMode: "Off"  # Recommendation-only first
```

```
GKE cost optimization checklist:
  [ ] Use Autopilot mode (pay per pod, not per node)
  [ ] Enable cluster autoscaler (scale down idle nodes)
  [ ] Use Spot VM node pools for fault-tolerant workloads
  [ ] Set resource requests/limits on all pods
  [ ] Use VPA recommendations to right-size
  [ ] Enable node auto-provisioning
  [ ] Use E2 machine family for general workloads (cheapest)
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| SELECT * in BigQuery | Select specific columns; use partitioned tables |
| N2 VMs for simple workloads | Use E2 family (20-40% cheaper) |
| No committed use for stable VMs | Buy CUDs for baseline (37-55% savings) |
| Cross-region traffic for same service | Co-locate services in same region/zone |
| GKE Standard with idle nodes | Use Autopilot or enable aggressive autoscaling |

## Quick Reference

- CUD savings: **37%** (1-year), **55%** (3-year)
- Spot VM savings: **60-91%** (with 30s termination notice)
- Sustained use: up to **60%** automatic (no action needed)
- BigQuery: partition + cluster + column select = **10x+ cost reduction**
- Egress: same zone is **free**, internet is **$0.12/GB**
- GKE Autopilot: pay per pod, no idle node waste
- E2 family: cheapest general-purpose VMs
