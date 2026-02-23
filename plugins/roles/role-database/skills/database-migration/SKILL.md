---
name: database-migration
description: |
  Schema and data migration patterns across all engines. Migration tools (Flyway, Liquibase, Alembic, Prisma Migrate, Atlas, golang-migrate, Knex, Ecto, EF Core, Diesel, ActiveRecord). Zero-downtime migration (expand-contract, blue-green, shadow writes). Cross-engine migration (MySQL→PG, Oracle→PG, MongoDB→PG). CDC-based migration (Debezium, DMS). Use when planning schema changes, migrating between databases, or implementing zero-downtime deployments.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Migration

## Reference Files

Load from `references/` based on what's needed:

### references/tools-zero-downtime.md
Migration tool comparison table (11 tools across all languages).
Expand-contract pattern step-by-step (expand, dual-write, backfill, switch, contract).
Online DDL operations matrix (PostgreSQL vs MySQL locking behavior).
PostgreSQL concurrent index creation with INVALID index recovery.
Batch migration for large tables. MySQL online tools (pt-osc, gh-ost).
Load when: choosing a migration tool, implementing zero-downtime changes, or migrating large tables.

### references/cross-engine-cicd.md
MySQL to PostgreSQL type mapping and pgloader one-liner.
Oracle to PostgreSQL key syntax differences and tooling.
MongoDB to PostgreSQL flattening patterns.
CDC-based migration with Debezium connector config and AWS DMS overview.
Migration validation (row count + checksum comparison).
CI/CD pipeline integration with Flyway. Safety checklist and anti-patterns.
Load when: migrating between database engines, using CDC for live migration, or integrating migrations into CI/CD.
