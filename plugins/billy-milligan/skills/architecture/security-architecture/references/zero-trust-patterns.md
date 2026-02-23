# Zero Trust Architecture Patterns

## When to load
Load when discussing service mesh security, mTLS between services, SPIFFE/SPIRE identity, network policies, or zero trust principles.

## Patterns

### Core principle: never trust, always verify
```
Traditional: trust everything inside the network perimeter
Zero Trust: verify every request regardless of source location

Every request must prove:
1. Identity (who are you?) - mTLS certificate, JWT, service account
2. Authorization (can you do this?) - policy check per request
3. Integrity (is the request tampered?) - signed payload, TLS
```

### mTLS between services
```yaml
# Istio mTLS configuration (automatic in service mesh)
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  # all traffic must be mTLS

---
# Authorization policy: only order-service can call payment-service
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: payment-service-policy
  namespace: production
spec:
  selector:
    matchLabels:
      app: payment-service
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/production/sa/order-service"]
      to:
        - operation:
            methods: ["POST"]
            paths: ["/api/v1/charges"]
```

### SPIFFE/SPIRE identity
```
SPIFFE: Secure Production Identity Framework for Everyone
SPIRE: SPIFFE Runtime Environment (reference implementation)

Identity format: spiffe://trust-domain/path
Example: spiffe://example.com/ns/production/sa/payment-service

How it works:
1. SPIRE Server issues SVIDs (SPIFFE Verifiable Identity Documents)
2. SPIRE Agent runs on each node, attests workload identity
3. Workloads get X.509 certificates or JWT-SVIDs
4. Certificates auto-rotate (default: 1 hour TTL)
5. No shared secrets, no static credentials
```

```yaml
# SPIRE registration entry
# Workload identity bound to Kubernetes service account
spire-server entry create \
  -spiffeID spiffe://example.com/ns/production/sa/order-service \
  -parentID spiffe://example.com/k8s-node \
  -selector k8s:ns:production \
  -selector k8s:sa:order-service
```

### Network policies (Kubernetes)
```yaml
# Default deny all ingress and egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress

---
# Allow specific traffic: order-service -> payment-service on port 8443
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-order-to-payment
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: order-service
      ports:
        - protocol: TCP
          port: 8443

---
# Allow DNS egress (required for service discovery)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to: []
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### Service-to-service authentication without mesh
```typescript
// For environments without service mesh: JWT-based service auth
// Each service has a signing key, tokens are short-lived

function createServiceToken(sourceService: string, targetService: string): string {
  return jwt.sign(
    {
      iss: sourceService,
      aud: targetService,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 60,  // 1 minute TTL
      jti: crypto.randomUUID(),
    },
    servicePrivateKey,
    { algorithm: 'RS256' }
  );
}

// Receiving service validates:
// 1. Signature valid (using sender's public key)
// 2. aud matches this service
// 3. exp not passed
// 4. jti not seen before (replay protection, Redis set with 2min TTL)
```

### No implicit trust checklist
```
Network level:
- [ ] Default deny network policies in place
- [ ] mTLS enforced for all service-to-service communication
- [ ] No services exposed without authentication

Identity level:
- [ ] Every service has a unique identity (SPIFFE or service account)
- [ ] Credentials rotate automatically (certificates: 1hr, tokens: 15min)
- [ ] No shared credentials between services

Authorization level:
- [ ] Per-request authorization checks (not just at the perimeter)
- [ ] Least privilege: services can only call what they need
- [ ] Authorization policies are declarative and auditable

Data level:
- [ ] Encryption in transit (TLS 1.2+ everywhere)
- [ ] Encryption at rest for sensitive data
- [ ] Data classification determines access controls
```

## Anti-patterns
- mTLS with long-lived certificates (>24hr) -> auto-rotate with short TTL
- Network policies without default deny -> new services are open by default
- Service mesh without authorization policies -> mTLS alone only proves identity, not permission
- Trusting requests from internal IPs -> compromised service can access everything

## Decision criteria
- **Service mesh (Istio/Linkerd)**: >10 services, need automatic mTLS, traffic management, observability
- **SPIFFE/SPIRE without mesh**: need identity framework, already have load balancing, lighter weight
- **JWT service-to-service**: few services, no mesh, simple setup, acceptable token validation overhead
- **Network policies alone**: minimum viable zero trust, must combine with application-level auth

## Quick reference
```
Zero trust: verify identity + authorization on every request
mTLS: mutual certificate verification, auto-rotate <24hr
SPIFFE ID: spiffe://domain/ns/namespace/sa/service-name
Network policy: default deny, explicitly allow required paths
Service mesh: Istio (feature-rich) or Linkerd (lightweight)
Certificate TTL: 1 hour (SPIRE default), max 24 hours
No shared secrets between services - ever
Defense in depth: network + identity + authorization + encryption
```
