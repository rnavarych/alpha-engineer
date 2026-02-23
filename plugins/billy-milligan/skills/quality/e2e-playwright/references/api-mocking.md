# API Mocking in E2E Tests

## When to load
Load when mocking API responses in Playwright tests: route interception, MSW, mock data.

## Playwright Route Interception

```typescript
// Mock a specific API endpoint
test('displays orders from API', async ({ page }) => {
  await page.route('**/api/orders', (route) => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        orders: [
          { id: '1', total: 4999, status: 'completed' },
          { id: '2', total: 1299, status: 'pending' },
        ],
      }),
    });
  });

  await page.goto('/orders');
  await expect(page.getByText('$49.99')).toBeVisible();
  await expect(page.getByText('$12.99')).toBeVisible();
});

// Mock error responses
test('shows error state on API failure', async ({ page }) => {
  await page.route('**/api/orders', (route) => {
    route.fulfill({ status: 500, body: JSON.stringify({ error: 'Server error' }) });
  });

  await page.goto('/orders');
  await expect(page.getByText('Something went wrong')).toBeVisible();
});

// Intercept and modify real responses
test('modify real API response', async ({ page }) => {
  await page.route('**/api/user', async (route) => {
    const response = await route.fetch();
    const json = await response.json();
    json.featureFlags.newCheckout = true; // Override flag
    await route.fulfill({ response, body: JSON.stringify(json) });
  });
  await page.goto('/');
});
```

## Wait for API calls

```typescript
// Wait for specific request to complete
test('submit order', async ({ page }) => {
  await page.goto('/checkout');

  const [response] = await Promise.all([
    page.waitForResponse('**/api/orders'),
    page.getByRole('button', { name: 'Place Order' }).click(),
  ]);

  expect(response.status()).toBe(201);
  await expect(page.getByText('Order confirmed')).toBeVisible();
});
```

## Mock Data Factories

```typescript
// test-utils/factories.ts
export function buildOrder(overrides = {}) {
  return {
    id: crypto.randomUUID(),
    userId: 'user-1',
    total: 4999,
    status: 'pending',
    items: [{ name: 'Widget', qty: 1, price: 4999 }],
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}

// Usage in test
await page.route('**/api/orders', (route) => {
  route.fulfill({
    body: JSON.stringify({ orders: [buildOrder({ status: 'completed' })] }),
  });
});
```

## Anti-patterns
- Mocking ALL APIs → miss real integration bugs; mock only what you need
- Hardcoded mock data inline → use factories for maintainability
- Not testing error states → only happy path coverage
- `page.waitForTimeout()` instead of `waitForResponse()` → flaky

## Quick reference
```
page.route(): intercept and mock any network request
route.fulfill(): return custom response
route.fetch(): get real response, modify it, return
page.waitForResponse(): wait for specific API call
Factories: buildOrder(), buildUser() for consistent test data
Mock errors: test 400, 401, 403, 404, 500 states
```
