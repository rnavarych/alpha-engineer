# Playwright Patterns

## When to load
Load when writing E2E tests with Playwright: page objects, fixtures, selectors, assertions.

## Page Object Model

```typescript
// pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Sign in' }).click();
    await this.page.waitForURL('/dashboard');
  }
}

// tests/login.spec.ts
test('successful login', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@test.com', 'password123');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

## Auth Fixture (reusable login state)

```typescript
// fixtures.ts
import { test as base } from '@playwright/test';

type Fixtures = { authenticatedPage: Page };

export const test = base.extend<Fixtures>({
  authenticatedPage: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'tests/.auth/user.json',
    });
    const page = await context.newPage();
    await use(page);
    await context.close();
  },
});

// Generate auth state once in global setup
// playwright.config.ts → globalSetup: './global-setup.ts'
```

## Selector Priority

```
1. getByRole('button', { name: 'Submit' })  — best: accessible
2. getByLabel('Email')                        — form fields
3. getByText('Welcome')                       — visible text
4. getByTestId('order-card')                  — data-testid fallback
5. page.locator('.class')                     — last resort
```

## Auto-waiting & Assertions

```typescript
// Playwright auto-waits for elements — no explicit waits needed
await expect(page.getByText('Order confirmed')).toBeVisible();
await expect(page.getByRole('table')).toContainText('$49.99');

// Wait for network idle after navigation
await page.goto('/orders', { waitUntil: 'networkidle' });

// Never do this:
// await page.waitForTimeout(3000); // FLAKY
```

## Anti-patterns
- `page.waitForTimeout()` → flaky; use auto-waiting assertions instead
- CSS selectors as primary strategy → break on refactor
- No Page Object Model → duplicated selectors across tests
- Testing against production API → use mocks or staging

## Quick reference
```
Selectors: getByRole > getByLabel > getByText > getByTestId
Auto-wait: assertions wait up to 30s by default
Auth: storageState for reusable login across tests
Page Objects: encapsulate selectors + actions per page
No hard sleeps: use expect().toBeVisible() instead
Trace: trace: 'on-first-retry' for debugging failures
```
