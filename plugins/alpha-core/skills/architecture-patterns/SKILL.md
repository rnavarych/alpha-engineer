---
name: architecture-patterns
description: |
  Advises on software architecture: SOLID, DDD, CQRS, Event Sourcing, Clean/Hexagonal
  Architecture, microservices, Data Mesh, EDA, Service Mesh, micro-frontends, Cell-based
  architecture, Platform Engineering, Vertical Slice, Feature Sliced Design, Saga/Outbox.
  Use when making architectural decisions, evaluating design patterns, or refactoring systems.
allowed-tools: Read, Grep, Glob, Bash
---

You are a software architecture specialist. Make decisions explicit: state trade-offs, not just recommendations.

## SOLID Principles

- **S**: Single Responsibility — one reason to change per class/module; cohesion over cleverness
- **O**: Open/Closed — extend behavior without modifying existing code (strategy, decorator patterns)
- **L**: Liskov Substitution — subtypes must be substitutable for base types; honor contracts
- **I**: Interface Segregation — prefer small, focused interfaces over fat interfaces
- **D**: Dependency Inversion — depend on abstractions; inject dependencies; invert control

## Architectural Styles

### Modular Monolith
- **When**: Small-to-medium teams, early product, complex domain requiring transactional integrity
- **Structure**: Bounded contexts as modules within single deployable unit; enforced module boundaries
- **Pros**: Simple deployment, easy debugging, no network overhead, single ACID transaction
- **Cons**: Scaling bottlenecks (scale all-or-nothing), deployment coupling, potential module boundary erosion
- **Pattern**: Strict module APIs; no direct cross-module DB access; events for cross-module side effects
- **Tools**: ArchUnit (Java), dependency-cruiser (JS/TS), NDepend (.NET) for boundary enforcement

### Microservices
- **When**: Large teams, independent scaling needs, polyglot requirements, organizational scaling
- **Pros**: Independent deployment, team autonomy, fault isolation, technology heterogeneity
- **Cons**: Network complexity, distributed transactions, operational overhead, testing complexity
- **Team topology**: Align services to Conway's Law — one team per bounded context
- **Rule**: Start modular monolith; extract services when pain points emerge (scaling, team autonomy)
- **Anti-patterns**: Nano-services (too chatty), distributed monolith (tight coupling across services)

### Serverless
- **When**: Event-driven workloads, variable/spiky traffic, rapid prototyping, edge functions
- **Pros**: No server management, auto-scaling, pay-per-use, fast deployment
- **Cons**: Cold starts, vendor lock-in, debugging complexity, statelessness, execution time limits
- **Platforms**: Lambda, Cloud Functions, Durable Functions, Cloudflare Workers, Deno Deploy, Vercel Edge

### Cell-Based Architecture
- **When**: Global scale requiring blast radius control and independent failure domains
- **Pattern**: Divide infrastructure into isolated "cells" (e.g., per-region, per-tenant cluster)
  - Each cell is self-contained: compute, data store, messaging, cache
  - Router service directs traffic to appropriate cell
  - Cell failure is isolated: no cross-cell dependencies in request path
  - Cells are identical but independent (replicated, not shared)
- **Examples**: Amazon's cell-based deployment, Slack's sharding architecture
- **Benefits**: Predictable blast radius, independent deployments, regulatory data residency

## Domain-Driven Design (DDD)

### Strategic Design
- **Bounded Context**: Clear semantic boundary where a model applies consistently; map with Context Map
- **Ubiquitous Language**: Shared vocabulary between developers and domain experts; enforced in code
- **Domain Vision Statement**: One-paragraph description of the core domain's value proposition
- **Context Mapping Patterns**:
  - *Partnership*: Two teams collaborate, coordinate releases
  - *Shared Kernel*: Shared model subset, coordinated changes
  - *Customer-Supplier*: Downstream depends on upstream, upstream prioritizes downstream needs
  - *Conformist*: Downstream conforms to upstream model without negotiation
  - *Anti-Corruption Layer (ACL)*: Translation layer protects downstream from upstream model
  - *Open Host Service*: Upstream provides protocol for integration; many downstreams
  - *Published Language*: Well-documented shared language (e.g., industry standards)
  - *Separate Ways*: No integration; teams go their own way

### Tactical Design
- **Aggregate**: Cluster of domain objects with consistency boundary; only root is referenced externally
- **Entity**: Identity-based objects (User, Order); identity persists through state changes
- **Value Object**: Immutable, defined by attributes (Money, Address, Email); no identity
- **Domain Event**: Something significant that happened (OrderPlaced, PaymentReceived); past tense, immutable
- **Repository**: Abstraction for aggregate persistence; hides storage details from domain
- **Domain Service**: Stateless operations that don't naturally fit an entity or value object
- **Application Service**: Orchestrates use cases; thin layer; no business logic

### Domain Events
```typescript
// Domain event — immutable, past tense, carries enough context
class OrderPlaced {
  readonly occurredAt = new Date();
  constructor(
    readonly orderId: string,
    readonly customerId: string,
    readonly items: OrderItem[],
    readonly totalAmount: Money,
  ) {}
}

// Aggregate raises events; application layer dispatches
class Order {
  private events: DomainEvent[] = [];

  place(items: OrderItem[], payment: PaymentMethod): void {
    this.validate(items);
    this.status = 'placed';
    this.events.push(new OrderPlaced(this.id, this.customerId, items, this.total));
  }

  pullEvents(): DomainEvent[] {
    const events = [...this.events];
    this.events = [];
    return events;
  }
}
```

## CQRS (Command Query Responsibility Segregation)

- Separate write model (commands) from read model (queries)
- Commands: mutate state, validate invariants, raise domain events; no return data
- Queries: return data from optimized read model; no side effects
- Read model can be separate database, materialized view, or Elasticsearch index
- **With Event Sourcing**: Write side stores events; read side builds projections from events
- **Without Event Sourcing**: Write side stores current state; read model updated via domain events
- **When to use**: Significantly different read/write patterns; complex reporting; high read volume

### CQRS with Projections
```typescript
// Write side (command handler)
class PlaceOrderHandler {
  async handle(cmd: PlaceOrderCommand): Promise<void> {
    const order = Order.create(cmd);
    await this.orderRepo.save(order);
    for (const event of order.pullEvents()) {
      await this.eventBus.publish(event);
    }
  }
}

// Projection (read model updater)
class OrderSummaryProjection {
  async on(event: OrderPlaced): Promise<void> {
    await this.db.orderSummaries.upsert({
      id: event.orderId,
      customerName: await this.customerService.getName(event.customerId),
      itemCount: event.items.length,
      total: event.totalAmount.toString(),
      placedAt: event.occurredAt,
    });
  }
}
```

## Event Sourcing

- Store sequence of immutable events instead of current state
- Rebuild current state by replaying events from beginning (or from snapshot)
- Natural audit trail; temporal queries ("what did the order look like last Tuesday?")
- Event store: EventStoreDB, Axon Server, Kafka (with compaction), PostgreSQL events table
- Snapshots: periodically save current state to avoid replaying entire history
- Complexity: eventual consistency, event versioning/upcasting, snapshot strategy
- **Upcasting**: Transform old event versions to current format; never mutate stored events

## Event-Driven Architecture (EDA)

### Event Types
- **Domain Events**: Business-significant (OrderPlaced, PaymentReceived) — trigger workflows
- **Integration Events**: Cross-service communication; translated from domain events at boundaries
- **CDC (Change Data Capture)**: Database-level change streaming (Debezium, DynamoDB Streams)
- **External Events**: Inbound from third parties (Stripe webhook, AWS EventBridge partner events)

### Event Schema Evolution
- Forward-compatible: add optional fields; consumers ignore unknown fields
- Backward-compatible: don't remove fields; use default values for old consumers
- Schema registry: Confluent Schema Registry, AWS Glue Schema Registry — enforce compatibility
- Versioning: include event version in envelope; use upcasters to transform old versions

### Event Storming
A collaborative workshop technique to discover domain events:
1. **Domain Events** (orange): What happened? Past tense. "Order Placed", "Payment Failed"
2. **Commands** (blue): What triggered the event? "Place Order", "Process Payment"
3. **Aggregates** (yellow): What handles the command? "Order", "Payment"
4. **Policies** (purple): Reactive logic. "When Payment Received, Then Ship Order"
5. **External Systems** (pink): Third parties. "Stripe", "Warehouse System"
6. **Read Models** (green): What data does the UI need?
7. **Hotspots** (red): Unresolved questions, complexity, disagreements

## Clean Architecture / Hexagonal Architecture

```
[External Systems] ←→ [Adapters/Ports] ←→ [Application/Use Cases] ←→ [Domain/Entities]
     (HTTP, DB)           (Controllers,           (Orchestration,          (Business rules,
                           Repositories)           Validation)              No dependencies)
```

- **Dependency Rule**: Source code dependencies point only inward (toward domain)
- **Domain layer**: Entities, value objects, domain events, domain services — zero dependencies
- **Application layer**: Use cases, application services, ports (interfaces) — depends only on domain
- **Adapters layer**: HTTP controllers, repository implementations, message consumers — depends on application
- **Frameworks layer**: Spring, Express, SQLAlchemy, Kafka client — outer ring, plug-and-play
- Test domain and application layers in isolation (no real DB, no HTTP); adapters tested separately

## Service Mesh

Infrastructure layer that handles service-to-service communication concerns transparently.

### Istio
- **Traffic Management**: VirtualService (routing rules), DestinationRule (circuit breaking, load balancing)
- **Security**: Automatic mTLS between pods, PeerAuthentication policy, AuthorizationPolicy
- **Observability**: Automatic telemetry (metrics, traces, access logs) via Envoy sidecar
- **Canary Releases**: Weight-based routing via VirtualService (10% → new version)
- **Fault Injection**: Inject delays/errors for chaos testing via VirtualService

### Linkerd
- **Lightweight**: Rust-based data plane (ultralight, low latency), simple installation
- **Automatic mTLS**: Zero-config mTLS, certificate rotation via trust anchor
- **Traffic splitting**: HTTPRoute for canary, A/B, blue-green
- **Multi-cluster**: Pod-to-pod communication across clusters via service mirroring

### Cilium (eBPF-based)
- **Performance**: Kernel-level networking (eBPF); replaces kube-proxy; no sidecar overhead
- **Network policies**: L3/L4/L7 policies; DNS-aware policies; cluster-wide enforcement
- **Hubble**: Network observability built into Cilium; service map, flow visibility
- **Mutual authentication**: WireGuard-based encryption between nodes

## Micro-Frontends

Decompose frontend by business domain; independent deployment per domain.

### Integration Approaches

**Build-time (npm packages)**
- Share components via private npm registry
- Tight coupling at build time; teams must coordinate releases
- Good for: shared design system components (not full micro-frontends)

**Run-time (Module Federation — Webpack 5)**
```javascript
// Host app webpack config
new ModuleFederationPlugin({
  remotes: {
    catalogApp: 'catalogApp@https://catalog.example.com/remoteEntry.js',
    cartApp: 'cartApp@https://cart.example.com/remoteEntry.js',
  },
  shared: ['react', 'react-dom'],
});

// Remote app exposes components
new ModuleFederationPlugin({
  name: 'catalogApp',
  filename: 'remoteEntry.js',
  exposes: { './ProductList': './src/ProductList', './ProductDetail': './src/ProductDetail' },
});
```

**Run-time (Single-SPA)**
- Application router coordinates which micro-frontends are mounted when
- Lifecycle hooks: bootstrap, mount, unmount
- Framework-agnostic: React, Vue, Angular, plain JS apps coexist

**Server-side Composition (Edge-side Includes / Next.js Parallel Routes)**
- Compose HTML fragments at edge or server (Zalando Tailor, nginx SSI)
- No JavaScript bundle sharing complexity
- Best for: SEO-critical, server-rendered applications

**iframe-based**
- Strong isolation: no CSS/JS leakage between apps
- Communication via postMessage
- UX limitations: scroll, deep linking, accessibility challenges

**Web Components**
- Standard browser custom elements; framework-independent
- Shadow DOM for style isolation
- Stencil.js, Lit for authoring; useful for leaf components, not full apps

## Platform Engineering

Internal Developer Platform (IDP) to improve developer experience and reduce cognitive load.

### Core Capabilities
- **Self-service infrastructure**: Provision dev/staging environments via UI/CLI (no ticket required)
- **Golden paths**: Opinionated templates for new services (with security, observability, CI/CD built in)
- **Service catalog**: Backstage, Port, Cortex — discover services, owners, runbooks, SLOs
- **Internal developer portal**: Single pane: deploy, monitor, manage secrets, view logs
- **Paved road**: Preferred patterns with escape hatches for exceptional cases

### Backstage (CNCF)
- **Software catalog**: All services, APIs, pipelines, docs in one searchable registry
- **TechDocs**: Docs-as-code (MkDocs) rendered in Backstage
- **Scaffolder**: Self-service templates to create new services with best practices baked in
- **Plugins**: 200+ community plugins (Kubernetes, Argo CD, PagerDuty, SonarQube, GitHub Actions)

## Vertical Slice Architecture

Organize code by feature (vertical slices) rather than technical layers (horizontal layers).

```
Traditional (horizontal):        Vertical Slice:
├── controllers/                 ├── features/
│   ├── UserController           │   ├── CreateUser/
│   └── OrderController          │   │   ├── CreateUserCommand.cs
├── services/                    │   │   ├── CreateUserHandler.cs
│   ├── UserService              │   │   ├── CreateUserValidator.cs
│   └── OrderService             │   │   └── CreateUserEndpoint.cs
└── repositories/                │   └── GetOrderHistory/
    ├── UserRepository                   ├── GetOrderHistoryQuery.cs
    └── OrderRepository                  ├── GetOrderHistoryHandler.cs
                                         └── GetOrderHistoryEndpoint.cs
```
- Each feature is a cohesive unit: request, handler, response, validation, tests
- Minimal coupling between features; each can evolve independently
- Feature teams own full slices end-to-end
- Popular in .NET with MediatR + Carter; also common in Go and Node.js

## Feature Sliced Design (FSD)

Frontend architecture methodology for large-scale applications.

```
src/
├── app/          # App initialization, providers, routing, global styles
├── pages/        # Page-level compositions; thin — delegate to widgets/features
├── widgets/      # Composite UI blocks (Header, Sidebar, ProductCard with actions)
├── features/     # User interactions with business value (AddToCart, UserLogin, SearchBar)
├── entities/     # Business domain models/UI (User, Product, Order — schema + basic UI)
└── shared/       # Reusable infrastructure (UI kit, API client, utils, config, i18n)
```
- Strict import rule: layer can only import from layers below it (no circular deps)
- Each layer has slices (domain concepts); slices have segments (ui, model, api, lib)
- Enforced by eslint-plugin-boundaries or @feature-sliced/eslint-config

## Design Patterns for Architecture

### Outbox Pattern (Reliable Event Publishing)
```sql
-- Application writes to DB and outbox in same transaction
BEGIN;
  INSERT INTO orders (id, status) VALUES ('ord_123', 'placed');
  INSERT INTO outbox (id, aggregate_type, aggregate_id, event_type, payload)
    VALUES (gen_random_uuid(), 'Order', 'ord_123', 'OrderPlaced', '{"..."}');
COMMIT;

-- Outbox poller (separate process) reads and publishes events
-- Debezium: CDC from outbox table to Kafka (at-least-once delivery)
-- Polling: SELECT * FROM outbox WHERE published = false LIMIT 100
```

### Strangler Fig Pattern (Legacy Migration)
1. Put a proxy/facade in front of the legacy system
2. Implement new capability in new system; route specific calls to new system
3. Gradually migrate endpoints from legacy to new
4. When all traffic migrated, decommission legacy system
- Use feature flags to switch traffic between old and new implementations
- Event interception: intercept events from legacy system to populate new system's data store

### Anti-Corruption Layer (ACL)
- Translation layer between your bounded context and external/legacy systems
- External model changes are absorbed in ACL; your domain model stays clean
- Implement as Adapter + Translator: convert external DTOs to your domain objects

### Sidecar Pattern
- Deploy helper containers alongside main container in same pod (Kubernetes)
- Use cases: logging agent, proxy (Envoy), secret rotation, config sync, TLS termination
- Service mesh data plane is the canonical sidecar example

### Ambassador Pattern
- Sidecar acts as outbound proxy for the main container
- Handles: retry, circuit breaking, routing, service discovery, distributed tracing
- Main application connects to localhost; ambassador handles remote communication

### Saga Pattern

**Choreography Saga**
- Services emit events; other services react with their own events
- No central coordinator; fully decentralized
- Hard to track overall state; debugging complex failure scenarios is difficult
- Best for: simple linear workflows with few services

**Orchestration Saga**
- Saga orchestrator (process manager) coordinates steps via commands
- Clear transaction flow; easy to monitor state; compensations managed centrally
- Orchestrator = potential single point of complexity (not failure if stateless + persisted)
- Best for: complex multi-step workflows; workflows requiring human approval steps

**Compensation**
```typescript
// Each step has a compensating action (semantically undo)
const bookingWorkflow: SagaStep[] = [
  {
    execute: () => reserveInventory(orderId, items),
    compensate: () => releaseInventory(orderId, items),
  },
  {
    execute: () => chargePayment(orderId, amount),
    compensate: () => refundPayment(orderId, amount),
  },
  {
    execute: () => scheduleShipment(orderId),
    compensate: () => cancelShipment(orderId),
  },
];
```

### Circuit Breaker States
- **Closed**: Normal operation; requests pass through; failure counter tracks errors
- **Open**: Failure threshold exceeded (e.g., >50% failure rate in 60s); requests fail immediately with fallback
- **Half-Open**: After timeout, allow limited test requests; success → Closed; failure → Open
- Libraries: Resilience4j (Java), Polly (.NET), opossum (Node.js), go-circuit (Go)

### Bulkhead Pattern
- Isolate failures to prevent cascade across the system
- Thread pool bulkhead: separate thread pools per downstream service (CPU-bound)
- Semaphore bulkhead: limit concurrent calls per dependency (I/O-bound)
- Container resource limits as bulkhead: CPU/memory limits prevent one service starving others

## Data Mesh

Decentralized data architecture treating data as a product owned by domain teams.

### Four Principles
1. **Domain Ownership**: Data produced by a domain is owned, published, and maintained by that domain team
2. **Data as a Product**: Each domain exposes data products with discoverability, quality SLAs, documentation
3. **Self-Serve Data Platform**: Infrastructure platform enables domain teams to build/publish data products without specialist help
4. **Federated Computational Governance**: Global policies (privacy, compliance, interoperability) enforced at platform level; local autonomy otherwise

For detailed patterns, see [reference-patterns.md](reference-patterns.md).
