# Cloud Services Comparison Reference

## Compute
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| VMs | EC2 | Compute Engine | Virtual Machines |
| Containers | ECS, EKS | GKE, Cloud Run | AKS, Container Instances |
| Serverless | Lambda | Cloud Functions | Azure Functions |
| PaaS | Elastic Beanstalk | App Engine | App Service |

## Databases
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| Relational | RDS, Aurora | Cloud SQL, AlloyDB | Azure SQL, PostgreSQL |
| NoSQL Document | DynamoDB | Firestore | Cosmos DB |
| Key-Value | ElastiCache | Memorystore | Azure Cache |
| Data Warehouse | Redshift | BigQuery | Synapse Analytics |

## Storage
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| Object | S3 | Cloud Storage | Blob Storage |
| File | EFS | Filestore | Azure Files |
| Block | EBS | Persistent Disk | Managed Disks |
| Archive | S3 Glacier | Archive Storage | Archive Storage |

## Messaging
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| Queue | SQS | Cloud Tasks | Queue Storage |
| Pub/Sub | SNS | Pub/Sub | Service Bus |
| Streaming | Kinesis | Dataflow | Event Hubs |

## Networking
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| CDN | CloudFront | Cloud CDN | Azure CDN |
| DNS | Route 53 | Cloud DNS | Azure DNS |
| Load Balancer | ALB/NLB | Cloud LB | Azure LB |
| VPN | VPN Gateway | Cloud VPN | VPN Gateway |

## Identity & Security
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| IAM | IAM | Cloud IAM | Entra ID (Azure AD) |
| Secrets | Secrets Manager | Secret Manager | Key Vault |
| KMS | KMS | Cloud KMS | Key Vault |
| WAF | WAF | Cloud Armor | Azure WAF |

## Monitoring
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| Monitoring | CloudWatch | Cloud Monitoring | Azure Monitor |
| Logging | CloudWatch Logs | Cloud Logging | Log Analytics |
| Tracing | X-Ray | Cloud Trace | App Insights |

## AI/ML Services
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| ML Platform | SageMaker | Vertex AI | Azure ML |
| Foundation Models | Bedrock (multi-model) | Vertex AI (Gemini) | Azure OpenAI Service |
| Vision | Rekognition | Cloud Vision AI | Azure AI Vision |
| Speech | Transcribe, Polly | Speech-to-Text, Text-to-Speech | Azure AI Speech |
| NLP | Comprehend | Cloud Natural Language | Azure AI Language |
| Translation | Translate | Cloud Translation | Azure AI Translator |
| Notebooks | SageMaker Studio | Vertex AI Workbench | Azure ML Notebooks |
| AutoML | SageMaker Autopilot | Vertex AI AutoML | Azure AutoML |

## IoT Services
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| Device Management | IoT Core | IoT Core (deprecated, use MQTT broker) | IoT Hub |
| Edge Computing | IoT Greengrass | Edge TPU, Anthos for bare metal | IoT Edge |
| Device Shadow | IoT Device Shadow | N/A | Device Twins |
| Analytics | IoT Analytics | Pub/Sub + Dataflow | Time Series Insights |
| Fleet Management | Fleet Hub | Fleet management in Cloud IoT | IoT Central |

## Analytics
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| Data Warehouse | Redshift | BigQuery | Synapse Analytics |
| ETL/ELT | Glue | Dataflow, Dataproc | Data Factory |
| Data Catalog | Glue Data Catalog | Data Catalog | Purview |
| BI/Visualization | QuickSight | Looker | Power BI |
| Stream Analytics | Kinesis Analytics | Dataflow Streaming | Stream Analytics |
| Data Lake | Lake Formation + S3 | BigLake + Cloud Storage | Azure Data Lake Storage |
| Lakehouse | Redshift Spectrum, EMR | BigLake, Dataproc | Synapse + ADLS Gen2 |

## CI/CD Services
| Service Type | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| Source Control | CodeCommit (deprecated) | Cloud Source Repos | Azure Repos |
| CI/CD Pipeline | CodePipeline + CodeBuild | Cloud Build | Azure Pipelines |
| Artifact Registry | ECR, CodeArtifact | Artifact Registry | Azure Artifacts, ACR |
| Deployment | CodeDeploy | Cloud Deploy | Azure DevOps Release |
| IaC | CloudFormation, CDK | Deployment Manager, Config Connector | ARM Templates, Bicep |
| GitOps | N/A (use ArgoCD/Flux) | Config Sync | GitOps with Flux (AKS) |

## Serverless Comparison: Functions

| Feature | Lambda (AWS) | Cloud Functions (GCP) | Azure Functions |
|---------|-------------|----------------------|-----------------|
| **Max timeout** | 15 min | 60 min (2nd gen) | 10 min (consumption), unlimited (premium/dedicated) |
| **Memory range** | 128 MB - 10 GB | 128 MB - 32 GB | 1.5 GB (consumption), 14 GB (premium) |
| **vCPU allocation** | Proportional to memory (1 vCPU at 1769 MB) | Proportional to memory | Proportional to memory |
| **Concurrency control** | Reserved + provisioned concurrency | Max instances setting | Per-instance concurrency |
| **Cold start mitigation** | Provisioned concurrency, SnapStart (Java) | Min instances (2nd gen) | Premium plan (pre-warmed), KEDA |
| **Container support** | Yes (up to 10 GB image) | Yes (Cloud Run) | Yes (custom handlers) |
| **VPC access** | ENI-based (adds cold start) | Serverless VPC Access connector | VNET integration (premium) |
| **Layers/dependencies** | Lambda Layers (5 layers, 250 MB) | N/A (use container images) | N/A (deploy with code) |
| **Local development** | SAM CLI, LocalStack | Functions Framework | Azure Functions Core Tools |
| **Event sources** | 200+ via EventBridge, native triggers | Eventarc, Pub/Sub, Cloud Storage, HTTP | Event Grid, Service Bus, Timer, HTTP, Blob, Cosmos DB |
| **Pricing (per million)** | $0.20 | $0.40 | $0.20 |
| **Pricing (duration)** | $0.0000166667/GB-s | $0.0000025/GHz-s | $0.000016/GB-s |

## Container Comparison: ECS/Fargate vs Cloud Run vs Container Apps

| Feature | ECS/Fargate (AWS) | Cloud Run (GCP) | Container Apps (Azure) |
|---------|-------------------|-----------------|----------------------|
| **Model** | Task definitions, services | Container instances, services | Container apps, revisions |
| **Orchestrator** | ECS (proprietary) | Knative-based | Kubernetes + Dapr + KEDA |
| **Scale to zero** | No (min 1 task) | Yes | Yes |
| **Max instances** | Service auto-scaling (1-unlimited) | 1000 instances per service | 300 replicas per revision |
| **Max vCPU/task** | 16 vCPU, 120 GB memory (Fargate) | 8 vCPU, 32 GB memory | 4 vCPU, 8 GB memory |
| **Request timeout** | No limit (long-running) | 60 min (HTTP), unlimited (jobs) | Unlimited |
| **GPU support** | Yes (EC2 launch type) | Yes (preview) | Yes (preview) |
| **Service mesh** | App Mesh (Envoy) | Built-in (Cloud Run mesh) | Dapr (built-in) |
| **Traffic splitting** | ALB weighted routing | Revision-based traffic split | Revision-based traffic split |
| **Pricing** | Per vCPU-hour + GB-hour (no scale to zero) | Per vCPU-second + GB-second + requests | Per vCPU-second + GB-second + requests |
| **Best for** | Long-running services, complex networking | HTTP APIs, event processing, scale-to-zero | Microservices with Dapr, event-driven |

## Pricing Model Comparison (Key Services)

### Compute (approximate, us-east, Linux)
| Instance Class | AWS (EC2) | GCP (Compute Engine) | Azure (VMs) |
|---------------|-----------|---------------------|-------------|
| 2 vCPU, 8 GB | m7i.large: ~$70/mo | e2-standard-2: ~$49/mo | D2s v5: ~$70/mo |
| 4 vCPU, 16 GB | m7i.xlarge: ~$140/mo | e2-standard-4: ~$97/mo | D4s v5: ~$140/mo |
| 8 vCPU, 32 GB | m7i.2xlarge: ~$280/mo | e2-standard-8: ~$195/mo | D8s v5: ~$280/mo |
| **Sustained discount** | None (use RIs/SPs) | Auto 20-30% | None (use RIs/SPs) |
| **Spot discount** | Up to 90% | Up to 91% | Up to 90% |

### Object Storage (per GB/month)
| Tier | S3 (AWS) | Cloud Storage (GCP) | Blob Storage (Azure) |
|------|----------|--------------------|--------------------|
| Hot | $0.023 | $0.020 | $0.018 |
| Infrequent | $0.0125 (IA) | $0.010 (Nearline) | $0.010 (Cool) |
| Archive | $0.004 (Glacier IR) | $0.004 (Coldline) | $0.002 (Cold) |
| Deep Archive | $0.00099 | $0.0012 (Archive) | $0.00099 (Archive) |
| **Egress (per GB)** | $0.09 | $0.12 | $0.087 |

### Managed Database (PostgreSQL, ~4 vCPU, 16 GB, 100 GB storage)
| Feature | RDS (AWS) | Cloud SQL (GCP) | Azure Database (Azure) |
|---------|-----------|-----------------|----------------------|
| **Monthly estimate** | ~$280 (db.m6g.xlarge) | ~$230 (db-custom-4-16384) | ~$330 (GP_Gen5_4) |
| **Multi-AZ HA** | 2x cost | Included (regional) | Zone-redundant included |
| **Serverless** | Aurora Serverless v2: $0.12/ACU-hr | AlloyDB Omni | Serverless: $0.000145/vCore-s |

## Region and Availability Zone Strategy

### Region Selection Criteria
1. **Latency**: Choose regions closest to your users (use latency testing tools: cloudping.info, gcping.com)
2. **Compliance**: Data residency requirements (EU data in EU regions, etc.)
3. **Service availability**: Not all services available in all regions (check service availability pages)
4. **Cost**: Pricing varies by region (us-east-1 is typically cheapest on AWS, us-central1 on GCP)
5. **Disaster recovery**: DR region should be geographically distant from primary

### Multi-Region Patterns
| Pattern | Description | Complexity | Use Case |
|---------|-------------|------------|----------|
| **Active-Passive** | Primary region serves traffic, standby for failover | Low | DR with RTO < 1 hour |
| **Active-Active** | Both regions serve traffic, data replicated | High | Global latency, near-zero RTO |
| **Pilot Light** | Minimal infra in DR region, scale up on failover | Medium | Cost-effective DR |
| **Warm Standby** | Scaled-down copy in DR region | Medium | RTO < 15 min |

### AZ Distribution
- **Minimum**: 2 AZs for any production workload
- **Recommended**: 3 AZs for critical workloads
- **Load balancing**: Distribute evenly across AZs
- **Data replication**: Synchronous within region (across AZs), asynchronous cross-region
- **Cost**: No data transfer charges within same AZ, minimal between AZs in same region

## Managed Kubernetes Comparison (Extended)

| Feature | EKS (AWS) | GKE (GCP) | AKS (Azure) |
|---------|-----------|-----------|-------------|
| **Control plane SLA** | 99.95% | 99.95% (Regional), 99.5% (Zonal) | 99.95% (with AZs), 99.9% (without) |
| **K8s version lag** | ~1-2 months behind upstream | ~1 month behind upstream | ~1-2 months behind upstream |
| **Node auto-provisioning** | Karpenter (recommended), Cluster Autoscaler | GKE Autopilot (full), NAP (Standard) | Karpenter (preview), Cluster Autoscaler |
| **Managed node groups** | EKS Managed Node Groups | Standard node pools | System + User node pools |
| **Serverless nodes** | Fargate profiles | Autopilot (all pods) | Virtual Nodes (ACI) |
| **Networking model** | VPC CNI (pod = VPC IP) | Alias IP or Dataplane V2 (Cilium) | Azure CNI (pod = VNET IP) or kubenet (overlay) |
| **Network policy** | Calico (addon) | Dataplane V2 (Cilium), Calico | Azure Network Policy, Calico |
| **Ingress controller** | ALB Controller, NGINX | GKE Ingress (GCE LB), Gateway API | App Gateway Ingress, NGINX |
| **Gateway API** | Supported via controller | Native support | Supported via controller |
| **Secret management** | Secrets Store CSI (AWS Secrets Manager) | Secret Manager addon | Secrets Store CSI (Key Vault) |
| **GitOps** | Flux (EKS addon) | Config Sync (Anthos) | Flux (AKS extension), ArgoCD |
| **Cost management** | Split cost allocation tags | GKE cost allocation | AKS cost analysis |
| **Windows nodes** | Supported | Supported (preview) | Supported |
| **Arm nodes** | Graviton (c7g, m7g, r7g) | Tau T2A (Ampere) | Dpsv5 (Ampere) |
| **Confidential computing** | Nitro Enclaves | Confidential GKE Nodes | Confidential VMs |
| **Backup** | Velero | GKE Backup | AKS Backup (Azure Backup) |
