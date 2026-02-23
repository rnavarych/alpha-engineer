---
name: unit-testing
description: |
  Unit testing patterns: Vitest config with v8 coverage, Testing Library behavior testing,
  MSW for HTTP mocking (vs jest.mock), it.each parametrized tests, spies vs mocks vs stubs,
  testing async code, snapshot testing guidelines. Use when writing unit and component tests.
allowed-tools: Read, Grep, Glob
---

# Unit Testing Patterns

## When to use
- Setting up Vitest or Jest for a new project
- Writing unit tests for business logic
- Component testing with Testing Library
- Mocking HTTP requests with MSW
- Parametrized tests with it.each

## Core principles

1. **Test behavior, not implementation** — what does it return/do, not how
2. **MSW over jest.mock** — mock at network level, not module level
3. **One assertion per test** — single reason to fail per test
4. **Arrange-Act-Assert** — consistent structure in every test
5. **No test interdependence** — each test must run independently

## References available
- `references/vitest-config.md` — globals, environment, coverage thresholds, thread pool, MSW setup
- `references/business-logic-testing.md` — pure function tests, AAA pattern, it.each parametrized tests
- `references/msw-http-mocking.md` — handlers setup, server lifecycle, per-test handler overrides
- `references/async-testing.md` — await patterns, rejected promise assertions, try/catch error checks
- `references/testing-library-react.md` — render, screen queries, userEvent vs fireEvent, role queries
