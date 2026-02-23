# Test Selection and ROI

## When to load
Load when deciding what type of test to write for a specific scenario, evaluating whether a test
is worth the maintenance cost, or making a case for skipping a test level.

## When to Skip Each Level

### Skip unit tests when:
- The function is a one-liner that delegates directly to a library
- The function is pure orchestration with zero logic (just calls A then B then C)
- Testing it would require mocking more than the function itself does
- Integration test already covers this path with real I/O

### Skip integration tests when:
- The only "integration" is calling a third-party API (use contract test instead)
- Pure business logic with no I/O (unit test is sufficient)
- The integration is already covered by a higher-level test and the cost of isolation is high

### Skip E2E tests when:
- The feature is an admin tool with 3 internal users (unit + integration is enough)
- The flow is already covered by an existing E2E test at a higher level
- The feature is an API-only change with no UI impact

## Cost Per Test Level

```
Dimension           | Unit      | Integration  | E2E
--------------------|-----------|--------------|----------
Write time          | 10 min    | 30 min       | 60–90 min
Execution time      | <5ms      | 100–500ms    | 10–30s
Maintenance/refactor| Low       | Medium       | High
Flakiness rate      | ~0%       | 1–3%         | 5–15%
Debug time on fail  | 2 min     | 15 min       | 45 min
Value per test      | Medium    | High         | Very high
```

E2E tests are the most valuable per test, but also the most expensive. Write fewer of them.

## Decision Map: Which Test to Write

```
Is there any I/O (DB, network, file)?
  No  → unit test
  Yes → Is it the full HTTP+DB stack?
          Yes → integration test
          No  → Is it a third-party API boundary?
                  Yes → contract test
                  No  → unit test with mock for I/O

Does the scenario require a real browser?
  Yes → E2E test (only for critical user journeys)
  No  → do not write an E2E test
```

## Test ROI by Scenario Type

```
Scenario                              | Best test type   | Why
--------------------------------------|------------------|--------------------------------
Business rule (discount calculation)  | Unit             | Fast, precise, zero I/O
Repository method (findByEmail)       | Integration      | Need real DB to catch SQL bugs
HTTP handler (POST /orders)           | Integration      | Tests routing, validation, DB
Third-party payment gateway           | Contract         | Can't mock Stripe's actual rules
User checkout flow                    | E2E              | Only test the critical happy path
Admin CRUD screen (3 internal users)  | Unit + Integr.   | E2E not worth the cost
Email template rendering              | Unit snapshot    | Fast, no browser needed
Queue consumer                        | Integration      | Need real queue or Testcontainers
```

## Red Flags: Misallocated Tests

```
Red flag                                    | Fix
--------------------------------------------|-------------------------------------------
80% E2E, 10% integration, 10% unit         | Ice cream cone — add unit tests for logic
DB mocked in integration tests              | Defeats the purpose — use Testcontainers
Unit tests for repository methods           | Can't catch real SQL bugs — use integration
E2E for every feature including admin tools | Lower to unit+integration for low-traffic UIs
Snapshot tests for logic-heavy components   | Snapshots don't test logic, add unit tests
```

## Estimating Test Suite Health

```
Total CI time > 15 minutes?
  → Too many integration/E2E tests running in sequence
  → Parallelize integration tests (Vitest workers + per-schema isolation)
  → Delete E2E tests that duplicate integration test coverage

Flaky tests > 2% of suite?
  → E2E tests with timing assumptions — add retry or explicit waits
  → Integration tests sharing DB state — add proper cleanup
  → Tests with real timers — use vi.useFakeTimers()

Coverage high but bugs still ship?
  → Line coverage without assertions — add mutation testing
  → Missing branch coverage — check coverage-analysis.md
```

## Quick reference

```
Unit              : pure logic, no I/O, < 10 min to write, run on every save
Integration       : real DB/queue, < 30 min to write, run on PR
E2E               : critical happy paths only, 60-90 min, run on main branch
Contract          : third-party API boundaries, prevents surprise breakage
Skip when         : mock cost > function cost, or higher-level test already covers it
Pyramid levels    : see testing-pyramid.md for ratios and layer definitions
```
