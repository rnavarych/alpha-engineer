# Coverage Strategy

## When to load
Load when setting up coverage thresholds, configuring vitest/jest coverage, choosing which
metrics to enforce in CI, or deciding what code to exclude from coverage reports.

## Coverage Metrics Explained

| Metric | What it measures | Usefulness |
|--------|-----------------|------------|
| Line coverage | Lines executed | Low — a line executed without assertion is noise |
| Statement coverage | Statements executed | Slightly better than line |
| Branch coverage | Both sides of every if/else/ternary | High — catches missing edge cases |
| Function coverage | Every function called | Medium — tells you dead code exists |
| Mutation score | Logic mutations caught by tests | Very high — the real metric |

**Use branch coverage as your primary metric. Line coverage is a minimum sanity check.**

## Recommended Thresholds

```javascript
// vitest.config.ts / jest.config.ts
coverage: {
  thresholds: {
    // Global minimums — enforced on CI
    statements: 80,
    branches: 75,
    functions: 80,
    lines: 80,

    // Per-file overrides for critical modules
    // (set higher floors for business-critical code)
    // 'src/domain/**': { statements: 90, branches: 85 }
  }
}
```

### Target by code type

```
Domain/business logic (src/domain/, src/services/):
  statements: 90, branches: 85

Data access layer (src/repositories/):
  statements: 80, branches: 75

HTTP handlers / controllers (src/routes/, src/controllers/):
  statements: 70, branches: 65

UI components (src/components/):
  statements: 60, branches: 55

Infrastructure glue / config (src/config/, src/middleware/):
  statements: 50 — minimal coverage, tested via integration

Generated code (src/generated/, prisma client, openapi types):
  exclude entirely — never test generated code
```

## What NOT to Test

Untested code is noise in your coverage report. Exclude aggressively.

```javascript
// In vitest/jest coverage config:
exclude: [
  // Generated code
  'src/generated/**',
  'src/__generated__/**',
  'prisma/generated/**',
  '*.d.ts',

  // Infrastructure / config (tested via integration)
  'src/config/**',
  'src/db/migrations/**',
  'src/db/seed/**',
  'drizzle/**',

  // Entry points (thin wrappers, no logic)
  'src/index.ts',
  'src/main.ts',
  'src/app.ts',

  // Type definitions
  'src/types/**',
  'src/interfaces/**',

  // Test helpers themselves
  'src/test/**',
  'src/**/__tests__/**',
  'src/**/*.test.ts',
  'src/**/*.spec.ts',

  // Third-party adapters with no logic
  'src/lib/prisma.ts',
  'src/lib/redis.ts',
]
```

### Also don't test:
- Getters/setters that are pure property access
- Logging statements (they change, they're not logic)
- Type assertions (`as SomeType`) — TypeScript handles this at compile time
- Error message strings — test that an error is thrown, not the exact wording

## Coverage in CI

```yaml
# GitHub Actions: fail PR if coverage drops
- name: Run tests with coverage
  run: pnpm test --coverage

- name: Check coverage thresholds
  run: pnpm test --coverage --coverage.thresholdAutoUpdate=false
  # Exits 1 if any threshold not met — CI fails

# Optional: comment coverage diff on PR
- uses: davelosert/vitest-coverage-report-action@v2
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    vite-config-path: ./vitest.config.ts
```

## Quick reference

```
Primary metric      : branch coverage (not line)
Target: business    : 90% statements, 85% branches
Target: handlers    : 70% statements, 65% branches
Target: UI          : 60% statements, 55% branches
Exclude always      : generated code, migrations, seeds, config, type files
Mutation testing    : see coverage-analysis.md
```
