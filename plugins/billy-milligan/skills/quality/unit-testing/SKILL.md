---
name: unit-testing
description: |
  Unit testing patterns: Vitest config with v8 coverage, Testing Library behavior testing,
  MSW for HTTP mocking (vs jest.mock), it.each parametrized tests, spies vs mocks vs stubs,
  testing async code, snapshot testing guidelines. Use when writing unit and component tests.
allowed-tools: Read, Grep, Glob
---

# Unit Testing Patterns

## When to Use This Skill
- Setting up Vitest or Jest for a new project
- Writing unit tests for business logic
- Component testing with Testing Library
- Mocking HTTP requests with MSW
- Parametrized tests with it.each

## Core Principles

1. **Test behavior, not implementation** — what does it return/do, not how
2. **MSW over jest.mock** — mock at network level, not module level
3. **One assertion per test** — single reason to fail per test
4. **Arrange-Act-Assert** — consistent structure in every test
5. **No test interdependence** — each test must run independently

---

## Patterns ✅

### Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';  // Only if testing React

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,         // No import { describe, it, expect } needed
    environment: 'node',   // or 'jsdom' for React component tests
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',      // Faster than babel coverage
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: [
        'src/**/*.test.ts',
        'src/**/*.spec.ts',
        'src/**/index.ts',
        'src/types/**',
        'src/generated/**',
      ],
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80,
      },
    },
    // Run tests in parallel
    pool: 'threads',
    poolOptions: { threads: { maxThreads: 4 } },
  },
});

// src/test/setup.ts
import '@testing-library/jest-dom';  // For React component assertions
import { server } from './msw-server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Testing Business Logic (Pure Functions)

```typescript
// src/domain/pricing.test.ts
import { calculateOrderTotal, applyDiscount } from './pricing';

describe('calculateOrderTotal', () => {
  // Arrange-Act-Assert pattern
  it('should sum item prices with quantities', () => {
    // Arrange
    const items = [
      { unitPrice: 100, quantity: 2 },  // 200
      { unitPrice: 50, quantity: 3 },   // 150
    ];

    // Act
    const total = calculateOrderTotal(items);

    // Assert
    expect(total).toBe(350);
  });

  it('should return 0 for empty items', () => {
    expect(calculateOrderTotal([])).toBe(0);
  });

  // Parametrized test — DRY for similar scenarios
  it.each([
    [{ type: 'percentage', value: 10 }, 100, 90],
    [{ type: 'percentage', value: 0 }, 100, 100],
    [{ type: 'flat', value: 20 }, 100, 80],
    [{ type: 'flat', value: 150 }, 100, 0],   // Can't go negative
  ])('applies %o discount to %d → %d', (discount, amount, expected) => {
    expect(applyDiscount(amount, discount)).toBe(expected);
  });
});
```

### MSW for HTTP Mocking (Better than jest.mock)

```typescript
// src/test/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/products/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      name: 'Test Product',
      price: 99.99,
    });
  }),

  http.post('/api/orders', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({
      id: 'ord_123',
      status: 'pending',
      ...body,
    }, { status: 201 });
  }),
];

// src/test/msw-server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';
export const server = setupServer(...handlers);
```

```typescript
// Why MSW over jest.mock?
// jest.mock mocks the module — breaks if internal implementation changes
// MSW mocks the network — tests the actual HTTP client code

// With MSW: test the real fetch/axios code
it('should fetch product details', async () => {
  const product = await productService.getProduct('prod_123');
  expect(product.name).toBe('Test Product');
  // The actual HTTP request was made and intercepted by MSW
});

// Override handler for specific test
it('should handle product not found', async () => {
  server.use(
    http.get('/api/products/:id', () => {
      return HttpResponse.json(
        { error: { code: 'NOT_FOUND', message: 'Product not found' } },
        { status: 404 }
      );
    })
  );
  await expect(productService.getProduct('nonexistent')).rejects.toThrow('Product not found');
});
```

### Testing Async Code

```typescript
// Always await async assertions
it('should create order and return with id', async () => {
  const result = await orderService.create({
    userId: 'usr_123',
    items: [{ productId: 'prod_456', quantity: 2 }],
  });

  expect(result.id).toBeDefined();
  expect(result.status).toBe('pending');
});

// Testing rejected promises
it('should throw when user does not exist', async () => {
  await expect(
    orderService.create({ userId: 'nonexistent', items: [] })
  ).rejects.toThrow('User not found');
});

// Or with try/catch for more specific assertions
it('should throw UserNotFoundError with userId in message', async () => {
  try {
    await orderService.create({ userId: 'usr_missing', items: [] });
    // Should not reach here
    expect.fail('Expected error was not thrown');
  } catch (err) {
    expect(err).toBeInstanceOf(UserNotFoundError);
    expect((err as UserNotFoundError).message).toContain('usr_missing');
  }
});
```

### Testing Library for React Components

```tsx
// src/components/OrderCard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { OrderCard } from './OrderCard';

describe('OrderCard', () => {
  const defaultOrder = {
    id: 'ord_123',
    status: 'pending',
    total: 150.00,
    createdAt: new Date('2024-01-15'),
  };

  it('should display order status and total', () => {
    render(<OrderCard order={defaultOrder} />);

    expect(screen.getByText('pending')).toBeInTheDocument();
    expect(screen.getByText('$150.00')).toBeInTheDocument();
  });

  it('should call onCancel when cancel button clicked', async () => {
    const user = userEvent.setup();
    const onCancel = vi.fn();

    render(<OrderCard order={defaultOrder} onCancel={onCancel} />);

    await user.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalledWith('ord_123');
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it('should not show cancel button for completed orders', () => {
    render(<OrderCard order={{ ...defaultOrder, status: 'completed' }} />);
    expect(screen.queryByRole('button', { name: /cancel/i })).not.toBeInTheDocument();
  });
});
```

---

## Anti-Patterns ❌

### Testing Implementation Details
```typescript
// Wrong — brittle, breaks on refactor
it('should call calculateTotal with correct args', () => {
  const spy = vi.spyOn(pricingModule, 'calculateTotal');
  orderService.create(input);
  expect(spy).toHaveBeenCalledWith(input.items);  // Implementation detail
});

// Correct — test the outcome
it('should set correct total on created order', async () => {
  const order = await orderService.create(input);
  expect(order.total).toBe(expectedTotal);  // What matters to the user
});
```

### Mocking Everything
**What it is**: Every external dependency mocked with `jest.mock()`.
**What breaks**: Test passes but system integration is broken. You're testing mocks, not your code.
**Fix**: Real dependencies where possible (Testcontainers for DB, MSW for HTTP). Mock only for third-party services with side effects (email, SMS, Stripe).

### No Cleanup After Tests
**What it is**: Tests mutate shared state, don't clean up.
**What breaks**: Test A passes, Test B fails because A left database dirty. Tests only pass in certain order.
**Fix**: `beforeEach` database reset, or database transactions rolled back after each test.

---

## Quick Reference

```
Vitest: globals: true, pool: 'threads', v8 coverage provider
MSW: mock at network level — better than jest.mock for HTTP
Testing Library: getByRole > getByLabel > getByText > getByTestId
Parametrized: it.each([...])('description %o', (arg) => { ... })
Async: always await — never .resolves/.rejects without await
AAA pattern: Arrange (setup), Act (call function), Assert (expect)
Coverage thresholds: 80/75/80/80 (statements/branches/functions/lines)
userEvent: prefer over fireEvent — simulates real user interaction
```
