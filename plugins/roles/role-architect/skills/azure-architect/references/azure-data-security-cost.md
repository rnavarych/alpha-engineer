# Azure Data Architecture, Security, and Cost

## When to load
Load when designing Azure data platforms (Cosmos DB, Azure SQL, Synapse, Fabric), configuring security posture with Defender for Cloud and Sentinel, or optimizing costs with reservations, Savings Plans, and FinOps practices.

## Data Architecture

### Cosmos DB
- Globally distributed, multi-model database. Single-digit millisecond latency at global scale. Supports document (NoSQL), graph (Gremlin), wide-column (Cassandra), table, and PostgreSQL APIs.
- **Partition key design**: Critical for performance and cost. Choose high cardinality and even distribution. Design for the most frequent query patterns. Avoid cross-partition queries on hot paths.
- **Consistency levels**: Five options from strong to eventual. Session consistency is the default (read-your-own-writes within a session). Use strong only for financial transactions. Use eventual for highest throughput.
- **Cost optimization**: Use autoscale throughput for variable workloads. Use serverless for development and low-traffic workloads. Use reserved capacity (1-year or 3-year) for predictable throughput.

### Azure SQL and Synapse
- **Azure SQL Database**: Managed SQL Server. Serverless tier for intermittent workloads (auto-pause after idle). Hyperscale tier for databases up to 100 TB with instant scale-out read replicas. Elastic Pools for consolidating multiple databases.
- **Azure SQL Managed Instance**: Near-100% SQL Server compatibility. Use for lift-and-shift of workloads requiring cross-database queries, SQL Agent, or linked servers.
- **Azure Synapse Analytics**: Unified analytics combining serverless SQL pools, dedicated SQL pools, Spark pools, and Synapse Pipelines. Use serverless SQL pool for ad-hoc querying of data lake files (Parquet, CSV, JSON in ADLS Gen2). Use dedicated SQL pool for high-concurrency enterprise data warehousing.

### Event-Driven and Messaging
- **Azure Service Bus**: Enterprise message broker with queues and topics. Supports sessions (ordered processing), dead-lettering, duplicate detection, and scheduled delivery. Premium tier for VNet integration.
- **Azure Event Hubs**: High-throughput event streaming (millions of events/second). Kafka-compatible API. Use Event Hubs Capture for automatic archival to Azure Storage or Data Lake.
- **Azure Event Grid**: Event routing service. System topics for Azure resource events. Custom topics for application events. Use with Azure Functions, Logic Apps, or Service Bus.

### Data Lake Architecture
- **Azure Data Lake Storage Gen2**: Hierarchical namespace on Azure Blob Storage. Foundation for data lakehouse architectures. Integrates with Synapse, Databricks, HDInsight.
- Use **Delta Lake** or **Apache Iceberg** on ADLS Gen2 for ACID transactions, schema evolution, and time travel. Enables unified batch and streaming.
- **Microsoft Fabric**: Unified analytics platform combining data engineering, warehousing, real-time analytics, data science, and Power BI. OneLake as the single organizational data lake.

## Security Architecture

### Microsoft Defender for Cloud
- **Cloud Security Posture Management (CSPM)**: Continuous assessment against security benchmarks. Secure Score quantifies security posture. Covers Azure, AWS, and GCP resources.
- **Cloud Workload Protection (CWP)**: Defender for Servers (malware, vulnerability, endpoint detection), Defender for Containers (image scanning, runtime protection), Defender for SQL, Defender for Storage, Defender for Key Vault.
- **Attack path analysis**: Visualize potential attack paths from internet exposure to sensitive data. Prioritize remediation based on actual exploitability.

### Azure Sentinel (Microsoft Sentinel)
- Cloud-native SIEM and SOAR. Ingest logs from Azure, Microsoft 365, and 200+ third-party sources. Use built-in analytics rules and threat intelligence. Use Playbooks (Logic Apps) for automated response.
- **Cost management**: Use Basic Logs tier for high-volume, low-value logs (reduce cost by up to 80%). Use Analytics tier for security-relevant logs. Implement data retention policies per table.

### Network Security
- **Azure Firewall**: Centralized network security in hub VNets. Application rules (FQDN-based), network rules (IP-based), DNAT rules. Premium SKU adds TLS inspection, IDPS, URL filtering.
- **Network Security Groups (NSGs)**: Stateful packet filtering at subnet and NIC level. Use application security groups (ASGs) for role-based rules. Enable NSG flow logs for traffic analysis.
- **Azure DDoS Protection**: Standard tier for automatic protection of public IPs. Provides attack analytics, alerting, and cost protection (credit for scale-out costs during attack).

### Data Protection
- **Azure Key Vault**: Centralized secrets, keys, and certificates. Use Managed HSM for FIPS 140-2 Level 3 certified hardware protection. Enable soft-delete and purge protection. Use RBAC for fine-grained access control.
- **Microsoft Purview**: Unified data governance across Azure, on-premises, and multi-cloud. Data catalog, data lineage, data classification, and policy management. Use for GDPR, CCPA, and compliance requirements.

## Cost Architecture

### Reserved Instances and Savings Plans
- **Azure Reservations**: 1-year or 3-year commitments for VMs, SQL Database, Cosmos DB, Synapse, App Service, and more. Savings up to 72% over pay-as-you-go. Exchangeable and refundable (with early termination fee).
- **Azure Savings Plans**: Compute-level commitment ($/hour) that applies automatically across VM sizes, regions, and services. More flexible than reservations but slightly lower discount.
- Analyze usage with Azure Cost Management before committing. Use reservation recommendations based on 7, 30, or 60-day usage patterns.

### Spot and Dev/Test Pricing
- **Azure Spot VMs**: Up to 90% discount for interruptible workloads. Use for batch processing, CI/CD, and stateless horizontally-scalable workloads. Combine with VMSS for Spot-based auto-scaling.
- **Dev/Test pricing**: Reduced rates for development and testing (no Windows Server license charges on VMs). Requires Visual Studio subscription. Apply to non-production subscriptions.
- **Azure Hybrid Benefit**: Use existing Windows Server and SQL Server licenses on Azure VMs. Saves up to 85% when combined with reservations.

### FinOps Practices
- **Azure Cost Management**: Built-in cost analysis, budgets, alerts, and recommendations. Use cost allocation rules to distribute shared costs to business units. Use tags for cost categorization.
- **Budget automation**: Create budgets with action groups that trigger Azure Functions or Logic Apps when thresholds are reached. Automate responses: send Teams/Slack notifications, shut down dev environments.
- **Azure Advisor**: Continuous recommendations for cost optimization, security, reliability, and performance. Review weekly. Automate implementation with Azure Policy and remediation tasks.
- **Resource lifecycle management**: Implement auto-shutdown for dev/test VMs. Use TTL tags with Azure Automation to delete temporary resources.
