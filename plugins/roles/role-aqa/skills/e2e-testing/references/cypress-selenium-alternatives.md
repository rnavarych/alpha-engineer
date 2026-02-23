# Cypress, Selenium, and Alternative E2E Frameworks

## When to load
When working with Cypress v13, Selenium 4 (BiDi, Grid), WebdriverIO, TestCafe, Robot Framework, or CodeceptJS; when Playwright is not the right fit for the project.

## Cypress v13

### Core Features
- **Time-travel debugging**: Step through commands in Cypress App with DOM snapshots at each step.
- **cy.intercept()**: Stub network requests for fully deterministic tests.
- **Real events**: Cypress fires real native browser events — click, type, drag behave exactly as a real user.
- **Session storage**: `cy.session()` caches authentication state across tests for faster execution.

```javascript
beforeEach(() => {
  cy.session('authenticated-user', () => {
    cy.visit('/login');
    cy.get('[data-cy="email"]').type('user@test.com');
    cy.get('[data-cy="password"]').type('password123');
    cy.get('[data-cy="login-btn"]').click();
    cy.url().should('include', '/dashboard');
  });
});

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
```python
from selenium import webdriver

driver = webdriver.Chrome()
async with driver.bidi_connection() as connection:
    await connection.session.subscribe("log.entryAdded")
    async for event in connection.session.listen("log.entryAdded"):
        print(event)
```

### Relative Locators
```python
from selenium.webdriver.support.relative_locator import locate_with

submit_btn = driver.find_element(
    locate_with(By.TAG_NAME, "button").to_the_right_of({By.ID: "email"})
)
```

### Chrome DevTools Protocol (CDP) Integration
```python
driver.execute_cdp_cmd("Network.emulateNetworkConditions", {
    "offline": False,
    "latency": 200,
    "downloadThroughput": 50000,
    "uploadThroughput": 25000,
})
```

### Selenium Grid 4
- Distribute tests across nodes in a hub-and-spoke topology.
- Docker Compose for local Grid; Kubernetes for scalable CI Grid.
- `--node-max-sessions=5` per node. Use `--session-request-timeout=300`.

## WebdriverIO
Strong alternative for Node.js teams, especially for mobile and browser extensions:
```javascript
export const config = {
  framework: 'mocha',
  reporters: ['allure'],
  services: ['browserstack'],
  capabilities: [{ browserName: 'chrome' }, { browserName: 'firefox' }],
};

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
Scenario('checkout flow', ({ I }) => {
  I.amOnPage('/products');
  I.click('Add to Cart');
  I.amOnPage('/checkout');
  I.fillField('Card Number', '4242424242424242');
  I.click('Place Order');
  I.see('Order Confirmed');
});
```
Supports Playwright, WebdriverIO, Puppeteer as backends.
