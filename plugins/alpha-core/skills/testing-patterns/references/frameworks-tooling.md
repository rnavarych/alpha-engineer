# Testing Framework Tooling

## When to load
Load when configuring test runners, setting up Testcontainers, comparing mocking libraries, or integrating tests into CI.

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
    systemProperty("junit.jupiter.execution.parallel.enabled", "true")
    systemProperty("junit.jupiter.execution.parallel.mode.default", "concurrent")
    finalizedBy(tasks.jacocoTestReport)
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
go tool cover -html=coverage.out -o coverage.html
go test -bench=. -benchmem -count=5 ./...
go test -fuzz=FuzzParseInput -fuzztime=30s ./parser/
```

## Testcontainers Setup Examples

### TypeScript
```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { RedisContainer } from '@testcontainers/redis';

const pgContainer = await new PostgreSqlContainer('postgres:16-alpine')
  .withDatabase('testdb').withExposedPorts(5432).start();

const redisContainer = await new RedisContainer('redis:7-alpine').start();
```

### Python
```python
from testcontainers.postgres import PostgresContainer

with PostgresContainer("postgres:16-alpine") as postgres:
    engine = create_engine(postgres.get_connection_url())
    # run tests with real database
```

### Java
```java
@Testcontainers
class UserRepositoryTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("testdb").withUsername("test").withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
    }
}
```

## Mocking Library Comparison

### JavaScript/TypeScript Mocking

| Feature | jest.mock | vi.mock (Vitest) | Sinon.js |
|---------|-----------|------------------|----------|
| Module mocking | `jest.mock('./module')` | `vi.mock('./module')` | `sinon.stub(module, 'fn')` |
| Timer mocking | `jest.useFakeTimers()` | `vi.useFakeTimers()` | `sinon.useFakeTimers()` |
| Spies | `jest.spyOn()` | `vi.spyOn()` | `sinon.spy()` |
| HTTP mocking | Needs MSW/nock | Needs MSW/nock | Needs nock |

## CI Integration Patterns

### GitHub Actions Test Workflow
```yaml
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
      - run: npm ci && npm test -- --coverage

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx playwright install --with-deps
      - run: npx playwright test --shard=${{ matrix.shard }}/4
        strategy:
          matrix:
            shard: [1, 2, 3, 4]
```

### Test Result Reporting
- **JUnit XML**: Universal CI format — Jest (`--reporters=jest-junit`), pytest (`--junitxml`), Go (`gotestsum --junitfile`)
- **HTML reports**: Playwright HTML reporter, pytest-html, Allure Report (multi-language)
- **Coverage uploads**: Codecov, Coveralls — merge coverage from parallel shards

## E2E and API Testing Tools
- **Playwright vs Cypress vs Selenium**: Playwright preferred (cross-browser, built-in parallel, trace viewer)
- **Postman/Newman**: Collections, environments, CLI runner for CI
- **REST Assured** (Java): Fluent DSL for REST API testing
- **SuperTest** (Node.js): HTTP assertion library, works with Express/Fastify
- **httpx** (Python): Async HTTP client, ASGI/WSGI app testing
- **MSW (Mock Service Worker)**: Browser and Node.js, intercepts at network layer
- **WireMock**: Java-based HTTP mock server, request matching, response templating
