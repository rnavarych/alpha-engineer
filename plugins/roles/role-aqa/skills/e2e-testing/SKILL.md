---
name: e2e-testing
description: |
  End-to-end test automation with Playwright (codegen, trace viewer, MCP, sharding,
  visual comparisons, fixtures, component testing), Cypress v13, Selenium 4 (BiDi),
  WebdriverIO, TestCafe, Robot Framework. Visual regression: Percy, Chromatic, Applitools,
  BackstopJS, Lost Pixel. Cross-browser: BrowserStack, Sauce Labs. Accessibility in E2E.
allowed-tools: Read, Grep, Glob, Bash
---

You are an E2E test automation specialist.

## Playwright (Recommended)

Playwright is the default choice for new E2E test suites. It offers the best developer experience, reliability, and feature set as of 2025.

### Core Features
- **Auto-wait**: No manual `waitFor` needed. Playwright waits for elements to be actionable (visible, stable, enabled, editable). No more `sleep()` calls.
- **Trace viewer**: `npx playwright show-trace trace.zip`. Captures DOM snapshots, network requests, console logs, and screenshots at every step. Essential for debugging CI failures.
- **Codegen**: `npx playwright codegen <url>` records user interactions and generates test code. Use as a starting point; refactor into Page Objects.
- **Network interception**: `page.route()` to mock APIs, simulate errors (500s, timeouts), and test loading states.

### Locator Strategy (in order of preference)
```typescript
// 1. Role-based (most resilient, accessibility-aligned)
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByRole('heading', { name: 'Order Confirmation' });

// 2. Label-based
await page.getByLabel('Email address').fill('user@test.com');

// 3. Placeholder
await page.getByPlaceholder('Search products').fill('laptop');

// 4. Text content
await page.getByText('Terms and Conditions').click();

// 5. Test ID (when semantic locators are not feasible)
await page.getByTestId('checkout-submit').click();

// 6. CSS/XPath (last resort - brittle)
await page.locator('[data-testid="cart-total"]');
```

### Advanced Playwright Features

#### Fixtures
```typescript
// fixtures.ts
import { test as base } from '@playwright/test';

type Fixtures = { authenticatedPage: Page; testUser: User };

export const test = base.extend<Fixtures>({
  testUser: async ({ request }, use) => {
    const user = await createUserViaAPI(request);
    await use(user);
    await deleteUserViaAPI(request, user.id);
  },
  authenticatedPage: async ({ page, testUser }, use) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill(testUser.email);
    await page.getByLabel('Password').fill(testUser.password);
    await page.getByRole('button', { name: 'Sign in' }).click();
    await use(page);
  },
});
```

#### test.step for Structured Reporting
```typescript
test('checkout flow', async ({ page }) => {
  await test.step('Add item to cart', async () => {
    await page.goto('/products/laptop');
    await page.getByRole('button', { name: 'Add to Cart' }).click();
  });

  await test.step('Complete checkout', async () => {
    await page.goto('/checkout');
    await page.getByLabel('Card number').fill('4242424242424242');
    await page.getByRole('button', { name: 'Place Order' }).click();
  });

  await test.step('Verify confirmation', async () => {
    await expect(page.getByRole('heading', { name: 'Order Confirmed' })).toBeVisible();
  });
});
```

#### Projects (Multi-browser and Multi-config)
```typescript
// playwright.config.ts
export default defineConfig({
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 7'] } },
    { name: 'mobile-safari', use: { ...devices['iPhone 14'] } },
    // Authenticated state project
    {
      name: 'authenticated',
      use: { storageState: 'playwright/.auth/user.json' },
      dependencies: ['setup'],
    },
  ],
});
```

#### Sharding for CI Distribution
```yaml
# GitHub Actions parallel sharding
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/4
  - uses: actions/upload-artifact@v4
    with:
      name: blob-report-${{ matrix.shard }}
      path: blob-report/
# Merge reports after all shards complete
- run: npx playwright merge-reports --reporter html ./all-blob-reports
```

#### API Testing with Playwright
```typescript
test('create user via API', async ({ request }) => {
  const response = await request.post('/api/users', {
    data: { email: 'newuser@test.com', name: 'New User' },
  });
  expect(response.status()).toBe(201);
  const user = await response.json();
  expect(user).toMatchObject({ email: 'newuser@test.com' });
});
```

#### Component Testing
```typescript
// Playwright component testing (React/Vue/Svelte)
import { test, expect } from '@playwright/experimental-ct-react';
import { Button } from './Button';

test('button fires onClick', async ({ mount }) => {
  let clicked = false;
  const component = await mount(
    <Button onClick={() => { clicked = true; }}>Click me</Button>
  );
  await component.click();
  expect(clicked).toBe(true);
});
```

#### Visual Comparisons
```typescript
// Visual regression with Playwright (built-in)
test('product page matches snapshot', async ({ page }) => {
  await page.goto('/products/laptop-pro');
  // Mask dynamic content before snapshotting
  await expect(page).toHaveScreenshot('product-page.png', {
    maxDiffPixelRatio: 0.02,
    mask: [page.locator('.price'), page.locator('.stock-count')],
    animations: 'disabled',
  });
});
```

### Playwright MCP Integration

The Playwright MCP server enables AI-assisted browser automation during test development:

```bash
# Install and run Playwright MCP
npx @playwright/mcp@latest

# Claude can then control the browser:
# - Navigate to pages
# - Capture accessibility snapshots (better than screenshots for locator discovery)
# - Identify best locators from live DOM
# - Generate test code from interactions
```

Use Playwright MCP to:
- Explore an unfamiliar application before writing tests.
- Discover the most resilient locators for elements.
- Verify page accessibility structure.
- Generate baseline test code to refactor into Page Objects.

## Cypress v13

### Core Features
- **Time-travel debugging**: Step through commands in Cypress App with DOM snapshots at each step.
- **cy.intercept()**: Stub network requests for fully deterministic tests. Never rely on real network calls in unit/integration tests.
- **Real events**: Cypress fires real native browser events (not simulated). Click, type, drag behave exactly as a real user.
- **Session storage**: `cy.session()` caches authentication state across tests for faster execution.

```javascript
// Cypress session for authentication
beforeEach(() => {
  cy.session('authenticated-user', () => {
    cy.visit('/login');
    cy.get('[data-cy="email"]').type('user@test.com');
    cy.get('[data-cy="password"]').type('password123');
    cy.get('[data-cy="login-btn"]').click();
    cy.url().should('include', '/dashboard');
  });
});

// cy.intercept for deterministic API stubbing
cy.intercept('GET', '/api/products*', { fixture: 'products.json' }).as('getProducts');
cy.visit('/products');
cy.wait('@getProducts');
cy.get('[data-cy="product-list"]').should('have.length', 5);
```

### Component Testing (Cypress v13)
```javascript
import { mount } from 'cypress/react';
import { ProductCard } from './ProductCard';

it('displays product name and price', () => {
  mount(<ProductCard name="Laptop Pro" price={1299.99} inStock={true} />);
  cy.contains('Laptop Pro').should('be.visible');
  cy.contains('$1,299.99').should('be.visible');
  cy.get('[data-cy="add-to-cart"]').should('not.be.disabled');
});
```

### Origin Testing (Multi-Domain)
```javascript
// Test flows that cross origins (e.g., OAuth redirects)
cy.origin('https://auth.example.com', () => {
  cy.get('#username').type('testuser');
  cy.get('#password').type('password');
  cy.get('#login-btn').click();
});
cy.url().should('include', '/dashboard');
```

## Selenium 4

Use Selenium when Playwright/Cypress coverage is insufficient (legacy apps, specific browser requirements).

### BiDi (Bidirectional Protocol)
Selenium 4 introduces the WebDriver BiDirectional Protocol (CDP alternative, cross-browser):
```python
from selenium import webdriver
from selenium.webdriver.common.bidi.cdp import import_cdp

driver = webdriver.Chrome()
# Listen to console logs via BiDi
async with driver.bidi_connection() as connection:
    await connection.session.subscribe("log.entryAdded")
    async for event in connection.session.listen("log.entryAdded"):
        print(event)
```

### Relative Locators (Selenium 4)
```python
from selenium.webdriver.support.relative_locator import locate_with

submit_btn = driver.find_element(locate_with(By.TAG_NAME, "button").to_the_right_of({By.ID: "email"}))
```

### Chrome DevTools Protocol (CDP) Integration
```python
driver.execute_cdp_cmd("Network.emulateNetworkConditions", {
    "offline": False,
    "latency": 200,  # ms
    "downloadThroughput": 50000,  # bytes/s
    "uploadThroughput": 25000,
})
```

### Selenium Grid 4
- Distribute tests across nodes in a hub-and-spoke topology.
- Docker Compose setup for local Grid; Kubernetes for scalable CI Grid.
- `--node-max-sessions=5` per node. Use `--session-request-timeout=300`.

## WebdriverIO

Strong alternative for Node.js teams, especially with mobile and browser extensions:

```javascript
// wdio.conf.js
export const config = {
  framework: 'mocha',
  reporters: ['allure'],
  services: ['browserstack'],
  capabilities: [{ browserName: 'chrome' }, { browserName: 'firefox' }],
};

// Test
it('should complete checkout', async () => {
  await browser.url('/checkout');
  await $('input[name="cardNumber"]').setValue('4242424242424242');
  await $('button[type="submit"]').click();
  await expect($('.order-confirmation')).toBeDisplayed();
});
```

## TestCafe

No WebDriver dependency. Runs in any modern browser without plugins:
```javascript
import { Selector, RequestLogger } from 'testcafe';

const apiLogger = RequestLogger('/api/orders', { logResponseBody: true });

fixture('Order Flow').page('https://app.example.com').requestHooks(apiLogger);

test('creates order on checkout', async (t) => {
  await t
    .typeText(Selector('#card-number'), '4242424242424242')
    .click(Selector('button').withText('Place Order'))
    .expect(Selector('.confirmation-number').exists).ok();

  const orderResponse = apiLogger.requests[0].response.body;
  await t.expect(JSON.parse(orderResponse).status).eql('created');
});
```

## Robot Framework

Keyword-driven testing. Excellent for teams with non-developer testers:

```robot
*** Settings ***
Library    Browser    # Playwright-backed browser library
Library    RequestsLibrary

*** Test Cases ***
User Can Complete Checkout
    New Browser    chromium    headless=True
    New Page    https://app.example.com/products
    Click    text=Add to Cart
    Navigate To    /checkout
    Fill Text    [name=cardNumber]    4242424242424242
    Click    button:has-text("Place Order")
    Get Text    h1    ==    Order Confirmed
```

## CodeceptJS

High-level acceptance testing with multiple backend drivers:
```javascript
// Supports Playwright, WebdriverIO, Puppeteer as backends
Scenario('checkout flow', ({ I }) => {
  I.amOnPage('/products');
  I.click('Add to Cart');
  I.amOnPage('/checkout');
  I.fillField('Card Number', '4242424242424242');
  I.click('Place Order');
  I.see('Order Confirmed');
});
```

## Visual Regression Testing

### Percy (BrowserStack)
- Cloud-based visual review with multi-browser rendering.
- `percy exec -- npx playwright test` captures snapshots automatically.
- Review and approve/reject diffs in pull request comments.
- Renders at multiple resolutions (responsive breakpoints).

### Chromatic (Storybook)
- Component-level visual testing integrated with Storybook.
- `npx chromatic --project-token=<token>` publishes stories and catches visual changes.
- Isolates visual regressions to specific component states.

### Applitools Eyes
- AI-powered visual comparison ignores rendering differences (anti-aliasing, sub-pixel fonts).
- Ultra-fast grid: render in 50+ browser/device combos simultaneously.
- Best for complex UIs with dynamic content regions.

```typescript
// Applitools with Playwright
import { BatchInfo, Configuration, EyesRunner, Eyes } from '@applitools/eyes-playwright';

const eyes = new Eyes(runner, config);
await eyes.open(page, 'App Name', 'Test Name');
await eyes.checkWindow('Product Page');
await eyes.close();
```

### BackstopJS
- Local visual regression testing with Docker rendering.
- Configuration in JSON. Captures and diffs screenshots.
- Good for projects avoiding cloud dependencies or vendor lock-in.

```json
{
  "scenarios": [{
    "label": "Homepage",
    "url": "http://localhost:3000",
    "hideSelectors": [".dynamic-price", ".timestamp"],
    "misMatchThreshold": 0.5
  }]
}
```

### Lost Pixel
- Open-source visual regression. Integrates with Storybook, Ladle, Histoire, and full pages.
- Stores baselines in S3 or local filesystem.

### reg-suit
- Visual regression testing toolkit.
- Connects to S3 for baseline storage, reports diffs in GitHub PR comments.
- Framework-agnostic: works with any screenshot tool.

### Visual Testing Best Practices
- Mask dynamic content (timestamps, prices, user avatars) before snapshotting.
- Set pixel diff thresholds to account for anti-aliasing across OS/GPU rendering differences.
- Disable CSS animations during visual tests (`animations: 'disabled'` in Playwright).
- Run visual tests in a consistent, headless Docker environment.
- Review all diffs before approving new baselines. Do not auto-approve via CI.
- Separate visual regression job from functional tests. Run on schedule or design-related PRs.

## Cross-Browser Testing (Cloud)

### BrowserStack Automate
- Real devices and browsers in the cloud.
- Parallel execution across hundreds of device/OS/browser combos.
- Video recording, network logs, visual logs for every test run.
- BrowserStack Local for testing behind firewalls.

### Sauce Labs
- Real devices and emulators/simulators.
- Sauce Connect Proxy for internal application testing.
- Unified reporting across web and mobile.

### LambdaTest
- Cloud browser testing with HyperExecute for faster parallel execution.
- Smart Test Orchestration for optimal test distribution.
- Real-time testing and automated testing support.

## Accessibility Testing in E2E

### playwright-axe
```typescript
import { checkA11y, injectAxe } from 'axe-playwright';

test('checkout is accessible', async ({ page }) => {
  await page.goto('/checkout');
  await injectAxe(page);
  await checkA11y(page, undefined, {
    axeOptions: {
      runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'best-practice'] },
    },
    detailedReport: true,
  });
});
```

### cypress-axe
```javascript
cy.visit('/checkout');
cy.injectAxe();
cy.checkA11y(null, {
  rules: { 'color-contrast': { enabled: true } },
}, (violations) => {
  cy.task('log', `${violations.length} accessibility violations`);
});
```

### Accessibility Assertions in E2E
- Verify keyboard navigation: Tab through all interactive elements in expected order.
- Verify focus management: After modal open, focus moves to modal. After close, focus returns to trigger.
- Verify ARIA live regions announce dynamic content changes.
- Verify form error messages are associated with inputs via `aria-describedby`.

## Page Object Model

```typescript
// Base page with common patterns
abstract class BasePage {
  constructor(protected page: Page) {}

  async waitForLoad() {
    await this.page.waitForLoadState('networkidle');
  }
}

class LoginPage extends BasePage {
  private emailInput = this.page.getByLabel('Email');
  private passwordInput = this.page.getByLabel('Password');
  private submitButton = this.page.getByRole('button', { name: 'Sign in' });

  async login(email: string, password: string): Promise<DashboardPage> {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
    const dashboard = new DashboardPage(this.page);
    await dashboard.waitForLoad();
    return dashboard;
  }
}
```

## Flaky Test Mitigation

- Track reliability metrics per test. Flag tests with >2% failure rate without code changes as flaky.
- Root causes: race conditions, time-dependent logic, shared state, external service dependencies, animation timing.
- Quarantine flaky tests: tag with `@flaky`, exclude from blocking pipeline gate.
- Fix within one sprint. Use deterministic test IDs, mock external services, disable animations.
- Reintegrate after verifying stability across 50+ consecutive runs.
- Use Playwright `--retries=2` in CI only. Do not mask flakiness with retries; fix the root cause.

## Test Data in E2E

- Create data via API in `beforeEach` (faster than UI setup). Clean up in `afterEach`.
- Use factory functions for unique entities per test. Never rely on pre-existing data.
- Store authentication state with `storageState` to avoid re-login on every test.
- Use unique email addresses and identifiers per test run (include `Date.now()` or UUID).
