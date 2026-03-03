---
name: role-architect:migration-planner
description: |
  Migration planning expertise including strangler fig pattern, parallel run strategy,
  data migration techniques, feature parity tracking, rollback plans,
  phased timelines, risk mitigation, and zero-downtime migration.
allowed-tools: Read, Grep, Glob, Bash
---

# Migration Planner

## When to use
- Planning an incremental migration from a legacy system using strangler fig
- Choosing between shadow mode, dark launch, and graduated cutover strategies
- Designing ETL, CDC, or dual-write data migration approaches
- Tracking feature parity between legacy and new systems during a migration
- Defining rollback procedures and automatic rollback triggers per migration phase
- Applying zero-downtime techniques (blue-green, rolling, expand-and-contract)

## Core principles
1. **Facade before cutover** — no traffic switches without a routing layer in place and tested
2. **CDC over dual-write for anything longer than a sprint** — dual-write consistency problems compound fast
3. **Rollback must be tested before go-live** — an untested rollback plan is not a plan
4. **Each phase independently deployable** — never combine two risky changes in a single phase
5. **Expand-and-contract for schema changes** — the only reliable zero-downtime database migration pattern

## Reference Files
- `references/migration-strategies-and-execution.md` — strangler fig pattern with facade design, parallel run modes (shadow/dark launch/graduated cutover), ETL and CDC data migration techniques, dual-write trade-offs, feature parity matrix and API-level tracking, phased timeline (Phase 0-4), and zero-downtime techniques (blue-green, rolling deployment, expand-and-contract schema migration, API versioning, feature flags)
- `references/rollback-and-risk-mitigation.md` — rollback procedure requirements (data rollback, traffic rollback), rollback trigger thresholds (error rate, latency, data discrepancy), risk identification per phase with likelihood/impact assessment, common mitigations (feature flags, canary deployments, automated triggers), and stakeholder/team/customer communication plan with post-migration retrospective
