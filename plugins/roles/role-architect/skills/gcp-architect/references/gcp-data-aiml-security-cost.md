# GCP Data Architecture, AI/ML, Security, and Cost

## When to load
Load when designing GCP data platforms (BigQuery, Pub/Sub, Dataflow, Spanner, AlloyDB), architecting Vertex AI and generative AI solutions, configuring security with BeyondCorp and VPC Service Controls, or optimizing costs with CUDs and FinOps practices.

## Data Architecture

### BigQuery
- Serverless data warehouse. Pay per query (on-demand) or flat-rate (BigQuery Editions with autoscaling slots).
- **Architecture patterns**: Use datasets for access control boundaries. Use authorized views and row-level security for fine-grained access. Use BigQuery BI Engine for sub-second dashboarding. Use materialized views for frequently computed aggregations.
- **BigQuery as data lakehouse**: Query data directly in Cloud Storage (BigLake tables) without loading. Supports Parquet, ORC, Avro, JSON, and CSV.
- **Streaming ingestion**: Use BigQuery Storage Write API for high-throughput streaming inserts (up to millions of rows/second). Use Dataflow for streaming ETL that writes to BigQuery.

### Dataflow and Pub/Sub
- **Pub/Sub**: Globally distributed message bus for decoupling services, event-driven architectures, and streaming data ingestion. Supports push (HTTP webhook) and pull delivery. Use Pub/Sub Lite for high-volume, single-region workloads at lower cost.
- **Dataflow**: Managed Apache Beam runner for both batch and streaming. Use for ETL, real-time analytics, ML feature engineering. Dataflow templates provide pre-built pipelines (Pub/Sub to BigQuery, GCS to BigQuery).
- **Streaming architecture pattern**: Pub/Sub (ingestion) → Dataflow (processing/enrichment) → BigQuery (analytics) + Cloud Storage (data lake). Use Pub/Sub dead-letter topics for failed message handling.

### Spanner and AlloyDB
- **Cloud Spanner**: Globally distributed, strongly consistent relational database. Use when you need global scale with ACID transactions. Supports up to 10 TB per node with horizontal scaling. Use for financial systems, inventory management, and gaming leaderboards.
- **AlloyDB**: PostgreSQL-compatible, AI-ready database. 4x faster than standard PostgreSQL for transactional workloads, 100x faster for analytical queries (columnar engine). Built-in vector search for AI applications.

### Firestore and Bigtable
- **Firestore**: Document database with real-time sync and offline support. Use for mobile/web backends, user profiles, and session management.
- **Cloud Bigtable**: Wide-column NoSQL for massive-scale, low-latency workloads. Use for time-series data (IoT, financial market data), analytics backends, and ML feature serving. Design row keys for even distribution to avoid hotspots. Scales linearly with nodes.

## AI/ML Architecture

### Vertex AI Platform
- Unified ML platform: data labeling, training (AutoML and custom), model registry, prediction serving, model monitoring, and feature store. Use Vertex AI Workbench (managed JupyterLab) for experimentation.
- **Training architecture**: Use Vertex AI Training with custom containers for distributed training on GPUs (A100, H100) and TPUs. Use Vertex AI Pipelines (Kubeflow Pipelines) for reproducible ML workflows.
- **Serving architecture**: Vertex AI Endpoints for online prediction with auto-scaling. Use traffic splitting for A/B testing between model versions. Use batch prediction for high-volume, non-real-time inference.

### TPU Architecture
- Tensor Processing Units for ML training and inference at scale. TPU v5e for cost-efficient inference and small-to-medium training. TPU v5p for large-scale training. Cloud TPU Multislice for training models exceeding single TPU pod capacity.
- Use TPU VMs for direct access. Use GKE with TPU node pools for Kubernetes-native TPU workloads.

### Generative AI
- **Vertex AI Studio**: Experiment with and tune foundation models (Gemini, PaLM). Use grounding with Google Search or custom data for RAG-style applications.
- **Vector Search**: Managed vector database for similarity search. Use for RAG retrieval, recommendation systems, and semantic search. Supports billions of vectors with low-latency queries.
- **Model Garden**: Access open-source and Google foundation models with one-click deployment to Vertex AI Endpoints or GKE.

## Security Architecture

### BeyondCorp and Zero Trust
- Use **Identity-Aware Proxy (IAP)** to protect web applications and VMs without VPN. IAP verifies user identity and device context before granting access.
- **BeyondCorp Enterprise**: Extends Zero Trust to any application. Integrates with Chrome Enterprise for device trust signals, endpoint verification, and data loss prevention.
- **Access Context Manager**: Define access levels based on IP range, device attributes, user identity, and geographic location. Use with VPC Service Controls and IAP.

### VPC Service Controls
- Create security perimeters around GCP services to prevent data exfiltration. Block API calls that would move data outside the perimeter.
- Use **ingress and egress rules** for controlled exceptions. Use **access bridges** for cross-perimeter service access. Design perimeters around data sensitivity levels.
- Critical for compliance: prevents accidental or malicious data copying to unauthorized projects. Essential for regulated industries (finance, healthcare, government).

### Security Command Center
- **SCC Premium**: Threat detection (Event Threat Detection, Container Threat Detection for GKE runtime), vulnerability scanning (Web Security Scanner), and compliance monitoring (CIS benchmarks, PCI-DSS, HIPAA).
- Use **Security Health Analytics** for automated detection of misconfigurations: public buckets, open firewall rules, encryption gaps, and IAM anomalies.
- Integrate SCC findings with Cloud Functions or Workflows for automated remediation. Export findings to SIEM (Chronicle, Splunk).

### Data Protection
- **Cloud KMS**: Key management for encryption at rest. Use Customer-Managed Encryption Keys (CMEK) for regulated workloads. Use Cloud HSM for FIPS 140-2 Level 3 certified hardware key management. Use Cloud External Key Manager (EKM) for keys managed outside GCP.
- **DLP API (Sensitive Data Protection)**: Automated discovery and classification of sensitive data across Cloud Storage, BigQuery, and Datastore. Use for PII detection, de-identification (tokenization, masking, redaction).
- **Certificate Authority Service**: Managed private CA for issuing TLS certificates to workloads. Integrates with GKE and Cloud Service Mesh for mutual TLS (mTLS).

## Cost Architecture

### Committed Use Discounts
- **Compute CUDs**: 1-year (37% discount) or 3-year (55% discount) commitments for CPU and memory across Compute Engine and GKE. CUDs apply automatically to any VM in the same region regardless of machine type.
- **Spend-based CUDs**: For Cloud SQL, AlloyDB, Cloud Run, and other services. Commit to a spend level rather than specific resource quantities.
- Analyze usage with Cost Management reports. Recommend CUDs based on 30-day sustained usage patterns. Start with 1-year CUDs to validate commitment levels before moving to 3-year.

### Sustained Use Discounts
- Automatic discounts for Compute Engine instances running more than 25% of the month. Up to 30% discount at 100% monthly usage. No commitment required.
- Note: Sustained use discounts do not apply to E2, A2, Tau, and Autopilot workloads. Use CUDs for these instead.

### FinOps Practices
- **Billing export to BigQuery**: Export detailed billing data for custom cost analytics. Build dashboards in Looker Studio. Set up scheduled queries for daily cost anomaly detection.
- **Budget alerts**: Set budgets per project and billing account. Configure alerting thresholds (50%, 80%, 100%, 120%). Use programmatic budget notifications (Pub/Sub) for automated cost control actions.
- **Recommender API (Active Assist)**: ML-powered recommendations for rightsizing, idle resource cleanup, and committed use purchases. Integrate into infrastructure automation for continuous optimization.
- **Labeling strategy**: Apply labels for cost allocation: environment, team, application, cost-center. Enforce labeling with organization policies.
