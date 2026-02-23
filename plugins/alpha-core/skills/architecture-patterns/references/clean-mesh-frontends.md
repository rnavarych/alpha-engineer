# Clean Architecture, Service Mesh, Micro-Frontends, and Platform Engineering

## When to load
Load when implementing Clean/Hexagonal Architecture, choosing a service mesh (Istio, Linkerd, Cilium), designing micro-frontends, or setting up an Internal Developer Platform with Backstage.

## Clean Architecture / Hexagonal Architecture

```
[External Systems] ←→ [Adapters/Ports] ←→ [Application/Use Cases] ←→ [Domain/Entities]
     (HTTP, DB)           (Controllers,           (Orchestration,          (Business rules,
                           Repositories)           Validation)              No dependencies)
```

- **Dependency Rule**: Source code dependencies point only inward (toward domain)
- **Domain layer**: Entities, value objects, domain events, domain services — zero dependencies
- **Application layer**: Use cases, ports (interfaces) — depends only on domain
- **Adapters layer**: HTTP controllers, repository implementations, message consumers
- Test domain and application layers in isolation (no real DB, no HTTP)

## Service Mesh

### Istio
- **Traffic Management**: VirtualService (routing rules), DestinationRule (circuit breaking, load balancing)
- **Security**: Automatic mTLS between pods, PeerAuthentication, AuthorizationPolicy
- **Canary Releases**: Weight-based routing via VirtualService (10% → new version)
- **Fault Injection**: Inject delays/errors for chaos testing via VirtualService

### Linkerd
- **Lightweight**: Rust-based data plane, simple installation, low latency overhead
- **Automatic mTLS**: Zero-config mTLS, certificate rotation via trust anchor
- **Traffic splitting**: HTTPRoute for canary, A/B, blue-green; multi-cluster via service mirroring

### Cilium (eBPF-based)
- **Performance**: Kernel-level networking (eBPF); replaces kube-proxy; no sidecar overhead
- **Network policies**: L3/L4/L7 policies; DNS-aware; cluster-wide enforcement
- **Hubble**: Network observability built into Cilium; service map, flow visibility

## Micro-Frontends

### Integration Approaches

**Module Federation (Webpack 5) — Run-time**
```javascript
// Host app
new ModuleFederationPlugin({
  remotes: { catalogApp: 'catalogApp@https://catalog.example.com/remoteEntry.js' },
  shared: ['react', 'react-dom'],
});
// Remote app
new ModuleFederationPlugin({
  name: 'catalogApp', filename: 'remoteEntry.js',
  exposes: { './ProductList': './src/ProductList' },
});
```

**Single-SPA** — framework-agnostic router; React, Vue, Angular, plain JS coexist; lifecycle hooks: bootstrap, mount, unmount

**Server-side Composition** — Compose HTML fragments at edge (Zalando Tailor, nginx SSI); best for SEO-critical applications

**Web Components** — Standard browser custom elements; Shadow DOM for style isolation; Stencil.js, Lit for authoring

## Platform Engineering / Internal Developer Platform

### Core Capabilities
- **Self-service infrastructure**: Provision dev/staging environments via UI/CLI (no ticket required)
- **Golden paths**: Opinionated templates for new services (security, observability, CI/CD built in)
- **Service catalog**: Backstage, Port, Cortex — discover services, owners, runbooks, SLOs
- **Paved road**: Preferred patterns with escape hatches for exceptional cases

### Backstage (CNCF)
- **Software catalog**: All services, APIs, pipelines, docs in one searchable registry
- **TechDocs**: Docs-as-code (MkDocs) rendered in Backstage
- **Scaffolder**: Self-service templates to create new services with best practices baked in
- **Plugins**: 200+ community plugins (Kubernetes, Argo CD, PagerDuty, SonarQube, GitHub Actions)

## Vertical Slice Architecture

```
features/
├── CreateUser/
│   ├── CreateUserCommand.cs
│   ├── CreateUserHandler.cs
│   ├── CreateUserValidator.cs
│   └── CreateUserEndpoint.cs
└── GetOrderHistory/
    ├── GetOrderHistoryQuery.cs
    └── GetOrderHistoryHandler.cs
```
Each feature is a cohesive unit: request, handler, response, validation, tests. Popular in .NET with MediatR + Carter.

## Feature Sliced Design (FSD)

```
src/
├── app/      # Initialization, providers, routing, global styles
├── pages/    # Page-level compositions; thin — delegate to widgets/features
├── widgets/  # Composite UI blocks (Header, Sidebar, ProductCard)
├── features/ # User interactions with business value (AddToCart, UserLogin)
├── entities/ # Business domain models/UI (User, Product, Order)
└── shared/   # Reusable infrastructure (UI kit, API client, utils)
```
Strict import rule: layer can only import from layers below (no circular deps). Enforced by `eslint-plugin-boundaries`.
