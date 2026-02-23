# Kubernetes Workload Management

## When to load
Load when configuring Deployments, StatefulSets, DaemonSets, Jobs, CronJobs, resource requests/limits,
or any pod-level workload scheduling concern.

## Deployments
- Use **Deployments** for stateless applications with rolling update strategy. Set `maxSurge` and `maxUnavailable` to control rollout speed. Use `minReadySeconds` to let new pods stabilize before being considered available.
- Always define `resources.requests` and `resources.limits` for CPU and memory. Requests drive scheduling; limits prevent noisy neighbors. Avoid setting CPU limits too tight — it causes throttling. Prefer generous CPU limits or no CPU limits with QoS class awareness.

## StatefulSets
- Use **StatefulSets** for databases and stateful services that need stable network identities and persistent volumes. Understand ordered pod creation/deletion guarantee.
- Use `podManagementPolicy: Parallel` when ordering is not needed to speed up scaling.
- Use `volumeClaimTemplates` for automatically provisioned persistent volumes per pod. Each pod gets its own PVC with a deterministic name.
- Implement `preStop` lifecycle hooks for graceful drain of stateful connections before pod termination.
- Use `updateStrategy.rollingUpdate.partition` for canary upgrades — only pods with ordinal >= partition are updated.
- Implement readiness gates for StatefulSet pods that perform leader election to prevent traffic to followers before they are caught up.

## DaemonSets
- Use **DaemonSets** for node-level agents (log collectors, monitoring exporters, network plugins). Use `updateStrategy: RollingUpdate` to safely update agents without downtime.
- Use `updateStrategy.rollingUpdate.maxUnavailable` to control how many nodes undergo agent updates simultaneously.
- Apply `nodeAffinity` to target specific OS (`kubernetes.io/os: linux`), architectures, or custom labels.
- Use `tolerations` to schedule on tainted nodes (GPU nodes, master nodes, spot nodes) where needed.
- Set resource limits carefully — DaemonSet pods run on every node and aggregate to significant cluster-wide consumption.

## Jobs and CronJobs
- Use **Jobs** and **CronJobs** for batch processing and scheduled tasks. Set `backoffLimit` and `activeDeadlineSeconds` to prevent runaway jobs.
- Use `concurrencyPolicy: Forbid` to prevent overlapping CronJob runs. Set `ttlSecondsAfterFinished` for automatic cleanup.
- Use `parallelism` and `completions` together for parallel batch processing with a completion count target.
- For CronJobs, set `startingDeadlineSeconds` to define how late a missed run can be started. Set `successfulJobsHistoryLimit` and `failedJobsHistoryLimit` to control history retention.
- Use Job templates with `generateName` for programmatic job creation from controllers or external triggers.

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

### Pod Disruption Budgets
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

- `whenUnsatisfiable: DoNotSchedule` is a hard constraint. `whenUnsatisfiable: ScheduleAnyway` is soft best-effort.
- Combine zone spread with node spread for high availability across both zones and individual node failures.

### Node Affinity, Anti-Affinity, and Taints
- `requiredDuringSchedulingIgnoredDuringExecution` (hard) and `preferredDuringSchedulingIgnoredDuringExecution` (soft) node affinity.
- Use `nodeAffinity` to schedule GPU workloads to GPU nodes, memory-intensive workloads to high-memory nodes.
- Use `podAntiAffinity` to spread replicas across nodes: prevents multiple replicas of the same pod landing on the same node.
- Taint nodes for dedicated workloads: `kubectl taint nodes gpu-node-1 nvidia.com/gpu=true:NoSchedule`.
- Use `NoExecute` taint effect to evict existing pods from nodes being dedicated.
- Common patterns: spot node taint, GPU node taint, arm64 architecture taint, maintenance taint before drain.
