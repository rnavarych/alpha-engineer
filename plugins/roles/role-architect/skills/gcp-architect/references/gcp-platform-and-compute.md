# GCP Platform, Organization, Networking, and Compute

## When to load
Load when designing GCP organization structure, project strategy, VPC and Shared VPC networking, global load balancing, hybrid connectivity, GKE clusters, Cloud Run, or Compute Engine architectures.

## Google Cloud Architecture Framework

### Five Pillars
- **Operational Excellence**: Use Cloud Monitoring dashboards, alerting policies, and SLO monitoring for every production service. Implement runbooks in Cloud Workflows. Use Cloud Deploy for managed continuous delivery with approval gates. Adopt SRE practices: define SLIs, SLOs, and error budgets.
- **Security, Privacy, and Compliance**: Apply least privilege with IAM. Use organization policies to enforce guardrails (disable external sharing, restrict service usage). Enable Security Command Center Premium. Use VPC Service Controls to create security perimeters. Design for BeyondCorp (Zero Trust) access.
- **Reliability**: Deploy across multiple zones as a baseline. Use regional services (Cloud SQL HA, regional GKE clusters) for automatic zone failover. Design multi-region when RPO < 1 hour or RTO < 15 minutes.
- **Performance Optimization**: Use the right compute tier: Cloud Run for request-based, GKE Autopilot for container orchestration, Compute Engine for full control. Profile with Cloud Profiler (always-on, low-overhead). Use Cloud CDN for static content and API response caching.
- **Cost Optimization**: Use committed use discounts (CUDs) for predictable compute. Enable Active Assist recommendations (rightsizing, idle resource identification). Use Preemptible/Spot VMs for fault-tolerant batch workloads. Label all resources for cost allocation.

## Organization and Project Structure

### Resource Hierarchy
- Organization → Folders → Projects → Resources. Design folder structure to reflect the organizational hierarchy: top-level folders for business units, sub-folders for teams or applications.
- **Project strategy**: One project per application per environment (e.g., myapp-dev, myapp-staging, myapp-prod). Strongest isolation boundary for IAM, networking, billing, and quota management.
- Dedicated project for shared services: CI/CD pipelines, artifact registries, shared VPCs, DNS, and monitoring. Separate project for security tooling.

### Organization Policies
- Set constraints at org or folder level: restrict allowed regions (gcp.resourceLocations), disable service account key creation (iam.disableServiceAccountKeyCreation), require OS Login for SSH (compute.requireOsLogin), enforce uniform bucket-level access on Cloud Storage.
- Use custom organization policies for fine-grained constraints not covered by built-ins. Combine with IAM Deny policies for explicit access denial that overrides Allow policies.

### Landing Zone
- Use Google Cloud Foundation Toolkit (CFT) or Terraform Example Foundation for automated landing zone deployment. Includes: organization setup, folder structure, shared VPC, IAM bindings, logging, and security configuration.
- Deploy Cloud Asset Inventory for real-time visibility into all resources. Use Asset Inventory feeds for automated compliance checking and drift detection.

## Networking Architecture

### VPC Design
- Use **Shared VPC** as the default networking model. Host project owns the VPC and subnets; service projects attach workloads. Centralizes network management while allowing decentralized compute deployment.
- Design a hierarchical IP address plan. Use /16 or /20 CIDR blocks per Shared VPC. Allocate subnet ranges per region and environment. Reserve ranges for GKE pod and service CIDRs (secondary ranges). Use Private Service Connect for managed service access without IP conflicts.
- Enable **VPC Flow Logs** on all subnets with sampling rate tuned for cost (0.5 sampling is usually sufficient). Export to BigQuery for network analytics and threat detection.

### Global Load Balancing
- GCP's load balancers are global by design. Use **External Application Load Balancer** (HTTP/HTTPS) for global traffic distribution with URL-based routing, TLS termination, and Cloud CDN integration.
- Use **Cloud Armor** for DDoS protection and WAF policies on the load balancer. Define security policies with preconfigured rules (OWASP Top 10), rate limiting, and geo-based access controls.
- Use **Traffic Director** or **Cloud Service Mesh** for internal service-to-service traffic management with load balancing, traffic splitting, fault injection, and observability.

### Hybrid and Multi-Cloud Connectivity
- **Cloud Interconnect**: Dedicated (10-200 Gbps) or Partner (50 Mbps-50 Gbps) interconnect. Use VLAN attachments to connect to multiple VPCs via Cloud Router.
- **Cloud VPN**: HA VPN provides 99.99% SLA with two tunnels across two interfaces.
- **Network Connectivity Center**: Hub-and-spoke model for connecting on-premises networks, VPCs, and other clouds through a centralized management plane.

## Compute Architecture

### GKE Architecture
- **GKE Autopilot**: Fully managed Kubernetes. Google manages nodes, scaling, and security patches. Pay per pod resource request. Enforces security best practices (no privileged containers, no host networking).
- **GKE Standard**: Self-managed node pools for full control. Use when you need GPUs, specific machine types, DaemonSets, or privileged workloads. Use node auto-provisioning for automatic node pool creation.
- **Multi-cluster architecture**: Use GKE Fleet for managing multiple clusters across regions. Use Multi Cluster Ingress for global load balancing. Use Config Sync for GitOps-based configuration management.
- **GKE security**: Enable Workload Identity for pod-to-GCP-service authentication. Use Binary Authorization to enforce signed container image policies. Enable GKE Dataplane V2 (Cilium-based) for network policies and observability.

### Cloud Run
- Serverless containers that scale to zero. No cluster management. Supports any language/runtime.
- Use **Cloud Run Jobs** for batch processing and scheduled tasks.
- Set minimum instances for latency-sensitive services (avoids cold starts). Set maximum instances for cost control. Use "always allocated" CPU mode for background processing.
- Integrate with Eventarc for event-driven architectures: Cloud Storage events, Pub/Sub messages, Cloud Audit Logs, and 90+ Google Cloud event sources.

### Compute Engine
- Use **Sole-Tenant Nodes** for workloads requiring physical isolation (compliance, licensing). Use **Confidential VMs** for workloads processing sensitive data (memory encryption with AMD SEV).
- Use **Managed Instance Groups (MIGs)** with autoscaler for stateless workloads. Use regional MIGs for cross-zone high availability.
- **Custom machine types**: Right-size CPU and memory independently for unusual CPU-to-memory ratios.
