# Test Data Management

## When to load
Load when setting up test factories, discussing fixture strategies, choosing between inline data
and generated data, or structuring test data for a new project.

## Strategies Overview

| Approach | Best for | Downside |
|----------|----------|----------|
| Factories (Fishery) | Unit + integration tests | Requires schema knowledge |
| Static fixtures (JSON files) | Snapshot tests, stable reference data | Go stale, hard to vary |
| Database seeds | Integration tests with known starting state | Slow to reset, coupling |
| Inline data | Simple units, one-off scenarios | Duplication across test files |
| Faker.js | Realistic data generation | Non-deterministic by default |

**Rule: prefer factories over fixtures. Fixtures accumulate drift; factories stay in sync with schema.**

## Fishery Factory Setup

```bash
npm install --save-dev fishery @faker-js/faker
```

```typescript
// src/test/factories/index.ts — export all factories from one place
export { userFactory } from './user.factory';
export { productFactory } from './product.factory';
export { orderFactory, orderItemFactory } from './order.factory';
```

```typescript
// src/test/factories/user.factory.ts
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import type { User } from '../../types';

export const userFactory = Factory.define<User>(({ sequence }) => ({
  id: faker.string.uuid(),
  email: faker.internet.email(),
  name: faker.person.fullName(),
  role: 'customer' as const,
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date(),
}));

// Trait: admin user
export const adminUserFactory = userFactory.params({ role: 'admin' });

// Trait: inactive user
export const inactiveUserFactory = userFactory.params({ isActive: false });
```

```typescript
// src/test/factories/order.factory.ts
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import type { Order, OrderItem } from '../../types';

export const orderItemFactory = Factory.define<OrderItem>(() => ({
  id: faker.string.uuid(),
  productId: faker.string.uuid(),
  productName: faker.commerce.productName(),
  quantity: faker.number.int({ min: 1, max: 5 }),
  unitPrice: parseFloat(faker.commerce.price({ min: 5, max: 200 })),
}));

export const orderFactory = Factory.define<Order>(({ associations }) => {
  const items = associations.items ?? orderItemFactory.buildList(2);
  const total = items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);

  return {
    id: faker.string.uuid(),
    userId: associations.user?.id ?? faker.string.uuid(),
    status: 'pending' as const,
    total,
    items,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
});
```

### Factory usage patterns

```typescript
// Basic: minimal object with defaults
const user = userFactory.build();

// Override specific fields
const premiumUser = userFactory.build({ role: 'premium', isActive: true });

// Trait shorthand
const admin = adminUserFactory.build();

// List
const users = userFactory.buildList(5);

// Association: order with specific user
const user = userFactory.build();
const order = orderFactory.build({}, { associations: { user } });
// order.userId === user.id

// Sequence: auto-incrementing for unique fields
const emailFactory = Factory.define<string>(({ sequence }) =>
  `user${sequence}@example.com`
);
```

## Deterministic Faker

By default Faker generates random data — tests pass today, fail tomorrow because `faker.number.int()` generates a different boundary value.

```typescript
// Fix: seed Faker for deterministic output in tests
import { faker } from '@faker-js/faker';

beforeEach(() => {
  faker.seed(12345);  // Same seed = same values every time
});

// Or: set globally in vitest setup file
// src/test/setup.ts
faker.seed(42);

// Even better: don't rely on Faker for boundary testing
// Use explicit values for any logic that depends on the value
const order = orderFactory.build({ total: 100.00 });  // Explicit, not random
expect(applyTax(order.total, 0.10)).toBe(110.00);     // Not dependent on random total
```

## Static Fixtures: When to Use Them

Static fixtures (JSON/TS files) are appropriate for:
- Snapshot tests where you want to compare against a known output
- Stable reference data that doesn't change (country codes, currency list)
- Large complex nested data structures that would be verbose as factory builds

```typescript
// src/test/fixtures/invoice-response.fixture.json
// Use for: API response snapshot testing

// src/test/fixtures/country-codes.fixture.ts
export const COUNTRY_CODES = ['US', 'GB', 'DE', 'FR', 'JP'] as const;
// Use for: tests that enumerate valid values

// AVOID: using fixtures for entity data that has logic-dependent fields
// If the fixture needs to match DB state, use factories instead
```

## Quick reference

```
Primary tool        : Fishery factories — dynamic, typed, override-friendly
Faker seeding       : faker.seed(42) in beforeEach for deterministic output
Static fixtures     : only for snapshot tests and stable reference data
DB factories        : see test-data-isolation.md for create* helpers and cleanup
Never              : module-level shared DB state mutated across tests
```
