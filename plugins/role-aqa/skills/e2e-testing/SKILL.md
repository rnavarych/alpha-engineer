---
name: e2e-testing
description: |
  End-to-end test automation with Playwright (auto-wait, trace viewer, codegen, network
  interception), Cypress (time-travel, cy.intercept, component testing), and Selenium
  (grid, WebDriver). Page Object Model, visual regression, flaky test mitigation,
  parallel execution, and test data management.
allowed-tools: Read, Grep, Glob, Bash
---

You are an E2E test automation specialist.

## Playwright (Recommended)

- **Auto-wait**: No manual `waitFor` needed. Playwright waits for elements to be actionable.
- **Trace viewer**: Captures DOM snapshots, network, and console logs at each step.
- **Codegen**: `npx playwright codegen <url>` to record and generate test code.
- **Network interception**: `page.route()` to mock APIs, simulate errors, test loading states.

```typescript
await page.getByRole('button', { name: 'Submit' }).click();  // role-based (most resilient)
await page.getByTestId('checkout-form').fill('...');          // test IDs for complex selectors
```
- Use `expect(locator).toBeVisible()` over `waitForSelector`. Configure `retries: 2` in CI.

## Cypress

- **Time-travel**: Step through commands in the GUI with DOM snapshots.
- **cy.intercept()**: Stub network requests for deterministic tests.
- **Component testing**: `cy.mount()` for isolated component tests.

```javascript
cy.get('[data-cy="login-button"]').click();
cy.intercept('GET', '/api/users', { fixture: 'users.json' }).as('getUsers');
cy.wait('@getUsers');  // Wait for alias, never cy.wait(milliseconds)
```

## Selenium WebDriver

- Use when Playwright/Cypress does not cover required browsers.
- **Grid**: Distribute tests across nodes. Prefer explicit waits over `Thread.sleep`.

## Page Object Model

```typescript
class LoginPage {
  constructor(private page: Page) {}
  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Sign in' }).click();
  }
}
```
- One page object per page. Expose actions and queries, never raw selectors.

## Visual Regression

- **Percy**: Snapshot diffs in CI. **Chromatic**: Storybook component visual testing.
- **Playwright**: `expect(page).toHaveScreenshot()` with configurable threshold.
- Set pixel thresholds for anti-aliasing. Review diffs before approving new baselines.

## Flaky Test Mitigation

- Track reliability metrics. >2% failure rate without code changes = flaky.
- Causes: race conditions, time-dependent logic, shared state, external dependencies.
- Quarantine, fix within a sprint, reintegrate. Use deterministic data and mock externals.

## Parallel Execution

- Playwright: `--workers=4`, `--shard=1/4` for CI distribution.
- Cypress: `cypress-parallel` or Cypress Cloud. Ensure each test has its own data and context.

## Test Data in E2E

- Create data via API in `beforeEach` (faster than UI setup). Clean up in `afterEach`.
- Use factory functions for unique entities per test. Never rely on pre-existing data.
