---
name: e2e-playwright
description: |
  Playwright e2e testing: config (parallel, retries=2 in CI, trace on failure), Page Object
  Model with semantic locators, fixtures for auth state reuse, no hard-coded sleeps,
  visual regression, accessibility testing, API mocking with route interception.
  Use when writing e2e tests, reviewing Playwright config, debugging flaky tests.
allowed-tools: Read, Grep, Glob
---

# E2E Testing with Playwright

## When to use
- Setting up Playwright for a new project
- Writing page object models for maintainable tests
- Reusing authentication state across tests
- Debugging flaky Playwright tests
- Visual regression and accessibility testing

## Core principles

1. **Page Object Model** — locators in one place, not spread across test files
2. **Semantic locators** — `getByRole`, `getByLabel` over CSS selectors
3. **Auth state fixtures** — log in once, reuse across hundreds of tests
4. **No hard-coded sleeps** — `waitForResponse`, `waitForSelector`, not `page.waitForTimeout()`
5. **Trace on failure** — trace files show exactly what went wrong

## References available
- `references/playwright-config.md` — parallel setup, retries, workers, reporter config, webServer
- `references/page-object-model.md` — POM class structure, semantic locators, constructor patterns
- `references/auth-fixtures.md` — globalSetup storage state, fixture extension, auth reuse patterns
- `references/network-waiting.md` — waitForResponse, Promise.all click patterns, auto-waiting
- `references/api-mocking.md` — page.route() interception, fulfilling responses, isolated tests
