---
name: test-strategy
description: |
  Test strategy: test pyramid with time budgets (unit <5ms, integration <500ms, e2e <30s),
  coverage targets (business logic >90%, UI >60%), Fishery factories, behavior vs implementation
  testing, test naming conventions, CI parallelization, flaky test handling.
  Use when designing test strategy, reviewing test coverage, choosing test types.
allowed-tools: Read, Grep, Glob
---

# Test Strategy

## When to Use This Skill
- Designing a testing strategy for a new service
- Reviewing test coverage and identifying gaps
- Choosing between unit, integration, and e2e tests
- Setting up test infrastructure (factories, fixtures)
- Handling flaky tests in CI

## Core Principles

1. **Test behavior, not implementation** — tests should survive refactoring
2. **Test pyramid: many unit, some integration, few e2e** — balance speed and confidence
3. **Each test must have ONE reason to fail** — test isolation prevents mysterious failures
4. **Fast tests run; slow tests are skipped** — if CI takes >15 minutes, people push and pray
5. **Factories over fixtures** — dynamic test data beats static snapshots

---

## Patterns ✅

### Test Pyramid with Time Budgets

```
Test Pyramid:

        ╱◥◤╲
       ╱ E2E ╲        2–10%  |  <30s each  | Run on main branch only
      ╱───────╲
     ╱  Integr. ╲     20–30% |  <500ms each | Run on every PR
    ╱─────────────╲
   ╱  Unit Tests  ╲  60–80%  |  <5ms each  | Run on every save
  ╱─────────────────╲

Coverage targets by layer:
  Business logic (domain services):  >90%
  Data access layer:                  >80%
  HTTP handlers/controllers:          >70%
  UI components:                      >60%
  External integrations:              Contract tests (not unit)
```

### Test Naming Convention

```typescript
// Format: it('should [action] when [condition]')
// or:      it('[action] given [condition]')

// Good names — tell a story
it('should decline payment when card is expired')
it('should send welcome email when user registers with valid email')
it('should return 404 when order does not exist')
it('should not allow two users to claim the same promo code simultaneously')

// Bad names — describe implementation
it('should call chargeCard')
it('tests the payment function')
it('paymentService')

// Group tests meaningfully
describe('OrderService', () => {
  describe('createOrder', () => {
    it('should create order with correct total when items have different prices')
    it('should reserve inventory when order is created')
    it('should throw InsufficientInventoryError when item is out of stock')
    it('should roll back inventory reservation when payment fails')
  })

  describe('cancelOrder', () => {
    it('should cancel order and release inventory when status is pending')
    it('should throw InvalidStateError when trying to cancel a completed order')
  })
})
```

### Test Factories with Fishery

```typescript
// factories/order.factory.ts
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import type { Order, OrderItem, User } from '../types';

export const userFactory = Factory.define<User>(() => ({
  id: faker.string.uuid(),
  email: faker.internet.email(),
  name: faker.person.fullName(),
  role: 'customer',
  createdAt: new Date(),
}));

export const orderItemFactory = Factory.define<OrderItem>(() => ({
  id: faker.string.uuid(),
  productId: faker.string.uuid(),
  productName: faker.commerce.productName(),
  quantity: faker.number.int({ min: 1, max: 5 }),
  unitPrice: parseFloat(faker.commerce.price({ min: 5, max: 500 })),
}));

export const orderFactory = Factory.define<Order>(({ associations }) => ({
  id: faker.string.uuid(),
  userId: associations.user?.id ?? faker.string.uuid(),
  status: 'pending',
  total: faker.number.float({ min: 10, max: 1000, fractionDigits: 2 }),
  items: orderItemFactory.buildList(2),
  createdAt: new Date(),
  updatedAt: new Date(),
}));

// Usage in tests
const order = orderFactory.build();                      // Minimal
const paidOrder = orderFactory.build({ status: 'paid' }); // Override specific fields
const orders = orderFactory.buildList(5);                 // Multiple
const orderWithUser = orderFactory.associations({ user: userFactory.build() });
```

### Vitest + Testing Library Setup

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,           // No need to import describe/it/expect
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80,
      },
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.d.ts',
        'src/migrations/**',
        'src/seed/**',
      ],
    },
    // Parallel execution
    pool: 'threads',
    poolOptions: { threads: { minThreads: 1, maxThreads: 4 } },
  },
});
```

```typescript
// Behavior test — tests what the code does, not how
describe('calculateOrderTotal', () => {
  it('should apply percentage discount to subtotal', () => {
    const items = [
      { price: 100, quantity: 2 },  // 200
      { price: 50, quantity: 1 },   // 50
    ];
    const discount = { type: 'percentage', value: 10 };

    const result = calculateOrderTotal(items, discount);

    expect(result.subtotal).toBe(250);
    expect(result.discountAmount).toBe(25);
    expect(result.total).toBe(225);
  });

  // Parametrized tests with it.each
  it.each([
    [100, 2, 50, 1, { type: 'flat', value: 20 }, 230],
    [100, 1, 0,  0, { type: 'percentage', value: 0 }, 100],
    [50,  3, 0,  0, null, 150],
  ])('item1=%d×%d + item2=%d×%d with discount=%j = %d', (
    price1, qty1, price2, qty2, discount, expected
  ) => {
    const items = [
      ...(qty1 > 0 ? [{ price: price1, quantity: qty1 }] : []),
      ...(qty2 > 0 ? [{ price: price2, quantity: qty2 }] : []),
    ];
    expect(calculateOrderTotal(items, discount).total).toBe(expected);
  });
});
```

---

## Anti-Patterns ❌

### Testing Implementation Details
**What it is**: Assertions on private methods, internal state, mock call counts.
**What breaks**: Every refactoring breaks tests even when behavior is correct. Tests become a liability, not an asset.
**Fix**: Test inputs and outputs only. If a function returns the right result, don't care how it got there.

### Shared Mutable State Between Tests
**What it is**: Module-level variables mutated in one test, affecting subsequent tests.
**What breaks**: Tests pass in isolation but fail in sequence. Test order matters. `--no-parallel` required. CI becomes non-deterministic.
**Fix**: `beforeEach`/`afterEach` to reset state. Factory functions that create fresh instances.

### Testing Third-Party Libraries
**What it is**: Writing tests that verify Prisma generates the right SQL, or that Express routes correctly.
**What breaks**: You're testing your dependencies, not your code. Time wasted. No value.
**Fix**: Trust your dependencies. Mock at the boundary. Test your code's interaction with the dependency, not the dependency itself.

### Flaky Tests Left in CI
**What it is**: Tests that fail intermittently, retried until they pass.
**What breaks**: CI becomes unreliable. Engineers dismiss failures. Real bugs hidden by flaky noise.
**Fix**: Quarantine flaky tests immediately (add `skip` + create ticket). Fix or delete within 1 week.

---

## Quick Reference

```
Unit test time: <5ms — if slower, it's integration
Integration test time: <500ms — if slower, add parallelism
E2e test time: <30s each — if slower, it's a problem
Coverage targets: business logic >90%, controllers >70%, UI >60%
Test naming: 'should [action] when [condition]'
Factories: fishery — dynamic data, override specific fields
Flaky tests: quarantine immediately, fix or delete within 1 week
Parallelism: threads pool in Vitest, shard flag in Playwright
```
