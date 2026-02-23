---
name: kubernetes-expert
description: |
  Deep Kubernetes expertise covering workload management, Gateway API, Cilium eBPF
  networking, Kyverno/OPA policy enforcement, KEDA event-driven autoscaling,
  Karpenter node provisioning, Helm advanced patterns, Kustomize, Operator pattern,
  CRDs, multi-cluster management, local development clusters, Crossplane,
  StatefulSets, DaemonSets, Jobs, Pod Disruption Budgets, topology spread,
  node affinity, taints, resource quotas, namespace management, and managed
  cluster operations on EKS, GKE, and AKS.
allowed-tools: Read, Grep, Glob, Bash
---

# Kubernetes Expert

## When to use
- Designing or reviewing Kubernetes workload configuration (Deployments, StatefulSets, DaemonSets, Jobs)
- Setting up cluster networking, NetworkPolicies, or migrating from Ingress to Gateway API
- Configuring autoscaling with HPA, VPA, KEDA, Cluster Autoscaler, or Karpenter
- Writing Helm charts, Kustomize overlays, or Kubernetes Operators
- Multi-cluster strategy, local development environments, or Crossplane infrastructure

## Core principles
1. **Resources are mandatory** — requests and limits on every container, every time
2. **Default-deny networking** — NetworkPolicies with default-deny ingress per namespace
3. **Gateway API over Ingress** — for all new ingress implementations
4. **Policy at admission** — Kyverno or OPA Gatekeeper, never after-the-fact auditing
5. **Autoscaling is layered** — KEDA for event-driven zero-scale, Karpenter for optimal nodes

## Reference Files

- `references/workloads.md` — Deployment/StatefulSet/DaemonSet/Job patterns, resource quotas, LimitRanges, PodDisruptionBudgets, topology spread constraints, node affinity and taints
- `references/networking-gateway.md` — ClusterIP/NodePort/LoadBalancer/Headless services, Gateway API (GatewayClass, Gateway, HTTPRoute), canary routing, namespace management
- `references/cilium-policy.md` — Cilium eBPF core concepts, CiliumNetworkPolicy L7 rules, Hubble observability, service mesh, Calico, Flannel, Kyverno admission policies, OPA Gatekeeper Rego
- `references/autoscaling.md` — HPA behavior and stabilization, VPA modes, KEDA ScaledObject/ScaledJob with Kafka/Redis/SQS triggers, Cluster Autoscaler, Karpenter NodePool with spot consolidation
- `references/helm-kustomize-ops.md` — OCI registries, Helm hooks, library charts, SOPS integration, Kustomize patches and components, kubebuilder/Operator SDK/kopf, CRD design, Cluster API, vCluster, local clusters (kind/k3d), Crossplane composite resources

## Best Practices Checklist
1. Resource requests and limits on every container
2. Liveness, readiness, and startup probes configured correctly
3. PodDisruptionBudgets for critical services
4. NetworkPolicies with default-deny ingress per namespace
5. RBAC with dedicated ServiceAccounts, no wildcard permissions
6. Namespaces with ResourceQuotas and LimitRanges
7. Topology spread constraints for zone and node distribution
8. Helm or Kustomize for manifest management, never raw kubectl apply
9. Karpenter or Cluster Autoscaler for dynamic node scaling
10. KEDA for event-driven workloads that should scale to zero
11. Gateway API (not Ingress) for new ingress implementations
12. Kyverno or OPA Gatekeeper policies enforced at admission
13. Cilium for eBPF-powered networking and observability
14. Crossplane for self-service infrastructure provisioning
15. Cluster upgrades tested in staging with Cluster API or managed upgrade tools
