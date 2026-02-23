---
name: test-strategy
description: |
  Test strategy patterns — TDD, BDD, testing pyramid, coverage strategy, test prioritization,
  test data management, factories, fixtures, mutation testing. Use when defining quality approach,
  planning test suites, setting coverage targets, structuring test layers, or establishing team
  testing standards for any project type.
allowed-tools: Read, Grep, Glob
---

# Test Strategy

## When to use
- Starting a new project or module and need to define testing approach
- Coverage is high but bugs still ship — metric is lying
- Team argues about what to test and at what level
- Test suite takes 20+ minutes and nobody runs it locally
- Need to justify testing investment to stakeholders
- Setting up test data management (factories, seeds, fixtures)
- TDD adoption — team doesn't know where to start

## Core principles
1. **Test behavior, not implementation** — tests survive refactoring; if touching internals breaks them, they're wrong
2. **Pyramid over ice cream cone** — unit:integration:e2e ratio matters more than absolute count
3. **Coverage is vanity, mutation score is truth** — 80% line coverage with zero mutation detection is theater
4. **Test data is production data's twin** — bad fixtures produce false confidence at scale
5. **Speed determines adoption** — suite > 15 minutes = nobody runs it before pushing = useless

## References available
- `references/testing-pyramid.md` — unit/integration/e2e ratios, layer definitions, anti-patterns
- `references/test-selection.md` — when to write which test type, cost per level, skip decisions, ROI by scenario
- `references/tdd-bdd-patterns.md` — red-green-refactor cycle, naming conventions, describe grouping
- `references/bdd-gherkin.md` — Given-When-Then, Gherkin feature files, Cucumber integration, Scenario Outline
- `references/coverage-strategy.md` — coverage metrics, thresholds by code type, CI enforcement, exclusions
- `references/coverage-analysis.md` — coverage gap analysis, mutation testing with Stryker, survived mutant patterns
- `references/test-data-management.md` — Fishery factories, deterministic Faker, static fixtures, when to use each
- `references/test-data-isolation.md` — DB cleanup strategies, transaction rollback, per-worker schema isolation

## Scripts available
- `scripts/analyze-coverage.sh` — parses lcov/json coverage reports and outputs improvement suggestions

## Assets available
- `assets/test-plan-template.md` — fillable test strategy document for project kickoffs
