---
name: role-database:schema-design
description: |
  Database schema design principles and patterns. Normalization (1NF through 5NF/BCNF), strategic denormalization for read performance, multi-tenancy schema patterns (shared schema, schema-per-tenant, database-per-tenant), primary key strategies (UUID v7, ULID, KSUID, Snowflake ID, BIGSERIAL, CUID2, NanoID), soft delete patterns, temporal tables (SCD Type 1/2/3/4/6), audit trails, schema evolution (expand-contract pattern), naming conventions, data type best practices, and anti-patterns to avoid (EAV, polymorphic associations, god tables). Use when designing new schemas, reviewing existing schema design, planning schema migrations, or choosing PK strategies.
allowed-tools: Read, Grep, Glob, Bash
---

# Schema Design

## Reference Files

Load from `references/` based on what's needed:

### references/normalization-multitenancy.md
Normal forms (1NF–4NF) with violation examples, denormalization patterns (materialized views, trigger counters).
Multi-tenancy: shared schema + RLS, schema-per-tenant, database-per-tenant decision guide.
Primary key strategy comparison (BIGSERIAL, UUID v7, ULID, Snowflake ID).
Load when: designing new schemas, choosing PK strategy, implementing multi-tenancy.

### references/temporal-audit-evolution.md
Soft delete patterns (timestamp, archive table, partial indexes).
SCD Type 2 temporal tables in PostgreSQL and SQL Server.
Generic audit trigger with JSONB old/new values.
Expand-contract pattern with safe migration operations table and zero-downtime column rename.
Load when: implementing audit trails, versioned data, or zero-downtime schema changes.

### references/datatypes-antipatterns.md
Data type decisions (money, timestamps, IP, email, JSON, enums, country, phone).
PostgreSQL domain types and range exclusion constraints.
Naming conventions table (tables, columns, PKs, FKs, indexes, booleans, timestamps).
Anti-patterns: EAV, polymorphic associations, god tables, over-indexing, missing FKs.
Load when: choosing column types, reviewing naming, or identifying schema problems.
