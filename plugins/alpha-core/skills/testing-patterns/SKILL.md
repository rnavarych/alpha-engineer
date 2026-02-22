---
name: testing-patterns
description: |
  Provides testing strategies: test pyramid, TDD/BDD, unit/integration/E2E patterns,
  mocking strategies, test data factories, snapshot testing, and mutation testing.
  Use when designing test strategies, writing tests, or improving test coverage.
allowed-tools: Read, Grep, Glob, Bash
---

You are a testing specialist. Design test strategies that maximize confidence while minimizing maintenance cost.

## Test Pyramid

```
    /  E2E  \        Few, slow, expensive
   /________\
  / Integration \    Moderate count
 /______________\
/   Unit Tests   \   Many, fast, cheap
/________________\
```

### Ratios by Project Type

| Project Type | Unit | Integration | E2E |
|-------------|------|-------------|-----|
| **Web Application** | 60% | 25% | 15% |
| **REST/GraphQL API** | 70% | 25% | 5% |
| **Library/SDK** | 80% | 15% | 5% |
| **CLI Tool** | 70% | 20% | 10% |
| **Microservice** | 60% | 30% | 10% |
| **Data Pipeline** | 50% | 40% | 10% |

- **Unit tests**: Test individual functions/methods in isolation. Fast (<100ms each), deterministic, no I/O.
- **Integration tests**: Test component interactions -- database, API, service boundaries, message queues.
- **E2E tests**: Test complete user flows -- browser automation, full system under test.

## Unit Testing Principles
- Test behavior, not implementation -- if refactoring breaks tests without changing behavior, tests are too coupled
- One assertion per logical concept (multiple asserts are fine if they verify one behavior)
- Follow AAA pattern: Arrange, Act, Assert (or Given/When/Then for BDD)
- Use descriptive test names: `should_return_error_when_email_is_invalid` or `test_order_total_includes_tax`
- Keep tests independent -- no shared mutable state, no test ordering dependencies
- Aim for <100ms per unit test, <10ms is ideal
- Test edge cases explicitly: null/nil, empty collections, boundary values, negative numbers, max values

### Unit Testing by Language

#### Jest / Vitest (TypeScript/JavaScript)
```typescript
// Vitest / Jest — AAA pattern
describe('OrderService', () => {
  it('should calculate total with tax', () => {
    // Arrange
    const items = [{ price: 10, quantity: 2 }, { price: 5, quantity: 1 }];
    const taxRate = 0.08;

    // Act
    const total = calculateOrderTotal(items, taxRate);

    // Assert
    expect(total).toBe(27.0); // (10*2 + 5*1) * 1.08
  });

  it('should throw for empty items', () => {
    expect(() => calculateOrderTotal([], 0.08)).toThrow('Items cannot be empty');
  });
});
```

#### pytest (Python)
```python
# pytest — fixtures and parametrize
import pytest
from order_service import calculate_order_total

@pytest.fixture
def sample_items():
    return [{"price": 10, "quantity": 2}, {"price": 5, "quantity": 1}]

def test_order_total_with_tax(sample_items):
    assert calculate_order_total(sample_items, tax_rate=0.08) == 27.0

@pytest.mark.parametrize("items,tax,expected", [
    ([{"price": 100, "quantity": 1}], 0.0, 100.0),
    ([{"price": 100, "quantity": 1}], 0.1, 110.0),
    ([], 0.08, pytest.raises(ValueError)),
])
def test_order_total_parametrized(items, tax, expected):
    if isinstance(expected, type) or hasattr(expected, '__enter__'):
        with expected:
            calculate_order_total(items, tax)
    else:
        assert calculate_order_total(items, tax) == expected
```

#### JUnit 5 (Java)
```java
// JUnit 5 — nested tests and display names
@DisplayName("OrderService")
class OrderServiceTest {
    @Nested
    @DisplayName("calculateTotal")
    class CalculateTotal {
        @Test
        @DisplayName("should include tax in total")
        void shouldIncludeTax() {
            var items = List.of(new Item(10, 2), new Item(5, 1));
            var total = OrderService.calculateTotal(items, 0.08);
            assertThat(total).isCloseTo(27.0, within(0.01));
        }

        @ParameterizedTest
        @CsvSource({"0.0, 25.0", "0.08, 27.0", "0.2, 30.0"})
        void shouldApplyDifferentTaxRates(double taxRate, double expected) {
            var items = List.of(new Item(10, 2), new Item(5, 1));
            assertThat(OrderService.calculateTotal(items, taxRate)).isCloseTo(expected, within(0.01));
        }
    }
}
```

#### testing (Go)
```go
// Go — table-driven tests
func TestCalculateOrderTotal(t *testing.T) {
    tests := []struct {
        name    string
        items   []Item
        taxRate float64
        want    float64
        wantErr bool
    }{
        {"with tax", []Item{{10, 2}, {5, 1}}, 0.08, 27.0, false},
        {"no tax", []Item{{10, 2}, {5, 1}}, 0.0, 25.0, false},
        {"empty items", nil, 0.08, 0, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CalculateOrderTotal(tt.items, tt.taxRate)
            if tt.wantErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.InDelta(t, tt.want, got, 0.01)
        })
    }
}
```

#### xUnit (.NET)
```csharp
// xUnit — Theory with InlineData
public class OrderServiceTests
{
    [Theory]
    [InlineData(0.0, 25.0)]
    [InlineData(0.08, 27.0)]
    [InlineData(0.2, 30.0)]
    public void CalculateTotal_WithTaxRate_ReturnsCorrectTotal(decimal taxRate, decimal expected)
    {
        var items = new[] { new Item(10, 2), new Item(5, 1) };
        var result = OrderService.CalculateTotal(items, taxRate);
        Assert.Equal(expected, result, precision: 2);
    }
}
```

## Mocking Strategy

### Test Doubles Hierarchy
- **Stubs**: Return fixed values (use for queries -- "what does this return?")
- **Mocks**: Verify interactions (use for commands -- "was this called?")
- **Fakes**: Simplified working implementations (in-memory DB, fake API server, fake filesystem)
- **Spies**: Record calls without changing behavior -- verify after the fact
- **Dummies**: Placeholder objects passed but never used (satisfy parameter requirements)

### When to Mock vs When to Use Fakes

| Scenario | Preferred Double | Rationale |
|----------|-----------------|-----------|
| External API calls | Fake (MSW, WireMock) | Validates full request/response cycle |
| Database queries | Fake (in-memory DB, Testcontainers) | Tests actual SQL/ORM behavior |
| Time/clock | Stub | Deterministic, simple |
| Email/SMS sending | Mock | Verify it was called, don't actually send |
| File system | Fake (memfs, in-memory FS) | Avoid cleanup, faster |
| Logging | Spy | Verify log output without suppressing |
| Internal service class | Don't mock | Tests become coupled to implementation |

### Dependency Injection for Testability
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
- Seed per-test with factory functions -- each test creates its own data
- Use transactions for isolation -- rollback after each test
- Truncate tables between test suites, not between individual tests (performance)
- Never rely on seeded data order -- use explicit assertions on specific records
- Use `beforeEach`/`setUp` for common fixtures, not global seeds

## Integration Testing

### Database Tests with Testcontainers
```typescript
// TypeScript with Testcontainers
import { PostgreSqlContainer } from '@testcontainers/postgresql';

describe('UserRepository', () => {
  let container: StartedPostgreSqlContainer;
  let db: Database;

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();
    db = await createConnection(container.getConnectionUri());
    await runMigrations(db);
  }, 60_000);

  afterAll(async () => {
    await db.close();
    await container.stop();
  });

  it('should persist and retrieve user', async () => {
    const repo = new UserRepository(db);
    await repo.create({ name: 'Alice', email: 'alice@example.com' });
    const user = await repo.findByEmail('alice@example.com');
    expect(user).toMatchObject({ name: 'Alice', email: 'alice@example.com' });
  });
});
```

### API Integration Tests
- Use supertest (Node.js), httpx (Python), REST Assured (Java), net/http/httptest (Go)
- Test against actual HTTP server, not mocked routes
- Validate response status, headers, body structure, and pagination
- Test authentication and authorization paths
- Test error responses (400, 401, 403, 404, 422, 500)

### Message Queue Tests
- Use Testcontainers for Kafka, RabbitMQ, Redis
- Publish message, verify consumer processes it correctly
- Test dead letter queue behavior for failed messages
- Test message ordering and idempotency

## E2E Testing

### Playwright Setup
```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 4 : undefined,
  reporter: [['html', { open: 'never' }], ['junit', { outputFile: 'results.xml' }]],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

### Page Object Model
```typescript
// pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() { await this.page.goto('/login'); }
  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Sign in' }).click();
  }
  async expectError(message: string) {
    await expect(this.page.getByRole('alert')).toContainText(message);
  }
}

// e2e/login.spec.ts
test('should show error for invalid credentials', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('wrong@email.com', 'wrongpassword');
  await loginPage.expectError('Invalid email or password');
});
```

### Visual Regression Testing
- Playwright: `await expect(page).toHaveScreenshot('dashboard.png', { maxDiffPixels: 100 })`
- Compare screenshots across runs -- catch unintended UI changes
- Update baselines intentionally: `npx playwright test --update-snapshots`
- Exclude dynamic content (timestamps, animations) with CSS masking

### Test Data Management for E2E
- Use API calls to seed data before tests (not UI interactions)
- Create unique data per test run to avoid conflicts in parallel execution
- Clean up data after tests or use isolated test tenants
- Use deterministic IDs where possible for easier debugging

## Contract Testing

### Pact Consumer-Driven Contract Testing
```typescript
// Consumer test (frontend or downstream service)
const interaction = {
  state: 'user 123 exists',
  uponReceiving: 'a request for user 123',
  withRequest: { method: 'GET', path: '/users/123' },
  willRespondWith: {
    status: 200,
    body: { id: like('123'), name: like('Alice'), email: email() }
  }
};
// Generates Pact contract file
// Provider runs verification against real implementation
```

### Schema Validation
- **Zod** (TypeScript): Runtime schema validation for API responses
- **Pydantic** (Python): Response model validation with type checking
- **JSON Schema**: Language-agnostic contract definition

### OpenAPI Contract Tests
- Generate tests from OpenAPI spec using Schemathesis (Python) or Dredd
- Validate request/response against spec automatically
- Catch drift between spec and implementation in CI

## Property-Based Testing

Test with randomly generated inputs to discover edge cases you didn't think of.

| Language | Library | Example |
|----------|---------|---------|
| **TypeScript** | fast-check | `fc.assert(fc.property(fc.array(fc.integer()), (arr) => sort(arr).length === arr.length))` |
| **Python** | Hypothesis | `@given(st.lists(st.integers())) def test_sort_preserves_length(xs): assert len(sorted(xs)) == len(xs)` |
| **Java** | jqwik | `@Property void sortPreservesLength(@ForAll List<Integer> list) { assertEquals(list.size(), sort(list).size()); }` |
| **Go** | rapid | `rapid.Check(t, func(t *rapid.T) { xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs"); assert len(Sort(xs)) == len(xs) })` |
| **Rust** | proptest | `proptest! { fn sort_preserves_length(v: Vec<i32>) { assert_eq!(sort(&v).len(), v.len()); } }` |
| **Haskell** | QuickCheck | `prop_sort_length xs = length (sort xs) == length xs` |

Use property-based testing for:
- Serialization roundtrips (`decode(encode(x)) == x`)
- Sorting invariants (length preserved, elements preserved, ordered)
- Mathematical properties (commutativity, associativity, idempotency)
- Parser/formatter pairs
- State machine testing (model-based testing)

## Mutation Testing

Measure test quality by introducing small code changes (mutants) and checking if tests catch them.

| Language | Tool | Command |
|----------|------|---------|
| **TypeScript/JavaScript** | Stryker | `npx stryker run` |
| **Python** | mutmut | `mutmut run --paths-to-mutate=src/` |
| **Java** | PIT (pitest) | `mvn org.pitest:pitest-maven:mutationCoverage` |
| **Rust** | cargo-mutants | `cargo mutants` |
| **C#/.NET** | Stryker.NET | `dotnet stryker` |

- **Mutation score**: Percentage of mutants killed by tests (target: > 80%)
- Surviving mutants reveal weak test assertions or missing test cases
- Run on critical business logic, not on all code (expensive)
- Integrate in CI as a quality gate on changed files

## Snapshot Testing

### When to Use
- Serialized output (JSON responses, HTML rendering, CLI output)
- Component rendering (React component trees)
- Configuration generation (Terraform plans, Kubernetes manifests)

### Anti-Patterns
- Snapshots of large objects -- hard to review changes, easy to blindly update
- Snapshots of volatile data (timestamps, random IDs) -- always failing
- Too many snapshots -- maintenance burden, reviewers skip them
- Using snapshots as a substitute for meaningful assertions

### Best Practices
- Keep snapshots small and focused on the relevant output
- Use inline snapshots for small values: `expect(result).toMatchInlineSnapshot()`
- Review snapshot updates carefully in PRs -- don't blindly `--update`
- Name snapshot files descriptively

## TDD / BDD Workflows

### TDD (Test-Driven Development)
1. **Red**: Write a failing test that describes the desired behavior
2. **Green**: Write the minimum code to make the test pass
3. **Refactor**: Improve the code while keeping tests green

Best for: algorithm design, utility functions, business logic, bug fixes (write test that reproduces bug first).

### BDD (Behavior-Driven Development)
```gherkin
Feature: User Registration
  Scenario: Successful registration
    Given the user is on the registration page
    When they submit valid registration details
    Then they should see a welcome message
    And they should receive a confirmation email

  Scenario: Registration with existing email
    Given a user with email "alice@example.com" already exists
    When a new user tries to register with "alice@example.com"
    Then they should see an error "Email already registered"
```

Tools: Cucumber (multi-language), behave (Python), Godog (Go), SpecFlow (.NET)

## Flaky Test Prevention and Management

### Common Causes and Fixes
| Cause | Fix |
|-------|-----|
| Timing dependencies | Use explicit waits, not `sleep()`. Playwright: `waitForSelector`, `waitForResponse` |
| Shared test state | Isolate tests -- each test creates and cleans up its own data |
| Non-deterministic data | Use factories with deterministic seeds, freeze time |
| External service dependency | Mock external services, use Testcontainers for infrastructure |
| Race conditions in async code | Use `waitFor` patterns, avoid polling with `setTimeout` |
| Order-dependent tests | Run tests in random order (Jest `--randomize`, pytest `pytest-randomly`) |
| Timezone sensitivity | Always use UTC in tests, mock timezone where needed |

### Flaky Test Management
- Quarantine flaky tests -- mark as `skip` with a ticket to fix, don't delete
- Track flaky test rate in CI dashboard
- Set a team policy: flaky tests must be fixed within 1 sprint or removed
- Use test retry as a temporary mitigation, not a permanent solution

## Test Parallelization and Sharding

- **Jest**: `--maxWorkers=50%` for parallel test files, `--shard=1/4` for CI sharding
- **Vitest**: `--pool=threads` or `--pool=forks`, `--shard=1/4`
- **pytest**: `pytest-xdist` with `-n auto` for parallel, `--dist=loadgroup` for grouping
- **JUnit 5**: `junit.jupiter.execution.parallel.enabled=true` in properties
- **Go**: Tests run in parallel by default with `t.Parallel()`
- **Playwright**: `fullyParallel: true` in config, `--shard=1/4` for CI

### CI Sharding Strategy
```yaml
# GitHub Actions -- matrix sharding
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx jest --shard=${{ matrix.shard }}/4
```

## Code Coverage

### Coverage Types
- **Line coverage**: Which lines were executed (most common, least informative)
- **Branch coverage**: Were both branches of every `if/else` taken?
- **Path coverage**: Were all possible execution paths tested? (expensive, rarely measured)
- **Function coverage**: Were all functions called at least once?
- **Condition coverage**: Were all boolean sub-expressions tested for true and false?

### Meaningful Coverage Thresholds

| Code Category | Recommended Threshold |
|---------------|----------------------|
| Business logic / domain | 90%+ branch coverage |
| API handlers / controllers | 80%+ line coverage |
| Data access / repositories | 80%+ line coverage |
| Utility / helper functions | 90%+ branch coverage |
| Configuration / boilerplate | No minimum (don't game it) |
| Generated code | Exclude from coverage |

### Coverage Commands
```bash
# TypeScript (Vitest)
npx vitest run --coverage --coverage.thresholds.lines=80 --coverage.thresholds.branches=75

# Python (pytest-cov)
pytest --cov=src --cov-report=html --cov-fail-under=80

# Go
go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out

# Java (JaCoCo via Maven)
mvn verify  # jacoco-maven-plugin in pom.xml

# .NET
dotnet test --collect:"XPlat Code Coverage" /p:Threshold=80
```

- Use coverage to find untested code paths, not as a vanity metric
- Enforce thresholds in CI to prevent coverage regression
- Exclude test files, generated code, and configuration from coverage metrics

For framework references, see [reference-frameworks.md](reference-frameworks.md).
