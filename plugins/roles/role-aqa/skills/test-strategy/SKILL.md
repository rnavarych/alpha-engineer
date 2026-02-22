---
name: test-strategy
description: |
  Designs comprehensive test strategies: test pyramid/trophy/diamond/honeycomb models,
  risk-based prioritization, shift-left, mutation testing, testing in production (feature
  flags, canary, shadow traffic), AI-assisted test generation, quality metrics (DORA,
  defect escape rate), test architecture patterns (Page Object, Screenplay, App Actions).
  Use when planning testing efforts, defining coverage goals, or creating test plans.
allowed-tools: Read, Grep, Glob, Bash
---

You are a test strategy specialist.

## Test Distribution Models

Choose the right model based on system architecture and team context:

### Test Pyramid (Classic)
```
    /   E2E    \       5-10% | Slow, expensive, highest confidence
   /____________\
  / Integration  \     15-25% | Moderate speed, service boundaries
 /________________\
/   Unit Tests    \    65-80% | Fast, cheap, isolated
/__________________\
```
- Enforce the right ratio. Microservices need more integration tests. Monoliths lean heavier on unit tests.
- Track pyramid inversion as a code smell. Too many E2E tests signal missing unit/integration coverage.
- Each layer tests different failure modes: unit tests catch logic errors, integration tests catch contract violations, E2E tests catch workflow breakages.

### Testing Trophy (Kent C. Dodds)
```
        [ E2E ]            (few, high value journeys)
   [ Integration ]         (most tests - service interactions, DB, API)
  [  Unit Tests  ]         (pure logic, algorithms, utils)
[ Static Analysis ]        (TypeScript, ESLint - free bug prevention)
```
- Integration tests give the best ROI in modern full-stack and microservice architectures.
- Static analysis (TypeScript, linting) sits below unit tests and prevents entire classes of bugs with zero runtime cost.
- Favored for React/Node.js applications with Testing Library at the integration layer.

### Testing Diamond
```
      / E2E \
     /________\
    /  Service  \          (API/service-level tests dominate)
   /______________\
  /     Unit      \
 /________________\
```
- Service/API tests dominate the middle. Useful for backend microservices where UI is thin.
- Fewer unit tests because logic lives at service boundaries, not in isolated functions.
- Prefer for API-first backends, internal services, and data processing pipelines.

### Testing Honeycomb (Spotify Model)
```
 (integrated service tests form the main body)
 Unit tests only for pure complex logic
 End-to-end tests for critical user journeys
```
- Replaces the pyramid with integrated service tests as the primary testing mechanism.
- Introduced by Spotify for microservice architectures.
- Each service is tested as a deployed unit against real (or containerized) dependencies.
- Reduces mocking complexity at the cost of slower test feedback.

## Shift-Left Testing Strategy

Move testing earlier in the development lifecycle:

### Developer-Time Testing (Leftmost)
- TypeScript strict mode eliminates null reference errors at compile time.
- ESLint security plugins (eslint-plugin-security, eslint-plugin-no-unsanitized) catch injection risks in the editor.
- Pre-commit hooks run unit tests related to changed files (lint-staged + jest --findRelatedTests).
- TDD: write tests before implementation for core business logic.

### PR-Time Testing
- Unit tests and integration tests run in under 5 minutes on every PR.
- Test impact analysis runs only tests affected by changed files.
- Contract tests verify no breaking changes to API contracts.
- SCA scans new dependencies for known CVEs.

### Merge-Time Testing
- Full integration test suite.
- Static analysis (SonarQube quality gate).
- SAST scan for new security hotspots.

### Deploy-Time Testing
- Smoke tests run immediately after deployment to staging.
- E2E critical path tests.
- Performance baseline validation.

## Risk-Based Test Prioritization

Prioritize testing effort using a risk matrix:

| Factor | High Priority | Low Priority |
|--------|--------------|--------------|
| Business impact | Payment, auth, data integrity | Static pages, tooltips |
| Change frequency | Actively developed modules | Stable, mature code |
| Complexity | Complex algorithms, state machines | Simple CRUD |
| Failure history | Components with past defects | Consistently reliable areas |
| User traffic | High-traffic endpoints | Admin-only features |
| Regulatory | PCI, HIPAA, SOX compliance paths | Marketing content |

- Assign risk scores (impact × likelihood) to features and allocate test effort proportionally.
- Re-evaluate risk scores each sprint as code changes shift the risk landscape.
- High-risk modules should have unit, integration, E2E, performance, and security tests.

## Exploratory Testing

Structured exploration finds what automation misses:

### Session-Based Test Management (SBTM)
- **Charter**: Define the exploration goal (mission) and area to explore.
- **Time-box**: 60-90 minutes of focused exploration. No interruptions.
- **Debrief**: Document findings, issues, and coverage within 15 minutes of the session.
- Use charters like: "Explore the checkout flow as a mobile user with an expired card on a slow network."

### Exploratory Testing Techniques
- **Tour testing**: Landmark tour (major features), FedEx tour (follow data through the system), Garbage collector tour (error paths, edge inputs).
- **Attack testing**: SQL injection, XSS, auth bypass, parameter tampering.
- **Persona testing**: Test as different user roles, device types, connection speeds, and locales.
- **State transition testing**: Find invalid state transitions. What happens if you refresh mid-checkout?

## Quality Gates in CI/CD

Quality gates are non-negotiable checks that block deployment:

### Gate Levels
```yaml
# PR Gate (must pass before merge)
- unit_tests: pass
- integration_tests: pass
- coverage_delta: no_decrease
- sca_scan: no_new_high_critical
- sast_scan: no_new_critical_hotspots
- contract_tests: pass

# Staging Gate (must pass before production deploy)
- e2e_smoke: pass
- performance_baseline: p95_within_20_percent
- security_scan: no_new_high_findings
- accessibility: no_new_critical_violations

# Production Gate (canary verification)
- synthetic_monitors: pass
- error_rate: below_threshold
- latency: p95_below_slo
```

### Ratcheting Coverage
- Never allow coverage to decrease. Use `--changedSince=main` for PR coverage.
- Increase coverage thresholds quarterly as the codebase matures.
- Per-file coverage for high-risk modules (payment, auth, data processing): 90%+.

## Test Impact Analysis

Run only tests that could be affected by changed code:

### Tools
- **Nx affected**: `nx affected:test --base=main` runs tests only for changed projects.
- **Turborepo filtered**: `turbo run test --filter=...[HEAD^1]` runs changed packages and their dependents.
- **Jest --findRelatedTests**: `jest --findRelatedTests src/payment/charge.ts` runs tests that import changed files.
- **Pytest-testmon**: Tracks which tests cover which source lines. Re-runs only relevant tests.
- **Bazel**: Precise dependency graph. Only rebuilds and tests what is actually affected.

### TIA Strategy
- Use on PR pipelines for fast feedback (< 5 min target).
- Run full test suite on merge to main and nightly.
- Always run the full suite before releases.

## Mutation Testing Strategy

Validate that tests actually detect faults:

### Tools
- **Stryker** (JavaScript/TypeScript): Mutates source code and checks if tests catch the change.
- **PITest** (Java): Bytecode-level mutation. Battle-tested for enterprise Java.
- **mutmut** (Python): Simple CLI-based mutation testing for Python.
- **cargo-mutants** (Rust): Mutation testing for Rust codebases.

### Mutation Operators
Stryker applies mutations like:
- Arithmetic: `+` → `-`, `*` → `/`
- Boolean: `&&` → `||`, `true` → `false`
- Equality: `===` → `!==`, `>` → `>=`
- Statement: remove return statements, skip function bodies

### Interpreting Results
- **Killed mutant**: A test failed because of the mutation. Good. Your tests detected the change.
- **Survived mutant**: No test failed. The mutation went undetected. Your tests are incomplete.
- **Mutation score**: percentage of killed/total. Target 70%+ on critical modules.
- Focus mutation testing on business-critical code. Running it on everything is slow and expensive.

## Testing in Production

Safe testing strategies in live production environments:

### Feature Flags
- Use LaunchDarkly, Unleash, or Flagsmith to control feature exposure.
- Enable features for internal users first. Gradually roll out to 1%, 5%, 20%, 100%.
- Write tests that run against both flag-on and flag-off states.
- Test flag configuration changes themselves. A bad flag config can be as damaging as bad code.

### Canary Deployments
- Route 1-5% of production traffic to new version. Monitor error rates and latency.
- Automated rollback if error rate exceeds threshold (>0.1% increase).
- Run synthetic tests against canary instances to verify functionality before expanding rollout.

### Shadow Traffic
- Duplicate production traffic and replay against new version without serving results to users.
- Compare responses between production and shadow. Flag divergences for investigation.
- Tools: Diffy (Twitter), Scientist (GitHub), shadow-proxy, traffic mirroring in Envoy/Nginx.

### Dark Launching
- Deploy new code paths but do not expose them to users.
- Execute new code path in parallel with old, compare results, log divergences.
- Validate new implementation against real production data before cutover.
- Reduce risk of big-bang feature launches.

### Synthetic Monitoring
- Run business-critical user flows as synthetic transactions every 1-5 minutes in production.
- Alert immediately when flows fail. Do not wait for user reports.
- Tools: Checkly, Datadog Synthetics, New Relic Scripted Browser, AWS CloudWatch Synthetics.

## AI-Assisted Test Generation

Accelerate test creation with AI tooling:

### Codium (TestGPT)
- Analyzes function signatures, implementation, and docstrings to generate tests.
- Generates happy path, edge cases, and error cases automatically.
- VS Code and JetBrains plugin. Review all suggestions before committing.

### Diffblue Cover
- Java-specific automated unit test generation.
- Runs in CI to regenerate tests when code changes.
- Best for brownfield Java codebases with low coverage.

### GitHub Copilot for Tests
- Describe intent in comments, Copilot completes the test body.
- Strong at boilerplate (describe blocks, beforeEach setup, assertion patterns).
- Weak at complex domain logic. Always verify correctness of generated assertions.

### AI Test Review
- Use Claude Code to review test quality: missing edge cases, incorrect assertions, test smell.
- Ask Claude to generate property-based test cases from function signatures.
- Generate test data with AI: "generate 20 test credit card numbers covering decline codes, international cards, and prepaid cards."

## Test Architecture Patterns

### Page Object Model (POM)
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

### Screenplay Pattern
- Actors have abilities (browse web, call API). They perform tasks. Tasks are composed of interactions. Questions check state.
- More expressive than POM for complex user journeys.
- Libraries: Serenity/JS (TypeScript), Serenity BDD (Java).

```typescript
// Serenity/JS Screenplay
await actorCalled('Alice').attemptsTo(
  NavigateTo.theCheckoutPage(),
  Enter.theValue(address.street).into(ShippingForm.streetField()),
  Click.on(CheckoutPage.placeOrderButton()),
  Ensure.that(OrderConfirmation.orderNumber(), isPresent()),
);
```

### App Actions Pattern (Cypress)
- Invoke application methods directly to set up state instead of navigating through the UI.
- Faster test setup. Avoid slow UI flows for precondition setup.

```javascript
// Cypress app action
cy.task('db:seed', { users: [{ email: 'admin@test.com', role: 'admin' }] });
cy.window().invoke('app.login', 'admin@test.com', 'password');
// Now test what matters - admin-only behavior - without going through the login UI
```

## Quality Metrics Beyond Coverage

Coverage is a necessary but insufficient measure of test quality:

### DORA Metrics (DevOps Research and Assessment)
- **Deployment Frequency**: How often code is deployed to production. Elite: multiple/day.
- **Lead Time for Changes**: Time from commit to production. Elite: < 1 hour.
- **Change Failure Rate**: Percentage of deployments causing production incidents. Elite: < 5%.
- **Mean Time to Restore (MTTR)**: Time to recover from production failures. Elite: < 1 hour.

### Quality-Specific Metrics
- **Defect Escape Rate**: Percentage of bugs found in production vs total bugs. Target: < 5%.
- **Test Flakiness Rate**: Percentage of test runs with at least one flaky failure. Target: < 1%.
- **Test Execution Time**: P95 time for each test suite. Track trends. Prevent suite slowdown.
- **False Positive Rate**: Test failures not caused by actual bugs. Track and eliminate.
- **Automation Coverage**: Percentage of manual test cases automated. Track by risk category.
- **Bug Detection Rate by Layer**: How many bugs does each test layer find? Justify investment.

### Test Plan Creation

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

## Coverage Goals

- **Line coverage**: Minimum 80% for application code. Measure but do not game.
- **Branch coverage**: Target 75%+ for complex business logic. Every `if/else`, `switch`, and ternary.
- **Path coverage**: Use for critical algorithms (payment calculations, access control decisions).
- **Mutation coverage**: Run mutation testing (Stryker, PITest) on critical modules. Target 70%+ kill rate.
- Coverage is a lagging indicator. A test suite with 90% coverage but no edge case testing is a false safety net.

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
- Environment parity: minimize drift between staging and production. Same versions, same configs.

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
- Include performance criteria in acceptance: "loads within 2 seconds on 4G."
- Include accessibility criteria: "navigable by keyboard, screen reader announces form errors."
