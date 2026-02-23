---
name: test-infrastructure
description: |
  Test infrastructure: Testcontainers with real PostgreSQL (60s timeout), parallel test
  isolation (per-worker schema), flaky test quarantine, test data seeding patterns,
  ephemeral test databases, CI database setup. Use when setting up database testing,
  managing test isolation, improving CI test reliability.
allowed-tools: Read, Grep, Glob
---

# Test Infrastructure

## When to use
- Setting up database tests with real PostgreSQL (not mocks)
- Isolating tests that run in parallel
- Managing test data with factories and seeds
- Handling flaky tests in CI
- Testcontainers for integration tests

## Core principles

1. **Real database over mocks** — SQLite for tests when you use PostgreSQL in prod = false confidence
2. **Parallel isolation via schemas** — each worker gets its own schema, no shared state
3. **Deterministic test data** — use factories, not shared fixtures that accumulate side effects
4. **Flaky tests: quarantine immediately** — don't let them degrade CI trust
5. **Fast teardown** — truncate tables, not DROP/CREATE (seconds vs minutes)

## References available
- `references/testcontainers-setup.md` — PostgreSqlContainer config, 60s startup timeout, migrate on start
- `references/per-worker-isolation.md` — vitest thread pool, globalSetup schema creation, search_path config
- `references/test-data-seeding.md` — factory pattern with beforeEach, seedStandardData, truncateAll
- `references/flaky-quarantine.md` — it.skip + ticket process, 1-week SLA, fix vs delete decision
- `references/ci-database-setup.md` — GitHub Actions service containers, health checks, schema init steps
