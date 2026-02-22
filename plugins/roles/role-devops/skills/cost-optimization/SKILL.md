---
name: cost-optimization
description: |
  Cloud cost optimization expertise covering instance right-sizing, reserved and
  savings plans, spot/preemptible instances, resource tagging, cost allocation,
  FinOps practices, auto-scaling policies, storage lifecycle, and unused resource cleanup.
allowed-tools: Read, Grep, Glob, Bash
---

# Cost Optimization

## Right-Sizing Instances

- Analyze CPU and memory utilization over 14-30 days before selecting instance types. Sustained utilization below 40% signals over-provisioning.
- Use cloud-native tools: AWS Compute Optimizer, GCP Recommender, Azure Advisor for right-sizing recommendations.
- Start smaller and scale up based on data, not assumptions. An `m5.large` is often sufficient where teams default to `m5.xlarge`.
- For Kubernetes workloads, use VPA recommendations to set accurate resource requests, then right-size node pools accordingly.
- Re-evaluate instance sizing quarterly or after significant traffic pattern changes.

## Reserved Instances and Savings Plans

- Commit to reserved instances or savings plans for stable, predictable workloads. 1-year commitments offer 30-40% savings; 3-year commitments offer 50-60%.
- Use **Compute Savings Plans** (AWS) for flexibility across instance families and regions. Use **Reserved Instances** only when you are certain of the specific instance type.
- Cover baseline capacity with commitments, not peak. Let on-demand and spot handle variable load above the baseline.
- Review reservation utilization monthly. Unused reservations are wasted money. Sell or exchange underutilized reservations.
- Stagger reservation purchases to avoid cliff-edge renewals and maintain flexibility.

## Spot and Preemptible Instances

- Use spot instances (AWS), preemptible VMs (GCP), or spot VMs (Azure) for fault-tolerant workloads: batch processing, CI/CD runners, stateless web tier with auto-scaling.
- Diversify across multiple instance types and availability zones to reduce interruption frequency.
- Implement graceful shutdown handling: trap SIGTERM, drain connections, checkpoint state.
- In Kubernetes, use mixed node pools with spot and on-demand nodes. Taint spot nodes and tolerate from non-critical workloads.
- Expected savings: 60-90% compared to on-demand pricing.

## Resource Tagging Strategy

- Enforce mandatory tags on all resources: `environment`, `service`, `team`, `cost-center`, `managed-by`.
- Use tag policies (AWS Organizations) or policy-as-code (OPA, Sentinel) to prevent untagged resource creation.
- Tags enable cost allocation, ownership identification, and automated cleanup of orphaned resources.
- Standardize tag values: use lowercase, hyphens, and a documented tag dictionary. Avoid free-form values.
- Audit tag compliance weekly and report non-compliant resources to owning teams.

## Cost Allocation and Showback

- Allocate cloud costs to business units, teams, or products using tags and cost allocation reports.
- Use AWS Cost Explorer, GCP Billing Reports, or Azure Cost Management for cost breakdowns by service, region, and tag.
- Implement **showback** (visibility) before **chargeback** (billing). Teams need to see their costs before they can optimize.
- Create per-team cost dashboards updated daily. Highlight trends, anomalies, and top cost drivers.
- Set cost anomaly detection alerts: notify when daily spend exceeds the trailing average by more than 20%.

## FinOps Practices

- Treat cloud cost management as a continuous practice, not a one-time project. Assign a FinOps champion or team.
- Follow the FinOps lifecycle: **Inform** (visibility) -> **Optimize** (action) -> **Operate** (governance).
- Hold monthly cost review meetings with engineering leads. Review top 10 cost drivers and optimization opportunities.
- Benchmark unit economics: cost per request, cost per customer, cost per transaction. Optimize for business efficiency, not just absolute cost.
- Build a culture where engineers consider cost as a non-functional requirement alongside performance and reliability.

## Auto-Scaling Policies

- Configure auto-scaling based on actual demand metrics, not just CPU. Use request rate, queue depth, or custom business metrics.
- Set scale-out aggressively (respond quickly to demand) and scale-in conservatively (avoid flapping with cooldown periods).
- Define minimum capacity to handle baseline traffic without scaling delays. Define maximum capacity as a cost ceiling.
- Use predictive scaling (AWS) for workloads with known daily or weekly patterns.
- Test scaling behavior under load. Verify that new instances are healthy and serving traffic before the original instances are terminated.

## Storage Lifecycle Management

- Implement S3/GCS lifecycle policies to transition infrequently accessed data to cheaper storage classes (S3 IA, Glacier, Coldline).
- Delete temporary data (CI artifacts, log exports, development snapshots) after a defined retention period.
- Use intelligent tiering (S3 Intelligent-Tiering) for data with unpredictable access patterns.
- Review EBS/persistent disk snapshots monthly. Delete orphaned snapshots and volumes not attached to running instances.
- Archive old database backups to cold storage. Maintain only the most recent N backups in hot storage.

## Unused Resource Cleanup

- Scan for idle resources weekly: unattached EBS volumes, unused Elastic IPs, empty load balancers, stopped instances running for more than 7 days.
- Use tools like AWS Trusted Advisor, GCP Recommender, or open-source tools (Cloud Custodian, Komiser) for automated detection.
- Implement automated cleanup for development environments: schedule non-production resources to shut down outside business hours.
- Tag resources with an `expiry` date for temporary workloads. Automate deletion when the date passes.
- Review and delete unused IAM roles, security groups, and other non-billable but cluttering resources.

## Cost Alerts and Budgets

- Set monthly budgets per account, team, or project. Alert at 50%, 80%, and 100% thresholds.
- Configure daily spend alerts for early detection of cost anomalies (misconfigured auto-scaling, runaway batch jobs).
- Use budget actions to automatically restrict resource creation when budgets are exceeded in non-production accounts.

## Best Practices Checklist

1. All resources tagged with mandatory cost allocation tags
2. Baseline workloads covered by reservations or savings plans
3. Spot instances used for fault-tolerant workloads
4. Auto-scaling configured with appropriate metrics and limits
5. Storage lifecycle policies active on all buckets
6. Weekly unused resource scan and cleanup
7. Monthly cost review with engineering stakeholders
8. Cost anomaly alerts configured and tested
