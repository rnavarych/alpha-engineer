---
name: role-aqa:test-strategy
description: |
  Designs comprehensive test strategies: test pyramid/trophy/diamond/honeycomb models,
  risk-based prioritization, shift-left, mutation testing, testing in production (feature
  flags, canary, shadow traffic), AI-assisted test generation, quality metrics (DORA,
  defect escape rate), test architecture patterns (Page Object, Screenplay, App Actions).
  Use when planning testing efforts, defining coverage goals, or creating test plans.
allowed-tools: Read, Grep, Glob, Bash
---

# Test Strategy

## When to use
- Starting a new project — need to choose pyramid, trophy, diamond, or honeycomb model
- Coverage is high but bugs still ship — need mutation testing or exploratory approach
- Designing CI/CD quality gates and shift-left checkpoints
- Risk-scoring features to allocate test effort proportionally
- Planning safe production validation (canary, feature flags, shadow traffic)
- Creating a formal test plan document with entry/exit criteria
- Choosing between Page Object Model, Screenplay, or App Actions patterns

## Core principles
1. **Test behavior, not implementation** — tests survive refactoring; if touching internals breaks them, they're wrong
2. **Model before metrics** — choose pyramid/trophy/diamond/honeycomb first, then set coverage targets accordingly
3. **Coverage is vanity, mutation score is truth** — 80% line coverage with 0% mutation detection is theater
4. **Shift left relentlessly** — every bug caught at compile time costs 1x; the same bug in production costs 100x
5. **Test in production safely** — canary + synthetic monitors + feature flags beats pretending staging is production

## Reference Files
- `references/distribution-models.md` — pyramid, trophy, diamond, honeycomb explained with ratios and when to pick each
- `references/shift-left-risk-prioritization.md` — shift-left pipeline gates, risk matrix scoring, test impact analysis tools, CI quality gate YAML
- `references/mutation-exploratory-testing.md` — Stryker/PITest/mutmut setup, mutation operators, SBTM exploratory charters, DORA and quality metrics
- `references/testing-in-production.md` — canary deployments, feature flags, shadow traffic, dark launching, synthetic monitoring, AI-assisted test generation
- `references/test-architecture-planning.md` — POM, Screenplay, App Actions patterns with code; regression strategy; environment topology; test plan template; Given/When/Then acceptance criteria
