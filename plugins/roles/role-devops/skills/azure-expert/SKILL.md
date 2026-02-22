---
name: azure-expert
description: |
  Deep Azure expertise covering Entra ID and RBAC, Virtual Networks, AKS,
  Azure Container Apps, App Service, Azure Functions, Azure SQL and Cosmos DB,
  Blob Storage, Azure CDN, Application Gateway, Azure Monitor, Log Analytics,
  Key Vault, Defender for Cloud, Microsoft Sentinel, Azure DevOps, ACR,
  Service Bus, Event Grid, Azure Reservations, and Cost Management for
  production Azure workloads.
allowed-tools: Read, Grep, Glob, Bash
---

# Azure Expert

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
- Grant managed identities only the specific RBAC roles they need on specific resources. Use Key Vault access policies or RBAC-backed Key Vault for secure secret access.
- Never store client secrets, certificates, or connection strings in application config or code — use managed identity-based access to Key Vault and Azure services.

### Azure Policy
- Use **Azure Policy** for preventive and audit guardrails: require tags, enforce allowed locations, require HTTPS, mandate diagnostic settings, require private endpoints.
- Assign policies at **Management Group** level to enforce organization-wide standards across all subscriptions.
- Use **Policy Initiatives** (sets of policies) for compliance frameworks: CIS Azure, NIST, ISO 27001, PCI DSS. Built-in initiatives available in Azure Security Benchmark.
- Use **Policy remediation tasks** with managed identities to auto-remediate non-compliant resources.
- Tag **Deny effect** policies carefully — they block resource creation and can disrupt operations if not tested with `Audit` first.

---

## Networking (Virtual Network)

### VNet Architecture
- Design VNets with dedicated address spaces per environment. Use **hub-and-spoke topology**: a central hub VNet for shared services (firewall, VPN/ExpressRoute, DNS, monitoring) peered to spoke VNets per workload.
- Use **Azure Virtual WAN** for large-scale multi-region hub-and-spoke with managed routing, SD-WAN integration, and Azure Firewall or NVA in virtual hubs.
- Segment VNets into subnets by tier: Application Gateway/WAF subnet, application subnet, database subnet, private endpoint subnet, AKS subnet.
- Enable **subnet delegation** for PaaS services that inject into VNets (AKS, App Service Environment, Azure SQL Managed Instance, NetApp Files).
- Use **Private Endpoints** for PaaS services (Azure SQL, Cosmos DB, Storage, Key Vault, ACR, Service Bus) — traffic stays within the VNet, off the public internet.
- Use **Azure Private DNS Zones** linked to VNets for automatic DNS resolution of private endpoint FQDNs.

### Azure Firewall and NSGs
- Use **Network Security Groups (NSGs)** for subnet and NIC-level traffic filtering. Use **Application Security Groups (ASGs)** to group VMs by role and reference ASGs in NSG rules instead of IP addresses.
- Use **Azure Firewall Premium** (IDPS, TLS inspection, URL filtering) in the hub for centralized egress control and east-west traffic inspection across spokes.
- Enable **NSG Flow Logs** to Log Analytics for traffic analysis and compliance auditing.
- Use **Azure DDoS Protection Standard** on production VNets. Standard provides adaptive tuning per resource, attack telemetry, and SLA guarantees.

### Load Balancing
- **Azure Application Gateway (WAF v2)**: regional Layer 7 LB with WAF, SSL offload, URL-based routing, session affinity, autoscaling. Use for web workloads requiring WAF.
- **Azure Front Door (Premium)**: global anycast Layer 7 LB with WAF, CDN, origin health probing, and Rules Engine for traffic manipulation. Use for multi-region global web applications.
- **Azure Load Balancer (Standard)**: Layer 4 TCP/UDP, zonal HA, backend pools with VMs or VMSS. Use for non-HTTP workloads or as an internal LB.
- **Azure Traffic Manager**: DNS-based global traffic routing with geographic, performance, weighted, and priority routing methods. Use for multi-region failover and latency-based routing.
- Use **Application Gateway Ingress Controller (AGIC)** for AKS to provision Application Gateway from Kubernetes Ingress resources.

---

## Compute

### AKS (Azure Kubernetes Service)
- Use **Azure CNI** for production AKS clusters: pods get VNet IPs, enabling direct NSG control, private endpoint access, and integration with Azure-native networking.
- Use **Azure CNI Overlay** for large clusters where IP exhaustion is a concern — pods use an overlay network with VNet IPs only on nodes.
- Enable **AKS Workload Identity** (OIDC + Azure AD federation) for pod-level Azure API access without secrets.
- Use **AKS node pools**: system node pool for critical kube-system components, user node pools for application workloads. Use dedicated node pools for GPU/specialized hardware.
- Enable **Cluster Autoscaler** on node pools and **KEDA** for event-driven pod scaling.
- Use **Azure Linux** (CBL-Mariner) or **Ubuntu** node images. Enable **auto-upgrade channels** (`patch` or `node-image`) for security patches.
- Enable **Defender for Containers** for runtime threat detection, image vulnerability assessment, and Kubernetes audit log analysis.
- Use **Azure Policy for AKS** (OPA Gatekeeper integration) to enforce pod security standards (disallow privileged pods, require resource limits, restrict image registries).
- Enable **AKS private cluster** for production — API server not exposed on public internet. Use private endpoints and DNS private zones.
- Use **NAP (Node Auto-Provisioning)** (Karpenter-based, preview) for dynamic optimal node provisioning in AKS.

### Azure Container Apps
- Use **Container Apps** for serverless container workloads with event-driven scaling (KEDA built-in), without managing Kubernetes.
- Deploy Container Apps in a **Container Apps Environment** backed by a managed Kubernetes cluster. Use VNet-integrated environments for private networking.
- Use **Dapr** sidecar integration in Container Apps for service-to-service communication, state management, and pub/sub abstraction.
- Use **Container Apps Jobs** for batch and scheduled workloads. **Event-driven jobs** for processing queues or event streams.

### App Service and Azure Functions
- Use **App Service Environments (ASE v3)** for private, isolated App Service with VNet integration and no shared infrastructure.
- Use **VNet Integration** on App Service to route outbound traffic through VNets for accessing private resources.
- Use **Premium Plan** for Azure Functions requiring VNet integration, longer execution times, and no cold starts.
- Use **Azure Functions Flex Consumption** (per-execution billing + VNet support) for the best of serverless economics with enterprise networking.
- Enable **Managed Identity** on all App Service and Functions apps for Azure service authentication.

---

## Storage and Databases

### Azure Blob Storage
- Use **Private Endpoints** for all production storage accounts — disable public network access.
- Enable **Storage Firewall** with specific VNet and IP allowlists as a defense-in-depth layer even with private endpoints.
- Use **Azure AD-based RBAC** for data plane access (Storage Blob Data Reader/Contributor) instead of storage account keys.
- Rotate storage account keys regularly or use Azure Key Vault for key management. Prefer managed identity access and disable key-based access where possible.
- Use **Lifecycle Management policies** to tier blobs to Cool, Cold, Archive, or delete based on age and last access time.
- Enable **Blob versioning** and **soft delete** for point-in-time recovery. Use **immutability policies** (WORM) for compliance data.
- Use **Azure Data Lake Storage Gen2** (hierarchical namespace on Blob Storage) for analytics workloads with directory-level ACLs.

### Azure SQL Database
- Deploy **Azure SQL Elastic Pool** to share compute across multiple databases with variable utilization. Use dedicated single-database sizing for consistently high-traffic databases.
- Use **Business Critical** tier for highest availability (built-in readable replicas, in-memory OLTP) and lowest latency. Use **General Purpose** for standard workloads.
- Enable **Azure SQL Managed Instance** for near-complete SQL Server feature compatibility and VNet-native deployment.
- Use **Microsoft Entra authentication** for SQL Database — no SQL login passwords. Assign Entra groups to database roles.
- Enable **Advanced Threat Protection** and **SQL Vulnerability Assessment** for security monitoring.
- Use **Geo-replication** or **Failover Groups** for cross-region disaster recovery with transparent failover.
- Enable **Transparent Data Encryption (TDE)** with **Customer-Managed Keys (CMK)** via Key Vault for data at rest encryption.

### Cosmos DB
- Choose the right **Cosmos DB API**: Core SQL (recommended default), MongoDB, Cassandra, Gremlin (graph), Table. Core SQL has most feature parity and best SDK support.
- Design **partition keys** with high cardinality and even distribution. Partition key choice is irreversible — get it right from the start.
- Use **serverless** Cosmos DB for development and unpredictable low-traffic workloads. Use **provisioned throughput with autoscale** for production.
- Enable **multi-region writes** for global active-active with configurable conflict resolution policies.
- Use **Cosmos DB RBAC** (built-in SQL roles) for data plane access with managed identities — no primary keys in application config.
- Enable **continuous backups** for point-in-time restore up to 30 days.

---

## Messaging and Events

### Service Bus
- Use **Service Bus queues** for point-to-point reliable messaging. Use **topics and subscriptions** for fan-out pub/sub patterns.
- Use **Premium tier** for VNet integration, private endpoints, message sessions, and large message support.
- Enable **message sessions** for ordered, stateful processing where all messages for a logical entity must be processed by the same consumer.
- Configure **Dead Letter Queues** (built-in) for messages that exceed `MaxDeliveryCount` or expire via TTL.
- Use **Service Bus Managed Identity** access — no connection strings in application config.

### Event Grid and Event Hubs
- **Event Grid**: event routing from Azure services (Blob Storage, Cosmos DB, Resource Manager, custom topics) to handlers (Functions, Logic Apps, Service Bus, webhooks). Use for low-latency reactive event processing.
- **Event Hubs**: high-throughput event streaming (Kafka-compatible). Use for log ingestion, telemetry pipelines, real-time analytics, and large-scale event streams.
- Use **Event Hubs Capture** to automatically archive raw event stream data to Blob Storage or Data Lake for replay and analysis.
- Use **Event Hubs with Kafka protocol** for existing Kafka applications without code changes (just update the broker endpoint and authentication).

---

## Security

### Azure Key Vault
- Use **Key Vault** for secrets, certificates, and cryptographic keys. Separate Key Vaults per environment and per application where secrets have different access requirements.
- Use **Azure RBAC** for Key Vault data plane access (recommended over access policies for new deployments). Roles: `Key Vault Secrets User`, `Key Vault Secrets Officer`, etc.
- Enable **soft delete** and **purge protection** on all Key Vaults to prevent accidental or malicious deletion.
- Use **Key Vault references** in App Service and Functions configuration for transparent secret injection without code changes.
- Enable **Key Vault Managed HSM** for FIPS 140-2 Level 3 key protection for regulated industries.
- Rotate secrets and certificates automatically using Event Grid notifications or Key Vault native rotation policies.

### Defender for Cloud
- Enable **Defender for Cloud** at the subscription level (or via Azure Policy at Management Group) for security posture management (CSPM) and workload protection.
- Enable **Defender for Servers** (Microsoft Defender for Endpoint integration), **Defender for Containers**, **Defender for SQL**, **Defender for Storage**, and **Defender for Key Vault** on all production subscriptions.
- Review the **Secure Score** and prioritize remediations. Integrate Defender recommendations with Azure DevOps or GitHub Issues for developer-driven remediation workflows.
- Use **Regulatory Compliance dashboard** for built-in framework assessments: Azure CIS, PCI DSS, ISO 27001, SOC 2.

### Microsoft Sentinel
- Use **Microsoft Sentinel** as the cloud-native SIEM/SOAR. Connect Azure activity logs, Defender for Cloud alerts, Entra ID sign-in logs, Office 365, and third-party sources.
- Use **Sentinel Analytics Rules** (scheduled, real-time, fusion) for threat detection. Leverage MITRE ATT&CK mapping for detection coverage visibility.
- Build **automation rules and playbooks** (Logic Apps) for automated incident response: block user, revoke session, isolate VM.
- Use **Sentinel Workbooks** for security dashboards. Use the built-in Threat Intelligence integration for IOC matching.

---

## Observability (Azure Monitor)

- Use **Log Analytics Workspaces** as the central store for all Azure and application logs. Design workspace topology: one workspace per environment, or centralized with table-level RBAC.
- Route all Azure resource diagnostic logs and platform metrics to Log Analytics via **Diagnostic Settings**. Use Azure Policy to enforce diagnostic settings across all resources.
- Use **KQL (Kusto Query Language)** for log queries, alert queries, and workbook queries. KQL is powerful for time-series, statistical, and join operations across log tables.
- Define **Azure Monitor Alerts** using KQL log search or metric rules. Use **Action Groups** for alert routing (email, SMS, webhook, ITSM, Logic App).
- Use **Azure Monitor Workbooks** for interactive dashboards combining metrics, logs, parameters, and visualizations.
- Use **Application Insights** for APM: distributed traces, dependency tracking, exception tracking, live metrics, availability tests, and usage analytics.
- Enable **OpenTelemetry-based instrumentation** via Azure Monitor OpenTelemetry Distro for .NET, Java, Node.js, Python.
- Use **Azure Monitor Managed Grafana** for Grafana dashboards fed by Azure Monitor data sources.

---

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

---

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

---

## Best Practices Checklist

1. All subscriptions under Management Groups with Azure Policy enforcing standards
2. PIM for all privileged role assignments — no permanent Owner/Contributor at subscription scope
3. Workload Identity (OIDC federation) for CI/CD pipelines — no client secrets
4. Managed Identities for all compute services — no client secrets in config
5. Private Endpoints for all PaaS services (SQL, Storage, Key Vault, ACR, Service Bus)
6. Hub-and-spoke VNet topology with Azure Firewall for centralized egress
7. AKS private cluster with Azure AD RBAC, Workload Identity, and Defender for Containers
8. Key Vault purge protection and soft delete enabled on all vaults
9. Defender for Cloud enabled across all subscriptions with Secure Score monitored
10. Diagnostic settings on all resources routing to Log Analytics (enforced via Policy)
11. Azure Monitor Alerts with burn-rate-based SLO alerting
12. ACR with private endpoints, geo-replication, and vulnerability scanning
13. Azure Reservations or Savings Plans covering baseline compute spend
14. Budget alerts configured at subscription and resource group level
15. DDoS Protection Standard on production VNets hosting public-facing workloads
