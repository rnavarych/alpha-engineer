# Requirements Analysis and Diagrams

## When to load
Load when analyzing functional/non-functional requirements, drawing system context diagrams, container diagrams, sequence diagrams, or data flow diagrams for a new or evolving system.

## Requirements Analysis

### Functional Requirements
- Enumerate all user-facing capabilities the system must provide. Express each as a user story or use case with clear acceptance criteria.
- Identify core vs. ancillary features. Core features define the system's reason for existence; ancillary features can be deferred or simplified.
- Map requirements to system boundaries. Each requirement should trace to exactly one owning service or module.

### Non-Functional Requirements
- Define explicit targets for each quality attribute:
  - **Availability**: Target SLA (e.g., 99.9% = 8.76 hours downtime/year). Identify which components are on the critical path.
  - **Latency**: P50, P95, P99 targets per endpoint or user flow. Distinguish between interactive (< 200ms) and background (< 5s) operations.
  - **Throughput**: Expected QPS at launch, at 6 months, at 2 years. Identify peak multipliers (e.g., 3x during promotions).
  - **Durability**: Data loss tolerance. RPO and RTO for disaster recovery.
  - **Consistency**: Strong vs. eventual. Per-feature, not system-wide. Financial transactions need strong; activity feeds can be eventual.
  - **Security**: Authentication method, authorization model, encryption requirements, compliance constraints.
- Rank non-functional requirements by priority. When they conflict (e.g., consistency vs. latency), the ranking determines which wins.

## C4 Model Diagrams

### Level 1: System Context
- Show the system as a single box surrounded by its users (personas) and external systems it interacts with.
- Label every arrow with the interaction type and protocol (e.g., "Places orders via HTTPS/REST").
- Include both human actors and automated systems (payment gateways, email providers, third-party APIs).
- Use Mermaid C4 syntax for embedding in ADRs:
  ```
  C4Context
    Person(user, "User", "A customer of the system")
    System(system, "System Name", "Provides X capability")
    System_Ext(ext, "External System", "Sends events")
    Rel(user, system, "Uses", "HTTPS")
    Rel(system, ext, "Calls", "REST/JSON")
  ```

### Level 2: Container Diagram
- Decompose the system into containers: web apps, APIs, databases, message brokers, caches, file storage.
- Show technology choices on each container (e.g., "API Server — Node.js / Express").
- Draw communication paths with protocols and data formats (REST/JSON, gRPC/Protobuf, AMQP).
- Every container should have a clearly stated responsibility boundary. Containers that do too many things indicate a missing decomposition.

### Level 3: Component Diagram
- For each container that warrants deeper exploration, show its internal components (modules, services, controllers, repositories).
- Map responsibilities to components. Each component should have a single, clear purpose.
- Show dependencies between components and highlight interfaces/contracts.

### Level 4: Code Diagram
- Use sparingly. Only for critical or complex components where the internal class/function structure is non-obvious.
- Show key classes, interfaces, and their relationships. Align with the actual code structure.

## Sequence Diagrams
- Create sequence diagrams for every critical user flow and every flow that crosses more than two system boundaries.
- Show the happy path first, then add alt/opt frames for error cases and edge conditions.
- Include timing annotations for steps with SLA implications (database queries, external API calls).
- Label messages with both the logical action and the technical mechanism (e.g., "Create Order — POST /api/orders").

## Data Flow Diagrams
- Map how data enters, transforms, and exits the system. Identify every data source and sink.
- Mark trust boundaries explicitly. Data crossing a trust boundary must be validated, sanitized, or encrypted.
- Identify data at rest and data in transit. Annotate encryption requirements for each.
- Show data retention policies and archival flows for compliance-sensitive data.

## Trade-off Documentation
- For every significant design choice, document at least two alternatives side by side.
- Evaluate each alternative against explicit criteria: cost, complexity, latency, scalability, operational burden, team familiarity, and time-to-market.
- Use a decision matrix with weighted scores when multiple stakeholders are involved.
- Record which trade-off was accepted and why. Link to the corresponding ADR.

## Capacity Estimation
- Start with user-facing metrics: DAU, peak concurrent users, average session length, actions per session.
- Derive system-level metrics: QPS = DAU x actions_per_session / seconds_per_day. Apply peak multiplier (typically 2x-5x average).
- Estimate storage: record size x records_per_day x retention_period. Account for indexes, replicas, and backups.
- Estimate bandwidth: average_response_size x QPS. Include both ingress and egress.
- Size infrastructure: CPU cores, memory, disk IOPS. Add 30-50% headroom for unexpected spikes.
