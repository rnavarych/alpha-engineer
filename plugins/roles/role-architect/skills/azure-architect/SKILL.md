---
name: azure-architect
description: |
  Azure architecture expertise including Azure Well-Architected Framework,
  subscription and management group strategy, virtual network and hybrid networking,
  identity architecture with Entra ID, data platform design, Kubernetes and
  serverless patterns, security architecture, and cost optimization strategies.
  Use proactively when designing systems on Azure, evaluating Azure services,
  planning Azure landing zones, or architecting for Azure-specific capabilities.
allowed-tools: Read, Grep, Glob, Bash
---

# Azure Architect

## Azure Well-Architected Framework

### Five Pillars
- **Reliability**: Design for failure with Availability Zones (99.99% SLA for zone-redundant deployments). Use Azure Load Balancer or Application Gateway for health-probed traffic distribution. Implement retry policies with Polly or built-in SDK retry. Use Azure Chaos Studio for fault injection testing. Define RTO/RPO targets and validate with regular DR drills.
- **Security**: Use Microsoft Entra ID (formerly Azure AD) as the identity foundation. Enable Conditional Access for risk-based authentication. Use Azure Policy for compliance guardrails. Enable Microsoft Defender for Cloud for threat detection across all resource types. Follow the Zero Trust model: verify explicitly, use least privilege, assume breach.
- **Cost Optimization**: Use Azure Advisor cost recommendations. Right-size with Azure Monitor metrics and VM insights. Use Reserved Instances (1-year or 3-year) for predictable workloads. Use Spot VMs for interruptible workloads. Implement auto-shutdown for dev/test environments. Use Azure Cost Management + Billing for budgets, alerts, and cost analysis.
- **Operational Excellence**: Use Infrastructure as Code (Bicep, Terraform, ARM templates). Implement CI/CD with Azure DevOps or GitHub Actions. Use Azure Monitor, Log Analytics, and Application Insights for full-stack observability. Define and track SLIs/SLOs. Use Azure Deployment Environments for self-service developer environments.
- **Performance Efficiency**: Select the right compute tier and size based on workload profiling. Use Azure CDN or Front Door for global content delivery. Use Azure Cache for Redis for hot data paths. Profile with Application Insights and identify bottlenecks before scaling. Use Proximity Placement Groups for latency-sensitive workloads.

### Well-Architected Reviews
- Use the Azure Well-Architected Review tool in the Azure portal. Conduct assessments per workload, not per subscription. Track recommendations and remediation progress over time.
- Use Azure Advisor for automated recommendations across reliability, security, performance, cost, and operational excellence.

## Subscription and Management Group Strategy

### Management Group Hierarchy
- Tenant Root Group → Platform Management Groups → Workload Management Groups → Subscriptions. Design the hierarchy to match organizational and governance requirements.
- **Azure Landing Zone architecture**: Platform group contains Identity (Entra ID, DNS), Management (monitoring, logging, automation), and Connectivity (hub networking, ExpressRoute, Firewall) subscriptions. Workload group contains application-specific subscriptions organized by environment and business unit.
- Use **Cloud Adoption Framework (CAF)** landing zone accelerators for automated deployment. Choose between the Bicep, Terraform, or Azure Portal deployment options.

### Subscription Strategy
- Use subscriptions as scale units and policy boundaries. One subscription per application per environment for strong isolation. Group related subscriptions under management groups for shared policy application.
- Avoid subscription sprawl by right-sizing: a single subscription supports up to 800 resource groups. Split when you need independent billing, separate RBAC boundaries, or distinct Azure Policy assignments.
- Use **Subscription Vending** automation: self-service subscription provisioning with pre-configured networking, policies, and RBAC. Implement with Azure DevOps pipelines or Terraform modules triggered by ServiceNow or internal portal requests.

### Azure Policy
- Apply policies at the management group level for organization-wide governance. Use built-in policy initiatives (CIS Azure Benchmark, NIST SP 800-53, ISO 27001) as baselines.
- Key policies: enforce resource tagging, restrict allowed regions, require encryption, deny public IP creation on VMs, enforce diagnostics settings, restrict allowed VM SKUs.
- Use **Azure Policy as Code**: store policy definitions in Git, deploy with CI/CD pipelines. Use policy exemptions (with expiration dates) for approved exceptions.

## Networking Architecture

### Hub-and-Spoke Topology
- **Hub VNet**: Central connectivity hub containing Azure Firewall (or third-party NVA), VPN Gateway, ExpressRoute Gateway, Azure Bastion, and shared services (DNS, Active Directory). One hub per region.
- **Spoke VNets**: Application workload networks peered to the hub. Use VNet peering for hub-to-spoke connectivity. Force-tunnel all outbound traffic through the hub firewall for centralized inspection and policy enforcement.
- Use **Azure Virtual WAN** for large-scale hub-and-spoke when managing multiple hubs, VPN sites, and ExpressRoute circuits. Virtual WAN automates routing between hubs and supports transit connectivity.

### Azure Front Door and Application Gateway
- **Azure Front Door**: Global HTTP load balancer with CDN, WAF, and SSL offloading. Use for global applications requiring fast failover (< 30 seconds), geo-routing, and DDoS protection. Supports custom domains, managed certificates, and Private Link origins.
- **Application Gateway**: Regional layer-7 load balancer with WAF v2. Use for applications within a single region. Supports URL-based routing, session affinity, SSL termination, and WebSocket. Use with AKS via Application Gateway Ingress Controller (AGIC).
- **Azure Firewall**: Managed network firewall with threat intelligence, TLS inspection, FQDN filtering, and network rules. Use Premium SKU for TLS inspection and IDPS. Deploy in each hub VNet for centralized network policy enforcement.

### Hybrid Connectivity
- **ExpressRoute**: Private connectivity to Azure (50 Mbps to 100 Gbps). Use ExpressRoute Global Reach for site-to-site connectivity through Microsoft's backbone. Use ExpressRoute Direct for dedicated ports at peering locations. FastPath for bypassing the gateway for ultra-low latency.
- **Site-to-Site VPN**: IPsec tunnels over the public internet. Use VPN Gateway with active-active configuration for high availability. Use zone-redundant gateway SKUs in production.
- **Azure Private Link**: Access Azure PaaS services (Storage, SQL, Cosmos DB, Key Vault) over a private endpoint in your VNet. Eliminates public internet exposure. Use Private DNS Zones for name resolution of private endpoints.

## Identity Architecture

### Microsoft Entra ID (Azure AD)
- Central identity platform for all Azure access. Use Entra ID as the authoritative identity provider for both human and workload identities. Integrate with on-premises Active Directory using Entra Connect (hybrid identity) or go cloud-native.
- **Conditional Access**: Risk-based access policies that evaluate sign-in risk, device compliance, location, and application sensitivity. Require MFA for all users. Block legacy authentication protocols. Require compliant or Entra-joined devices for accessing sensitive applications.
- **Privileged Identity Management (PIM)**: Just-in-time privileged access. Assign roles as eligible rather than permanent. Require approval workflows and justification for activation. Set maximum activation duration (4-8 hours). Configure access reviews for periodic role validation.

### Workload Identity
- **Managed Identities**: System-assigned (tied to the resource lifecycle) or user-assigned (independent lifecycle, reusable). Use for all service-to-Azure-resource authentication. Eliminates credential management for Azure SDK calls, Key Vault access, Storage access, and database connections.
- **Workload Identity Federation**: Authenticate external workloads (GitHub Actions, GCP services, Kubernetes clusters) to Azure without storing credentials. Configure trust relationships between external identity providers and Entra ID applications.
- **Service principals**: Use for CI/CD pipelines and third-party integrations that cannot use managed identities. Rotate secrets on a 90-day schedule. Prefer certificate-based authentication over client secrets.

### RBAC Design
- Use Azure built-in roles when possible. Create custom roles only when built-in roles grant too broad or too narrow access. Follow least-privilege: prefer Reader over Contributor, Contributor over Owner.
- Assign roles to Entra ID groups, not individual users. Use dynamic groups based on user attributes for automatic membership management.
- Scope roles at the narrowest level possible: resource group > subscription > management group. Avoid management-group-level Owner or Contributor assignments.

## Compute Architecture

### AKS Architecture
- **AKS with Azure CNI Overlay**: Default networking mode. Pods get IPs from an overlay network (reduces VNet IP consumption). Use Azure CNI Powered by Cilium for advanced network policies and observability.
- **Node pool strategy**: System node pool (dedicated to system pods, tainted for NoSchedule of user workloads) and user node pools (per workload type: general purpose, GPU, memory-optimized). Use cluster autoscaler for dynamic scaling. Use KEDA for event-driven pod scaling.
- **AKS security**: Enable Azure Policy for AKS (Gatekeeper-based admission control). Use Workload Identity (Entra ID federated credentials for pods). Enable Defender for Containers for runtime threat detection. Use Azure Key Vault provider for Secrets Store CSI Driver.
- **AKS Fleet Manager**: Multi-cluster management for AKS. Use for consistent configuration, workload placement, and multi-cluster load balancing. Deploy applications across clusters for geographic distribution and high availability.

### Azure Container Apps
- Serverless container platform built on Kubernetes and KEDA. Scale to zero. Best for microservices, API backends, event-driven processing, and background jobs without Kubernetes operational overhead.
- Use **Dapr integration** for service invocation, state management, pub/sub, and bindings. Dapr components abstract infrastructure dependencies (swap Redis for Cosmos DB without code changes).
- Use Container Apps Jobs for batch processing and scheduled tasks. Use revision-based traffic splitting for blue-green and canary deployments.

### Azure Functions
- Event-driven serverless compute. Use Consumption plan for scale-to-zero cost optimization. Use Premium plan for VNet integration, pre-warmed instances, and larger instance sizes. Use Dedicated (App Service) plan for always-on workloads.
- **Durable Functions**: Stateful function orchestrations. Use for fan-out/fan-in, function chaining, human interaction patterns, and long-running processes. Supports .NET, JavaScript, Python, Java, and PowerShell.
- Integrate with Event Grid for Azure-native event routing. Use Azure Functions with Service Bus for reliable message processing with dead-letter handling and session support.

## Data Architecture

### Cosmos DB
- Globally distributed, multi-model database. Use for applications requiring single-digit millisecond latency at global scale. Supports document (NoSQL API), graph (Gremlin), wide-column (Cassandra), table, and PostgreSQL APIs.
- **Partition key design**: Critical for performance and cost. Choose a partition key with high cardinality and even distribution. Design for the most frequent query patterns. Avoid cross-partition queries for hot paths.
- **Consistency levels**: Five options from strong to eventual. Session consistency is the default and most common: guarantees read-your-own-writes within a session. Use strong consistency only when required (financial transactions). Use eventual for highest throughput (analytics, caching).
- **Cost optimization**: Use autoscale throughput for variable workloads. Use serverless for development and low-traffic workloads. Use reserved capacity (1-year or 3-year) for predictable throughput needs. Monitor RU consumption and optimize queries to reduce RU cost.

### Azure SQL and Synapse
- **Azure SQL Database**: Managed SQL Server. Use serverless tier for intermittent workloads (auto-pause after idle period). Use Hyperscale tier for databases up to 100 TB with instant scale-out read replicas. Use Elastic Pools for consolidating multiple databases with variable usage patterns.
- **Azure SQL Managed Instance**: Near-100% SQL Server compatibility in a managed service. Use for lift-and-shift of existing SQL Server workloads that require features not available in Azure SQL Database (cross-database queries, SQL Agent, linked servers).
- **Azure Synapse Analytics**: Unified analytics platform combining serverless and dedicated SQL pools, Spark pools, and data integration (Synapse Pipelines). Use serverless SQL pool for ad-hoc querying of data lake files (Parquet, CSV, JSON in ADLS Gen2). Use dedicated SQL pool for high-concurrency enterprise data warehousing.

### Event-Driven and Messaging
- **Azure Service Bus**: Enterprise message broker with queues and topics. Use for reliable asynchronous communication between services. Supports sessions (ordered processing), dead-lettering, duplicate detection, and scheduled delivery. Premium tier for dedicated capacity and VNet integration.
- **Azure Event Hubs**: High-throughput event streaming (millions of events/second). Use for telemetry ingestion, log aggregation, and real-time analytics. Kafka-compatible API for existing Kafka workloads. Use Event Hubs Capture for automatic archival to Azure Storage or Data Lake.
- **Azure Event Grid**: Event routing service for reactive architectures. System topics for Azure resource events (blob created, resource group changed). Custom topics for application events. Use with Azure Functions, Logic Apps, or Service Bus for event-driven processing.

### Data Lake Architecture
- **Azure Data Lake Storage Gen2**: Hierarchical namespace on Azure Blob Storage. Foundation for data lakehouse architectures. Integrates with Synapse, Databricks, HDInsight, and all Azure analytics services.
- Use **Delta Lake** or **Apache Iceberg** table format on ADLS Gen2 for ACID transactions, schema evolution, and time travel on data lake files. Enables lakehouse pattern with unified batch and streaming.
- **Microsoft Fabric**: Unified analytics platform combining data engineering, data warehousing, real-time analytics, data science, and Power BI. Use OneLake as the single data lake for the organization. Fabric simplifies the analytics stack by replacing multiple standalone services.

## Security Architecture

### Microsoft Defender for Cloud
- **Cloud Security Posture Management (CSPM)**: Continuous assessment of Azure, AWS, and GCP resources against security benchmarks. Secure Score quantifies security posture. Use CSPM recommendations to prioritize remediation.
- **Cloud Workload Protection (CWP)**: Defender for Servers (malware, vulnerability, endpoint detection), Defender for Containers (image scanning, runtime protection), Defender for SQL (threat detection, vulnerability assessment), Defender for Storage (malware scanning), and Defender for Key Vault (anomalous access detection).
- **Attack path analysis**: Visualize potential attack paths from internet exposure to sensitive data. Prioritize remediation based on actual exploitability, not theoretical risk.

### Azure Sentinel (Microsoft Sentinel)
- Cloud-native SIEM and SOAR. Ingest logs from Azure (Activity Log, Entra ID, Defender), Microsoft 365, and third-party sources. Use built-in analytics rules and threat intelligence for detection. Use Playbooks (Logic Apps) for automated response.
- **Data connectors**: Native connectors for 200+ sources. Use Common Event Format (CEF) and Syslog for on-premises and third-party systems. Use Azure Monitor Agent for VM-level log collection.
- **Cost management**: Use Basic Logs tier for high-volume, low-value logs (reduce cost by up to 80%). Use Analytics tier for security-relevant logs that require full query and alerting. Implement data retention policies per table.

### Network Security
- **Azure Firewall**: Centralized network security in hub VNets. Use application rules (FQDN-based), network rules (IP-based), and DNAT rules. Premium SKU adds TLS inspection, IDPS, URL filtering, and web categories.
- **Network Security Groups (NSGs)**: Stateful packet filtering at the subnet and NIC level. Use application security groups (ASGs) for role-based rules instead of IP-based rules. Enable NSG flow logs for traffic analysis and compliance.
- **Azure DDoS Protection**: Standard tier for automatic protection of public IPs. Provides attack analytics, alerting, and cost protection (credit for scale-out costs during attack). Enable on VNets with public-facing workloads.

### Data Protection
- **Azure Key Vault**: Centralized secrets, keys, and certificates management. Use Managed HSM for FIPS 140-2 Level 3 certified hardware protection. Enable soft-delete and purge protection for production vaults. Use RBAC (not access policies) for fine-grained access control.
- **Azure Information Protection**: Classify and protect documents and emails based on sensitivity labels. Integrate with Microsoft 365 for automatic labeling and encryption. Use with Purview for data governance across the organization.
- **Microsoft Purview**: Unified data governance across Azure, on-premises, and multi-cloud. Data catalog, data lineage, data classification, and policy management. Use for GDPR, CCPA, and industry-specific compliance requirements.

## Cost Architecture

### Reserved Instances and Savings Plans
- **Azure Reservations**: 1-year or 3-year commitments for VMs, SQL Database, Cosmos DB, Synapse, App Service, Azure Cache, and more. Savings up to 72% over pay-as-you-go. Reservations are exchangeable (swap for different size/region) and refundable (with early termination fee).
- **Azure Savings Plans**: Compute-level commitment ($/hour) that applies automatically across VM sizes, regions, and services (VMs, Container Instances, Azure Premium Functions, Azure App Service). More flexible than reservations but slightly lower discount. Use for workloads where instance type may change.
- Analyze usage with Azure Cost Management before committing. Use reservation recommendations based on 7, 30, or 60-day usage patterns.

### Spot and Dev/Test Pricing
- **Azure Spot VMs**: Up to 90% discount for interruptible workloads. Use for batch processing, CI/CD, dev/test, and stateless horizontally-scalable workloads. Set maximum price or use auto-eviction policies. Combine with VMSS for Spot-based auto-scaling.
- **Dev/Test pricing**: Reduced rates on Azure services for development and testing (no Windows Server license charges on VMs, discounted rates on PaaS services). Requires Visual Studio subscription or Enterprise Dev/Test offer. Apply to non-production subscriptions.
- **Azure Hybrid Benefit**: Use existing Windows Server and SQL Server licenses on Azure VMs. Saves up to 85% compared to pay-as-you-go when combined with reservations. Track license utilization with Azure Hybrid Benefit management tools.

### FinOps Practices
- **Azure Cost Management**: Built-in cost analysis, budgets, alerts, and recommendations. Use cost allocation rules to distribute shared costs to business units. Use tags for cost categorization (environment, team, project, cost-center).
- **Budget automation**: Create budgets with action groups that trigger Azure Functions or Logic Apps when thresholds are reached. Automate responses: send Teams/Slack notifications, shut down dev environments, or create ServiceNow tickets.
- **Azure Advisor**: Continuous recommendations for cost optimization, security, reliability, operational excellence, and performance. Review weekly. Automate recommendation implementation with Azure Policy and remediation tasks.
- **Resource lifecycle management**: Implement auto-shutdown for dev/test VMs. Use TTL (time-to-live) tags with Azure Automation to delete temporary resources. Use Azure DevTest Labs for managed dev/test environments with cost controls and auto-expiry.
