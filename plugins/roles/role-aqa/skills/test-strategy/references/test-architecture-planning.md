# Test Architecture Patterns and Test Plan Structure

## When to load
When choosing between Page Object Model, Screenplay, or App Actions; when creating a test plan document; when designing test environment topology; when writing acceptance criteria in Given/When/Then format.

## Page Object Model (POM)
- Encapsulates page structure and interactions in a class.
- Tests interact with page objects, not raw locators.
- Changes to UI require only page object updates, not test rewrites.

```typescript
class CheckoutPage {
  constructor(private page: Page) {}

  async fillShippingAddress(address: Address) {
    await this.page.getByLabel('Street').fill(address.street);
    await this.page.getByLabel('City').fill(address.city);
    await this.page.getByLabel('ZIP Code').fill(address.zip);
  }

  async placeOrder(): Promise<OrderConfirmationPage> {
    await this.page.getByRole('button', { name: 'Place Order' }).click();
    return new OrderConfirmationPage(this.page);
  }
}
```

## Screenplay Pattern
- Actors have abilities (browse web, call API). They perform tasks. Tasks compose interactions. Questions check state.
- More expressive than POM for complex user journeys.
- Libraries: Serenity/JS (TypeScript), Serenity BDD (Java).

```typescript
await actorCalled('Alice').attemptsTo(
  NavigateTo.theCheckoutPage(),
  Enter.theValue(address.street).into(ShippingForm.streetField()),
  Click.on(CheckoutPage.placeOrderButton()),
  Ensure.that(OrderConfirmation.orderNumber(), isPresent()),
);
```

## App Actions Pattern (Cypress)
- Invoke application methods directly to set up state instead of navigating through the UI.
- Faster test setup. Avoid slow UI flows for precondition setup.

```javascript
cy.task('db:seed', { users: [{ email: 'admin@test.com', role: 'admin' }] });
cy.window().invoke('app.login', 'admin@test.com', 'password');
// Now test admin-only behavior without going through the login UI
```

## Regression Strategy
- Maintain a smoke test suite (under 5 minutes) that runs on every commit.
- Full regression suite runs nightly or on release branches.
- Tag tests by priority: `@critical`, `@high`, `@medium`, `@low`. Run critical tests in PR pipelines.
- When a bug is found in production, write a regression test before fixing the bug.
- Review and prune regression suite quarterly. Remove tests for deprecated features.

## Test Environment Planning
- **Local**: Developer machine with Docker Compose for dependencies. Fast iteration.
- **CI**: Ephemeral environments spun up per pipeline run. Testcontainers for databases.
- **Staging**: Production-like environment for E2E and performance tests.
- **Production**: Synthetic monitoring and canary tests (read-only, non-destructive).
- Environment parity: minimize drift between staging and production — same versions, same configs.

## Test Plan Structure

A test plan should contain:
1. **Scope**: What is being tested and what is explicitly out of scope
2. **Test types**: Unit, integration, E2E, performance, security, accessibility, chaos
3. **Entry criteria**: When testing can begin (build passes, environment ready, test data available)
4. **Exit criteria**: When testing is complete (coverage met, no P0/P1 open, performance baseline met)
5. **Environment requirements**: Databases, services, third-party sandboxes, device farms
6. **Test data requirements**: Seed data, synthetic generation, anonymized production data
7. **Resource allocation**: Who tests what, estimated effort per area
8. **Risk register**: Known risks and mitigation strategies
9. **Quality metrics**: How success will be measured beyond pass/fail

## Acceptance Criteria Definition

Write acceptance criteria in Given/When/Then format:
```gherkin
Given a registered user with a valid credit card
When they purchase a product priced at $49.99
Then the order total should be $49.99 plus applicable tax
And the payment should be charged to their credit card
And they should receive an order confirmation email within 5 minutes
And the inventory count for the purchased item should decrease by 1
```

- Each criterion must be testable and unambiguous.
- Include positive paths, negative paths, and boundary conditions.
- Acceptance criteria drive automated acceptance tests. One criterion maps to one or more test cases.
- Include performance criteria: "loads within 2 seconds on 4G."
- Include accessibility criteria: "navigable by keyboard, screen reader announces form errors."
