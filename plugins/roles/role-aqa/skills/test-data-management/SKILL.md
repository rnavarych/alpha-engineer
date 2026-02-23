---
name: test-data-management
description: |
  Test data management with factory patterns (Faker.js, Fishery, Factory Bot),
  database seeding, test data isolation (transactions, cleanup), anonymization
  and masking for production data, synthetic data generation, fixture management,
  and shared test state risks.
  Use when designing test data strategies or debugging data-related test failures.
allowed-tools: Read, Grep, Glob, Bash
---

# Test Data Management

## When to use
- Setting up Fishery/Faker factories for TypeScript test data generation
- Choosing between transaction rollback, cleanup-after, or schema isolation strategies
- Debugging flaky tests caused by shared mutable state between test runs
- Building a pipeline to anonymize production data for test environments
- Deciding when to use factories vs fixtures vs static seeds
- Generating edge case data (Unicode, max-length fields, boundary values)

## Core principles
1. **Every test owns its data** — tests that share state are tests that fail randomly; isolation is not optional
2. **Factories over fixtures for most tests** — fixtures are static and collide; factories generate fresh unique data every run
3. **Sequences prevent collisions** — unique fields must use sequence numbers or UUIDs, not hardcoded values
4. **Production data never reaches test environments raw** — anonymize in a separate pipeline, maintain referential integrity
5. **Seed the RNG for reproducibility** — `faker.seed(12345)` turns a flaky data generator into a deterministic one

## Reference Files
- `references/factories-seeding-isolation.md` — Fishery + Faker.js factory patterns, factory design principles, idempotent seed scripts, transaction rollback vs cleanup vs schema isolation strategies, shared state flakiness diagnosis
- `references/anonymization-synthetic-fixtures.md` — field-level anonymization techniques table, referential integrity in masking pipelines, synthetic data with edge cases, fixture vs factory decision guide, reproducible random seeding
