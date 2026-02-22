---
name: gcp-architect
description: |
  GCP architecture expertise including Google Cloud Architecture Framework,
  project and organization structure, VPC and networking design, data and analytics
  architecture, Kubernetes and serverless patterns, AI/ML platform design,
  security architecture, and cost optimization strategies.
  Use proactively when designing systems on GCP, evaluating GCP services,
  planning GCP organization structure, or architecting for GCP-specific capabilities.
allowed-tools: Read, Grep, Glob, Bash
---

# GCP Architect

## Google Cloud Architecture Framework

### Five Pillars
- **Operational Excellence**: Use Cloud Monitoring dashboards, alerting policies, and SLO monitoring for every production service. Implement runbooks in Cloud Workflows. Use Cloud Deploy for managed continuous delivery with approval gates. Adopt Site Reliability Engineering practices: define SLIs, SLOs, and error budgets for each service.
- **Security, Privacy, and Compliance**: Apply the principle of least privilege with IAM. Use organization policies to enforce guardrails (disable external sharing, restrict service usage). Enable Security Command Center Premium for threat detection. Use VPC Service Controls to create security perimeters around sensitive data. Design for BeyondCorp (Zero Trust) access.
- **Reliability**: Deploy across multiple zones as a baseline. Use regional services (Cloud SQL HA, regional GKE clusters) for automatic zone failover. Design for multi-region when RPO < 1 hour or RTO < 15 minutes. Use Cloud Load Balancing for global traffic distribution with automatic failover.
- **Performance Optimization**: Use the right compute tier for the workload: Cloud Run for request-based, GKE Autopilot for container orchestration, Compute Engine for full control. Profile with Cloud Profiler (always-on, low-overhead production profiling). Use Cloud CDN for static content and API response caching.
- **Cost Optimization**: Use committed use discounts (CUDs) for predictable compute workloads. Enable recommendations from Active Assist (rightsizing, idle resource identification, committed use recommendations). Use Preemptible/Spot VMs for fault-tolerant batch workloads. Label all resources for cost allocation and reporting.

## Organization and Project Structure

### Resource Hierarchy
- Organization → Folders → Projects → Resources. Design the folder structure to reflect the organizational hierarchy: top-level folders for business units or environments, sub-folders for teams or applications.
- **Project strategy**: One project per application per environment (e.g., myapp-dev, myapp-staging, myapp-prod). This provides the strongest isolation boundary for IAM, networking, billing, and quota management.
- Use a dedicated project for shared services: CI/CD pipelines, artifact registries, shared VPCs, DNS, and monitoring. Use a separate project for the security tooling (Security Command Center, log sinks, SIEM integration).

### Organization Policies
- Set organization policy constraints at the org or folder level to enforce governance: restrict allowed regions (gcp.resourceLocations), disable service account key creation (iam.disableServiceAccountKeyCreation), require OS Login for SSH (compute.requireOsLogin), and enforce uniform bucket-level access on Cloud Storage.
- Use custom organization policies for fine-grained constraints not covered by built-in policies. Combine with IAM Deny policies for explicit access denial that overrides Allow policies.

### Landing Zone
- Use Google Cloud Foundation Toolkit (CFT) or Terraform Example Foundation for automated landing zone deployment. Includes: organization setup, folder structure, shared VPC, IAM bindings, logging, and security configuration.
- Deploy Cloud Asset Inventory for real-time visibility into all resources across the organization. Use Asset Inventory feeds for automated compliance checking and drift detection.

## Networking Architecture

### VPC Design
- Use **Shared VPC** as the default networking model. Host project owns the VPC and subnets; service projects attach workloads. This centralizes network management while allowing decentralized compute deployment.
- Design a hierarchical IP address plan. Use /16 or /20 CIDR blocks per Shared VPC. Allocate subnet ranges per region and environment. Reserve ranges for GKE pod and service CIDRs (secondary ranges). Use Private Service Connect for managed service access without IP conflicts.
- Enable **VPC Flow Logs** on all subnets with sampling rate tuned for cost (0.5 sampling is usually sufficient). Export to BigQuery for network analytics and threat detection.

### Global Load Balancing
- GCP's load balancers are global by design. Use **External Application Load Balancer** (HTTP/HTTPS) for global traffic distribution with URL-based routing, TLS termination, and Cloud CDN integration. Use **External Network Load Balancer** for non-HTTP protocols (TCP/UDP, gaming, IoT).
- Use **Cloud Armor** for DDoS protection and WAF policies on the load balancer. Define security policies with preconfigured rules (OWASP Top 10), rate limiting, and geo-based access controls.
- Use **Traffic Director** or **Cloud Service Mesh** for internal service-to-service traffic management. Provides load balancing, traffic splitting, fault injection, and observability for microservices.

### Hybrid and Multi-Cloud Connectivity
- **Cloud Interconnect**: Dedicated (10-200 Gbps) or Partner (50 Mbps-50 Gbps) interconnect for high-bandwidth, low-latency connectivity to on-premises. Use VLAN attachments to connect to multiple VPCs via Cloud Router.
- **Cloud VPN**: IPsec VPN tunnels over the internet. HA VPN provides 99.99% SLA with two tunnels across two interfaces. Use for lower-bandwidth or backup connectivity.
- **Network Connectivity Center**: Hub-and-spoke model for connecting on-premises networks, VPCs, and other clouds through a centralized management plane. Simplifies complex hybrid topologies.

## Compute Architecture

### GKE Architecture
- **GKE Autopilot**: Fully managed Kubernetes. Google manages nodes, scaling, and security patches. Pay per pod resource request. Best for teams that want Kubernetes API compatibility without node management. Enforces security best practices (no privileged containers, no host networking).
- **GKE Standard**: Self-managed node pools for full control. Use when you need GPUs, specific machine types, DaemonSets, or privileged workloads. Use node auto-provisioning for automatic node pool creation based on pod requirements.
- **Multi-cluster architecture**: Use GKE Fleet for managing multiple clusters across regions. Use Multi Cluster Ingress for global load balancing across GKE clusters. Use Config Sync for GitOps-based configuration management across fleet clusters.
- **GKE security**: Enable Workload Identity for pod-to-GCP-service authentication (eliminates service account keys). Use Binary Authorization to enforce signed container image policies. Enable GKE Dataplane V2 (Cilium-based) for network policies and observability.

### Cloud Run
- Serverless containers that scale to zero. No cluster management. Best for HTTP services, event-driven processing, and scheduled jobs. Supports any language/runtime via container images.
- Use **Cloud Run Jobs** for batch processing and scheduled tasks (replaces cron-based container workloads).
- Cloud Run services auto-scale based on concurrent requests. Set minimum instances for latency-sensitive services (avoids cold starts). Set maximum instances for cost control. Use CPU allocation mode: "always allocated" for background processing, "request-only" for API workloads.
- Integrate with Eventarc for event-driven architectures: Cloud Storage events, Pub/Sub messages, Cloud Audit Logs, and 90+ Google Cloud event sources trigger Cloud Run services directly.

### Compute Engine
- Use **Sole-Tenant Nodes** for workloads that require physical isolation (compliance, licensing). Use **Confidential VMs** for workloads processing sensitive data (memory encryption with AMD SEV).
- Use **Managed Instance Groups (MIGs)** with autoscaler for stateless workloads. Use regional MIGs for cross-zone high availability. Use stateful MIGs for workloads with persistent disks and network identity.
- **Custom machine types**: Right-size CPU and memory independently rather than choosing from predefined families. Useful when workloads have unusual CPU-to-memory ratios.

## Data Architecture

### BigQuery
- Serverless data warehouse. No infrastructure to manage. Pay per query (on-demand) or flat-rate (BigQuery Editions with autoscaling slots). Use BigQuery Editions for predictable costs when query volume is high.
- **Architecture patterns**: Use datasets for access control boundaries. Use authorized views and row-level security for fine-grained access. Use BigQuery BI Engine for sub-second dashboarding. Use materialized views for frequently computed aggregations.
- **BigQuery as data lakehouse**: Query data directly in Cloud Storage (BigLake tables) without loading. Supports Parquet, ORC, Avro, JSON, and CSV. Use BigLake for unified governance across BigQuery and Cloud Storage data.
- **Streaming ingestion**: Use BigQuery Storage Write API for high-throughput streaming inserts (up to millions of rows/second). Use Dataflow for streaming ETL that writes to BigQuery.

### Dataflow and Pub/Sub
- **Pub/Sub**: Globally distributed message bus. Use for decoupling services, event-driven architectures, and streaming data ingestion. Supports push (HTTP webhook) and pull delivery. Use Pub/Sub Lite for high-volume, single-region workloads at lower cost.
- **Dataflow**: Managed Apache Beam runner for both batch and streaming data processing. Use for ETL, real-time analytics, ML feature engineering, and data enrichment. Dataflow templates provide pre-built pipelines for common patterns (Pub/Sub to BigQuery, GCS to BigQuery).
- **Streaming architecture pattern**: Pub/Sub (ingestion) → Dataflow (processing/enrichment) → BigQuery (analytics) + Cloud Storage (data lake). Use Pub/Sub dead-letter topics for failed message handling.

### Spanner and AlloyDB
- **Cloud Spanner**: Globally distributed, strongly consistent relational database. Use when you need global scale with ACID transactions. Supports up to 10 TB per node with horizontal scaling. Use for financial systems, inventory management, and gaming leaderboards that require global consistency.
- **AlloyDB**: PostgreSQL-compatible, AI-ready database. 4x faster than standard PostgreSQL for transactional workloads, 100x faster for analytical queries (columnar engine). Use for workloads that need PostgreSQL compatibility with enterprise performance. Built-in vector search for AI applications.

### Firestore and Bigtable
- **Firestore**: Document database with real-time sync and offline support. Use for mobile/web backends, user profiles, and session management. Native mode for document-centric access; Datastore mode for key-value access patterns.
- **Cloud Bigtable**: Wide-column NoSQL for massive-scale, low-latency workloads. Use for time-series data (IoT, financial market data), analytics backends, and ML feature serving. Design row keys for even distribution (avoid hotspots). Scales linearly with nodes.

## AI/ML Architecture

### Vertex AI Platform
- Unified ML platform: data labeling, training (AutoML and custom), model registry, prediction serving, model monitoring, and feature store. Use Vertex AI Workbench (managed JupyterLab) for experimentation.
- **Training architecture**: Use Vertex AI Training with custom containers for distributed training on GPUs (A100, H100) and TPUs. Use pre-built containers for TensorFlow, PyTorch, XGBoost, and scikit-learn. Use Vertex AI Pipelines (Kubeflow Pipelines) for reproducible ML workflows.
- **Serving architecture**: Vertex AI Endpoints for online prediction with auto-scaling. Use traffic splitting for A/B testing between model versions. Use batch prediction for high-volume, non-real-time inference. Deploy to GKE for custom serving infrastructure needs.

### TPU Architecture
- Tensor Processing Units for ML training and inference at scale. TPU v5e for cost-efficient inference and small-to-medium training. TPU v5p for large-scale training. Cloud TPU Multislice for training models that exceed single TPU pod capacity.
- Use TPU VMs for direct access to TPU hardware with custom frameworks. Use GKE with TPU node pools for Kubernetes-native TPU workloads.

### Generative AI
- **Vertex AI Studio**: Experiment with and tune foundation models (Gemini, PaLM). Use grounding with Google Search or custom data for RAG-style applications.
- **Vector Search**: Managed vector database for similarity search. Use for RAG retrieval, recommendation systems, and semantic search. Supports billions of vectors with low-latency queries.
- **Model Garden**: Access open-source and Google foundation models with one-click deployment. Deploy on Vertex AI Endpoints or GKE for custom serving.

## Security Architecture

### BeyondCorp and Zero Trust
- GCP's implementation of Zero Trust access. Use **Identity-Aware Proxy (IAP)** to protect web applications and VMs without VPN. IAP verifies user identity and device context before granting access.
- **BeyondCorp Enterprise**: Extends Zero Trust to any application (not just GCP). Integrates with Chrome Enterprise for device trust signals, endpoint verification, and data loss prevention.
- **Access Context Manager**: Define access levels based on IP range, device attributes, user identity, and geographic location. Use with VPC Service Controls and IAP.

### VPC Service Controls
- Create security perimeters around GCP services to prevent data exfiltration. Define which projects and services are inside the perimeter. Block API calls that would move data outside the perimeter.
- Use **ingress and egress rules** for controlled exceptions. Use **access bridges** for cross-perimeter service access. Design perimeters around data sensitivity levels.
- Critical for compliance: prevents accidental or malicious data copying to unauthorized projects. Essential for regulated industries (finance, healthcare, government).

### Security Command Center
- **SCC Premium**: Threat detection (Event Threat Detection for log-based threats, Container Threat Detection for GKE runtime threats), vulnerability scanning (Web Security Scanner), and compliance monitoring (CIS benchmarks, PCI-DSS, HIPAA).
- Use **Security Health Analytics** for automated detection of misconfigurations: public buckets, open firewall rules, encryption gaps, and IAM anomalies.
- Integrate SCC findings with Cloud Functions or Workflows for automated remediation. Export findings to SIEM (Chronicle, Splunk) for correlation with non-GCP security events.

### Data Protection
- **Cloud KMS**: Key management for encryption at rest. Use Customer-Managed Encryption Keys (CMEK) for regulated workloads. Use Cloud HSM for FIPS 140-2 Level 3 certified hardware key management. Use Cloud External Key Manager (EKM) for keys you manage outside GCP.
- **DLP API (Sensitive Data Protection)**: Automated discovery and classification of sensitive data across Cloud Storage, BigQuery, and Datastore. Use for PII detection, de-identification (tokenization, masking, redaction), and data risk analysis.
- **Certificate Authority Service**: Managed private CA for issuing TLS certificates to workloads. Integrates with GKE, Traffic Director, and Cloud Service Mesh for mutual TLS (mTLS).

## Cost Architecture

### Committed Use Discounts
- **Compute CUDs**: 1-year (37% discount) or 3-year (55% discount) commitments for CPU and memory across Compute Engine and GKE. CUDs apply automatically to any VM in the same region regardless of machine type.
- **Spend-based CUDs**: For Cloud SQL, AlloyDB, Cloud Run, and other services. Commit to a spend level rather than specific resource quantities.
- Analyze usage with Cost Management reports. Recommend CUDs based on 30-day sustained usage patterns. Start with 1-year CUDs to validate commitment levels before moving to 3-year.

### Sustained Use Discounts
- Automatic discounts for Compute Engine instances running more than 25% of the month. Up to 30% discount at 100% monthly usage. No commitment required. Applies to GKE Standard nodes.
- Note: Sustained use discounts do not apply to E2, A2, Tau, and Autopilot workloads. Use CUDs for these instead.

### FinOps Practices
- **Billing export to BigQuery**: Export detailed billing data to BigQuery for custom cost analytics. Build dashboards in Looker Studio. Set up scheduled queries for daily cost anomaly detection.
- **Budget alerts**: Set budgets per project and billing account. Configure alerting thresholds (50%, 80%, 100%, 120%). Use programmatic budget notifications (Pub/Sub) for automated cost control actions (stop instances, disable billing).
- **Recommender API (Active Assist)**: Machine learning-powered recommendations for rightsizing, idle resource cleanup, and committed use purchases. Integrate recommendations into infrastructure automation for continuous optimization.
- **Labeling strategy**: Apply labels consistently for cost allocation: environment, team, application, cost-center. Use label-based billing reports. Enforce labeling with organization policies.
