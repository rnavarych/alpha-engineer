---
name: contract-testing
description: |
  Contract testing: Pact consumer-driven contracts (provider states, interaction definitions),
  provider verification with state handlers, OpenAPI validation middleware, breaking change
  detection. Use when microservices need integration confidence without full e2e tests.
allowed-tools: Read, Grep, Glob
---

# Contract Testing

## When to use
- Building microservices that need integration confidence
- Replacing brittle integration tests with faster contract tests
- Detecting breaking API changes before deployment
- Setting up provider verification in CI

## Core principles

1. **Consumer drives the contract** — the client defines what it actually needs
2. **Provider verifies against consumer contracts** — not against a human-written spec
3. **Contracts live in Pact Broker** — visible to all teams, tracked over time
4. **State handlers make tests reproducible** — provider sets up data for each interaction
5. **Can-I-Deploy check** — never deploy a provider that breaks a consumer contract

## References available
- `references/consumer-pact-test.md` — PactV3 setup, MatchersV3, interaction definition, executeTest
- `references/provider-verification.md` — Verifier config, stateHandlers, Pact Broker publish, CI flags
- `references/openapi-validation.md` — express-openapi-validator middleware, validateResponses in staging
- `references/can-i-deploy.md` — pact-broker CLI check, CI gate before deploy, exit code semantics
