# Playwright Core

## When to load
When setting up Playwright, writing locators, using fixtures, trace viewer, codegen, sharding CI, API testing via request context, component testing, or visual comparisons.

## Core Features
- **Auto-wait**: No manual `waitFor` needed. Playwright waits for elements to be actionable (visible, stable, enabled, editable). No more `sleep()` calls.
- **Trace viewer**: `npx playwright show-trace trace.zip`. Captures DOM snapshots, network requests, console logs, and screenshots at every step. Essential for debugging CI failures.
- **Codegen**: `npx playwright codegen <url>` records user interactions and generates test code. Use as a starting point; refactor into Page Objects.
- **Network interception**: `page.route()` to mock APIs, simulate errors (500s, timeouts), and test loading states.

## Locator Strategy (in order of preference)
```typescript
// 1. Role-based (most resilient, accessibility-aligned)
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByRole('heading', { name: 'Order Confirmation' });

// 2. Label-based
await page.getByLabel('Email address').fill('user@test.com');

// 3. Placeholder
await page.getByPlaceholder('Search products').fill('laptop');

// 4. Text content
await page.getByText('Terms and Conditions').click();

// 5. Test ID (when semantic locators are not feasible)
await page.getByTestId('checkout-submit').click();

// 6. CSS/XPath (last resort - brittle)
await page.locator('[data-testid="cart-total"]');
```

## Fixtures
```typescript
import { test as base } from '@playwright/test';

type Fixtures = { authenticatedPage: Page; testUser: User };

export const test = base.extend<Fixtures>({
  testUser: async ({ request }, use) => {
    const user = await createUserViaAPI(request);
    await use(user);
    await deleteUserViaAPI(request, user.id);
  },
  authenticatedPage: async ({ page, testUser }, use) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill(testUser.email);
    await page.getByLabel('Password').fill(testUser.password);
    await page.getByRole('button', { name: 'Sign in' }).click();
    await use(page);
  },
});
```

## test.step for Structured Reporting
```typescript
test('checkout flow', async ({ page }) => {
  await test.step('Add item to cart', async () => {
    await page.goto('/products/laptop');
    await page.getByRole('button', { name: 'Add to Cart' }).click();
  });
  await test.step('Complete checkout', async () => {
    await page.goto('/checkout');
    await page.getByLabel('Card number').fill('4242424242424242');
    await page.getByRole('button', { name: 'Place Order' }).click();
  });
  await test.step('Verify confirmation', async () => {
    await expect(page.getByRole('heading', { name: 'Order Confirmed' })).toBeVisible();
  });
});
```

## Projects (Multi-browser and Multi-config)
```typescript
export default defineConfig({
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 7'] } },
    { name: 'mobile-safari', use: { ...devices['iPhone 14'] } },
    {
      name: 'authenticated',
      use: { storageState: 'playwright/.auth/user.json' },
      dependencies: ['setup'],
    },
  ],
});
```

## Sharding for CI Distribution
```yaml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/4
  - uses: actions/upload-artifact@v4
    with:
      name: blob-report-${{ matrix.shard }}
      path: blob-report/
# Merge reports after all shards complete
- run: npx playwright merge-reports --reporter html ./all-blob-reports
```

## API Testing with Playwright
```typescript
test('create user via API', async ({ request }) => {
  const response = await request.post('/api/users', {
    data: { email: 'newuser@test.com', name: 'New User' },
  });
  expect(response.status()).toBe(201);
  const user = await response.json();
  expect(user).toMatchObject({ email: 'newuser@test.com' });
});
```

## Component Testing
```typescript
import { test, expect } from '@playwright/experimental-ct-react';
import { Button } from './Button';

test('button fires onClick', async ({ mount }) => {
  let clicked = false;
  const component = await mount(
    <Button onClick={() => { clicked = true; }}>Click me</Button>
  );
  await component.click();
  expect(clicked).toBe(true);
});
```

## Visual Comparisons
```typescript
test('product page matches snapshot', async ({ page }) => {
  await page.goto('/products/laptop-pro');
  await expect(page).toHaveScreenshot('product-page.png', {
    maxDiffPixelRatio: 0.02,
    mask: [page.locator('.price'), page.locator('.stock-count')],
    animations: 'disabled',
  });
});
```

## Playwright MCP Integration
```bash
npx @playwright/mcp@latest
```
The Playwright MCP server enables AI-assisted browser automation during test development. Use to:
- Explore an unfamiliar application before writing tests.
- Discover the most resilient locators from live DOM (accessibility snapshots).
- Verify page accessibility structure.
- Generate baseline test code to refactor into Page Objects.
