# Coverage Analysis and Mutation Testing

## When to load
Load when coverage numbers look good but bugs still ship, running mutation testing with Stryker,
interpreting survived mutants, or doing a gap analysis on an existing test suite.

## The Coverage Lie

100% line coverage tells you every line was executed. It does NOT tell you:
- That all branches were tested (line coverage != branch coverage)
- That mutations to logic would be caught
- That the assertions actually verify anything meaningful

```typescript
// This function has 100% line coverage from one test:
function applyDiscount(price: number, discount: number): number {
  if (discount > 0) {
    return price - (price * discount / 100);
  }
  return price;
}

// Test achieving 100% line coverage:
it('applies discount', () => {
  applyDiscount(100, 10);  // Calls both branches, executes every line
  // But there are ZERO assertions. This test is useless.
});

// Test achieving meaningful coverage:
it('should subtract percentage discount from price', () => {
  expect(applyDiscount(100, 10)).toBe(90);
  expect(applyDiscount(200, 25)).toBe(150);
  expect(applyDiscount(100, 0)).toBe(100);  // Zero discount returns original
});
```

## Mutation Testing with Stryker

Mutation testing modifies your code (introduces bugs) and checks whether your tests catch them.
A high mutation score = tests actually catch real logic errors.

### Install and configure Stryker

```bash
npm install --save-dev @stryker-mutator/core @stryker-mutator/vitest-runner
```

```javascript
// stryker.config.mjs
export default {
  testRunner: 'vitest',
  coverageAnalysis: 'perTest',
  mutate: [
    'src/domain/**/*.ts',       // Focus on business logic
    'src/services/**/*.ts',
    '!src/**/*.test.ts',
    '!src/**/*.spec.ts',
  ],
  timeoutMS: 30000,
  concurrency: 4,
  thresholds: {
    high: 80,    // Score above 80: green
    low: 60,     // Score 60–80: yellow warning
    break: 50,   // Score below 50: fail CI
  },
  reporters: ['html', 'progress', 'clear-text'],
  htmlReporter: { fileName: 'reports/mutation/index.html' },
};
```

```bash
# Run mutation tests (takes longer than unit tests — run in CI nightly or on PR to domain/)
npx stryker run

# Output example:
# Mutation score: 73.5% (128/174 mutants killed)
# Survived mutants: 46 — these mutations were NOT caught by your tests
```

### Interpreting mutation results

```
Mutant KILLED   → Your test caught the bug. Good.
Mutant SURVIVED → Your test did NOT catch the bug. This is a gap.
Mutant TIMEOUT  → Test timed out. Usually means infinite loop mutant — acceptable.
Mutant NO_COVER → No test executed this code at all. You have dead or untested code.
```

### Common survived mutations (what to fix)

```typescript
// Boundary condition mutations — extremely common to survive
if (quantity > 0)     // Stryker tests: quantity >= 0, quantity > 1
// If your test only uses quantity=5, Stryker's boundary mutations survive.
// Fix: add tests for quantity=0, quantity=1

// Conditional negation — very common
if (user.isActive && user.hasPermission('admin'))
// Stryker tests: removing one condition entirely
// Fix: test case where isActive=false, test case where hasPermission fails

// Return value mutations
return { success: true, id: result.id }
// Stryker tests: return { success: false, id: result.id }
// Fix: assert on the success field explicitly
```

## Gap Analysis: Finding Undertested Code

```bash
# Generate lcov report, then find files below threshold
pnpm test --coverage --coverage.reporter=lcov

# Parse with genhtml for visual report
genhtml coverage/lcov.info --output-directory coverage/html
open coverage/html/index.html
```

```typescript
// Use the analyze-coverage.sh script in this skill's scripts/ directory
// It reads lcov output and prints files below threshold with suggestions

// Manual approach: sort by branch coverage to find the gaps
// In the HTML report: sort "Branch %" column ascending
// Focus on domain/ and services/ — those matter most
```

### Gap analysis checklist

```
[ ] List all files with branch coverage < 75%
[ ] Filter to domain/ and services/ only (other layers have lower thresholds)
[ ] For each file: identify which branches are uncovered (red highlights in HTML)
[ ] Prioritize: conditional logic > null checks > error paths
[ ] Add tests targeting uncovered branches — not arbitrary lines
[ ] Re-run; if mutation score doesn't improve, the new tests have weak assertions
```

## When to Run Mutation Tests

```
Every PR      : too slow for most codebases — kills developer flow
Nightly CI    : good default — catches regressions in mutation score over time
PR to domain/ : trigger mutation only when business logic changes
Pre-release   : always run before a major release
```

```yaml
# GitHub Actions: mutation tests on schedule + domain/ changes
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM nightly
  push:
    paths:
      - 'src/domain/**'
      - 'src/services/**'

jobs:
  mutation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install
      - run: npx stryker run
```

## Quick reference

```
Coverage lie        : 100% line coverage with no assertions = theater
Primary metric      : branch coverage — both sides of every if/else
Mutation tool       : Stryker — npx stryker run
Mutation threshold  : score < 50 = fail CI
Survived mutations  : boundary conditions, conditional negation, return values
Run cadence         : nightly or on PR to domain/ — not on every commit
Coverage thresholds and config : see coverage-strategy.md
```
