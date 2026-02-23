# Azure Storage, Databases, Security, and Observability

## When to load
Load when configuring Blob Storage, Azure SQL, Cosmos DB, Key Vault, Defender for Cloud,
Microsoft Sentinel, or Azure Monitor and Log Analytics observability stack.

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
- Deploy **Azure SQL Elastic Pool** to share compute across multiple databases with variable utilization.
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

## Security

### Azure Key Vault
- Use **Key Vault** for secrets, certificates, and cryptographic keys. Separate Key Vaults per environment and per application where secrets have different access requirements.
- Use **Azure RBAC** for Key Vault data plane access (recommended over access policies for new deployments). Roles: `Key Vault Secrets User`, `Key Vault Secrets Officer`, etc.
- Enable **soft delete** and **purge protection** on all Key Vaults to prevent accidental or malicious deletion.
- Use **Key Vault references** in App Service and Functions configuration for transparent secret injection without code changes.
- Enable **Key Vault Managed HSM** for FIPS 140-2 Level 3 key protection for regulated industries.
- Rotate secrets and certificates automatically using Event Grid notifications or Key Vault native rotation policies.

### Defender for Cloud
- Enable **Defender for Cloud** at the subscription level for security posture management (CSPM) and workload protection.
- Enable **Defender for Servers**, **Defender for Containers**, **Defender for SQL**, **Defender for Storage**, and **Defender for Key Vault** on all production subscriptions.
- Review the **Secure Score** and prioritize remediations. Integrate Defender recommendations with Azure DevOps or GitHub Issues for developer-driven remediation workflows.
- Use **Regulatory Compliance dashboard** for built-in framework assessments: Azure CIS, PCI DSS, ISO 27001, SOC 2.

### Microsoft Sentinel
- Use **Microsoft Sentinel** as the cloud-native SIEM/SOAR. Connect Azure activity logs, Defender for Cloud alerts, Entra ID sign-in logs, Office 365, and third-party sources.
- Use **Sentinel Analytics Rules** (scheduled, real-time, fusion) for threat detection. Leverage MITRE ATT&CK mapping for detection coverage visibility.
- Build **automation rules and playbooks** (Logic Apps) for automated incident response: block user, revoke session, isolate VM.
- Use **Sentinel Workbooks** for security dashboards. Use the built-in Threat Intelligence integration for IOC matching.

## Observability (Azure Monitor)

- Use **Log Analytics Workspaces** as the central store for all Azure and application logs. Design workspace topology: one workspace per environment, or centralized with table-level RBAC.
- Route all Azure resource diagnostic logs and platform metrics to Log Analytics via **Diagnostic Settings**. Use Azure Policy to enforce diagnostic settings across all resources.
- Use **KQL (Kusto Query Language)** for log queries, alert queries, and workbook queries. KQL is powerful for time-series, statistical, and join operations across log tables.
- Define **Azure Monitor Alerts** using KQL log search or metric rules. Use **Action Groups** for alert routing (email, SMS, webhook, ITSM, Logic App).
- Use **Azure Monitor Workbooks** for interactive dashboards combining metrics, logs, parameters, and visualizations.
- Use **Application Insights** for APM: distributed traces, dependency tracking, exception tracking, live metrics, availability tests, and usage analytics.
- Enable **OpenTelemetry-based instrumentation** via Azure Monitor OpenTelemetry Distro for .NET, Java, Node.js, Python.
- Use **Azure Monitor Managed Grafana** for Grafana dashboards fed by Azure Monitor data sources.
