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

## When to use
- Designing or reviewing an Azure landing zone, subscription, or management group hierarchy
- Selecting between AKS, Container Apps, and Azure Functions for a workload
- Architecting hub-and-spoke networking, ExpressRoute, or Private Link topology
- Choosing between Cosmos DB, Azure SQL, Synapse, and Event Hubs for a data platform
- Configuring Defender for Cloud, Sentinel, or Azure Policy for security posture
- Optimizing Azure costs with reservations, Savings Plans, Spot VMs, or Hybrid Benefit

## Core principles
1. **Landing zone first** — governance and network topology before any workload
2. **Managed identity everywhere** — no credentials in code, ever
3. **Hub-and-spoke by default** — centralized firewall, spokes for workload isolation
4. **Policy as guardrails** — enforce standards at the management group level, not per resource
5. **Cost visibility before commitment** — analyze usage patterns before buying reservations

## Reference Files
- `references/azure-platform-and-networking.md` — Well-Architected Framework five pillars, subscription strategy, Azure Policy, hub-and-spoke topology, Front Door vs Application Gateway, ExpressRoute vs VPN, Entra ID identity architecture, PIM, workload identity, RBAC design, AKS, Container Apps, and Azure Functions patterns
- `references/azure-data-security-cost.md` — Cosmos DB partition design and consistency levels, Azure SQL and Synapse tiers, Event Hubs and Service Bus patterns, Data Lake Gen2 and Microsoft Fabric, Defender for Cloud CSPM/CWP, Microsoft Sentinel, NSGs, Azure Key Vault, Purview; Reserved Instances, Savings Plans, Spot VMs, Hybrid Benefit, and FinOps practices
