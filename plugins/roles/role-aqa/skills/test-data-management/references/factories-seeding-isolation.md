# Factory Patterns, Database Seeding, and Test Data Isolation

## When to load
When setting up Fishery/Faker factories, writing seed scripts, choosing a data isolation strategy (transaction rollback vs cleanup vs schema isolation), or debugging flaky tests caused by shared state.

## Factory Patterns

### Faker.js + Fishery (TypeScript)
```typescript
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';

const userFactory = Factory.define<User>(({ sequence }) => ({
  id: faker.string.uuid(),
  email: `user-${sequence}@test.com`,
  name: faker.person.fullName(),
  role: 'user',
}));

const user = userFactory.build({ role: 'admin' });
const users = userFactory.buildList(5);
```

### Factory Design Principles
- Factories produce valid objects by default. Override only what the test cares about.
- Use sequences for unique fields to avoid collisions in parallel test runs.
- Define traits for common variations: admin user, expired subscription, pending order.
- Nest factories for related objects: user with orders, order with line items.

## Database Seeding
- Seed scripts create a known baseline state for integration and E2E tests.
- Keep seed data minimal — only create what tests actually need.
- Version seed scripts alongside application code. Schema changes must update seeds.
- Use idempotent seeds: running twice should not create duplicates.

## Test Data Isolation

### Transaction Rollback
- Wrap each test in a transaction and roll back after. Fastest cleanup method.
- Limitation: does not work when the app uses its own transactions or multiple connections.

### Cleanup After Each Test
- Use test-specific markers (test_run_id, email domain) to scope cleanup.
- Order cleanup by foreign key dependencies — child tables before parent tables.

### Schema Isolation
- Separate database schemas per test suite. Eliminates all data collision risks.
- Best for parallel execution across multiple CI nodes. Slower setup cost.

## Shared Test State Risks

Shared mutable state is the number one cause of flaky tests.
- **Symptoms**: Tests pass in isolation, fail together. Results change with execution order.
- **Prevention**: Each test creates its own data. Use unique identifiers per test. Run in random order (`jest --randomize`). Never assume data from another test exists.
