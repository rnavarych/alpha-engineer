# Right-Sizing, Commitments, Spot Instances, and Auto-Scaling

## When to load
Load when analyzing instance utilization, purchasing reserved instances or savings plans,
configuring spot/preemptible workloads, or tuning auto-scaling policies for cost efficiency.

## Right-Sizing Instances

- Analyze CPU and memory utilization over 14-30 days before selecting instance types. Sustained utilization below 40% signals over-provisioning.
- Use cloud-native tools: AWS Compute Optimizer, GCP Recommender, Azure Advisor for right-sizing recommendations.
- Start smaller and scale up based on data, not assumptions. An `m5.large` is often sufficient where teams default to `m5.xlarge`.
- For Kubernetes workloads, use VPA recommendations to set accurate resource requests, then right-size node pools accordingly.
- Re-evaluate instance sizing quarterly or after significant traffic pattern changes.

## Reserved Instances and Savings Plans

- Commit to reserved instances or savings plans for stable, predictable workloads. 1-year commitments offer 30-40% savings; 3-year commitments offer 50-60%.
- Use **Compute Savings Plans** (AWS) for flexibility across instance families and regions. Use **Reserved Instances** only when certain of the specific instance type.
- Cover baseline capacity with commitments, not peak. Let on-demand and spot handle variable load above the baseline.
- Review reservation utilization monthly. Unused reservations are wasted money. Sell or exchange underutilized reservations.
- Stagger reservation purchases to avoid cliff-edge renewals and maintain flexibility.

### Cloud-Specific Commitment Options
- **AWS**: Compute Savings Plans (most flexible), EC2 Instance Savings Plans, Reserved Instances (Convertible for uncertain type needs).
- **GCP**: Flexible CUDs (spend-based for GCE, Cloud SQL, Spanner), Resource-based CUDs (up to 70% for 3-year).
- **Azure**: Azure Savings Plans for Compute (up to 65%), Reserved VM Instances (up to 72%), SQL and Cosmos DB reserved capacity.

## Spot and Preemptible Instances

- Use spot instances (AWS), preemptible VMs (GCP), or spot VMs (Azure) for fault-tolerant workloads: batch processing, CI/CD runners, stateless web tier with auto-scaling.
- Diversify across multiple instance types and availability zones to reduce interruption frequency.
- Implement graceful shutdown handling: trap SIGTERM, drain connections, checkpoint state.
- In Kubernetes, use mixed node pools with spot and on-demand nodes. Taint spot nodes and tolerate from non-critical workloads.
- Expected savings: 60-90% compared to on-demand pricing.

### Kubernetes Spot Node Pattern

```yaml
# Taint on spot nodes (applied by Karpenter or node group config)
# tolerations in non-critical Deployment:
tolerations:
- key: "spot"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"

# Node affinity to prefer spot but allow on-demand fallback:
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 80
      preference:
        matchExpressions:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
```

## Auto-Scaling Policies

- Configure auto-scaling based on actual demand metrics, not just CPU. Use request rate, queue depth, or custom business metrics.
- Set scale-out aggressively (respond quickly to demand) and scale-in conservatively (avoid flapping with cooldown periods).
- Define minimum capacity to handle baseline traffic without scaling delays. Define maximum capacity as a cost ceiling.
- Use predictive scaling (AWS) for workloads with known daily or weekly patterns.
- Test scaling behavior under load. Verify that new instances are healthy and serving traffic before the original instances are terminated.
