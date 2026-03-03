---
name: role-aqa:api-testing
description: |
  API test automation with Postman/Newman, REST Assured, SuperTest, and httpx.
  Contract testing (Pact, consumer-driven), schema validation (JSON Schema, OpenAPI),
  mock servers (WireMock, MSW), API performance baselines, and auth token management.
  Use when testing REST/GraphQL APIs or setting up API test infrastructure.
allowed-tools: Read, Grep, Glob, Bash
---

# API Testing

## When to use
- Writing integration tests for REST or GraphQL endpoints (SuperTest, REST Assured, httpx)
- Setting up contract testing between consumer and provider services with Pact
- Validating API responses against an OpenAPI spec or JSON Schema
- Configuring WireMock or MSW to stub external dependencies in tests
- Auditing coverage of an existing API test suite against the HTTP scenario checklist
- Running Newman collections in CI pipelines
- Setting performance baselines for critical endpoints

## Core principles
1. **Test the contract, not the implementation** — verify what the API returns, not how it produces it
2. **Every status code is a scenario** — 200 is one test; 400, 401, 403, 404, 429 are five more
3. **Mock at the network boundary** — WireMock/MSW intercept at the wire; never mock internal service methods
4. **Tokens come from helpers, never fixtures** — hardcoded tokens in test files are a security incident waiting to happen
5. **Performance baselines belong in CI** — if P95 regresses >20%, it's a bug, not a metric

## Reference Files
- `references/tools-and-patterns.md` — tool selection table, SuperTest examples, Pact contract testing workflow, schema validation with schemathesis, WireMock and MSW mock server setup, auth token patterns, performance baseline approach
- `references/coverage-checklist.md` — HTTP scenario coverage checklist (happy path through rate limiting), GraphQL-specific scenarios, error response quality standards, edge cases worth testing
