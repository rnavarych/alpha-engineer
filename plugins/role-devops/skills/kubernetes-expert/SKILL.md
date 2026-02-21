---
name: kubernetes-expert
description: |
  Deep Kubernetes expertise covering workload management, service networking,
  ingress configuration, autoscaling, RBAC, Helm/Kustomize templating,
  operator patterns, and managed cluster operations on EKS, GKE, and AKS.
allowed-tools: Read, Grep, Glob, Bash
---

# Kubernetes Expert

## Workload Management

- Use **Deployments** for stateless applications with rolling update strategy. Set `maxSurge` and `maxUnavailable` to control rollout speed.
- Use **StatefulSets** for databases and stateful services that need stable network identities and persistent volumes.
- Use **DaemonSets** for node-level agents (log collectors, monitoring exporters, network plugins).
- Use **Jobs** and **CronJobs** for batch processing and scheduled tasks. Set `backoffLimit` and `activeDeadlineSeconds` to prevent runaway jobs.
- Always define `resources.requests` and `resources.limits` for CPU and memory. Requests drive scheduling; limits prevent noisy neighbors.

## Services and Networking

- **ClusterIP** (default) for internal service-to-service communication. Use DNS names (`service.namespace.svc.cluster.local`).
- **NodePort** for development or when an external load balancer is unavailable. Avoid in production.
- **LoadBalancer** to provision cloud load balancers automatically. Annotate for internal-only LBs where needed.
- **Headless services** (`clusterIP: None`) for StatefulSets that need direct pod addressing.
- Apply **NetworkPolicies** to restrict pod-to-pod traffic. Default-deny ingress per namespace, then whitelist required paths.

## Ingress

- Use **nginx-ingress** or **Traefik** as the ingress controller. Configure TLS termination with cert-manager for automatic Let's Encrypt certificates.
- Define path-based and host-based routing rules. Use annotations for rate limiting, CORS, and authentication.
- For advanced traffic management (canary, header-based routing, traffic mirroring), consider Istio or Linkerd service mesh.

## Autoscaling

- **HPA (Horizontal Pod Autoscaler)** scales pods based on CPU, memory, or custom metrics. Set `minReplicas` to handle baseline traffic and `maxReplicas` as a cost ceiling.
- **VPA (Vertical Pod Autoscaler)** recommends or auto-adjusts resource requests. Use in recommendation mode first to gather data before enabling auto-updates.
- **Cluster Autoscaler** or **Karpenter** scales nodes to meet pod scheduling demands. Configure scale-down delays to prevent flapping.
- Combine HPA with PodDisruptionBudgets (PDBs) to ensure minimum availability during scaling events and node drains.

## RBAC

- Define **Roles** (namespace-scoped) and **ClusterRoles** for fine-grained permission control. Bind them with RoleBindings or ClusterRoleBindings.
- Follow least privilege: grant only the verbs (`get`, `list`, `create`, `update`, `delete`) and resources each service account needs.
- Use dedicated ServiceAccounts per workload. Never use the `default` ServiceAccount for production pods.
- Audit RBAC with `kubectl auth can-i --list` and tools like `rbac-lookup` or `rakkess`.

## Helm Charts

- Structure charts with `values.yaml` for defaults, environment-specific overrides in `values-{env}.yaml`.
- Use `helm template` to render manifests locally for review before applying. Lint charts with `helm lint`.
- Pin chart versions in `Chart.lock`. Use a private Helm repository (ChartMuseum, Harbor, OCI registry) for internal charts.
- Define helpers in `_helpers.tpl` for labels, selectors, and naming conventions to ensure consistency.

## Kustomize

- Use Kustomize for environment overlays when Helm templating is overkill. Base manifests with patches per environment.
- Leverage `configMapGenerator` and `secretGenerator` for automatic hash suffixing and rollout triggers.
- Use `commonLabels` and `commonAnnotations` for consistent metadata across all resources.

## Cluster Management (EKS, GKE, AKS)

- Provision managed clusters with Terraform, not console clicks. Pin Kubernetes versions and plan upgrade windows.
- Use **node pools** or **managed node groups** with labels and taints for workload isolation (GPU, high-memory, spot).
- Enable control plane logging and audit logs. Ship to a centralized logging backend.
- Regularly upgrade clusters. Follow the N-2 version support policy and test upgrades in staging first.

## Resource Limits and Pod Disruption Budgets

- Set `requests` to guarantee scheduling and `limits` to cap usage. Avoid setting CPU limits too tight (causes throttling); memory limits should match expected peak.
- Define PodDisruptionBudgets for critical workloads: `minAvailable: 1` or `maxUnavailable: 25%` to protect during voluntary disruptions (node drains, upgrades).

## Best Practices Checklist

1. Resource requests and limits on every container
2. Liveness and readiness probes configured
3. PodDisruptionBudgets for critical services
4. NetworkPolicies enforcing least-privilege networking
5. RBAC with dedicated ServiceAccounts
6. Namespaces for logical isolation
7. Helm or Kustomize for manifest management
8. Cluster upgrades tested in staging first
