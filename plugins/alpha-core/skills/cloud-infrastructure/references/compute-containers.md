# Compute and Container Orchestration

## When to load
Load when choosing VM instance families, configuring auto-scaling, working with spot instances, comparing managed Kubernetes (EKS/GKE/AKS), or selecting service mesh and container registry.

## Cloud Provider Overview

| Provider | Market Share | Strengths | Best For |
|----------|-------------|-----------|----------|
| AWS | ~32% | Broadest catalog (200+ services), maturity, ecosystem | Enterprise, regulated industries, broadest workload coverage |
| GCP | ~12% | Data/ML, GKE, BigQuery, global networking | Data-intensive, ML/AI, Kubernetes-native, multi-cloud via Anthos |
| Azure | ~23% | Microsoft/.NET, Entra ID, hybrid cloud (Arc) | Microsoft shops, enterprise identity, hybrid cloud, .NET workloads |

## VM Sizing and Auto-Scaling

### Instance Families

| Provider | Service | Key Instance Families |
|----------|---------|----------------------|
| AWS | EC2 | General (M), Compute (C), Memory (R), Storage (I), Accelerated (P, G, Inf, Trn) |
| GCP | Compute Engine | General (E2, N2), Compute (C2, C3), Memory (M2), Accelerated (A2, G2) |
| Azure | Virtual Machines | General (D), Compute (F), Memory (E, M), Storage (L), GPU (N) |

**Sizing guidelines**
- Start small, measure, right-size: use cloud provider recommendations (Compute Optimizer, GCP Recommender, Azure Advisor)
- CPU-bound: compute-optimized (C-family); Memory-bound: memory-optimized (R/M-family)
- Burstable (T-series / e2-micro / B-series) for dev/test and low-utilization workloads; monitor CPU credits

**Auto-scaling groups**
- Scale on: CPU utilization (target 60-70%), request count, queue depth, custom metrics
- Policies: target tracking (simplest), step scaling (fine control), predictive scaling (ML-based)
- Cooldown periods: 300s default; always set min/max boundaries and use multiple AZs

### Spot / Preemptible Strategies

- Up to 60-90% cost savings for fault-tolerant workloads
- Use cases: batch processing, CI/CD runners, stateless web workers, ML training
- **AWS Spot**: Capacity-optimized allocation, 2-minute termination notice
- **GCP Spot VMs**: Max 24-hour runtime, 30-second termination notice
- **Azure Spot VMs**: Eviction policies (deallocate or delete), max price setting
- Best practice: Mix spot with on-demand (80/20 ratio), use multiple instance types, implement graceful shutdown handlers

### GPU Instances

- **AWS**: P5 (H100), P4d (A100), G5 (A10G), Inf2 (Inferentia2), Trn1 (Trainium)
- **GCP**: A3 (H100), A2 (A100), G2 (L4), TPU v5e
- **Azure**: ND H100 v5, NC A100 v4, NV A10 v5
- Consider: NVIDIA MIG for GPU partitioning, spot GPUs for training, reserved for inference

## Managed Kubernetes Comparison

| Feature | EKS (AWS) | GKE (GCP) | AKS (Azure) |
|---------|-----------|-----------|-------------|
| **Control plane cost** | $0.10/hr ($73/mo) | Free (Autopilot: pay per pod) | Free |
| **Autopilot/Serverless** | Fargate profiles | GKE Autopilot | Virtual Nodes (ACI) |
| **Max nodes** | 5,000 per cluster | 15,000 per cluster | 5,000 per cluster |
| **Control plane SLA** | 99.95% | 99.95% (Regional) | 99.95% (with AZs) |
| **Default CNI** | VPC CNI (AWS IPs) | Calico or Dataplane V2 (Cilium) | Azure CNI or kubenet |
| **Node auto-provisioning** | Karpenter (recommended) | GKE Autopilot / NAP | Karpenter (preview) |
| **Ingress** | ALB Ingress Controller | GKE Ingress (Cloud LB) | App Gateway Ingress |
| **Service mesh** | App Mesh, Istio add-on | Anthos Service Mesh, Istio | Istio add-on |
| **Multi-cluster** | EKS Anywhere | Anthos, Fleet | Azure Arc, Fleet Manager |
| **Arm nodes** | Graviton (c7g, m7g, r7g) | Tau T2A (Ampere) | Dpsv5 (Ampere) |
| **GitOps** | Flux (EKS addon) | Config Sync (Anthos) | Flux (AKS extension) |

## Service Mesh

- **Istio**: Feature-rich, Envoy-based. mTLS, traffic management, observability, policy enforcement.
- **Linkerd**: Lightweight, Rust-based proxy. CNCF graduated. Automatic mTLS, retries, timeouts.
- **Cilium**: eBPF-based, high-performance L3/L4/L7 networking. Service mesh without sidecars.
- **Consul Connect**: HashiCorp. Multi-platform (K8s + VMs). Service discovery + mesh.

## Container Registries

- **ECR** (AWS): Integrated with ECS/EKS, image scanning, lifecycle policies, cross-region replication
- **Artifact Registry** (GCP): Multi-format (Docker, Maven, npm, Python), vulnerability scanning
- **ACR** (Azure): Geo-replication, Tasks (in-registry builds), Helm chart support
- **GitHub Container Registry (ghcr.io)**: Free for public images, GitHub Actions integration, OIDC auth

## Serverless Containers Comparison

| Feature | ECS/Fargate (AWS) | Cloud Run (GCP) | Container Apps (Azure) |
|---------|-------------------|-----------------|----------------------|
| **Scale to zero** | No (min 1 task) | Yes | Yes |
| **Max vCPU/task** | 16 vCPU, 120 GB | 8 vCPU, 32 GB | 4 vCPU, 8 GB |
| **Service mesh** | App Mesh (Envoy) | Built-in Cloud Run mesh | Dapr (built-in) |
| **Best for** | Long-running, complex networking | HTTP APIs, scale-to-zero | Microservices with Dapr |
