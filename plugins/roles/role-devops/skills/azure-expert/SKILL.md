---
name: role-devops:azure-expert
description: |
  Deep Azure expertise covering Entra ID and RBAC, Virtual Networks, AKS,
  Azure Container Apps, App Service, Azure Functions, Azure SQL and Cosmos DB,
  Blob Storage, Azure CDN, Application Gateway, Azure Monitor, Log Analytics,
  Key Vault, Defender for Cloud, Microsoft Sentinel, Azure DevOps, ACR,
  Service Bus, Event Grid, Azure Reservations, and Cost Management for
  production Azure workloads.
allowed-tools: Read, Grep, Glob, Bash
---

# Azure Expert

## When to use
- Configuring Entra ID RBAC, PIM, Managed Identities, or Workload Identity federation for CI/CD
- Designing VNet hub-and-spoke topology, NSGs, load balancers, or Private Endpoints for PaaS
- Working with AKS, Container Apps, App Service, or Azure Functions
- Setting up Azure SQL, Cosmos DB, Blob Storage, Service Bus, or Event Hubs
- Security hardening with Key Vault, Defender for Cloud, or Microsoft Sentinel
- Observability with Log Analytics, KQL, Application Insights, or Azure Monitor alerts
- Cost optimization with Savings Plans, Reserved Instances, or Cost Management budgets

## Core principles
1. **Managed Identity everywhere** — no client secrets or connection strings in app config
2. **Private Endpoints for PaaS** — all SQL, Storage, Key Vault, ACR, Service Bus off public internet
3. **PIM for privileged access** — no permanent Owner/Contributor at subscription scope
4. **Policy-driven governance** — Azure Policy at Management Group level, Deny before Audit
5. **OIDC federation for CI/CD** — Workload Identity, no stored service principal secrets

## Reference Files

- `references/identity-policy.md` — Entra ID RBAC, custom roles, PIM just-in-time elevation, Conditional Access, system/user-assigned Managed Identities, Azure Policy initiatives and remediation, Azure DevOps/GitHub Actions OIDC, ACR private endpoints and geo-replication, Azure Savings Plans and Cost Management
- `references/networking-compute.md` — Hub-and-spoke VNet, Virtual WAN, subnet delegation, Private Endpoints, Azure Firewall Premium, NSG Flow Logs, DDoS Protection, Application Gateway WAF, Front Door, Traffic Manager, AKS CNI/Overlay/Workload Identity/node pools, Container Apps with Dapr, App Service VNet Integration, Service Bus, Event Grid, Event Hubs Kafka
- `references/storage-security-observability.md` — Blob Storage RBAC and lifecycle, WORM immutability, Azure SQL Elastic Pool/Failover Groups/TDE-CMK, Cosmos DB partition key design and RBAC, Key Vault soft delete and purge protection, Defender for Cloud Secure Score, Microsoft Sentinel analytics rules and playbooks, Log Analytics KQL, Application Insights OpenTelemetry, Azure Monitor Workbooks

## Best Practices Checklist
1. All subscriptions under Management Groups with Azure Policy enforcing standards
2. PIM for all privileged role assignments — no permanent Owner/Contributor at subscription scope
3. Workload Identity (OIDC federation) for CI/CD pipelines — no client secrets
4. Managed Identities for all compute services — no client secrets in config
5. Private Endpoints for all PaaS services (SQL, Storage, Key Vault, ACR, Service Bus)
6. Hub-and-spoke VNet topology with Azure Firewall for centralized egress
7. AKS private cluster with Azure AD RBAC, Workload Identity, and Defender for Containers
8. Key Vault purge protection and soft delete enabled on all vaults
9. Defender for Cloud enabled across all subscriptions with Secure Score monitored
10. Diagnostic settings on all resources routing to Log Analytics (enforced via Policy)
11. Azure Monitor Alerts with burn-rate-based SLO alerting
12. ACR with private endpoints, geo-replication, and vulnerability scanning
13. Azure Reservations or Savings Plans covering baseline compute spend
14. Budget alerts configured at subscription and resource group level
15. DDoS Protection Standard on production VNets hosting public-facing workloads
