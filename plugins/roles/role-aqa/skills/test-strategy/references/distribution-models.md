# Test Distribution Models

## When to load
When choosing between pyramid, trophy, diamond, or honeycomb; when evaluating test suite composition; when pyramid inversion is detected or suspected.

## Test Pyramid (Classic)
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

## Testing Trophy (Kent C. Dodds)
```
        [ E2E ]            (few, high value journeys)
   [ Integration ]         (most tests - service interactions, DB, API)
  [  Unit Tests  ]         (pure logic, algorithms, utils)
[ Static Analysis ]        (TypeScript, ESLint - free bug prevention)
```
- Integration tests give the best ROI in modern full-stack and microservice architectures.
- Static analysis (TypeScript, linting) sits below unit tests and prevents entire classes of bugs at zero runtime cost.
- Favored for React/Node.js applications with Testing Library at the integration layer.

## Testing Diamond
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

## Testing Honeycomb (Spotify Model)
```
 (integrated service tests form the main body)
 Unit tests only for pure complex logic
 End-to-end tests for critical user journeys
```
- Replaces the pyramid with integrated service tests as the primary testing mechanism.
- Each service is tested as a deployed unit against real (or containerized) dependencies.
- Reduces mocking complexity at the cost of slower test feedback.
- Introduced by Spotify for microservice architectures.
