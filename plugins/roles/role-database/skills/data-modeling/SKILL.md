---
name: data-modeling
description: |
  Data modeling methodologies and patterns across paradigms. Entity-Relationship modeling (Chen, Crow's Foot, UML), document modeling (embedding vs referencing, polymorphic, bucket, outlier patterns), graph modeling (labeled property graph, RDF), time-series modeling, event sourcing, dimensional modeling (star/snowflake schema, SCD), Data Vault (hubs, links, satellites), polyglot persistence. Use when designing data models, choosing between modeling approaches, or mapping domain models to database schemas.
allowed-tools: Read, Grep, Glob, Bash
---

# Data Modeling

## Reference Files

Load from `references/` based on what's needed:

### references/relational-document-modeling.md
ER notation systems (Chen, Crow's Foot, UML, IDEF1X).
Relationship types (1:1, 1:N, M:N, self-referential, polymorphic) with implementation patterns.
Normalization decision guide by scenario (OLTP, writes, reads, warehouse).
MongoDB embedding vs referencing decision table.
Document design patterns: polymorphic, bucket (time-series), outlier, subset, computed.
Load when: designing relational schemas, modeling MongoDB documents, or choosing ER notation.

### references/graph-timeseries-warehouse.md
Labeled property graph model syntax and best practices. RDF triple model and SPARQL use cases.
Time-series design principles, TimescaleDB hypertable, PostgreSQL native range partitioning.
Star schema structure, SCD types comparison table, SCD Type 2 implementation.
Data Vault components (hub/link/satellite) and advantages.
Polyglot persistence decision table and consistency patterns (CDC, Saga, CQRS).
Load when: designing graph models, time-series schemas, data warehouses, or multi-database architectures.
