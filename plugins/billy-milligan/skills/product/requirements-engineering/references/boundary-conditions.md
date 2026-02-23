# Boundary Conditions

## When to load
Load when discovering edge cases before implementation, writing boundary and negative scenarios for acceptance criteria, or reviewing a story's AC coverage for missing edge cases.

---

## Boundary Condition Discovery Checklist

Use this checklist for any story involving numbers, lengths, dates, statuses, or permissions:

**Numeric inputs:**
- [ ] Minimum valid value (e.g., quantity = 1)
- [ ] Maximum valid value (e.g., quantity = 999)
- [ ] Value at exact boundary (e.g., file = 5.0 MB)
- [ ] Value one unit outside boundary (e.g., file = 5.0 MB + 1 byte)
- [ ] Zero (is it valid? what happens?)
- [ ] Negative values (should they be rejected? how?)
- [ ] Very large values (what's the overflow risk?)

**Text inputs:**
- [ ] Empty string
- [ ] Maximum allowed length
- [ ] Maximum + 1 character
- [ ] Special characters: `<>'"&\` (XSS vectors)
- [ ] Unicode and emoji (multi-byte characters)
- [ ] Whitespace-only input

**Dates and times:**
- [ ] Past date (is it valid?)
- [ ] Today (edge case for "future only" rules)
- [ ] Far future date (year 9999, etc.)
- [ ] Time zone boundaries (midnight UTC vs. midnight local)
- [ ] Daylight saving time transitions

**Status machine transitions:**
- [ ] All valid transitions (draw the state machine)
- [ ] All invalid transitions (what is the error?)
- [ ] Transition to current state (idempotent?)

**Permission boundaries:**
- [ ] Own resource (permitted)
- [ ] Another user's resource (forbidden)
- [ ] Resource that doesn't exist (404 vs. 403 — don't reveal existence)
- [ ] Role with partial permissions

---

## Boundary Scenario Examples

```gherkin
# Minimum valid value
Scenario: Order with exactly 1 item can be cancelled
  Given I have order ORD-002 in status "pending" with 1 item
  When I cancel the order
  Then the order is cancelled and the 1 item is returned to inventory

# Maximum allowed value
Scenario: Cannot add more than 10 items of one product
  Given my cart has 10 units of Product-A
  When I attempt to add 1 more unit of Product-A
  Then I see the error "Maximum 10 units per product allowed"
  And the cart still contains 10 units

# Exactly at limit
Scenario: File upload at exactly the maximum size limit
  Given I am on the profile photo upload page
  When I upload a JPEG file of exactly 5 MB
  Then the photo is accepted and displayed as my avatar

# One byte over limit
Scenario: File upload one byte over the maximum size limit
  Given I am on the profile photo upload page
  When I upload a JPEG file of 5 MB + 1 byte
  Then I see the error "File must be under 5 MB"
  And my current avatar is unchanged
```

## Negative and Concurrent Scenario Examples

```gherkin
# Not permitted (wrong status)
Scenario: Customer cannot cancel an order that has shipped
  Given I have order ORD-003 in status "shipped"
  When I view the order detail page
  Then the "Cancel Order" button is not present
  And I see "This order has shipped and can no longer be cancelled"

# Not permitted (wrong role)
Scenario: Customer cannot access admin order management
  Given I am authenticated as a customer (not admin)
  When I navigate to /admin/orders
  Then I am redirected to /dashboard
  And I see the error "You don't have permission to access this page"

# Concurrent — idempotent result
Scenario: Two requests to cancel the same order — idempotent result
  Given I have order ORD-004 in status "pending"
  When two simultaneous cancellation requests are submitted
  Then the order ends in status "cancelled" exactly once
  And no duplicate cancellation emails are sent
  And inventory is released exactly once per item

# Race condition — status changes during action
Scenario: Order is shipped while customer attempts to cancel
  Given I have order ORD-005 in status "pending"
  And the order is simultaneously marked "shipped" by the warehouse system
  When I submit a cancellation request
  Then I see "This order has already shipped and cannot be cancelled"
  And the order status is "shipped"
```

---

## Anti-Patterns

### Missing negative cases
Every happy path scenario has at least one corresponding failure scenario. If you have written only happy paths, you are not done.

### Skipping concurrent scenarios for stateful operations
Any story where two users or processes could interact with the same resource simultaneously requires at least one concurrent scenario. Skipping this is how duplicate-charge bugs and inventory oversell bugs happen.

---

## Quick Reference

```
Boundary rule: test at the limit, one below, one above
Required scenario types: happy path, boundary, negative/error, concurrent (for stateful ops)
Idempotency: cancelling twice = cancelled once; duplicate webhooks = handled once
Permission boundary: 404 vs 403 — don't reveal resource existence to unauthorized users
State machine: draw all valid transitions AND all invalid ones before writing ACs
"Then" must be observable by a human or automated test — never vague
```
