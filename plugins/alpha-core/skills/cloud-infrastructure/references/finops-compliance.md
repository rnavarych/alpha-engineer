# FinOps, Multi-Cloud, and Compliance

## When to load
Load when optimizing cloud costs, planning multi-cloud strategy, evaluating reserved instances vs savings plans, or addressing compliance requirements (SOC 2, HIPAA, data residency).

## FinOps: Cloud Cost Optimization

### Cost Allocation

- **Tagging strategy**: Enforce tags for `environment`, `team`, `project`, `cost-center`, `owner`
- **Tag policies**: AWS Tag Policies, GCP labels with org policies, Azure Policy for required tags
- **Showback/chargeback**: Allocate costs to teams. Use CUR (AWS), billing export (GCP), Cost Management (Azure).
- Set billing alerts at 50%, 80%, 100% of monthly budget
- Review cost anomaly detection (AWS Cost Anomaly Detection, GCP budgets with alerts)
- Use Infracost in CI/CD to estimate cost impact of infrastructure changes before merge

### Reserved Instances vs Savings Plans

| Feature | Reserved Instances | Savings Plans (AWS) | CUDs (GCP) |
|---------|-------------------|---------------------|------------|
| **Commitment** | Specific instance type + region | $/hr spend commitment | vCPU + memory in region |
| **Flexibility** | Low (convertible has some) | High (any instance type) | Medium (machine family) |
| **Discount** | Up to 72% (3yr all upfront) | Up to 72% | Up to 57% (3yr) |
| **Best for** | Stable, predictable workloads | Flexible compute spending | Steady-state GCP workloads |

### Compute Pricing Reference (approximate, us-east, Linux)

| Instance Class | AWS (EC2) | GCP (Compute Engine) | Azure (VMs) |
|---------------|-----------|---------------------|-------------|
| 2 vCPU, 8 GB | m7i.large: ~$70/mo | e2-standard-2: ~$49/mo | D2s v5: ~$70/mo |
| 4 vCPU, 16 GB | m7i.xlarge: ~$140/mo | e2-standard-4: ~$97/mo | D4s v5: ~$140/mo |
| 8 vCPU, 32 GB | m7i.2xlarge: ~$280/mo | e2-standard-8: ~$195/mo | D8s v5: ~$280/mo |
| **Sustained discount** | None (use RIs/SPs) | Auto 20-30% | None (use RIs/SPs) |
| **Spot discount** | Up to 90% | Up to 91% | Up to 90% |

### Right-Sizing Tools

- **AWS Compute Optimizer**: ML-based instance recommendations from CloudWatch metrics
- **GCP Recommender**: VM, disk, and idle resource recommendations
- **Azure Advisor**: Right-size, shutdown, and reserved instance recommendations
- **Third-party**: Spot.io (now NetApp), Cast AI (Kubernetes), Kubecost, Infracost (IaC cost estimation)

## Multi-Cloud Strategy

### When to Use Multi-Cloud

- **Compliance**: Data residency requiring specific regions only available on certain providers
- **Best-of-breed**: BigQuery for analytics + AWS for everything else
- **M&A**: Acquired company on different cloud
- **Vendor negotiation**: Leverage for pricing negotiations

### When to Avoid Multi-Cloud

- Small/medium teams (operational overhead is prohibitive)
- No specific compliance or technical driver
- "Just in case" is not a valid reason (cost of abstraction > benefit)

### Abstraction Layers

- **Kubernetes**: Workload portability across clouds (EKS, GKE, AKS)
- **Terraform**: Infrastructure portability with provider-specific modules
- **Crossplane**: Kubernetes-native infrastructure provisioning across clouds
- **Dapr**: Application runtime abstraction (service invocation, state, pub/sub)
- **Data gravity**: Data is expensive and slow to move. Egress: AWS ($0.09/GB), GCP ($0.12/GB), Azure ($0.087/GB).

## Compliance

### SOC 2

- All three major clouds support SOC 2 Type II compliance
- Enable audit logging: CloudTrail, Cloud Audit Logs, Azure Activity Log
- Encryption at rest and in transit by default
- Implement least-privilege IAM with regular access reviews

### HIPAA-Eligible Services

- **AWS**: 100+ HIPAA-eligible services, BAA required. Key: S3, RDS, Lambda, ECS, SageMaker
- **GCP**: 80+ covered services, BAA required. Key: GKE, Cloud SQL, BigQuery, Vertex AI
- **Azure**: 90+ in-scope services, BAA required. Key: Azure SQL, AKS, Azure OpenAI

### Data Residency

- **AWS**: 33 regions. Local Zones for low-latency. AWS Outposts for on-premises.
- **GCP**: 40 regions. Assured Workloads for compliance. Sovereign Controls.
- **Azure**: 60+ regions. Azure Government (US), Azure China (21Vianet), Confidential Computing.
- Use org policies to restrict resource creation to approved regions
- Key regulations: EU (GDPR), Australia, Canada, India, US Government (FedRAMP)
