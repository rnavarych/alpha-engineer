# CI Test Optimization

## When to load
Load when optimizing CI test execution: parallel execution, test splitting, caching, matrix.

## Test Splitting & Parallelization

```yaml
# GitHub Actions: matrix-based parallel execution
jobs:
  test:
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npx vitest --shard=${{ matrix.shard }}/4

  # Playwright parallel shards
  e2e:
    strategy:
      matrix:
        shard: [1/4, 2/4, 3/4, 4/4]
    steps:
      - run: npx playwright test --shard=${{ matrix.shard }}
```

## Caching Dependencies

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: deps-${{ hashFiles('package-lock.json') }}
    restore-keys: deps-

# Turborepo remote cache
- run: npx turbo test --cache-dir=.turbo
  env:
    TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
    TURBO_TEAM: ${{ vars.TURBO_TEAM }}
```

## Affected-Only Testing

```bash
# Run tests only for changed files (Vitest)
npx vitest --changed HEAD~1

# Nx affected
npx nx affected --target=test --base=main

# Turborepo affected
npx turbo test --filter='...[HEAD~1]'
```

## Test Timing Optimization

```
Priority order:
1. Run lint + type-check first (fastest, catches most errors)
2. Run unit tests (fast, high signal)
3. Run integration tests (medium speed)
4. Run E2E tests (slowest, run in parallel shards)

Timeout targets:
  Lint + types: < 2 minutes
  Unit tests: < 5 minutes
  Integration: < 10 minutes
  E2E (sharded): < 15 minutes
  Total pipeline: < 20 minutes
```

## Anti-patterns
- Sequential test execution in CI → 30+ minute pipelines
- No caching → npm install on every run (2-3 min wasted)
- Running all tests for every change → test full suite only on main
- No test splitting → single shard runs all E2E tests

## Quick reference
```
Sharding: --shard=1/4 for Vitest/Playwright parallelism
Cache: actions/cache with package-lock.json hash key
Affected: vitest --changed, nx affected, turbo --filter
Order: lint → types → unit → integration → E2E
Target: total pipeline < 20 minutes
PR: affected tests only; main: full suite
```
