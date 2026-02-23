# Kubernetes Autoscaling

## When to load
Load when configuring HPA, VPA, KEDA event-driven scaling, Cluster Autoscaler, Karpenter node provisioning,
or designing scale-to-zero workload patterns.

## HPA (Horizontal Pod Autoscaler)

- Scales pods based on CPU, memory, or custom/external metrics. Set `minReplicas` to handle baseline traffic and `maxReplicas` as a cost ceiling.
- Use `behavior` to configure separate scale-up and scale-down policies with stabilization windows to prevent flapping.
- Custom metrics via Prometheus Adapter or KEDA (preferred for event-driven metrics).
- `scaleTargetRef` supports Deployments, StatefulSets, and custom CRDs that implement the scale subresource.

## VPA (Vertical Pod Autoscaler)

- Recommends or auto-adjusts resource requests. Use `updateMode: Off` first to gather recommendations without applying changes.
- `updateMode: Initial` applies recommendations only at pod creation. `updateMode: Auto` evicts and recreates pods to apply new recommendations.
- VPA cannot scale in-place in Kubernetes < 1.27. `InPlaceOrRecreate` mode available from 1.27+.
- VPA and HPA cannot both target CPU/memory on the same Deployment. Use VPA for right-sizing and HPA for replicas, or use KEDA for combined scaling.

## KEDA (Kubernetes Event-Driven Autoscaling)

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

## Cluster Autoscaler

- Scales node groups up when pods are unschedulable. Scales down when nodes are underutilized for `scale-down-unneeded-time` (default 10 min).
- Configure `--scale-down-delay-after-add` to prevent premature scale-down after a scale-up event.
- Use `cluster-autoscaler.kubernetes.io/safe-to-evict: "false"` annotation on pods that must not be evicted for scale-down.
- Per-node-group `--balance-similar-node-groups` for multi-AZ distribution.

## Karpenter (AWS-native Node Provisioning)

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
