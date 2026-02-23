# Helm, Kustomize, Operators, Multi-Cluster, and Crossplane

## When to load
Load when working with Helm chart patterns, Kustomize overlays, writing Kubernetes operators (kubebuilder/kopf),
multi-cluster management (Cluster API, vCluster), local dev clusters, or Crossplane infrastructure provisioning.

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

### Helm Tests and Library Charts
- Define test pods with `"helm.sh/hook": test` annotation. Run with `helm test <release-name>`.
- Library charts (`type: library` in Chart.yaml) provide reusable template helpers without rendering any resources themselves.
- Define common `_deployment.tpl`, `_service.tpl`, `_ingress.tpl` helpers in a library chart. Reference from application charts.

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
- **HelmChartInflationGenerator** to render Helm charts as Kustomize bases — bridge between Helm and Kustomize workflows.
- Use `namePrefix`/`nameSuffix` for safe multi-tenancy: separate instances of the same base in the same cluster.

## Operator Pattern

### kubebuilder and Operator SDK
- `kubebuilder init` scaffolds a Go operator with controller-runtime, CRD generation, and webhook scaffolding.
- Define Custom Resources with `//+kubebuilder:object:root=true` and `//+kubebuilder:subresource:status` markers.
- Implement reconcile loops that handle: create, update, delete, and status update. Reconcilers must be idempotent.
- Use `controller-runtime`'s `Builder` to set up watches and event filters. Use `Owns()` for owned resources, `Watches()` for non-owned.
- Use predicates to filter reconcile events and avoid unnecessary reconcile loops.
- Operator SDK supports Go (kubebuilder-based), Ansible (for teams preferring YAML over Go), and Helm (wrap a Helm chart as an operator).

### kopf (Python Operator Framework)
- Python-based operator framework. Handlers are decorated Python functions: `@kopf.on.create`, `@kopf.on.update`, `@kopf.on.delete`.
- Excellent choice for data teams or ML platform engineers more comfortable with Python than Go.
- kopf manages event watching, retry logic, and status conditions automatically.

### CRD Design Principles
- Define validation schemas with OpenAPI v3 to enforce required fields and value constraints at admission time.
- Use `status` subresource for operator-managed status. Never expose status fields as `spec`.
- Use `additionalPrinterColumns` to display useful information in `kubectl get` output.
- Version CRDs carefully: use conversion webhooks for breaking schema changes.
- Use `spec.preserveUnknownFields: false` to reject unknown fields at admission.

## Multi-Cluster Management

### Cluster API (CAPI) and Rancher
- Kubernetes-native cluster lifecycle management. Clusters are Kubernetes CRDs managed by controllers.
- Infrastructure providers: AWS (CAPA), GCP (CAPG), Azure (CAPZ), vSphere (CAPV), bare-metal (CAPM3).
- Define clusters as YAML manifests, version control them, apply via GitOps. Cluster upgrades via spec change.
- ClusterClass for opinionated cluster templates — define a class once, stamp out many clusters from it.
- Rancher provides multi-cluster management UI, Fleet for GitOps at scale across thousands of clusters.

### vCluster and Local Dev Clusters
- **vCluster** creates virtual Kubernetes clusters inside a host cluster namespace. Lightweight, fast, isolated — without provisioning real infrastructure.
- Use cases: development environments, CI cluster isolation, multi-tenancy where namespace-level isolation is insufficient.
- **Kind** (Kubernetes IN Docker): fast to provision (~1 min), used extensively in CI for integration tests. Load local images: `kind load docker-image myimage:latest`.
- **k3d** (k3s in Docker): even faster startup than kind. Single binary. Traefik ingress bundled by default.
- **Talos Linux**: immutable, API-driven Linux OS for Kubernetes. No SSH, no shell, no package manager. Minimal attack surface.

## Crossplane (Infrastructure as Kubernetes Resources)

- Crossplane extends Kubernetes with the ability to provision and manage cloud infrastructure via CRDs.
- **Managed Resources** (MRs) — CRDs that map 1:1 to cloud resources (e.g., `RDSInstance`, `S3Bucket`). Providers: AWS, GCP, Azure, Helm, Terraform.
- **Composite Resources** (XRs) — Custom CRDs that compose multiple MRs into a higher-level abstraction.
- **Claims** — Namespace-scoped requests for XRs. Developers create Claims; Crossplane creates XRs cluster-wide.

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

- Use Crossplane for platform engineering self-service: developers declare infrastructure as Kubernetes objects; platform team controls composition and policies.
- Crossplane vs. Terraform: Crossplane lives in the cluster and continuously reconciles (detects and corrects drift). Terraform is run on-demand.
