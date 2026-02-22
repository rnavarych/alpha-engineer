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

## When to Use This Skill
- Setting up Playwright for a new project
- Writing page object models for maintainable tests
- Reusing authentication state across tests
- Debugging flaky Playwright tests
- Visual regression and accessibility testing

## Core Principles

1. **Page Object Model** — locators in one place, not spread across test files
2. **Semantic locators** — `getByRole`, `getByLabel` over CSS selectors
3. **Auth state fixtures** — log in once, reuse across hundreds of tests
4. **No hard-coded sleeps** — `waitForResponse`, `waitForSelector`, not `page.waitForTimeout()`
5. **Trace on failure** — trace files show exactly what went wrong

---

## Patterns ✅

### Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,          // Run tests in parallel across files
  forbidOnly: !!process.env.CI, // Fail if test.only committed
  retries: process.env.CI ? 2 : 0,  // 2 retries in CI — flaky test safety net
  workers: process.env.CI ? 4 : undefined,  // 4 workers in CI, auto locally

  reporter: [
    ['list'],
    ['html', { open: 'never' }],  // HTML report for review
    process.env.CI ? ['github'] : ['dot'],
  ],

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',    // Record trace on first retry — debug failures
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    // Accessibility: auto-include ARIA snapshots
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['Pixel 5'] } },
    // Only run Firefox/Safari on main branch (slower)
    ...(process.env.CI && process.env.BRANCH === 'main'
      ? [{ name: 'firefox', use: { ...devices['Desktop Firefox'] } }]
      : []),
  ],

  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

### Page Object Model

```typescript
// e2e/pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  private readonly emailInput: Locator;
  private readonly passwordInput: Locator;
  private readonly submitButton: Locator;
  private readonly errorMessage: Locator;

  constructor(private readonly page: Page) {
    // Semantic locators — test IDs or ARIA roles, not CSS classes
    this.emailInput = page.getByLabel('Email address');
    this.passwordInput = page.getByLabel('Password');
    this.submitButton = page.getByRole('button', { name: 'Sign in' });
    this.errorMessage = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/auth/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async expectError(message: string) {
    await this.errorMessage.toBeVisible();
    await this.errorMessage.toContainText(message);
  }
}

// e2e/pages/OrdersPage.ts
export class OrdersPage {
  constructor(private readonly page: Page) {}

  async goto() {
    await this.page.goto('/orders');
  }

  async createOrder(items: OrderItem[]) {
    await this.page.getByRole('button', { name: 'New Order' }).click();
    for (const item of items) {
      await this.page.getByLabel('Product').selectOption(item.productName);
      await this.page.getByLabel('Quantity').fill(String(item.quantity));
      await this.page.getByRole('button', { name: 'Add item' }).click();
    }
    // Wait for navigation response, not arbitrary delay
    const [response] = await Promise.all([
      this.page.waitForResponse('**/api/orders'),
      this.page.getByRole('button', { name: 'Place Order' }).click(),
    ]);
    return response.json();
  }

  getOrderRow(orderId: string) {
    return this.page.getByTestId(`order-row-${orderId}`);
  }
}
```

### Auth State Fixtures

```typescript
// e2e/fixtures.ts — avoid logging in before every test
import { test as baseTest, expect } from '@playwright/test';
import { LoginPage } from './pages/LoginPage';

// Extend test with fixtures
export const test = baseTest.extend<{
  loginPage: LoginPage;
  authenticatedPage: void;  // Fixture for pre-authenticated state
}>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },

  // Auth fixture: log in once, save state to file, reuse across tests
  authenticatedPage: [async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('test@example.com', 'testpassword123');
    // Wait for successful redirect
    await page.waitForURL('/dashboard');
    await use();
  }, { auto: false }],
});

export { expect };

// In playwright.config.ts — global setup saves auth state
// storageState: 'e2e/.auth/user.json'  (stored login cookies/tokens)
```

```typescript
// e2e/global-setup.ts — log in once before test suite
import { chromium, FullConfig } from '@playwright/test';

export default async function globalSetup(config: FullConfig) {
  const { baseURL } = config.projects[0].use;
  const browser = await chromium.launch();
  const page = await browser.newPage();

  await page.goto(`${baseURL}/auth/login`);
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Password').fill('testpassword123');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL(`${baseURL}/dashboard`);

  // Save authentication state (cookies + localStorage)
  await page.context().storageState({ path: 'e2e/.auth/user.json' });
  await browser.close();
}
```

### Waiting for Network, Not Time

```typescript
// Wrong: arbitrary wait
await page.click('button[type="submit"]');
await page.waitForTimeout(2000);  // Hope 2 seconds is enough
expect(await page.textContent('.result')).toContain('Success');

// Correct: wait for actual network response
const [response] = await Promise.all([
  page.waitForResponse((resp) =>
    resp.url().includes('/api/orders') && resp.status() === 201
  ),
  page.getByRole('button', { name: 'Place Order' }).click(),
]);
const order = await response.json();
expect(order.id).toBeDefined();

// Or wait for UI state
await page.getByRole('button', { name: 'Place Order' }).click();
await expect(page.getByText('Order placed successfully')).toBeVisible();
// Playwright auto-waits up to timeout (default 5s)
```

### API Mocking for Isolated Tests

```typescript
// Mock specific API responses for isolated, fast tests
test('shows error when payment fails', async ({ page }) => {
  // Intercept Stripe API and return error
  await page.route('**/api/payments', async (route) => {
    await route.fulfill({
      status: 402,
      contentType: 'application/json',
      body: JSON.stringify({ error: { code: 'CARD_DECLINED', message: 'Card declined' } }),
    });
  });

  await page.goto('/checkout');
  await page.getByRole('button', { name: 'Pay now' }).click();
  await expect(page.getByRole('alert')).toContainText('Card declined');
});
```

---

## Anti-Patterns ❌

### CSS Selector Locators
**What it is**: `page.locator('.btn-primary.checkout-submit')`
**What breaks**: CSS class changes → every test using that locator fails. CSS selectors are implementation details.
**Fix**: `page.getByRole('button', { name: 'Checkout' })` — survives CSS refactoring.

### No Page Object Model
**What it is**: Locators and page interactions directly in test files, duplicated across tests.
**What breaks**: Form label changes → 15 tests fail, each with a different locator to fix.
**Fix**: Page Objects. Change locator in one place, all tests updated.

### Hard-Coded Sleeps
**What it is**: `await page.waitForTimeout(3000)` — wait 3 seconds and hope it loads.
**What breaks**: Slow CI = timeouts. Fast CI = false confidence. Adds seconds to every test.
**Fix**: Wait for response, network idle, or specific element visibility. Playwright's auto-waiting handles most cases.

---

## Quick Reference

```
Retry: retries: 2 in CI (env.CI), 0 locally
Trace: 'on-first-retry' — captures video+network+screenshots of failures
Locators (priority): getByRole → getByLabel → getByText → getByTestId
Auth reuse: globalSetup saves storageState, tests start authenticated
Network wait: waitForResponse() not waitForTimeout()
Page Objects: one class per page, locators defined in constructor
API mocking: page.route() for isolated payment/external API tests
Parallel: fullyParallel: true, 4 workers in CI
```
