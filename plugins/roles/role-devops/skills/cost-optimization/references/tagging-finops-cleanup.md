# Tagging, FinOps, Storage Lifecycle, and Unused Resource Cleanup

## When to load
Load when establishing cost allocation tagging strategy, setting up FinOps practices,
configuring storage lifecycle policies, running unused resource cleanup, or setting up cost alerts and budgets.

## Resource Tagging Strategy

- Enforce mandatory tags on all resources: `environment`, `service`, `team`, `cost-center`, `managed-by`.
- Use tag policies (AWS Organizations) or policy-as-code (OPA, Sentinel, Azure Policy) to prevent untagged resource creation.
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
- Follow the FinOps lifecycle: **Inform** (visibility) → **Optimize** (action) → **Operate** (governance).
- Hold monthly cost review meetings with engineering leads. Review top 10 cost drivers and optimization opportunities.
- Benchmark unit economics: cost per request, cost per customer, cost per transaction. Optimize for business efficiency, not just absolute cost.
- Build a culture where engineers consider cost as a non-functional requirement alongside performance and reliability.

## Storage Lifecycle Management

- Implement S3/GCS lifecycle policies to transition infrequently accessed data to cheaper storage classes (S3 IA, Glacier, Coldline).
- Delete temporary data (CI artifacts, log exports, development snapshots) after a defined retention period.
- Use intelligent tiering (S3 Intelligent-Tiering) for data with unpredictable access patterns.
- Review EBS/persistent disk snapshots monthly. Delete orphaned snapshots and volumes not attached to running instances.
- Archive old database backups to cold storage. Maintain only the most recent N backups in hot storage.

## Unused Resource Cleanup

- Scan for idle resources weekly: unattached EBS volumes, unused Elastic IPs, empty load balancers, stopped instances running for more than 7 days.
- Use tools like AWS Trusted Advisor, GCP Recommender, Azure Advisor, or open-source tools (Cloud Custodian, Komiser) for automated detection.
- Implement automated cleanup for development environments: schedule non-production resources to shut down outside business hours.
- Tag resources with an `expiry` date for temporary workloads. Automate deletion when the date passes.
- Review and delete unused IAM roles, security groups, and other non-billable but cluttering resources.

## Cost Alerts and Budgets

- Set monthly budgets per account, team, or project. Alert at 50%, 80%, and 100% thresholds.
- Configure daily spend alerts for early detection of cost anomalies (misconfigured auto-scaling, runaway batch jobs).
- Use budget actions to automatically restrict resource creation when budgets are exceeded in non-production accounts.
