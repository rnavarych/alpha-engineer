# Integration and E2E Testing

## When to load
Load when setting up integration tests with Testcontainers, writing E2E tests with Playwright, or designing contract tests.

## Database Tests with Testcontainers
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

## API Integration Tests
- Use supertest (Node.js), httpx (Python), REST Assured (Java), net/http/httptest (Go)
- Test against actual HTTP server, not mocked routes
- Validate response status, headers, body structure, and pagination
- Test authentication and authorization paths
- Test error responses (400, 401, 403, 404, 422, 500)

## Message Queue Tests
- Use Testcontainers for Kafka, RabbitMQ, Redis
- Publish message, verify consumer processes it correctly
- Test dead letter queue behavior for failed messages
- Test message ordering and idempotency

## Playwright E2E Setup
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

## Page Object Model
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

## Visual Regression Testing
- Playwright: `await expect(page).toHaveScreenshot('dashboard.png', { maxDiffPixels: 100 })`
- Compare screenshots across runs — catch unintended UI changes
- Update baselines intentionally: `npx playwright test --update-snapshots`
- Exclude dynamic content (timestamps, animations) with CSS masking

## Test Data Management for E2E
- Use API calls to seed data before tests (not UI interactions)
- Create unique data per test run to avoid conflicts in parallel execution
- Clean up data after tests or use isolated test tenants
- Use deterministic IDs where possible for easier debugging

## Contract Testing with Pact
```typescript
// Consumer test
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
