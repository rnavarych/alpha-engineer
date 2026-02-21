---
name: testing-patterns
description: |
  Provides testing strategies: test pyramid, TDD/BDD, unit/integration/E2E patterns,
  mocking strategies, test data factories, snapshot testing, and mutation testing.
  Use when designing test strategies, writing tests, or improving test coverage.
allowed-tools: Read, Grep, Glob, Bash
---

You are a testing specialist.

## Test Pyramid

```
    /  E2E  \        Few, slow, expensive
   /________\
  / Integration \    Moderate count
 /______________\
/   Unit Tests   \   Many, fast, cheap
/________________\
```

- **Unit tests** (70%): Test individual functions/methods in isolation. Fast, deterministic.
- **Integration tests** (20%): Test component interactions. Database, API, service boundaries.
- **E2E tests** (10%): Test complete user flows. Browser/app automation.

## Unit Testing Principles
- Test behavior, not implementation
- One assertion per logical concept
- Follow AAA pattern: Arrange, Act, Assert
- Use descriptive test names: `should_return_error_when_email_is_invalid`
- Keep tests independent — no shared mutable state
- Aim for <100ms per unit test

## Mocking Strategy
- **Stubs**: Return fixed values (use for queries)
- **Mocks**: Verify interactions (use for commands)
- **Fakes**: Simplified implementations (in-memory DB, fake API server)
- **Spies**: Record calls without changing behavior
- Mock at boundaries, not internals. Over-mocking creates brittle tests.

## Test Data Management
- **Factories**: Builder pattern for test objects (Fishery, Factory Bot, FactoryGirl)
- **Faker**: Generate realistic test data (names, emails, addresses)
- **Fixtures**: Static data files for deterministic scenarios
- **Database seeding**: Programmatic setup/teardown per test
- Never share mutable test data between tests

## Integration Testing
- Use test containers (Testcontainers) for databases, message queues
- Test API contracts with actual HTTP calls (supertest, httpx)
- Verify database state after operations
- Test error paths: timeouts, connection failures, invalid data

## E2E Testing
- Use Page Object Model for maintainability
- Test critical user journeys, not every edge case
- Handle flaky tests: retry mechanisms, wait strategies, deterministic selectors
- Run in CI with headless browsers
- Visual regression testing for UI changes

## TDD Workflow
1. Write a failing test (Red)
2. Write minimal code to pass (Green)
3. Refactor while keeping tests passing (Refactor)

## Code Coverage
- Aim for 80%+ line coverage for critical paths
- 100% coverage is not a goal — diminishing returns
- Focus on branch coverage for complex logic
- Use coverage reports to find untested paths, not as a metric to game

For framework references, see [reference-frameworks.md](reference-frameworks.md).
