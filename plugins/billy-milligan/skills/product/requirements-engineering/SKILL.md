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

## When to use
- Writing user stories that meet INVEST criteria
- Defining complete acceptance criteria with edge cases
- Breaking down large features into vertical slices
- Prioritizing backlog with MoSCoW
- Defining non-functional requirements for a feature

## Core principles
1. **INVEST for user stories** — Independent, Negotiable, Valuable, Estimable, Small, Testable
2. **GWT for acceptance criteria** — Given-When-Then; no "and" chains (split them)
3. **Vertical slices** — each story delivers value end-to-end, not "backend only"
4. **Edge cases in the story** — not as surprises during implementation
5. **Non-functional requirements are requirements** — performance, accessibility, security belong in stories

## References available
- `references/user-story-patterns.md` — INVEST checklist, story format templates, story mapping
- `references/story-splitting.md` — splitting strategies by workflow step, data variation, CRUD, quality tier
- `references/acceptance-criteria.md` — Given-When-Then structure, rules per clause, happy path example
- `references/boundary-conditions.md` — boundary condition discovery checklist, negative and concurrent scenario examples
- `references/definition-of-done.md` — DoD concept, recommended DoD checklist
- `references/moscow-prioritization.md` — MoSCoW category definitions, 60/20/20 rule, e-commerce example
- `references/mvp-definition.md` — hypothesis-first approach, MVP scope decision table, Wizard of Oz test
- `references/scope-creep.md` — warning signals, response protocol, negotiation script, release scope lock
- `references/scope-management.md` — story points Fibonacci scale, Planning Poker rules, velocity and capacity formula

## Assets available
- `assets/requirements-template.md` — ready-to-fill story + AC template for new features
