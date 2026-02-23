# BDD and Gherkin

## When to load
Load when writing behavior specs in Gherkin, integrating Cucumber with a test runner, translating
product requirements into executable scenarios, or establishing Given-When-Then conventions.

## BDD: Given-When-Then

BDD is TDD at a higher level — behavior is described in business terms, not code terms.
Good for: acceptance criteria, API contracts, feature specs that product can read.

### Syntax

```
GIVEN  [initial context / precondition]
WHEN   [action / event]
THEN   [expected outcome]
AND    [additional condition] (chains to any section)
```

## Gherkin Feature Files

```gherkin
Feature: Order Cancellation

  Scenario: Customer cancels a pending order
    Given a customer has a pending order with 2 items
    And the order was placed less than 1 hour ago
    When the customer requests cancellation
    Then the order status changes to "cancelled"
    And the customer receives a cancellation confirmation email
    And the inventory is restored for both items

  Scenario: Customer cannot cancel a shipped order
    Given a customer has an order with status "shipped"
    When the customer requests cancellation
    Then the request is rejected with error "OrderNotCancellableError"
    And the order status remains "shipped"
    And no email is sent

  Scenario: Cancellation after 1 hour requires manager approval
    Given a customer has a pending order
    And the order was placed more than 1 hour ago
    When the customer requests cancellation
    Then a cancellation request is created with status "pending_approval"
    And a notification is sent to the order management team
```

### Scenario Outline: parameterized scenarios

```gherkin
Feature: Discount calculation

  Scenario Outline: Apply membership discount
    Given a user with "<membership>" membership
    When they purchase an item priced at $<price>
    Then the final price is $<final>

    Examples:
      | membership | price | final |
      | standard   | 100   | 100   |
      | premium    | 100   | 90    |
      | vip        | 100   | 80    |
```

## Translating BDD to Code (Vitest without Cucumber)

```typescript
// BDD-style test — readable by product, engineer, and QA
describe('Order cancellation', () => {
  describe('when customer cancels a pending order within 1 hour', () => {
    it('changes order status to cancelled', async () => {
      // Given
      const order = await orderFactory.create({
        status: 'pending',
        createdAt: subMinutes(new Date(), 30),  // 30 minutes ago
      });

      // When
      const result = await orderService.cancel(order.id, customerId);

      // Then
      expect(result.status).toBe('cancelled');
    });

    it('restores inventory for all items', async () => {
      const items = [
        { productId: 'prod_1', quantity: 2, reservedStock: 2 },
        { productId: 'prod_2', quantity: 1, reservedStock: 1 },
      ];
      const order = await orderFactory.create({ status: 'pending', items });

      await orderService.cancel(order.id, customerId);

      const stock1 = await inventoryRepo.findByProductId('prod_1');
      const stock2 = await inventoryRepo.findByProductId('prod_2');
      expect(stock1.available).toBe(initialStock.prod_1 + 2);
      expect(stock2.available).toBe(initialStock.prod_2 + 1);
    });
  });

  describe('when customer tries to cancel a shipped order', () => {
    it('throws OrderNotCancellableError', async () => {
      const order = await orderFactory.create({ status: 'shipped' });

      await expect(
        orderService.cancel(order.id, customerId)
      ).rejects.toThrow(OrderNotCancellableError);
    });
  });
});
```

## Cucumber Integration (when you need living documentation)

```bash
npm install --save-dev @cucumber/cucumber @cucumber/pretty-formatter
```

```typescript
// features/step-definitions/order-cancellation.steps.ts
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';

Given('a customer has a pending order with {int} items', async function (itemCount: number) {
  this.order = await createOrder({ status: 'pending', itemCount });
  this.customerId = this.order.userId;
});

When('the customer requests cancellation', async function () {
  this.result = await orderService.cancel(this.order.id, this.customerId);
});

Then('the order status changes to {string}', async function (status: string) {
  expect(this.result.status).toBe(status);
});
```

```json
// cucumber.json
{
  "default": {
    "paths": ["features/**/*.feature"],
    "require": ["features/step-definitions/**/*.ts"],
    "requireModule": ["ts-node/register"],
    "format": ["@cucumber/pretty-formatter", "json:reports/cucumber.json"]
  }
}
```

## When to use Gherkin vs plain describe/it

```
Use Gherkin when:
  - Product owners / QA need to read and validate scenarios
  - Acceptance tests are contractual (client signs off on feature files)
  - Team has dedicated QA writing feature files, engineers writing step defs

Use plain describe/it (Given-When-Then comments) when:
  - Purely engineering team, no external stakeholders reading tests
  - Cucumber integration adds overhead without value
  - Scenarios are complex and parameterized — Gherkin tables get unwieldy
```

## Quick reference

```
BDD format        : Given (context) / When (action) / Then (outcome)
Gherkin           : .feature files, Scenario Outline for parameterized cases
Cucumber install  : @cucumber/cucumber + ts-node/register
Living docs       : json:reports/cucumber.json -> HTML report via cucumber-html-reporter
TDD patterns      : see tdd-bdd-patterns.md
```
