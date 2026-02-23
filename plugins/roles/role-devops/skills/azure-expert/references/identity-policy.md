# Azure Identity, RBAC, Managed Identities, and Azure Policy

## When to load
Load when configuring Entra ID RBAC, Privileged Identity Management, Managed Identities,
Workload Identity federation, or Azure Policy guardrails at management group and subscription scope.

## Identity and Access (Microsoft Entra ID)

### RBAC and Least Privilege
- Azure uses **Role-Based Access Control (RBAC)** at management group, subscription, resource group, and resource scope levels. Always assign roles at the narrowest scope that satisfies the requirement.
- Use **built-in roles** over custom roles where they fit (Contributor, Reader, specific data plane roles). Avoid `Owner` and `Contributor` at subscription scope for regular workloads.
- Create **custom roles** using JSON role definitions when built-in roles are too broad. Scope `assignableScopes` to the specific subscription or resource group.
- Use **Privileged Identity Management (PIM)** for just-in-time (JIT) elevation to privileged roles. No permanent `Owner` or `Global Administrator` assignments — require approval and time-bound activation.
- Apply **Conditional Access policies** to enforce MFA for all users and specific conditions (risky sign-in, unmanaged devices, non-trusted locations).
- Use **Microsoft Entra Workload Identity** (OIDC federation) for CI/CD pipelines (GitHub Actions, GitLab CI, Azure DevOps) — no client secrets or certificates needed.

### Managed Identities
- Use **System-assigned Managed Identities** for single-service scenarios — identity lifecycle tied to the Azure resource.
- Use **User-assigned Managed Identities** for identities shared across multiple services or when identity must persist beyond resource replacement.
- Grant managed identities only the specific RBAC roles they need on specific resources. Use Key Vault RBAC-backed access for secure secret access.
- Never store client secrets, certificates, or connection strings in application config or code — use managed identity-based access to Key Vault and Azure services.

### Azure Policy
- Use **Azure Policy** for preventive and audit guardrails: require tags, enforce allowed locations, require HTTPS, mandate diagnostic settings, require private endpoints.
- Assign policies at **Management Group** level to enforce organization-wide standards across all subscriptions.
- Use **Policy Initiatives** (sets of policies) for compliance frameworks: CIS Azure, NIST, ISO 27001, PCI DSS. Built-in initiatives available in Azure Security Benchmark.
- Use **Policy remediation tasks** with managed identities to auto-remediate non-compliant resources.
- Tag **Deny effect** policies carefully — they block resource creation and can disrupt operations if not tested with `Audit` first.

## CI/CD and Container Registry

### Azure DevOps and GitHub Actions
- Use **Azure DevOps Pipelines** for enterprise CI/CD with YAML-based pipeline definitions. Store pipelines in the same repository as code.
- Use **Azure DevOps environments** with approval gates for production deployments.
- Use **Microsoft-hosted agents** for standard builds. Use **self-hosted agents** in AKS or VMSS for VNet-private builds, custom tools, or performance requirements.
- Use **Workload Identity Federation** in Azure DevOps Service Connections — no stored credentials.
- Use **GitHub Actions** with OIDC and the `azure/login` action for Azure deployments from GitHub — no client secrets.

### Azure Container Registry (ACR)
- Use **Private Endpoints** for ACR in production — no public access. Configure **dedicated data endpoints** for Firewall bypass.
- Enable **ACR Tasks** for automated image building, testing, and patching triggered by base image updates.
- Use **ACR geo-replication** to replicate images to pull regions for low-latency and resilience.
- Enable **Defender for Containers** integration for vulnerability scanning of pushed images.
- Use **ACR RBAC** with Managed Identities — no admin credentials. `AcrPull` for pull-only identities (AKS, App Service), `AcrPush` for CI/CD.
- Use **ACR content trust** (Notary v2 + Cosign) for image signing and verification in AKS via image integrity.

## Cost Optimization

### Azure Reservations and Savings Plans
- Use **Azure Savings Plans for Compute** for flexible compute savings across VM families and regions (up to 65% vs. pay-as-you-go).
- Use **Reserved VM Instances** for committed VM families in specific regions for maximum discount (up to 72%). Use for AKS node pools and stable VMs.
- Use **Azure SQL Reserved Capacity** and **Cosmos DB Reserved Capacity** for predictable database workloads.
- Commit 1-year plans initially; extend to 3-year for stable, well-understood workloads.

### Cost Visibility and Governance
- Enable **Cost Management + Billing** and configure **Budgets** with alerts per subscription, resource group, and tag dimension.
- Use **Cost Allocation Tags** (via Azure Policy enforcement) for granular chargeback: `team`, `environment`, `project`.
- Use **Azure Advisor** cost recommendations: right-size underutilized VMs, delete idle resources, purchase reservations.
- Use **Cost Management exports** to Storage Account or Power BI for custom dashboards and finance reporting.
- Use **Azure Spot VMs** for interruptible batch workloads (AKS spot node pools, batch processing) — up to 90% discount.
- Implement **auto-shutdown policies** on non-production VMs using Azure Automation or DevTest Labs policies.
