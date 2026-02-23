# Shift-Left Testing and Risk-Based Prioritization

## When to load
When planning where in the pipeline to add test gates; when prioritizing test effort across features; when justifying testing investment by risk; when designing CI quality gates.

## Shift-Left Testing Strategy

Move testing earlier in the development lifecycle:

### Developer-Time Testing (Leftmost)
- TypeScript strict mode eliminates null reference errors at compile time.
- ESLint security plugins (eslint-plugin-security, eslint-plugin-no-unsanitized) catch injection risks in the editor.
- Pre-commit hooks run unit tests related to changed files (lint-staged + jest --findRelatedTests).
- TDD: write tests before implementation for core business logic.

### PR-Time Testing
- Unit tests and integration tests run in under 5 minutes on every PR.
- Test impact analysis runs only tests affected by changed files.
- Contract tests verify no breaking changes to API contracts.
- SCA scans new dependencies for known CVEs.

### Merge-Time Testing
- Full integration test suite.
- Static analysis (SonarQube quality gate).
- SAST scan for new security hotspots.

### Deploy-Time Testing
- Smoke tests run immediately after deployment to staging.
- E2E critical path tests.
- Performance baseline validation.

## Risk-Based Test Prioritization

Prioritize testing effort using a risk matrix:

| Factor | High Priority | Low Priority |
|--------|--------------|--------------|
| Business impact | Payment, auth, data integrity | Static pages, tooltips |
| Change frequency | Actively developed modules | Stable, mature code |
| Complexity | Complex algorithms, state machines | Simple CRUD |
| Failure history | Components with past defects | Consistently reliable areas |
| User traffic | High-traffic endpoints | Admin-only features |
| Regulatory | PCI, HIPAA, SOX compliance paths | Marketing content |

- Assign risk scores (impact × likelihood) to features and allocate test effort proportionally.
- Re-evaluate risk scores each sprint as code changes shift the risk landscape.
- High-risk modules should have unit, integration, E2E, performance, and security tests.

## Quality Gates in CI/CD

```yaml
# PR Gate (must pass before merge)
- unit_tests: pass
- integration_tests: pass
- coverage_delta: no_decrease
- sca_scan: no_new_high_critical
- sast_scan: no_new_critical_hotspots
- contract_tests: pass

# Staging Gate (must pass before production deploy)
- e2e_smoke: pass
- performance_baseline: p95_within_20_percent
- security_scan: no_new_high_findings
- accessibility: no_new_critical_violations

# Production Gate (canary verification)
- synthetic_monitors: pass
- error_rate: below_threshold
- latency: p95_below_slo
```

### Ratcheting Coverage
- Never allow coverage to decrease. Use `--changedSince=main` for PR coverage.
- Increase coverage thresholds quarterly as the codebase matures.
- Per-file coverage for high-risk modules (payment, auth, data processing): 90%+.

## Test Impact Analysis

Run only tests that could be affected by changed code:

- **Nx affected**: `nx affected:test --base=main` runs tests only for changed projects.
- **Turborepo filtered**: `turbo run test --filter=...[HEAD^1]` runs changed packages and their dependents.
- **Jest --findRelatedTests**: `jest --findRelatedTests src/payment/charge.ts` runs tests that import changed files.
- **Pytest-testmon**: Tracks which tests cover which source lines.
- **Bazel**: Precise dependency graph. Only rebuilds and tests what is actually affected.

### TIA Strategy
- Use on PR pipelines for fast feedback (< 5 min target).
- Run full test suite on merge to main and nightly.
- Always run the full suite before releases.
