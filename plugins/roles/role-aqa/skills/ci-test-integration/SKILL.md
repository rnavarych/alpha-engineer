---
name: role-aqa:ci-test-integration
description: |
  CI/CD test integration: parallel test execution (sharding), test splitting strategies,
  flaky test quarantine, test reporting (Allure, ReportPortal, JUnit XML), quality gates
  (coverage thresholds, no new failures), test result caching, and pre-commit hooks.
  Use when configuring test pipelines, optimizing CI test execution, or setting up reporting.
allowed-tools: Read, Grep, Glob, Bash
---

You are a CI test integration specialist.

## Parallel Test Execution

### Sharding
```yaml
# GitHub Actions matrix strategy
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/4
```
- Playwright: `--shard=N/total`. Jest: `--shard=N/total`. pytest: `pytest-xdist -n 4`.
- Run unit, integration, and E2E tests in separate concurrent CI jobs.

## Test Splitting Strategies

| Strategy | How | Best For |
|----------|-----|----------|
| **File-based** | Split test files evenly across shards | Simple, deterministic |
| **Timing-based** | Use historical run times to balance shards | Even distribution |
| **Changed-file** | Run only tests affected by changed files | PR pipelines, fast feedback |

- Record test durations from CI runs and rebalance shards periodically.

## Flaky Test Quarantine

1. **Detect**: Track pass/fail history. Flag tests with >2% failure rate.
2. **Quarantine**: Tag with `@flaky`, exclude from blocking pipeline.
3. **Fix**: Assign owner. Common causes: race conditions, time deps, shared state.
4. **Reintegrate**: Verify stability over 50+ runs before unquarantining.

## Test Reporting

- **Allure**: Rich HTML reports with history, categories, `@severity` annotations. Host on GitHub Pages or S3.
- **ReportPortal**: Centralized dashboard with AI failure analysis. Classifies: product bug, automation bug, system issue.
- **JUnit XML**: Universal format for GitHub Actions, GitLab CI, Jenkins. Use as baseline, layer richer tools on top.

## Quality Gates

```json
{
  "coverageThreshold": {
    "global": { "branches": 75, "functions": 80, "lines": 80, "statements": 80 }
  }
}
```

- All non-quarantined tests pass. Coverage meets thresholds. No new critical security findings.
- **Ratcheting**: Never allow coverage to decrease. Increase thresholds as codebase matures.
- Require coverage on changed files: `--changedSince=main` with per-file thresholds.

## Test Result Caching

- Nx, Turborepo, and Bazel support computation caching including test results.
- Invalidate cache when dependencies, env vars, or configuration change.
- Cache Playwright browsers and Docker layers for faster environment setup.

## Pre-Commit Hooks

```json
{ "lint-staged": { "*.{ts,tsx}": ["eslint --fix", "jest --bail --findRelatedTests"] } }
```
- Run only tests related to changed files. Keep under 30 seconds.
- Reserve full suite for CI. Never run E2E tests in pre-commit.
