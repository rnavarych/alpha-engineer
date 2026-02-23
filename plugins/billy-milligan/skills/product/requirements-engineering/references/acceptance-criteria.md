# Acceptance Criteria

## When to load
Load when writing or reviewing acceptance criteria in Given-When-Then format, defining the happy path scenario, or validating that a story's core success case is well-specified before writing edge cases.

---

## Given-When-Then Structure

### Core format
```gherkin
Scenario: [Name describing what this scenario tests]
  Given [precondition — the system state and user context before the action]
  When  [the specific action the user takes or the event that occurs]
  Then  [the observable outcome — what the user sees or what the system does]
```

### Rules for each clause

**Given — precondition:**
- Describes system state, not the action
- Be specific: "I have an order ORD-123 in status 'pending'" not "I have an order"
- Multiple Givens use `And`: `Given ... And ...`
- Avoid business logic in Given — set up the state, don't assert

**When — action:**
- One action per scenario (if you need two actions, consider two scenarios)
- User-perspective language: "I click", "I submit", "I navigate to"
- For system events: "When a payment webhook arrives with status 'failed'"
- Avoid `And` in When — it means the scenario is doing too much

**Then — outcome:**
- Must be observable by a person or a test
- Avoid vague words: "correctly", "properly", "successfully" — specify the exact behavior
- Multiple Then clauses use `And`: verify multiple observable outcomes
- Negative outcomes: "Then the error message 'X' is displayed" not "Then nothing bad happens"

---

## Happy Path Scenario

The normal, expected flow when everything works as intended. Required for every story.

```gherkin
Scenario: Customer successfully cancels a pending order
  Given I am authenticated as customer@example.com
  And I have order ORD-001 in status "pending" with 2 items
  When I click "Cancel Order" on the order detail page
  And I confirm the cancellation in the modal dialog
  Then the order status changes to "cancelled"
  And I see the message "Your order has been cancelled"
  And I receive a cancellation confirmation email within 5 minutes
  And the items are returned to available inventory
```

---

## Anti-Patterns

### The "And" trap in When
```gherkin
# Bad — two actions in one scenario
When I fill in my email address
And I click submit
And the server sends a verification email
And I click the link in the email

# Good — split into two scenarios
Scenario: User submits email to start verification
  When I enter my email and click "Get verification link"
  Then I see "Check your email for a verification link"

Scenario: User completes verification via email link
  Given I have received a verification email
  When I click the verification link
  Then my email is verified and I am logged in
```

### Vague Then clauses
```gherkin
# Bad — cannot be automated, cannot be verified
Then the form is submitted successfully
Then the user is happy
Then everything works correctly

# Good — specific, observable, automatable
Then I see the success message "Your profile has been updated"
And the updated name appears in the navigation header
And an email confirmation is sent to my address within 2 minutes
```

### ACs written after implementation
Acceptance criteria written after a feature is built are not acceptance criteria — they are documentation of what was built. They cannot catch misunderstandings because the misunderstanding is already in the code.

---

## Quick Reference

```
GWT format: Given [state] / When [action] / Then [observable outcome]
Given: system state — be specific, no business logic, use And for multiple conditions
When: one action only — if you need And, split the scenario
Then: must be observable by human or automated test — never vague
Happy path: required first scenario — the normal flow when everything works
Write ACs before estimation — if you can't write them, the story isn't ready
```
