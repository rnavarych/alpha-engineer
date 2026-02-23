# Flaky Test Management

## When to load
Load when dealing with intermittent test failures: detection, quarantine, root causes.

## Detection

```
Flaky test definition:
  Same code + same test = different results across runs.

Detection methods:
1. CI tracking: test passes on retry without code change
2. Repeat run: npx vitest --repeat=5 suspicious.test.ts
3. Statistical: test fails > 2% of runs over 7 days
4. Playwright trace: trace: 'on-first-retry' captures failure context
```

## Quarantine Process

```typescript
// Step 1: Mark flaky test with skip + ticket reference
describe.skip('Payment flow', () => {
  // TODO: Flaky — race condition in webhook handler (TICKET-1234)
  it('processes payment and sends confirmation', async () => {
    // ...
  });
});

// Step 2: Move to quarantine file (optional — for tracking)
// tests/quarantine/payment-flow.test.ts

// Step 3: Fix root cause within 1 sprint (2 weeks max)
// Step 4: Remove skip, verify with --repeat=10
```

## Common Root Causes

```
1. Timing/Race conditions (60% of flaky tests)
   Fix: use waitFor/polling instead of fixed delays
   Fix: use retry assertions (expect.poll in Playwright)

2. Shared mutable state (20%)
   Fix: isolate test state in beforeEach
   Fix: unique IDs per test (not sequential)

3. External dependencies (10%)
   Fix: mock external APIs
   Fix: use Testcontainers for databases

4. Resource exhaustion (5%)
   Fix: close connections/handles in afterEach
   Fix: increase CI runner resources

5. Non-deterministic data (5%)
   Fix: seed random generators
   Fix: freeze time with vi.useFakeTimers()
```

## Anti-patterns
- Retrying flaky tests forever → hides real bugs
- Deleting flaky tests → losing coverage
- Adding `sleep(5000)` → slows suite, still flaky
- Ignoring flaky tests → team loses trust in CI

## Quick reference
```
Detect: CI retry tracking, --repeat=5, >2% failure rate
Quarantine: describe.skip + ticket reference, fix within 2 weeks
Root causes: timing (60%), shared state (20%), external deps (10%)
Fix timing: waitFor/polling, not sleep()
Fix state: beforeEach isolation, unique IDs
Verify fix: --repeat=10 passes all
Metric: flaky test count should trend toward 0
```
