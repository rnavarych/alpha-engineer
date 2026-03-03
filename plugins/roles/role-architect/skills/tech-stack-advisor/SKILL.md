---
name: role-architect:tech-stack-advisor
description: |
  Tech stack evaluation expertise including comparison matrices, TCO analysis,
  team capability assessment, ecosystem maturity evaluation, migration paths,
  build vs buy decisions, and vendor lock-in assessment.
allowed-tools: Read, Grep, Glob, Bash
---

# Tech Stack Advisor

## Comparison Matrices

### Language Comparison
- Evaluate languages against project-specific criteria: performance requirements, type safety, ecosystem maturity, team proficiency, and hiring pool availability.
- Core dimensions: runtime performance (throughput, latency, memory), developer productivity (compile times, tooling, debugging), concurrency model (threads, async/await, actors), and deployment footprint (binary size, container image size, cold start time).
- Document the comparison in a matrix with weighted scores. Share weights with stakeholders before scoring to avoid bias toward a predetermined conclusion.

### Framework Comparison
- Assess frameworks on: learning curve, documentation quality, community activity (GitHub stars are vanity; recent commits and issue response times are substance), upgrade path stability, and production references at comparable scale.
- Test framework candidates with a representative spike (2-3 days). Focus on: how the framework handles the project's hardest problem (not its simplest CRUD operation).
- Avoid framework lock-in by isolating business logic from framework code. Use ports-and-adapters (hexagonal) architecture.

### Database Comparison
- Match database type to access patterns: relational for complex joins and transactions, document for flexible schemas and nested data, key-value for high-throughput simple lookups, time-series for metric and event data, graph for relationship-heavy queries.
- Evaluate: consistency model (strong vs. eventual), scaling mechanism (vertical, sharding, replication), operational complexity (managed vs. self-hosted), backup/restore capabilities, and cost at projected data volumes.

### Infrastructure Comparison
- Compare cloud providers (AWS, GCP, Azure) and self-hosted options on: service breadth, pricing model, compliance certifications, geographic availability, and existing team expertise.
- For specific services (e.g., managed Kubernetes, serverless functions, managed databases), compare on: feature parity, pricing, SLA guarantees, and migration effort.

## TCO Analysis

- Total Cost of Ownership includes all costs over the analysis period (typically 3-5 years):
  - **License costs**: Per-seat, per-core, per-instance, or usage-based. Include annual increases.
  - **Infrastructure costs**: Compute, storage, network, CDN, DNS, monitoring, logging.
  - **Operational costs**: On-call burden (hours x engineer cost), incident frequency, patching cadence, upgrade effort.
  - **Training costs**: Onboarding new team members, certification programs, conference attendance.
  - **Opportunity cost**: Time spent on operational work instead of feature development.
- Present TCO as a range (optimistic, expected, pessimistic), not a single number. State assumptions explicitly.

## Team Capability Assessment

- Audit the current team's skills against the proposed stack. Use a skill matrix: list each technology and rate team members on a scale (learning, proficient, expert).
- Identify skill gaps. For each gap, evaluate: can we train existing members (timeline and cost), do we need to hire (availability and compensation), or should we choose a more familiar technology?
- Consider the bus factor. If only one person knows a critical technology, that is a risk regardless of how good the technology is.
- Factor in team growth plans. A technology that is easy to hire for (JavaScript, Python, Go) may be preferable to a technically superior but niche option (Erlang, Haskell).

## Ecosystem Maturity

### Community Health
- Measure by: number of active contributors (not total), issue/PR response time, release cadence, and presence of a governance model or sponsoring organization.
- Check for corporate backing or foundation support. Projects with a single maintainer are a risk for production-critical dependencies.

### Library Ecosystem
- Evaluate the availability and quality of libraries for common needs: HTTP clients, ORMs, authentication, logging, testing, and monitoring.
- Prefer ecosystems where essential libraries are stable and well-maintained over ecosystems where you must build everything from scratch.

### Hiring Pool
- Check job posting volumes and candidate availability on major platforms for the technology.
- Consider geographic constraints. Some technologies have strong communities in specific regions.
- Factor in compensation expectations. Niche technology specialists often command premium salaries.

## Migration Paths

- Before adopting a technology, plan the exit. What does it take to migrate away if the choice proves wrong?
- Evaluate migration cost along three dimensions: data (can you export?), code (how coupled is your logic to the framework/platform?), and operations (can you run both systems in parallel during migration?).
- Prefer technologies with open standards and data portability (e.g., PostgreSQL over a proprietary database, Kubernetes over a vendor-specific orchestrator).

## Build vs. Buy Decisions

- **Build when**: the capability is a core differentiator, off-the-shelf products do not fit your requirements without heavy customization, or the buy option creates unacceptable vendor dependency.
- **Buy when**: the capability is commodity (authentication, email delivery, payment processing), the vendor has a strong track record, and the integration cost is lower than the build and maintenance cost.
- Quantify both options over 3 years: build cost (dev hours x rate + ongoing maintenance) vs. buy cost (license + integration + operational overhead).
- Consider the hidden costs of building: security patching, compliance certification, documentation, and on-call support for a homegrown system.

## Vendor Lock-in Assessment

- Categorize lock-in risk by layer: infrastructure (cloud provider), platform (managed services), application (proprietary APIs), and data (proprietary formats).
- For each layer, identify the switching cost: code changes, data migration effort, retraining, and downtime.
- Mitigate lock-in with abstraction layers, but only where the abstraction does not sacrifice the primary benefit of the vendor service.
- Accept lock-in deliberately when the vendor's capability significantly exceeds what you can build or operate, and document the decision in an ADR.
