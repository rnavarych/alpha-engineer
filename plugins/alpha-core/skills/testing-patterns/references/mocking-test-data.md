# Mocking and Test Data

## When to load
Load when choosing test doubles, setting up mocking strategies, or managing test data with factories and fakers.

## Test Doubles Hierarchy
- **Stubs**: Return fixed values (use for queries — "what does this return?")
- **Mocks**: Verify interactions (use for commands — "was this called?")
- **Fakes**: Simplified working implementations (in-memory DB, fake API server, fake filesystem)
- **Spies**: Record calls without changing behavior — verify after the fact
- **Dummies**: Placeholder objects passed but never used (satisfy parameter requirements)

## When to Mock vs When to Use Fakes

| Scenario | Preferred Double | Rationale |
|----------|-----------------|-----------|
| External API calls | Fake (MSW, WireMock) | Validates full request/response cycle |
| Database queries | Fake (in-memory DB, Testcontainers) | Tests actual SQL/ORM behavior |
| Time/clock | Stub | Deterministic, simple |
| Email/SMS sending | Mock | Verify it was called, don't actually send |
| File system | Fake (memfs, in-memory FS) | Avoid cleanup, faster |
| Logging | Spy | Verify log output without suppressing |
| Internal service class | Don't mock | Tests become coupled to implementation |

## Dependency Injection for Testability
```typescript
// BAD -- hard to test, tightly coupled
class OrderService {
  async createOrder(items: Item[]) {
    const db = new PostgresDatabase(); // hard dependency
    await db.insert('orders', items);
  }
}

// GOOD -- injectable dependency
class OrderService {
  constructor(private readonly db: Database) {} // interface
  async createOrder(items: Item[]) {
    await this.db.insert('orders', items);
  }
}

// In test:
const fakeDb = new InMemoryDatabase();
const service = new OrderService(fakeDb);
```

## Test Data Management

### Factories
- **Fishery** (TypeScript): `Factory.define<User>(() => ({ name: faker.person.fullName(), email: faker.internet.email() }))`
- **FactoryBot** (Ruby): `FactoryBot.define { factory :user { name { Faker::Name.name } } }`
- **factory_boy** (Python): `class UserFactory(factory.django.DjangoModelFactory): class Meta: model = User`
- **Instancio** (Java): `Instancio.of(User.class).set(field(User::getEmail), "test@example.com").create()`
- **gofakeit** (Go): `gofakeit.Person()`, `gofakeit.Email()`

### Faker Libraries
- **@faker-js/faker** (JS/TS): `faker.person.fullName()`, `faker.internet.email()`, `faker.commerce.price()`
- **Faker** (Python): `fake.name()`, `fake.email()`, `fake.address()`
- **JavaFaker / Datafaker** (Java): `faker.name().fullName()`, `faker.internet().emailAddress()`
- **gofakeit** (Go): `gofakeit.Name()`, `gofakeit.Email()`

### Database Seeding Patterns
- Seed per-test with factory functions — each test creates its own data
- Use transactions for isolation — rollback after each test
- Truncate tables between test suites, not between individual tests (performance)
- Never rely on seeded data order — use explicit assertions on specific records
- Use `beforeEach`/`setUp` for common fixtures, not global seeds

## Flaky Test Prevention and Management

### Common Causes and Fixes
| Cause | Fix |
|-------|-----|
| Timing dependencies | Use explicit waits, not `sleep()`. Playwright: `waitForSelector`, `waitForResponse` |
| Shared test state | Isolate tests — each test creates and cleans up its own data |
| Non-deterministic data | Use factories with deterministic seeds, freeze time |
| External service dependency | Mock external services, use Testcontainers for infrastructure |
| Race conditions in async code | Use `waitFor` patterns, avoid polling with `setTimeout` |
| Order-dependent tests | Run tests in random order (Jest `--randomize`, pytest `pytest-randomly`) |
| Timezone sensitivity | Always use UTC in tests, mock timezone where needed |

### Flaky Test Management
- Quarantine flaky tests — mark as `skip` with a ticket to fix, don't delete
- Track flaky test rate in CI dashboard
- Set a team policy: flaky tests must be fixed within 1 sprint or removed
- Use test retry as a temporary mitigation, not a permanent solution
