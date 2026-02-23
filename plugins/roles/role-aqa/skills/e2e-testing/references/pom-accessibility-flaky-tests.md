# Page Object Model, Accessibility Testing, and Flaky Test Mitigation

## When to load
When implementing Page Object Model pattern; when adding accessibility checks (axe) to E2E tests; when debugging, quarantining, or fixing flaky tests; when managing test data in E2E suites.

## Page Object Model

```typescript
abstract class BasePage {
  constructor(protected page: Page) {}

  async waitForLoad() {
    await this.page.waitForLoadState('networkidle');
  }
}

class LoginPage extends BasePage {
  private emailInput = this.page.getByLabel('Email');
  private passwordInput = this.page.getByLabel('Password');
  private submitButton = this.page.getByRole('button', { name: 'Sign in' });

  async login(email: string, password: string): Promise<DashboardPage> {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
    const dashboard = new DashboardPage(this.page);
    await dashboard.waitForLoad();
    return dashboard;
  }
}
```

## Accessibility Testing in E2E

### playwright-axe
```typescript
import { checkA11y, injectAxe } from 'axe-playwright';

test('checkout is accessible', async ({ page }) => {
  await page.goto('/checkout');
  await injectAxe(page);
  await checkA11y(page, undefined, {
    axeOptions: {
      runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'best-practice'] },
    },
    detailedReport: true,
  });
});
```

### cypress-axe
```javascript
cy.visit('/checkout');
cy.injectAxe();
cy.checkA11y(null, {
  rules: { 'color-contrast': { enabled: true } },
}, (violations) => {
  cy.task('log', `${violations.length} accessibility violations`);
});
```

### Accessibility Assertions in E2E
- Verify keyboard navigation: Tab through all interactive elements in expected order.
- Verify focus management: After modal open, focus moves to modal. After close, focus returns to trigger.
- Verify ARIA live regions announce dynamic content changes.
- Verify form error messages are associated with inputs via `aria-describedby`.

## Flaky Test Mitigation

- Track reliability metrics per test. Flag tests with >2% failure rate without code changes as flaky.
- Root causes: race conditions, time-dependent logic, shared state, external service dependencies, animation timing.
- Quarantine flaky tests: tag with `@flaky`, exclude from blocking pipeline gate.
- Fix within one sprint. Use deterministic test IDs, mock external services, disable animations.
- Reintegrate after verifying stability across 50+ consecutive runs.
- Use Playwright `--retries=2` in CI only. Do not mask flakiness with retries — fix the root cause.

## Test Data in E2E

- Create data via API in `beforeEach` (faster than UI setup). Clean up in `afterEach`.
- Use factory functions for unique entities per test. Never rely on pre-existing data.
- Store authentication state with `storageState` to avoid re-login on every test.
- Use unique email addresses and identifiers per test run (include `Date.now()` or UUID).
