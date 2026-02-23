# Mutation Testing and Exploratory Testing

## When to load
When coverage looks good but bugs still ship; when validating test suite quality with mutation testing; when planning exploratory testing sessions; when assessing test effectiveness beyond coverage numbers.

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
- **Killed mutant**: A test failed because of the mutation. Good — tests detected the change.
- **Survived mutant**: No test failed. The mutation went undetected. Tests are incomplete.
- **Mutation score**: percentage of killed/total. Target 70%+ on critical modules.
- Focus mutation testing on business-critical code. Running it on everything is slow and expensive.

## Exploratory Testing

Structured exploration finds what automation misses:

### Session-Based Test Management (SBTM)
- **Charter**: Define the exploration goal (mission) and area to explore.
- **Time-box**: 60-90 minutes of focused exploration. No interruptions.
- **Debrief**: Document findings, issues, and coverage within 15 minutes of the session.
- Example charter: "Explore the checkout flow as a mobile user with an expired card on a slow network."

### Exploratory Testing Techniques
- **Tour testing**: Landmark tour (major features), FedEx tour (follow data through the system), Garbage collector tour (error paths, edge inputs).
- **Attack testing**: SQL injection, XSS, auth bypass, parameter tampering.
- **Persona testing**: Test as different user roles, device types, connection speeds, and locales.
- **State transition testing**: Find invalid state transitions. What happens if you refresh mid-checkout?

## Coverage Goals

- **Line coverage**: Minimum 80% for application code. Measure but do not game.
- **Branch coverage**: Target 75%+ for complex business logic. Every `if/else`, `switch`, and ternary.
- **Path coverage**: Use for critical algorithms (payment calculations, access control decisions).
- **Mutation coverage**: Run mutation testing on critical modules. Target 70%+ kill rate.
- Coverage is a lagging indicator. A test suite with 90% coverage but no edge case testing is a false safety net.

## Quality Metrics Beyond Coverage

### DORA Metrics
- **Deployment Frequency**: How often code is deployed to production. Elite: multiple/day.
- **Lead Time for Changes**: Time from commit to production. Elite: < 1 hour.
- **Change Failure Rate**: Percentage of deployments causing production incidents. Elite: < 5%.
- **Mean Time to Restore (MTTR)**: Time to recover from production failures. Elite: < 1 hour.

### Quality-Specific Metrics
- **Defect Escape Rate**: Percentage of bugs found in production vs total bugs. Target: < 5%.
- **Test Flakiness Rate**: Percentage of test runs with at least one flaky failure. Target: < 1%.
- **Test Execution Time**: P95 time for each test suite. Track trends. Prevent suite slowdown.
- **False Positive Rate**: Test failures not caused by actual bugs. Track and eliminate.
- **Bug Detection Rate by Layer**: How many bugs does each test layer find? Justify investment.
