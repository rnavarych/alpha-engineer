---
name: requirements-engineering
description: |
  Requirements engineering: INVEST criteria for user stories, Given-When-Then acceptance
  criteria with edge cases, MoSCoW prioritization, vertical slices, story mapping,
  decomposition patterns, non-functional requirements, Definition of Done.
  Use when writing user stories, breaking down epics, defining acceptance criteria.
allowed-tools: Read, Grep, Glob
---

# Requirements Engineering

## When to Use This Skill
- Writing user stories that meet INVEST criteria
- Defining complete acceptance criteria with edge cases
- Breaking down large features into vertical slices
- Prioritizing backlog with MoSCoW
- Defining non-functional requirements for a feature

## Core Principles

1. **INVEST for user stories** — Independent, Negotiable, Valuable, Estimable, Small, Testable
2. **GWT for acceptance criteria** — Given-When-Then; no "and" chains (split them)
3. **Vertical slices** — each story delivers value end-to-end, not "backend only"
4. **Edge cases in the story** — not as surprises during implementation
5. **Non-functional requirements are requirements** — performance, accessibility, security belong in stories

---

## Patterns ✅

### INVEST Criteria Checklist

```
I — Independent: Can this be developed and deployed without other stories?
     BAD:  "User can see order history" (needs login story to be done first — not independent)
     GOOD: Dependencies identified upfront, or story includes all needed parts

N — Negotiable: The HOW is flexible; the WHAT is the goal
     BAD:  "Implement Redis caching for product queries"
     GOOD: "Product listing loads in under 500ms for 95th percentile"

V — Valuable: Delivers value to user or business (not just technical task)
     BAD:  "Refactor order service to use repository pattern"
     GOOD: "Allow customers to cancel pending orders to reduce support tickets"

E — Estimable: Team can estimate relative size
     BAD:  "Optimize the entire checkout flow" (too vague)
     GOOD: "Add address validation to checkout step 2"

S — Small: Completable in one sprint (typically 1–5 days of work)
     Rule: If it takes longer than a sprint, split it.
     Exception: Spikes (research tasks) can be time-boxed.

T — Testable: Acceptance criteria exist and are verifiable
     BAD:  "User experience should be good"
     GOOD: "Given a mobile screen, when the user taps checkout, then the button is at least 44px touch target"
```

### User Story Format

```
Standard format:
  As a [specific role / type of user]
  I want to [accomplish this goal]
  So that [I receive this value / benefit]

Avoid: "As a user" — too generic
Use:   "As a returning customer who hasn't ordered in 90 days"
       "As an admin reviewing fraud alerts"
       "As a warehouse manager processing returns"

Example:
  As a customer who placed an order in the last 24 hours
  I want to cancel my order from the order detail page
  So that I can stop an order I placed by mistake before it ships
```

### Acceptance Criteria (Given-When-Then)

```gherkin
# Feature: Order Cancellation

# Happy path
Scenario: Customer cancels a pending order
  Given I am logged in as a customer
  And I have an order ORD-123 with status "pending"
  When I click "Cancel Order" on the order detail page
  And I confirm cancellation in the dialog
  Then the order status changes to "cancelled"
  And I receive a cancellation email within 2 minutes
  And the inventory for all items is released

# Edge case: timing
Scenario: Customer cannot cancel an order that has already shipped
  Given I have an order ORD-456 with status "shipped"
  When I view the order detail page
  Then the "Cancel Order" button is not visible
  And a message "This order has been shipped and cannot be cancelled" is displayed

# Edge case: partial fulfillment
Scenario: Customer cancels an order where some items have shipped
  Given I have order ORD-789 with 3 items:
    - Item A: status "shipped"
    - Item B: status "pending"
    - Item C: status "pending"
  When I request order cancellation
  Then Items B and C are cancelled with inventory released
  And Item A remains in status "shipped"
  And I receive a partial cancellation confirmation email
  And the order total is updated to reflect only Item A

# Non-functional requirement in AC
Scenario: Cancellation response time
  Given a valid cancellation request
  When the request is submitted
  Then the order status updates within 2 seconds
  And the response confirms the new status
```

### Vertical Slice Decomposition

```
Horizontal slice (BAD — no value delivered until all are done):
  Story 1: "Create database schema for orders"
  Story 2: "Create order API endpoint"
  Story 3: "Create order form UI"
  → No value until all 3 done. Can't demo after Story 1.

Vertical slice (GOOD — each slice delivers end-to-end value):
  Story 1: "Customer can place an order for a single item"
    → Full stack: DB + API + UI — but minimal. Works end-to-end.

  Story 2: "Customer can add multiple items to an order"
    → Adds to Story 1's working foundation.

  Story 3: "Customer receives order confirmation email"
    → Adds to Story 2's working foundation.

Rule: Each story should produce a working feature that can be demoed to a stakeholder.
```

### MoSCoW Prioritization

```
M — Must Have: Non-negotiable. MVP fails without this.
    "Customer can complete a purchase" — without this, there is no product.

S — Should Have: Important, but MVP can launch without temporarily.
    "Customer receives order status emails" — can manually notify early users.

C — Could Have: Nice to have. Include if time permits.
    "Customer can save order as a favorite" — adds value, not blocking.

W — Won't Have (this iteration): Explicitly deferred to future.
    "Customer can split payment between two cards" — backlogged.

Rule: For a fixed-scope release:
  Must Have: 60% of capacity
  Should Have: 20% of capacity (some will slip)
  Could Have: 20% of capacity (most will slip — that's OK)

Warning signs:
  Too many "Must Have" → team says everything is critical (need to negotiate)
  No "Won't Have" → no scope control mechanism
```

### Definition of Done

```
Checklist (add to sprint/team Definition of Done):
  [ ] Code reviewed by at least one other engineer
  [ ] Unit tests written (coverage doesn't decrease)
  [ ] Integration tests written for new API endpoints
  [ ] Documentation updated (API docs, README if needed)
  [ ] Feature flag configured (if gradual rollout needed)
  [ ] Migrations tested (can run and rollback)
  [ ] Deployed to staging and verified
  [ ] Acceptance criteria verified by QA or PO
  [ ] Monitoring/alerting configured for new functionality
  [ ] Accessibility: keyboard navigation and screen reader tested
  [ ] Performance: measured against response time budget
```

---

## Anti-Patterns ❌

### "As a User" Stories
**What it is**: Generic actor with no specific context.
**What breaks**: No empathy with the actual user scenario. Requirements are vague. "User" could mean customer, admin, warehouse worker — all with different needs.
**Fix**: Specific actor with context. "As a warehouse manager processing returns" leads to different requirements than "as a customer tracking a return."

### Missing Negative Scenarios in Acceptance Criteria
**What it is**: ACs only describe happy path. No edge cases, no error states.
**What breaks**: Implementation team discovers edge cases during development. "Oh, what happens when the order is already cancelled? When payment fails? When product is out of stock?" — all discovered late.
**Fix**: For every scenario, ask: "What can go wrong? What's the failure state? What if the user does this twice?"

### Horizontal Slicing
**What it is**: Stories split by technical layer (backend/frontend/DB).
**What breaks**: Story 1 (backend) completed, but 0 user value until stories 2 and 3 are done. Sprint ends, nothing to demo. Business can't validate direction until the end.
**Fix**: Vertical slices — thin end-to-end features. Even if minimal, they prove the concept works.

---

## Quick Reference

```
INVEST: Independent, Negotiable, Valuable, Estimable, Small, Testable
GWT: Given (context), When (action), Then (observable outcome)
Vertical slice: thin end-to-end — always demable to stakeholder
MoSCoW: Must (60%), Should (20%), Could (20%), Won't (explicitly listed)
ACs per story: 3-8 scenarios (happy path + 3-5 edge cases)
Story size: completable in 1-5 days
Split trigger: if estimate > 5 story points, decompose further
NFRs: always in ACs — performance targets, accessibility, security level
```
