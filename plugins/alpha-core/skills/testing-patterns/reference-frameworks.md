# Testing Frameworks Reference

## Testing Framework Feature Comparison

### JavaScript/TypeScript Test Runners

| Feature | Jest | Vitest | Node.js Test Runner |
|---------|------|--------|---------------------|
| Speed | Moderate (parallel workers) | Fast (Vite-native, ESM) | Fast (built-in, minimal overhead) |
| Mocking | Built-in `jest.mock()` | Built-in `vi.mock()`, Jest-compatible | Built-in `mock` module (Node 22+) |
| Snapshot testing | Built-in | Built-in, Jest-compatible | Not built-in |
| Code coverage | Built-in (Istanbul/V8) | Built-in (V8/Istanbul) | Built-in `--experimental-test-coverage` |
| Watch mode | `--watch` with pattern matching | `--watch` with HMR (instant) | `--watch` (Node 22+) |
| TypeScript | Needs ts-jest or SWC | Native via Vite transform | Needs `--loader tsx` |
| Config | `jest.config.ts` | `vitest.config.ts` (extends Vite) | No config file needed |
| Ecosystem | Largest, most plugins | Growing, Vite ecosystem | Minimal, standard library |
| Best for | Legacy projects, CRA, large codebases | Vite projects, new projects, fast feedback | Simple projects, no dependencies |

- **Jest**: Unit/integration, built-in mocking, snapshot testing, code coverage, largest ecosystem
- **Vitest**: Vite-native, Jest-compatible API, faster for Vite projects, native ESM support, in-source testing
- **Playwright**: E2E, cross-browser, auto-wait, trace viewer, codegen, API testing, component testing
- **Cypress**: E2E, time-travel debugging, network stubbing, component testing, real browser execution
- **Testing Library**: DOM testing utilities, user-centric queries (`getByRole`, `getByText`), framework adapters (React, Vue, Angular, Svelte)

### Python Test Frameworks

| Feature | pytest | unittest | nose2 |
|---------|--------|----------|-------|
| Style | Function-based, fixtures | Class-based, setUp/tearDown | Function or class |
| Assertions | Plain `assert` with rewriting | `self.assertEqual()` methods | Plain `assert` |
| Parametrize | `@pytest.mark.parametrize` | `subTest` (limited) | Via plugins |
| Fixtures | Powerful fixture system with scopes | setUp/tearDown only | setUp/tearDown |
| Plugins | 1000+ plugins (pytest-cov, pytest-mock, pytest-asyncio, pytest-xdist) | Limited | Some plugins |
| Autodiscovery | `test_*.py` files, `test_*` functions | `test*.py` files, `Test*` classes | Configurable |
| Best for | Everything (de facto standard) | Standard library only projects | Legacy projects |

- **pytest**: Fixtures, parametrize, plugins (pytest-cov, pytest-mock, pytest-asyncio, pytest-xdist, pytest-randomly)
- **unittest**: Built-in, class-based, setUp/tearDown, no external dependencies
- **Hypothesis**: Property-based testing, automatic edge case generation, stateful testing

### Java/Kotlin Test Frameworks

| Feature | JUnit 5 | TestNG | Kotest |
|---------|---------|--------|--------|
| Style | Annotations, nested, display names | Annotations, XML config, groups | Kotlin DSL, multiple styles |
| Parameterized | `@ParameterizedTest`, `@CsvSource`, `@MethodSource` | `@DataProvider` | Data-driven via `forAll` |
| Extensions | `@ExtendWith`, lifecycle callbacks | Listeners, ITestNGMethod | Extensions, lifecycle |
| Parallel | `junit.jupiter.execution.parallel.enabled` | `parallel` attribute in XML | `coroutineTestScope` |
| Best for | Standard Java/Kotlin projects | Legacy, complex test suites | Kotlin-first projects |

- **JUnit 5**: Annotations, parameterized tests, extensions, nested tests, display names, dynamic tests
- **Mockito**: Mock/stub/verify, argument captors, BDD API (`given`/`when`/`then`), Kotlin extension (`mockito-kotlin`)
- **Kotest**: Kotlin-native, multiple test styles (FunSpec, BehaviorSpec, StringSpec), property-based testing built-in
- **TestContainers**: Docker containers for integration tests (Postgres, MySQL, Redis, Kafka, Elasticsearch, MongoDB)

### Go Testing

- **testing**: Built-in package, table-driven tests, benchmarks, fuzzing (Go 1.18+), `t.Parallel()`, subtests
- **testify**: Assertions (`assert`, `require`), mocking, suite with setUp/tearDown
- **gomock**: Interface-based mocking with code generation (`mockgen`)
- **is**: Minimal assertion library, zero dependencies
- **goconvey**: BDD-style, web UI, live reload
- **rapid**: Property-based testing, imperative style

### .NET Testing

| Feature | xUnit | NUnit | MSTest |
|---------|-------|-------|--------|
| Style | Constructor injection, `IClassFixture` | `[SetUp]`/`[TearDown]` attributes | `[TestInitialize]`/`[TestCleanup]` |
| Parameterized | `[Theory]`, `[InlineData]`, `[MemberData]` | `[TestCase]`, `[TestCaseSource]` | `[DataRow]`, `[DynamicData]` |
| Parallel | Default parallel by collection | Configurable via assembly | Configurable |
| Best for | Modern .NET, recommended by Microsoft | Migrated from NUnit 2 | Microsoft-first shops |

- **xUnit**: Modern .NET testing, constructor injection, `[Theory]`/`[Fact]`, parallel by default
- **NUnit**: Mature, feature-rich, constraint-based assertions, `Assert.That()`
- **Moq**: .NET mocking with LINQ expressions, `Mock<T>`, `Setup()`, `Verify()`
- **NSubstitute**: Simpler .NET mocking syntax, `Substitute.For<T>()`
- **FluentAssertions**: Readable assertions, `result.Should().Be(42)`

### Rust Testing

- **Built-in**: `#[test]`, `#[cfg(test)]` modules, `cargo test`, doc tests, integration test directory
- **proptest**: Property-based testing, shrinking, regex-based generators
- **mockall**: Trait-based mocking with `#[automock]`
- **rstest**: Fixtures and parametrized tests for Rust, `#[rstest]`
- **criterion**: Benchmarking with statistical analysis, HTML reports

## Test Runner Configuration Examples

### jest.config.ts
```typescript
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.test.ts', '**/*.spec.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts', '!src/**/index.ts'],
  coverageThreshold: {
    global: { branches: 75, functions: 80, lines: 80, statements: 80 },
  },
  moduleNameMapper: { '^@/(.*)$': '<rootDir>/src/$1' },
  setupFilesAfterSetup: ['<rootDir>/test/setup.ts'],
  maxWorkers: '50%',
};

export default config;
```

### vitest.config.ts
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: { branches: 75, functions: 80, lines: 80 },
      exclude: ['**/*.d.ts', '**/index.ts', '**/__mocks__/**'],
    },
    setupFiles: ['./test/setup.ts'],
    pool: 'threads',
    poolOptions: { threads: { maxThreads: 4, minThreads: 1 } },
  },
});
```

### pytest configuration (pyproject.toml)
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "-ra -q --strict-markers --cov=src --cov-report=html --cov-fail-under=80"
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks integration tests requiring external services",
]
asyncio_mode = "auto"
filterwarnings = ["error", "ignore::DeprecationWarning"]
```

### build.gradle.kts (JUnit 5 + JaCoCo)
```kotlin
dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")
    testImplementation("org.mockito:mockito-core:5.11.0")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.3.1")
    testImplementation("org.assertj:assertj-core:3.25.3")
    testImplementation("org.testcontainers:testcontainers:1.19.7")
    testImplementation("org.testcontainers:postgresql:1.19.7")
}

tasks.test {
    useJUnitPlatform()
    jvmArgs("-XX:+EnableDynamicAgentLoading")
    systemProperty("junit.jupiter.execution.parallel.enabled", "true")
    systemProperty("junit.jupiter.execution.parallel.mode.default", "concurrent")
    finalizedBy(tasks.jacocoTestReport)
}

tasks.jacocoTestReport {
    reports { xml.required = true; html.required = true }
}

tasks.jacocoTestCoverageVerification {
    violationRules {
        rule { limit { minimum = "0.80".toBigDecimal() } }
    }
}
```

### Go test configuration
```bash
# Run all tests with race detection and coverage
go test -race -coverprofile=coverage.out -covermode=atomic ./...

# View coverage report
go tool cover -html=coverage.out -o coverage.html

# Run benchmarks
go test -bench=. -benchmem -count=5 ./...

# Run fuzzing
go test -fuzz=FuzzParseInput -fuzztime=30s ./parser/
```

## Testcontainers Setup Examples

### TypeScript
```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { RedisContainer } from '@testcontainers/redis';
import { KafkaContainer } from '@testcontainers/kafka';

// PostgreSQL
const pgContainer = await new PostgreSqlContainer('postgres:16-alpine')
  .withDatabase('testdb')
  .withExposedPorts(5432)
  .start();
const connectionUri = pgContainer.getConnectionUri();

// Redis
const redisContainer = await new RedisContainer('redis:7-alpine').start();
const redisUrl = redisContainer.getConnectionUrl();

// Kafka
const kafkaContainer = await new KafkaContainer('confluentinc/cp-kafka:7.6.0')
  .withExposedPorts(9093)
  .start();
```

### Python
```python
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer

# PostgreSQL
with PostgresContainer("postgres:16-alpine") as postgres:
    engine = create_engine(postgres.get_connection_url())
    # run tests with real database

# Redis
with RedisContainer("redis:7-alpine") as redis:
    client = redis.get_client()
    # run tests with real Redis
```

### Java
```java
@Testcontainers
class UserRepositoryTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

### Go
```go
func TestWithPostgres(t *testing.T) {
    ctx := context.Background()
    container, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        testcontainers.WithWaitStrategy(
            wait.ForLog("database system is ready to accept connections").WithOccurrence(2),
        ),
    )
    require.NoError(t, err)
    defer container.Terminate(ctx)
    connStr, _ := container.ConnectionString(ctx, "sslmode=disable")
    // use connStr for database tests
}
```

## Mocking Library Comparison

### Java Mocking

| Feature | Mockito | EasyMock | MockK (Kotlin) |
|---------|---------|----------|----------------|
| Style | `when().thenReturn()` | `expect().andReturn()` | `every { } returns` |
| Verification | `verify(mock).method()` | `verify(mock)` | `verify { mock.method() }` |
| Spy support | `@Spy`, `spy()` | Partial mocks | `spyk()` |
| Static mocking | `mockStatic()` (Mockito 5+) | PowerMock needed | `mockkStatic()` built-in |
| Kotlin support | Via mockito-kotlin | Poor | Native, first-class |
| Best for | Java projects | Legacy projects | Kotlin projects |

### JavaScript/TypeScript Mocking

| Feature | jest.mock | vi.mock (Vitest) | Sinon.js |
|---------|-----------|------------------|----------|
| Module mocking | `jest.mock('./module')` | `vi.mock('./module')` | `sinon.stub(module, 'fn')` |
| Timer mocking | `jest.useFakeTimers()` | `vi.useFakeTimers()` | `sinon.useFakeTimers()` |
| Spies | `jest.spyOn()` | `vi.spyOn()` | `sinon.spy()` |
| Stubs | `jest.fn().mockReturnValue()` | `vi.fn().mockReturnValue()` | `sinon.stub().returns()` |
| HTTP mocking | Needs MSW/nock | Needs MSW/nock | Needs nock |

### Python Mocking

| Feature | unittest.mock | pytest-mock | responses |
|---------|---------------|-------------|-----------|
| Style | `@patch('module.Class')` | `mocker.patch('module.Class')` | `@responses.activate` |
| Scope | Function/class decorators | Fixture-based (auto cleanup) | Decorator/context manager |
| HTTP | Needs responses/httpretty | Needs responses/httpretty | Built-in HTTP mocking |
| Best for | Standard library only | pytest projects | HTTP API tests |

## E2E Framework Comparison

| Feature | Playwright | Cypress | Selenium |
|---------|-----------|---------|----------|
| Languages | JS/TS, Python, Java, .NET | JavaScript/TypeScript only | Java, Python, C#, JS, Ruby |
| Browsers | Chromium, Firefox, WebKit | Chrome, Firefox, Edge, Electron | All major browsers |
| Auto-wait | Built-in, intelligent | Built-in, automatic retry | Manual waits needed |
| Parallel | Built-in, per-worker | Via Cypress Cloud (paid) | Via Selenium Grid |
| Network interception | `page.route()`, full control | `cy.intercept()`, easy API | Limited, proxy-based |
| Mobile emulation | Built-in device profiles | Viewport only | Appium integration |
| Component testing | `@playwright/experimental-ct-*` | Built-in component testing | Not supported |
| Trace/debug | Trace viewer, video, screenshot | Time-travel, video, screenshot | Screenshot only |
| Speed | Fast (browser contexts) | Moderate (new browser per spec) | Slow (WebDriver protocol) |
| API testing | Built-in `request` context | `cy.request()` | Not built-in |
| Best for | Cross-browser, CI, API+E2E | Interactive development, DX | Legacy, multi-language |

## Contract Testing with Pact

### Consumer Side (TypeScript)
```typescript
import { PactV4 } from '@pact-foundation/pact';

const pact = new PactV4({ consumer: 'frontend', provider: 'user-service' });

test('get user by ID', async () => {
  await pact
    .addInteraction()
    .given('user 123 exists')
    .uponReceiving('a request for user 123')
    .withRequest('GET', '/api/users/123')
    .willRespondWith(200, (builder) => {
      builder.jsonBody({ id: '123', name: string('Alice'), email: email() });
    })
    .executeTest(async (mockServer) => {
      const response = await fetch(`${mockServer.url}/api/users/123`);
      const user = await response.json();
      expect(user.name).toBeDefined();
    });
});
// Pact file generated at pacts/frontend-user-service.json
```

### Provider Side Verification
```typescript
import { Verifier } from '@pact-foundation/pact';

const verifier = new Verifier({
  providerBaseUrl: 'http://localhost:3000',
  pactUrls: ['./pacts/frontend-user-service.json'],
  stateHandlers: {
    'user 123 exists': async () => {
      await db.users.create({ id: '123', name: 'Alice', email: 'alice@test.com' });
    },
  },
});

await verifier.verifyProvider();
```

### Pact Broker Integration
```bash
# Publish consumer pact
npx pact-broker publish ./pacts --consumer-app-version=$(git rev-parse HEAD) --broker-base-url=https://pact.example.com

# Can I deploy? (check compatibility)
npx pact-broker can-i-deploy --pacticipant=frontend --version=$(git rev-parse HEAD) --to-environment=production
```

## Property-Based Testing Libraries

| Language | Library | Generator Example | Shrinking |
|----------|---------|-------------------|-----------|
| **TypeScript** | fast-check | `fc.string()`, `fc.integer()`, `fc.record()` | Automatic |
| **Python** | Hypothesis | `st.text()`, `st.integers()`, `st.builds(User)` | Automatic, database of examples |
| **Java** | jqwik | `@ForAll String s`, `@IntRange(min=0, max=100)` | Automatic |
| **Go** | rapid | `rapid.String()`, `rapid.IntRange(0, 100)` | Automatic |
| **Rust** | proptest | `proptest! { fn test(s in ".*") {} }` | Automatic |
| **Haskell** | QuickCheck | `arbitrary :: Gen a`, `choose (0, 100)` | Automatic |
| **Scala** | ScalaCheck | `Gen.alphaStr`, `Gen.choose(0, 100)` | Automatic |

## CI Integration Patterns

### GitHub Actions Test Workflow
```yaml
name: Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '${{ matrix.node-version }}' }
      - run: npm ci
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        with: { name: coverage-${{ matrix.node-version }}, path: coverage/ }

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env: { POSTGRES_DB: testdb, POSTGRES_PASSWORD: test }
        ports: ['5432:5432']
        options: --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npm run test:integration
        env: { DATABASE_URL: 'postgresql://postgres:test@localhost:5432/testdb' }

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npx playwright test --shard=${{ matrix.shard }}/4
        strategy:
          matrix:
            shard: [1, 2, 3, 4]
      - uses: actions/upload-artifact@v4
        if: failure()
        with: { name: playwright-report, path: playwright-report/ }
```

### Test Result Reporting
- **JUnit XML**: Universal CI format -- Jest (`--reporters=jest-junit`), pytest (`--junitxml`), Go (`gotestsum --junitfile`)
- **HTML reports**: Playwright HTML reporter, pytest-html, Allure Report (multi-language)
- **Coverage uploads**: Codecov, Coveralls -- merge coverage from parallel shards
- **Slack/Teams notifications**: On failure only, include test summary and links

## API Testing
- **Postman/Newman**: Collections, environments, CLI runner for CI, pre/post-request scripts
- **REST Assured** (Java): Fluent DSL for REST API testing, JSON/XML validation, auth support
- **SuperTest** (Node.js): HTTP assertion library, works with Express/Koa/Fastify
- **httpx** (Python): Async HTTP client, works with pytest, ASGI/WSGI app testing
- **Pact**: Consumer-driven contract testing across services
- **WireMock**: Java-based HTTP mock server, request matching, response templating, record/replay
- **MSW (Mock Service Worker)**: Browser and Node.js, intercepts at network layer, OpenAPI integration

## Performance Testing
- **k6**: JavaScript scripting, cloud execution, Grafana integration, browser testing (k6 browser)
- **JMeter**: GUI-based, protocol support, distributed testing, extensive plugin ecosystem
- **Gatling**: Scala/Java DSL, detailed reports, CI integration, simulation scripts
- **Artillery**: YAML config, WebSocket/HTTP/gRPC support, easy CI integration, Playwright scenarios
- **Locust**: Python-based, distributed, real-time web UI, code-as-config

## Mobile Testing
- **Appium**: Cross-platform (iOS/Android), WebDriver protocol, multiple language bindings
- **Detox**: React Native, gray-box testing, synchronization with app, fast
- **XCUITest**: iOS native, Xcode integration, Swift/Objective-C
- **Espresso**: Android native, synchronization, Kotlin/Java, fast and reliable
- **Maestro**: Simple YAML-based mobile testing, cross-platform, visual validation
