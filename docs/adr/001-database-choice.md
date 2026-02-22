# ADR-001: Database Choice

## Status
ACCEPTED

## Date
2025-02-19

## Context
The project requires a primary database for a B2B SaaS dashboard. Key requirements:
- Relational data model (users, organizations, subscriptions, dashboard metrics)
- ACID transactions for billing and subscription state changes
- Future vector search capability for potential AI features
- Operational simplicity for a small team without dedicated DBA

## Options Considered

### Option A: PostgreSQL
- **Pros:** Mature, reliable, ACID compliant, rich ecosystem, pgvector extension for future vector search, excellent JSON support for semi-structured data, strong community and tooling
- **Cons:** Vertical scaling primarily (Citus for horizontal), requires schema discipline

### Option B: MongoDB
- **Pros:** Flexible schema, horizontal scaling built-in, document model suits some use cases
- **Cons:** Weaker ACID guarantees, previous project experience revealed operational complexity at scale, schema flexibility becomes a liability without strict discipline

### Option C: MySQL / MariaDB
- **Pros:** Widely supported, fast for read-heavy workloads, well-understood operations
- **Cons:** Less capable JSON support, no vector extension, weaker extensibility than PostgreSQL

## Decision
**Option A: PostgreSQL 16 with pgvector extension.**

## Rationale
- The data model is fundamentally relational: users belong to organizations, subscriptions are associated with billing events, dashboard metrics have foreign key relationships
- ACID compliance is non-negotiable for billing and subscription state transitions
- pgvector provides a forward-looking capability for AI-driven features without adding infrastructure
- PostgreSQL's operational characteristics are well-understood by the team; no additional database expertise required
- JSON column support handles any semi-structured data without requiring a separate document store

## Consequences
- All data access goes through PostgreSQL — no polyglot persistence complexity
- Horizontal write scaling requires Citus or architectural changes if write throughput becomes a bottleneck
- Team must maintain schema discipline; migrations are a first-class concern
- Vector search capability available without adding a dedicated vector database

## Related
- Informs: ADR-002 (refresh tokens stored in PostgreSQL)
- Informs: Future ADR on caching strategy (read replicas vs application cache)
