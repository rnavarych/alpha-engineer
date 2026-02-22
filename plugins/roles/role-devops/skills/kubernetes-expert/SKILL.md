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

## Workload Management

- Use **Deployments** for stateless applications with rolling update strategy. Set `maxSurge` and `maxUnavailable` to control rollout speed. Use `minReadySeconds` to let new pods stabilize before being considered available.
- Use **StatefulSets** for databases and stateful services that need stable network identities and persistent volumes. Understand the ordered pod creation/deletion guarantee and use `podManagementPolicy: Parallel` when ordering is not needed to speed up scaling.
- Use **DaemonSets** for node-level agents (log collectors, monitoring exporters, network plugins). Use `updateStrategy: RollingUpdate` to safely update agents without downtime. Use node selectors and tolerations to target specific node pools.
- Use **Jobs** and **CronJobs** for batch processing and scheduled tasks. Set `backoffLimit` and `activeDeadlineSeconds` to prevent runaway jobs. Use `concurrencyPolicy: Forbid` to prevent overlapping CronJob runs. Set `ttlSecondsAfterFinished` for automatic cleanup.
- Always define `resources.requests` and `resources.limits` for CPU and memory. Requests drive scheduling; limits prevent noisy neighbors. Avoid setting CPU limits too tight as it causes throttling - prefer generous CPU limits or no CPU limits with QoS class awareness.

### StatefulSet Patterns
- Use `volumeClaimTemplates` for automatically provisioned persistent volumes per pod. Each pod gets its own PVC with a deterministic name.
- Implement `preStop` lifecycle hooks for graceful drain of stateful connections before pod termination.
- Use `podManagementPolicy: Parallel` for StatefulSets where ordering is not needed (peer replication sets, sharded stores) to dramatically speed up scaling.
- Implement readiness gates for StatefulSet pods that perform leader election to prevent traffic to followers before they are caught up.
- Use `updateStrategy.rollingUpdate.partition` for canary upgrades of StatefulSets - only pods with ordinal >= partition are updated.

### DaemonSet Patterns
- Use `updateStrategy.rollingUpdate.maxUnavailable` to control how many nodes undergo agent updates simultaneously.
- Apply `nodeAffinity` to target specific operating systems (`kubernetes.io/os: linux`), architectures (`kubernetes.io/arch: amd64`), or custom labels.
- Use `tolerations` to schedule on tainted nodes (GPU nodes, master nodes, spot nodes) where needed.
- Set resource limits carefully on DaemonSet pods - they run on every node and aggregate to significant cluster-wide consumption.

### Jobs and CronJobs
- Use `parallelism` and `completions` together for parallel batch processing with a completion count target.
- Use `ttlSecondsAfterFinished` to auto-delete completed Jobs and avoid accumulation.
- For CronJobs, set `startingDeadlineSeconds` to define how late a missed run can be started. Set `successfulJobsHistoryLimit` and `failedJobsHistoryLimit` to control history retention.
- Use Job templates with `generateName` for programmatic job creation from controllers or external triggers.

## Services and Networking

- **ClusterIP** (default) for internal service-to-service communication. Use DNS names (`service.namespace.svc.cluster.local`). Short form `service.namespace` works within the cluster.
- **NodePort** for development or when an external load balancer is unavailable. Avoid in production.
- **LoadBalancer** to provision cloud load balancers automatically. Annotate for internal-only LBs where needed. Use `service.beta.kubernetes.io/aws-load-balancer-type: nlb-ip` for NLB target groups in EKS.
- **Headless services** (`clusterIP: None`) for StatefulSets that need direct pod addressing. Enables DNS-based service discovery for each pod (`pod-0.service.namespace.svc.cluster.local`).
- Apply **NetworkPolicies** to restrict pod-to-pod traffic. Default-deny ingress per namespace, then whitelist required paths. Use `podSelector: {}` for namespace-wide policies.

## Gateway API (Replacing Ingress)

The Kubernetes Gateway API is the evolution beyond Ingress, providing richer routing semantics, multi-tenancy, and a portable API across implementations.

### Core Gateway API Resources
- **GatewayClass** - Cluster-scoped resource that identifies a controller (e.g., `nginx`, `cilium`, `istio`, `envoy-gateway`). Managed by infrastructure team.
- **Gateway** - Namespace-scoped resource that requests a particular class and defines listeners (ports, protocols, TLS). Managed by platform team.
- **HTTPRoute** - Namespace-scoped route that attaches to a Gateway and defines path/header/method matching rules. Managed by application teams.
- **GRPCRoute**, **TCPRoute**, **TLSRoute**, **UDPRoute** - Protocol-specific route types for non-HTTP traffic.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-route
  namespace: app
spec:
  parentRefs:
  - name: prod-gateway
    namespace: infra
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        add:
        - name: X-Forwarded-Host
          value: api.example.com
    backendRefs:
    - name: api-service
      port: 8080
      weight: 90
    - name: api-service-canary
      port: 8080
      weight: 10
```

### Gateway API Advantages over Ingress
- Native traffic splitting and weighted routing (canary deployments without annotations).
- Clean separation of concerns: infrastructure team manages Gateways, application teams manage Routes.
- Header, query parameter, and method-based routing as first-class citizens.
- TLS termination and passthrough handled at the Gateway level with clear cert references.
- Portable across implementations: Cilium, Envoy Gateway, Istio, NGINX, Contour, Traefik all support Gateway API.

## Cilium CNI (eBPF Networking)

Cilium is the leading eBPF-powered Kubernetes CNI, providing networking, security, and observability at the kernel level.

### Cilium Core Concepts
- **eBPF data plane** - Programs compiled and loaded into the Linux kernel's BPF VM. Packet processing at kernel level without context switches to user space. Significantly lower latency than iptables-based CNIs.
- **Identity-based security** - Policies enforce based on pod identity (labels) rather than IP addresses. Policies remain stable across pod restarts.
- **XDP (eXpress Data Path)** acceleration - Process packets at the network driver level before entering the kernel network stack. Maximum packet processing performance.
- **kube-proxy replacement** - Cilium can fully replace kube-proxy using eBPF for service load balancing. Lower latency, DSR (Direct Server Return) support, no conntrack table overhead.

### Cilium Network Policies
- Cilium extends standard Kubernetes NetworkPolicies with `CiliumNetworkPolicy` and `CiliumClusterwideNetworkPolicy` CRDs.
- L7 policies: restrict HTTP methods, paths, headers, and gRPC methods - not just L3/L4 ports and protocols.

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-l7-policy
spec:
  endpointSelector:
    matchLabels:
      app: api
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: frontend
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: GET
          path: /api/v1/.*
        - method: POST
          path: /api/v1/events
```

### Hubble (Cilium Observability)
- **Hubble** is the observability layer built on Cilium's eBPF data plane. Zero-instrumentation network flow visibility.
- Hubble UI provides a real-time network flow visualization for the entire cluster. Visualize service dependencies as a graph.
- Hubble CLI (`hubble observe`) provides real-time flow inspection and filtering without any application changes.
- Hubble metrics export Prometheus metrics for connection establishment rates, DNS resolution, HTTP request rates, and drop rates per identity pair.
- Use Hubble for network policy troubleshooting: observe what flows are being dropped and by which policy rule before writing new policies.

### Cilium Service Mesh
- Cilium Gateway API implementation provides ingress, load balancing, and traffic management without Envoy sidecars.
- **Sidecar-free mTLS** using WireGuard node-to-node encryption or eBPF-based mTLS at the kernel level. No sidecar overhead.
- For full sidecar-based mesh (when needed), Cilium integrates with Envoy via per-node Envoy proxy rather than per-pod sidecars.
- Mutual TLS authentication using SPIFFE/SPIRE for workload identity.

## Other CNI Options

### Calico
- Battle-tested CNI with extensive NetworkPolicy support. Calico-native extended policies (`NetworkPolicy` + `GlobalNetworkPolicy`) for cluster-wide rules.
- **eBPF data plane** available in Calico (Calico eBPF) as an alternative to iptables. Similar benefits to Cilium's eBPF.
- WireGuard encryption for pod-to-pod traffic at the node level.
- Calico Enterprise adds tiered policies, compliance reporting, and security controls for regulated industries.
- Use Calico when you need proven stability, extensive enterprise support, and strong NetworkPolicy enforcement without full eBPF adoption.

### Flannel
- Simplest CNI. VXLAN or host-gw backend. Minimal features - no NetworkPolicy support (requires a separate NetworkPolicy enforcer like Canal = Flannel + Calico policies).
- Appropriate only for simple development clusters or when operational simplicity outweighs networking feature needs.
- Not recommended for production workloads requiring NetworkPolicies, observability, or performance.

## Policy Enforcement (Kyverno and OPA Gatekeeper)

### Kyverno
- Kubernetes-native policy engine. Policies are Kubernetes CRDs, not Rego or a separate language. Lower barrier to entry for teams unfamiliar with Rego.
- Supports **validate** (admission webhook), **mutate** (auto-inject labels, add default resource limits), and **generate** (create ConfigMaps, NetworkPolicies when a namespace is created) policies.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: enforce
  rules:
  - name: check-container-resources
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "CPU and memory limits are required."
      pattern:
        spec:
          containers:
          - name: "*"
            resources:
              limits:
                memory: "?*"
                cpu: "?*"
```

- Use Kyverno policies for: image registry restrictions, label requirements, resource limit enforcement, disabling privilege escalation, requiring non-root users.
- Kyverno CLI (`kyverno apply`) for testing policies against manifests in CI before cluster application.

### OPA Gatekeeper
- Open Policy Agent Gatekeeper uses **Rego** policy language. More powerful and flexible than Kyverno for complex policy logic.
- **ConstraintTemplate** defines the policy logic in Rego. **Constraint** applies it with parameters to specific resource kinds.
- Use OPA for complex policies requiring joins, data lookups, and multi-resource validation.
- Gatekeeper audit mode continuously checks existing resources against policies and reports violations without blocking.
- Use `ExternalData` provider to fetch external data (secret manager values, CMDB data) during admission evaluation.
- Integration with Conftest for pre-admission testing in CI pipelines.

## Autoscaling

### HPA (Horizontal Pod Autoscaler)
- Scales pods based on CPU, memory, or custom/external metrics. Set `minReplicas` to handle baseline traffic and `maxReplicas` as a cost ceiling.
- Use `behavior` to configure separate scale-up and scale-down policies with stabilization windows to prevent flapping.
- Custom metrics via Prometheus Adapter or KEDA (preferred for event-driven metrics).
- `scaleTargetRef` supports Deployments, StatefulSets, and custom CRDs that implement the scale subresource.

### VPA (Vertical Pod Autoscaler)
- Recommends or auto-adjusts resource requests. Use `updateMode: Off` first to gather recommendations without applying changes.
- `updateMode: Initial` applies recommendations only at pod creation. `updateMode: Auto` evicts and recreates pods to apply new recommendations.
- VPA cannot scale in-place in Kubernetes < 1.27. `InPlaceOrRecreate` mode available from 1.27+.
- VPA and HPA cannot both target CPU/memory on the same Deployment. Use VPA for right-sizing and HPA for replicas, or use KEDA for combined scaling.

### KEDA (Kubernetes Event-Driven Autoscaling)
- Scale from zero to N based on external event sources: Kafka consumer lag, Redis queue depth, SQS queue length, HTTP request rate, Prometheus metrics, Cron schedules.
- **ScaledObject** wraps HPA with rich trigger configuration. **ScaledJob** scales Jobs (not Deployments) for burst processing.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: worker-scaledobject
spec:
  scaleTargetRef:
    name: worker-deployment
  minReplicaCount: 0
  maxReplicaCount: 50
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: kafka.default.svc.cluster.local:9092
      consumerGroup: my-consumer-group
      topic: events
      lagThreshold: "100"
      activationLagThreshold: "10"
```

- Scale to zero with KEDA for cost optimization: workers only exist when there is work to process.
- Use `cooldownPeriod` to avoid premature scale-down before all events are processed.
- KEDA supports `ExternalScaler` for custom scale targets not covered by built-in scalers.

### Cluster Autoscaler
- Scales node groups up when pods are unschedulable. Scales down when nodes are underutilized for `scale-down-unneeded-time` (default 10 min).
- Configure `--scale-down-delay-after-add` to prevent premature scale-down after a scale-up event.
- Use `cluster-autoscaler.kubernetes.io/safe-to-evict: "false"` annotation on pods that must not be evicted for scale-down.
- Per-node-group `--balance-similar-node-groups` for multi-AZ distribution.

### Karpenter (AWS-native, Kubernetes-native Node Provisioning)
- Karpenter provisions nodes in seconds, selecting the optimal instance type from a broad pool rather than pre-configured node groups.
- **NodePool** defines constraints (instance categories, sizes, architectures, OS, capacity types) and node expiry/disruption settings.
- **NodeClaim** represents a request for capacity; Karpenter satisfies it by creating instances directly via EC2 Fleet API.
- Supports spot consolidation: replaces spot nodes with cheaper spot options as prices change.
- `disruption.consolidationPolicy: WhenUnderutilized` actively consolidates workloads onto fewer, denser nodes.
- Expiry-based node recycling via `expireAfter` ensures nodes are regularly refreshed for security patching.

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: general
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64", "arm64"]
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h
```

## Helm Advanced Patterns

### OCI Helm Registries
- Store Helm charts in OCI-compliant registries (GitHub Container Registry, ECR, GCR, Harbor). No separate ChartMuseum required.
- Push: `helm push mychart.tgz oci://ghcr.io/org/charts`. Pull: `helm install myrelease oci://ghcr.io/org/charts/mychart --version 1.2.3`.
- Sign charts with cosign for supply-chain integrity verification.

### Helm Hooks
- `pre-install`, `post-install`, `pre-upgrade`, `post-upgrade`, `pre-delete`, `post-delete`, `pre-rollback`, `post-rollback` hooks.
- Use hooks for: database migrations (pre-upgrade Job), cache warming (post-install Job), cleanup tasks (pre-delete).
- Set `"helm.sh/hook-weight"` for ordering multiple hooks of the same type.
- Set `"helm.sh/hook-delete-policy": hook-succeeded` to clean up hook resources after completion.

### Helm Tests
- Define test pods with `"helm.sh/hook": test` annotation. Run with `helm test <release-name>`.
- Tests validate the deployed service: HTTP health check, database connectivity, queue reachability.
- Integrate `helm test` into post-deployment verification steps in CD pipelines.

### Library Charts
- Library charts (`type: library` in Chart.yaml) provide reusable template helpers without rendering any resources themselves.
- Define common `_deployment.tpl`, `_service.tpl`, `_ingress.tpl` helpers in a library chart. Reference from application charts.
- Version and distribute library charts via OCI registry for consistent templates across the organization.

### Helm Secrets and SOPS Integration
- `helm-secrets` plugin decrypts SOPS-encrypted values files before rendering. `helm secrets upgrade ... -f secrets.yaml`.
- Store encrypted values files alongside plain values files in Git. Only the secrets file is encrypted; its structure is visible.
- Use `helm-secrets` with age encryption for simpler key management than PGP or KMS in development.

## Kustomize Advanced

- Use Kustomize for environment overlays when Helm templating is overkill. Base manifests with patches per environment.
- Leverage `configMapGenerator` and `secretGenerator` for automatic hash suffixing and rollout triggers.
- Use `commonLabels` and `commonAnnotations` for consistent metadata across all resources.
- **Strategic Merge Patches** for complex modifications that merge arrays: add container sidecars, add volumes, merge tolerations.
- **JSON 6902 Patches** for precise path-based replacements when strategic merge is insufficient.
- **Replacements** (kustomize v5+) for cross-resource field references: reference a Service name in an Ingress backend.
- **Components** for reusable feature modules (e.g., enable-monitoring, enable-pdb) that can be added to any overlay.
- **HelmChartInflationGenerator** to render Helm charts as Kustomize bases - bridge between Helm and Kustomize workflows.
- Use `namePrefix`/`nameSuffix` for safe multi-tenancy: separate instances of the same base in the same cluster.

## Operator Pattern

### kubebuilder
- `kubebuilder init` scaffolds a Go operator with controller-runtime, CRD generation, and webhook scaffolding.
- Define Custom Resources with `//+kubebuilder:object:root=true` and `//+kubebuilder:subresource:status` markers.
- Implement reconcile loops that handle: create, update, delete, and status update. Reconcilers must be idempotent.
- Use `controller-runtime`'s `Builder` to set up watches and event filters. Use `Owns()` for owned resources and `Watches()` for non-owned.
- Generate CRD manifests with `make generate && make manifests`. CRD validation schema is auto-generated from Go struct tags.
- Use predicates to filter reconcile events and avoid unnecessary reconcile loops.

### Operator SDK
- Operator SDK supports Go (kubebuilder-based), Ansible (for teams preferring YAML over Go), and Helm (wrap a Helm chart as an operator).
- Ansible operators use `watches.yaml` and Ansible roles for reconciliation logic. Lower barrier for Ansible-fluent teams.
- Helm operators wrap an existing Helm chart and reconcile it continuously. Useful for giving a Helm release operator semantics.
- `operator-sdk scorecard` tests operator packaging and OLM bundle quality.

### kopf (Kubernetes Operator Pythonic Framework)
- Python-based operator framework. Handlers are decorated Python functions: `@kopf.on.create`, `@kopf.on.update`, `@kopf.on.delete`.
- Excellent choice for data teams or ML platform engineers more comfortable with Python than Go.
- kopf manages event watching, retry logic, and status conditions automatically.

### CRD Design Principles
- Define validation schemas with OpenAPI v3 to enforce required fields and value constraints at admission time.
- Use `status` subresource for operator-managed status. Never expose status fields as `spec`.
- Use `additionalPrinterColumns` to display useful information in `kubectl get` output.
- Version CRDs carefully: use conversion webhooks for breaking schema changes. Follow Kubernetes API deprecation policy for externally consumed CRDs.
- Use `spec.preserveUnknownFields: false` to reject unknown fields at admission.

## Resource Management

### Resource Quotas and LimitRanges
- **ResourceQuota** enforces aggregate limits per namespace: total CPU, memory, PVC count, pod count, service count.
- **LimitRange** sets default requests/limits and min/max constraints per container, pod, or PVC within a namespace.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "4"
      memory: "8Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
```

- Use ResourceQuotas to prevent namespace-level resource monopolization in shared clusters.
- Set LimitRange defaults so pods without resource specifications still have requests/limits applied.

### Namespace Management
- One namespace per team or per application component. Use namespace labels for NetworkPolicy selectors and Kyverno policy matching.
- Namespace lifecycle management: provision via GitOps (Flux HelmRelease or Kustomize), deprovision with validation (check for running workloads, PVCs, non-empty secrets).
- Use `kubectl label namespace` for Istio/Cilium mesh enrollment, Kyverno policy targeting, and network isolation grouping.
- Implement namespace-scoped RBAC: give teams admin access to their namespace, not cluster-admin.
- Use hierarchical namespaces (HNC) for multi-level namespace trees: organization -> team -> environment namespace hierarchies.

### Pod Disruption Budgets (PDB)
- Define PDBs for critical workloads: `minAvailable: 1` or `maxUnavailable: 25%` to protect during voluntary disruptions (node drains, upgrades, Karpenter consolidation).
- PDBs interact with: `kubectl drain`, Karpenter disruption, Cluster Autoscaler scale-down, rolling update pod termination.
- Use `maxUnavailable` (percentage) for large deployments. Use `minAvailable` (absolute count) for small deployments where percentages round to zero.

### Topology Spread Constraints
- Distribute pods across zones, nodes, or custom topology domains to prevent single-zone or single-node concentration.

```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
      app: api
- maxSkew: 2
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
  labelSelector:
    matchLabels:
      app: api
```

- `whenUnsatisfiable: DoNotSchedule` is a hard constraint. `whenUnsatisfiable: ScheduleAnyway` is a soft best-effort.
- Combine zone spread with node spread for high availability across both zones and individual node failures.

### Node Affinity and Anti-Affinity
- `requiredDuringSchedulingIgnoredDuringExecution` (hard) and `preferredDuringSchedulingIgnoredDuringExecution` (soft) node affinity.
- Use `nodeAffinity` to schedule GPU workloads to GPU nodes, memory-intensive workloads to high-memory nodes.
- Use `podAntiAffinity` to spread replicas across nodes: prevents multiple replicas of the same pod landing on the same node.

### Taints and Tolerations
- Taint nodes for dedicated workloads: `kubectl taint nodes gpu-node-1 nvidia.com/gpu=true:NoSchedule`.
- Tolerate node taints in pods that should run on tainted nodes: `tolerations: [{key: "nvidia.com/gpu", value: "true", effect: "NoSchedule"}]`.
- Use `NoExecute` taint effect to evict existing pods from nodes being dedicated.
- Common patterns: spot node taint, GPU node taint, arm64 architecture taint, maintenance taint before drain.

## Multi-Cluster Management

### Cluster API (CAPI)
- Kubernetes-native cluster lifecycle management. Clusters are Kubernetes CRDs managed by controllers.
- Infrastructure providers: AWS (CAPA), GCP (CAPG), Azure (CAPZ), vSphere (CAPV), bare-metal (CAPM3).
- Define clusters as YAML manifests, version control them, apply via GitOps. Cluster upgrades via spec change.
- ClusterClass for opinionated cluster templates - define a class once, stamp out many clusters from it.

### Rancher
- Multi-cluster management UI and API. Manages clusters across clouds, on-premises, and edge.
- Fleet (by Rancher) for GitOps at scale: manage thousands of clusters from a single Git repository.
- Rancher provides integrated monitoring, logging, RBAC, and catalog (Helm charts) across all clusters.

### vCluster and Loft
- **vCluster** creates virtual Kubernetes clusters inside a host cluster namespace. Lightweight, fast, isolated - without provisioning real infrastructure.
- Use cases: development environments, CI cluster isolation, multi-tenancy where namespace-level isolation is insufficient.
- vCluster runs a virtual API server (k3s or k8s) inside a pod. Workloads scheduled into the virtual cluster appear as pods in the host cluster namespace.
- **Loft** (now Loft Labs) wraps vCluster with self-service UI, RBAC, sleep/wake policies (to save cost), and billing.

### Local Development Clusters

#### Kind (Kubernetes IN Docker)
- Run Kubernetes control plane and workers as Docker containers. Fast to provision (~1 min). Multiple clusters on one machine.
- Used extensively in CI for Kubernetes integration tests. `kind create cluster --config kind-config.yaml`.
- Multi-node kind clusters for testing pod anti-affinity, topology spread, and DaemonSets.
- Load local images into kind: `kind load docker-image myimage:latest`.

#### k3d (k3s in Docker)
- k3s (lightweight Kubernetes) inside Docker containers. Even faster startup than kind. Single binary.
- Traefik ingress bundled by default. Use `--no-deploy traefik` to disable if testing other ingress controllers.
- `k3d cluster create` with `--servers` and `--agents` flags for HA and multi-node local clusters.

#### Minikube
- Local cluster with multiple driver options: Docker, VirtualBox, Hyperkit, KVM. More flexible than kind for non-Docker setups.
- Add-ons: `minikube addons enable ingress metrics-server`. Good for learning and exploration.
- Multi-node support: `minikube start --nodes=3`. Node labels and taints configurable.

#### Talos Linux and Sidero
- **Talos Linux** - Immutable, API-driven Linux OS designed exclusively for Kubernetes. No SSH, no shell, no package manager. All management via `talosctl` API.
- Talos produces minimal attack surface: the OS is entirely read-only except for ephemeral mounts.
- **Sidero** - Bare-metal Kubernetes cluster provisioner built on Cluster API and Talos Linux. PXE-boot bare-metal servers into Talos, manage via CAPI.
- Excellent for on-premises production Kubernetes that requires operator-controlled immutable infrastructure.

## Crossplane (Infrastructure as Kubernetes Resources)

- Crossplane extends Kubernetes with the ability to provision and manage cloud infrastructure via CRDs.
- **Managed Resources** (MRs) - CRDs that map 1:1 to cloud resources (e.g., `RDSInstance`, `S3Bucket`, `GKECluster`). Providers: AWS, GCP, Azure, Helm, Terraform.
- **Composite Resources** (XRs) - Custom CRDs that compose multiple MRs into a higher-level abstraction (e.g., a `Database` XR that provisions RDS + security group + parameter group + Route53 entry).
- **Claims** - Namespace-scoped requests for XRs. Developers create Claims in their namespace; Crossplane creates XRs cluster-wide.

```yaml
apiVersion: database.platform.example.com/v1alpha1
kind: PostgreSQLInstance
metadata:
  name: my-app-db
  namespace: app-team
spec:
  parameters:
    storageGB: 20
    version: "14"
  writeConnectionSecretToRef:
    name: db-connection
```

- Use Crossplane for platform engineering self-service: developers declare the infrastructure they need as Kubernetes objects; platform team controls the composition and policies.
- Crossplane vs. Terraform: Crossplane lives in the cluster and continuously reconciles (detects and corrects drift). Terraform is run on-demand.

## Best Practices Checklist

1. Resource requests and limits on every container
2. Liveness, readiness, and startup probes configured correctly
3. PodDisruptionBudgets for critical services with correct `minAvailable`/`maxUnavailable`
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
