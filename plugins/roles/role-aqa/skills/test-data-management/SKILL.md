---
name: test-data-management
description: |
  Test data management with factory patterns (Faker.js, Fishery, Factory Bot),
  database seeding, test data isolation (transactions, cleanup), anonymization
  and masking for production data, synthetic data generation, fixture management,
  and shared test state risks.
  Use when designing test data strategies or debugging data-related test failures.
allowed-tools: Read, Grep, Glob, Bash
---

You are a test data management specialist.

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
- Use sequences for unique fields to avoid collisions in parallel tests.
- Define traits for common variations (admin user, expired subscription, pending order).
- Nest factories for related objects (user with orders, order with line items).

## Database Seeding

- Seed scripts create a known baseline state for integration and E2E tests.
- Keep seed data minimal. Only create what tests actually need.
- Version seed scripts alongside application code. Schema changes must update seeds.
- Use idempotent seeds: running twice should not create duplicates.

## Test Data Isolation

### Transaction Rollback
- Wrap each test in a transaction and roll back after. Fastest cleanup method.
- Limitation: does not work when the app uses its own transactions or multiple connections.

### Cleanup After Each Test
- Use test-specific markers (test_run_id, email domain) to scope cleanup.
- Order cleanup by foreign key dependencies (child tables first).

### Schema Isolation
- Separate database schemas per test suite. Eliminates all data collision risks.
- Best for parallel execution across multiple CI nodes. Slower to set up.

## Shared Test State Risks

Shared mutable state is the number one cause of flaky tests.
- **Symptoms**: Tests pass alone, fail together. Results change with execution order.
- **Prevention**: Each test creates its own data. Use unique identifiers per test. Run in random order (`jest --randomize`). Never assume data from another test exists.

## Anonymization and Masking

| Field | Technique | Example |
|-------|-----------|---------|
| Email | Domain replacement | `user@co.com` -> `user1@test.invalid` |
| Name | Faker replacement | `John Smith` -> `Alice Johnson` |
| Phone | Format preservation | `+1-555-123-4567` -> `+1-555-000-0001` |
| SSN/CC | Full replacement | Replace with test values or tokens |

- Anonymize in a separate pipeline. Never expose production data directly to test environments.
- Maintain referential integrity: same source ID maps to same anonymized ID.

## Synthetic Data Generation

- Generate data that statistically resembles production without using real records.
- Generate edge cases: Unicode names, max-length fields, special characters.
- Seed the random generator for reproducibility: `faker.seed(12345)`.

## Fixture Management

- Use fixtures for data that must be exactly the same across all test runs.
- Keep fixtures small and focused. One fixture per scenario, not one giant file.
- Prefer factories over fixtures for most tests. Use fixtures for snapshot and contract testing.
