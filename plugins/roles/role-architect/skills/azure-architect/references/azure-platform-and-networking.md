# Azure Platform, Networking, and Identity

## When to load
Load when designing Azure landing zones, subscription strategy, hub-and-spoke networking, hybrid connectivity, identity architecture, or AKS/Container Apps/Functions compute patterns.

## Azure Well-Architected Framework

### Five Pillars
- **Reliability**: Design for failure with Availability Zones (99.99% SLA for zone-redundant deployments). Use Azure Load Balancer or Application Gateway for health-probed traffic distribution. Implement retry policies with Polly or built-in SDK retry. Use Azure Chaos Studio for fault injection testing. Define RTO/RPO targets and validate with regular DR drills.
- **Security**: Use Microsoft Entra ID (formerly Azure AD) as the identity foundation. Enable Conditional Access for risk-based authentication. Use Azure Policy for compliance guardrails. Enable Microsoft Defender for Cloud for threat detection across all resource types. Follow the Zero Trust model: verify explicitly, use least privilege, assume breach.
- **Cost Optimization**: Use Azure Advisor cost recommendations. Right-size with Azure Monitor metrics and VM insights. Use Reserved Instances (1-year or 3-year) for predictable workloads. Use Spot VMs for interruptible workloads. Implement auto-shutdown for dev/test environments.
- **Operational Excellence**: Use Infrastructure as Code (Bicep, Terraform, ARM templates). Implement CI/CD with Azure DevOps or GitHub Actions. Use Azure Monitor, Log Analytics, and Application Insights for full-stack observability.
- **Performance Efficiency**: Select the right compute tier and size based on workload profiling. Use Azure CDN or Front Door for global content delivery. Use Azure Cache for Redis for hot data paths. Use Proximity Placement Groups for latency-sensitive workloads.

### Well-Architected Reviews
- Use the Azure Well-Architected Review tool in the Azure portal. Conduct assessments per workload, not per subscription.
- Use Azure Advisor for automated recommendations across reliability, security, performance, cost, and operational excellence.

## Subscription and Management Group Strategy

### Management Group Hierarchy
- Tenant Root Group → Platform Management Groups → Workload Management Groups → Subscriptions.
- **Azure Landing Zone architecture**: Platform group contains Identity, Management (monitoring, logging), and Connectivity (hub networking, ExpressRoute, Firewall) subscriptions. Workload group contains application-specific subscriptions organized by environment and business unit.
- Use **Cloud Adoption Framework (CAF)** landing zone accelerators for automated deployment.

### Subscription Strategy
- Use subscriptions as scale units and policy boundaries. One subscription per application per environment for strong isolation.
- Avoid subscription sprawl: a single subscription supports up to 800 resource groups. Split when you need independent billing, separate RBAC boundaries, or distinct Azure Policy assignments.
- Use **Subscription Vending** automation for self-service subscription provisioning with pre-configured networking, policies, and RBAC.

### Azure Policy
- Apply policies at the management group level for organization-wide governance. Use built-in policy initiatives (CIS Azure Benchmark, NIST SP 800-53, ISO 27001) as baselines.
- Key policies: enforce resource tagging, restrict allowed regions, require encryption, deny public IP creation on VMs, enforce diagnostics settings.
- Use **Azure Policy as Code**: store policy definitions in Git, deploy with CI/CD pipelines.

## Networking Architecture

### Hub-and-Spoke Topology
- **Hub VNet**: Central connectivity hub containing Azure Firewall (or NVA), VPN Gateway, ExpressRoute Gateway, Azure Bastion, and shared services (DNS, AD). One hub per region.
- **Spoke VNets**: Application workload networks peered to the hub. Force-tunnel all outbound traffic through the hub firewall for centralized inspection.
- Use **Azure Virtual WAN** for large-scale hub-and-spoke when managing multiple hubs, VPN sites, and ExpressRoute circuits.

### Azure Front Door and Application Gateway
- **Azure Front Door**: Global HTTP load balancer with CDN, WAF, and SSL offloading. Use for global applications requiring fast failover (< 30 seconds), geo-routing, and DDoS protection.
- **Application Gateway**: Regional layer-7 load balancer with WAF v2. Supports URL-based routing, session affinity, SSL termination, and WebSocket. Use with AKS via AGIC.
- **Azure Firewall**: Managed network firewall with threat intelligence, TLS inspection, FQDN filtering. Use Premium SKU for TLS inspection and IDPS.

### Hybrid Connectivity
- **ExpressRoute**: Private connectivity to Azure (50 Mbps to 100 Gbps). Use ExpressRoute Global Reach for site-to-site connectivity through Microsoft's backbone. FastPath for ultra-low latency.
- **Site-to-Site VPN**: IPsec tunnels over the public internet. Use VPN Gateway with active-active configuration. Use zone-redundant gateway SKUs in production.
- **Azure Private Link**: Access Azure PaaS services over a private endpoint in your VNet. Use Private DNS Zones for name resolution of private endpoints.

## Identity Architecture

### Microsoft Entra ID (Azure AD)
- Central identity platform for all Azure access. Integrate with on-premises AD using Entra Connect or go cloud-native.
- **Conditional Access**: Risk-based access policies. Require MFA for all users. Block legacy authentication. Require compliant or Entra-joined devices for sensitive applications.
- **Privileged Identity Management (PIM)**: Just-in-time privileged access. Assign roles as eligible rather than permanent. Require approval workflows. Set maximum activation duration (4-8 hours).

### Workload Identity
- **Managed Identities**: System-assigned (tied to resource lifecycle) or user-assigned (independent lifecycle, reusable). Use for all service-to-Azure-resource authentication. Eliminates credential management.
- **Workload Identity Federation**: Authenticate external workloads (GitHub Actions, GCP services, Kubernetes) to Azure without storing credentials.
- **Service principals**: Use for CI/CD pipelines that cannot use managed identities. Rotate secrets on a 90-day schedule. Prefer certificate-based authentication.

### RBAC Design
- Use Azure built-in roles when possible. Create custom roles only when built-in roles are too broad or narrow.
- Assign roles to Entra ID groups, not individual users. Use dynamic groups for automatic membership.
- Scope roles at the narrowest level: resource group > subscription > management group.

## Compute Architecture

### AKS Architecture
- **AKS with Azure CNI Overlay**: Default networking mode. Use Azure CNI Powered by Cilium for advanced network policies and observability.
- **Node pool strategy**: System node pool (dedicated to system pods) and user node pools per workload type. Use cluster autoscaler and KEDA for event-driven pod scaling.
- **AKS security**: Enable Azure Policy for AKS (Gatekeeper). Use Workload Identity. Enable Defender for Containers. Use Azure Key Vault provider for Secrets Store CSI Driver.
- **AKS Fleet Manager**: Multi-cluster management for consistent configuration, workload placement, and multi-cluster load balancing.

### Azure Container Apps
- Serverless container platform built on Kubernetes and KEDA. Scale to zero.
- Use **Dapr integration** for service invocation, state management, pub/sub, and bindings.
- Use Container Apps Jobs for batch processing. Use revision-based traffic splitting for blue-green and canary deployments.

### Azure Functions
- Consumption plan for scale-to-zero. Premium plan for VNet integration and pre-warmed instances. Dedicated plan for always-on workloads.
- **Durable Functions**: Stateful function orchestrations for fan-out/fan-in, function chaining, and long-running processes.
- Integrate with Event Grid for Azure-native event routing. Use with Service Bus for reliable message processing.
