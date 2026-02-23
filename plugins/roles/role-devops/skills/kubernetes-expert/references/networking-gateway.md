# Kubernetes Networking and Gateway API

## When to load
Load when configuring Services, NetworkPolicies, Gateway API resources (HTTPRoute, GatewayClass),
or migrating away from Ingress to the Gateway API model.

## Services

- **ClusterIP** (default) for internal service-to-service communication. Use DNS names (`service.namespace.svc.cluster.local`). Short form `service.namespace` works within the cluster.
- **NodePort** for development or when an external load balancer is unavailable. Avoid in production.
- **LoadBalancer** to provision cloud load balancers automatically. Annotate for internal-only LBs where needed. Use `service.beta.kubernetes.io/aws-load-balancer-type: nlb-ip` for NLB target groups in EKS.
- **Headless services** (`clusterIP: None`) for StatefulSets that need direct pod addressing. Enables DNS-based service discovery for each pod (`pod-0.service.namespace.svc.cluster.local`).
- Apply **NetworkPolicies** to restrict pod-to-pod traffic. Default-deny ingress per namespace, then whitelist required paths. Use `podSelector: {}` for namespace-wide policies.

## Gateway API (Replacing Ingress)

The Kubernetes Gateway API is the evolution beyond Ingress, providing richer routing semantics, multi-tenancy, and a portable API across implementations.

### Core Resources
- **GatewayClass** — Cluster-scoped resource that identifies a controller (e.g., `nginx`, `cilium`, `istio`, `envoy-gateway`). Managed by infrastructure team.
- **Gateway** — Namespace-scoped resource that requests a particular class and defines listeners (ports, protocols, TLS). Managed by platform team.
- **HTTPRoute** — Namespace-scoped route that attaches to a Gateway and defines path/header/method matching rules. Managed by application teams.
- **GRPCRoute**, **TCPRoute**, **TLSRoute**, **UDPRoute** — Protocol-specific route types for non-HTTP traffic.

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

## Namespace Management

- One namespace per team or per application component. Use namespace labels for NetworkPolicy selectors and Kyverno policy matching.
- Namespace lifecycle management: provision via GitOps (Flux HelmRelease or Kustomize), deprovision with validation (check for running workloads, PVCs, non-empty secrets).
- Use `kubectl label namespace` for Istio/Cilium mesh enrollment, Kyverno policy targeting, and network isolation grouping.
- Implement namespace-scoped RBAC: give teams admin access to their namespace, not cluster-admin.
- Use hierarchical namespaces (HNC) for multi-level namespace trees: organization -> team -> environment namespace hierarchies.
