# Cilium CNI and Policy Enforcement

## When to load
Load when working with Cilium eBPF networking, Hubble observability, Kyverno admission policies,
OPA Gatekeeper constraints, or other CNI options (Calico, Flannel).

## Cilium CNI (eBPF Networking)

Cilium is the leading eBPF-powered Kubernetes CNI, providing networking, security, and observability at the kernel level.

### Core Concepts
- **eBPF data plane** — Programs compiled and loaded into the Linux kernel's BPF VM. Packet processing at kernel level without context switches to user space. Significantly lower latency than iptables-based CNIs.
- **Identity-based security** — Policies enforce based on pod identity (labels) rather than IP addresses. Policies remain stable across pod restarts.
- **XDP (eXpress Data Path)** acceleration — Process packets at the network driver level before entering the kernel network stack. Maximum packet processing performance.
- **kube-proxy replacement** — Cilium can fully replace kube-proxy using eBPF for service load balancing. Lower latency, DSR (Direct Server Return) support, no conntrack table overhead.

### Cilium Network Policies
- Cilium extends standard Kubernetes NetworkPolicies with `CiliumNetworkPolicy` and `CiliumClusterwideNetworkPolicy` CRDs.
- L7 policies: restrict HTTP methods, paths, headers, and gRPC methods — not just L3/L4 ports and protocols.

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
- **eBPF data plane** available in Calico as an alternative to iptables. Similar benefits to Cilium's eBPF.
- WireGuard encryption for pod-to-pod traffic at the node level.
- Calico Enterprise adds tiered policies, compliance reporting, and security controls for regulated industries.
- Use Calico when you need proven stability, extensive enterprise support, and strong NetworkPolicy enforcement without full eBPF adoption.

### Flannel
- Simplest CNI. VXLAN or host-gw backend. Minimal features — no NetworkPolicy support (requires Canal = Flannel + Calico policies).
- Not recommended for production workloads requiring NetworkPolicies, observability, or performance.

## Policy Enforcement

### Kyverno
- Kubernetes-native policy engine. Policies are Kubernetes CRDs — no Rego or separate language. Lower barrier to entry.
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

- Use Kyverno for: image registry restrictions, label requirements, resource limit enforcement, disabling privilege escalation, requiring non-root users.
- Kyverno CLI (`kyverno apply`) for testing policies against manifests in CI before cluster application.

### OPA Gatekeeper
- Open Policy Agent Gatekeeper uses **Rego** policy language. More powerful and flexible than Kyverno for complex policy logic.
- **ConstraintTemplate** defines the policy logic in Rego. **Constraint** applies it with parameters to specific resource kinds.
- Use OPA for complex policies requiring joins, data lookups, and multi-resource validation.
- Gatekeeper audit mode continuously checks existing resources against policies and reports violations without blocking.
- Use `ExternalData` provider to fetch external data during admission evaluation.
- Integration with Conftest for pre-admission testing in CI pipelines.
