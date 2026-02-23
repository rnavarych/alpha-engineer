# Network Segmentation for PCI

## When to load
Load when isolating cardholder data environment, configuring firewalls, micro-segmentation.

## CDE Isolation

```
CDE (Cardholder Data Environment): systems that store, process, or transmit card data.

Principle: Minimize what's in the CDE. Everything in the CDE must be PCI compliant.

Network zones:
  Internet ─→ DMZ ─→ Application Zone ─→ CDE ─→ Database Zone
                         │
                         └─→ Internal (out of scope)

Firewall rules:
  - Default deny all
  - Allow only specific ports and protocols
  - No direct internet access to CDE
  - CDE → Internet: only for payment processor APIs
```

## AWS Architecture

```
VPC: 10.0.0.0/16
├── Public Subnet (DMZ):        10.0.1.0/24
│   └── ALB (terminates TLS)
├── Private Subnet (App):       10.0.2.0/24
│   └── ECS Tasks (application logic)
├── Private Subnet (CDE):       10.0.3.0/24
│   └── Payment service (only component touching card data)
└── Private Subnet (Data):      10.0.4.0/24
    └── RDS (encrypted at rest)

Security groups:
  ALB: 443 from 0.0.0.0/0
  App: 3000 from ALB only
  CDE: 3000 from App only, 443 to payment processor
  RDS: 5432 from CDE only
```

## Kubernetes Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-service-isolation
  namespace: cde
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes: [Ingress, Egress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels: { zone: application }
          podSelector:
            matchLabels: { app: order-service }
      ports: [{ port: 3000, protocol: TCP }]
  egress:
    - to:
        - ipBlock: { cidr: 10.0.4.0/24 }  # Database
      ports: [{ port: 5432 }]
    - to:
        - ipBlock: { cidr: 0.0.0.0/0 }    # Payment processor
      ports: [{ port: 443 }]
```

## Anti-patterns
- Flat network with no segmentation → everything is in PCI scope
- Application servers with direct DB access to CDE → scope creep
- Shared logging/monitoring infra with CDE → pulls monitoring into scope
- VPN from developer laptops to CDE → laptops become PCI scope

## Quick reference
```
CDE: minimize — only systems that touch card data
Zones: DMZ → App → CDE → Data, each with firewall rules
Default deny: whitelist only required connections
CDE egress: only to payment processor + database
No direct internet → CDE
Network policies: Kubernetes labels for pod-level isolation
Scope reduction: tokenize to keep payment processing out of CDE
Audit: log all connections in/out of CDE
```
