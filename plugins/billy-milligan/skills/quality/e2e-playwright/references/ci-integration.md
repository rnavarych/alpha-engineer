# Playwright CI Integration

## When to load
Load when configuring Playwright in CI: GitHub Actions, parallel execution, artifacts, sharding.

## GitHub Actions Setup

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    container: mcr.microsoft.com/playwright:v1.40.0-jammy
    strategy:
      matrix:
        shard: [1/4, 2/4, 3/4, 4/4]  # 4-way parallel
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci

      - name: Run E2E tests
        run: npx playwright test --shard=${{ matrix.shard }}

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report-${{ matrix.strategy.job-index }}
          path: playwright-report/
          retention-days: 7

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-traces-${{ matrix.strategy.job-index }}
          path: test-results/
          retention-days: 3
```

## Playwright Config for CI

```typescript
// playwright.config.ts
export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,  // Retry in CI only
  workers: process.env.CI ? 1 : undefined,  // 1 worker per shard in CI
  reporter: process.env.CI
    ? [['html'], ['github'], ['json', { outputFile: 'results.json' }]]
    : [['html']],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',  // Capture trace on retry
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: process.env.CI ? undefined : {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: true,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'mobile', use: { ...devices['iPhone 14'] } },
  ],
});
```

## Merge Shard Reports

```yaml
  merge-reports:
    needs: e2e
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with: { pattern: playwright-report-*, path: all-reports }
      - run: npx playwright merge-reports --reporter=html all-reports
      - uses: actions/upload-artifact@v4
        with:
          name: full-report
          path: playwright-report/
```

## Anti-patterns
- Not using Playwright Docker image in CI → missing system deps
- Retries in local development → hides flaky tests
- No sharding for 100+ tests → CI takes 30+ minutes
- Keeping video/trace for passing tests → artifacts bloat

## Quick reference
```
Container: mcr.microsoft.com/playwright:v1.40.0-jammy
Sharding: --shard=1/4 for parallel CI jobs
Retries: 2 in CI, 0 locally
Trace: on-first-retry (captures only failing)
Screenshot: only-on-failure
Video: retain-on-failure
Artifacts: upload on failure, 7 day retention
webServer: only for local, not CI (app already running)
```
