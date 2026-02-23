# Definition of Done

## When to load
Load when establishing or reviewing a team's Definition of Done, auditing whether a story is truly complete, or distinguishing between acceptance criteria passing and the story meeting craft standards.

---

## What DoD Is

DoD is the team-level contract that every story must meet before it's marked complete. Acceptance criteria verify the story behavior; DoD verifies the craft. A story with all ACs green but no tests written is not done.

---

## Recommended DoD Checklist

```
Code quality:
  [ ] Code reviewed by at least one peer
  [ ] No linting errors or TypeScript errors
  [ ] No debug output (console.log, print statements) in committed code
  [ ] Magic numbers replaced with named constants

Testing:
  [ ] Unit tests written for new functions and business logic
  [ ] Integration tests written for new API endpoints
  [ ] All acceptance criteria verified by automated test or manual QA sign-off
  [ ] Existing test suite passes — no regressions

Documentation:
  [ ] Public functions have JSDoc with parameters, return type, and edge cases
  [ ] API endpoints documented (OpenAPI / Swagger updated if applicable)
  [ ] README updated if setup steps changed

Deployment readiness:
  [ ] Feature flag configured for gradual rollout (if applicable)
  [ ] Database migrations tested: can run forward and rollback cleanly
  [ ] Deployed to staging and smoke-tested
  [ ] Environment variables documented in .env.example

Observability:
  [ ] Structured logs added to critical paths (info for state changes, error for failures)
  [ ] Metrics or alerts configured if this is a high-traffic or revenue-critical path

Non-functional:
  [ ] Performance measured against response time budget
  [ ] Accessibility: keyboard navigation works, ARIA labels present on interactive elements
  [ ] Mobile: tested at 375px width (iPhone SE)
  [ ] Security: user input validated and sanitized; no secrets in code
```

---

## Anti-Patterns

### "Done" Without DoD
"I finished coding" is not done. "Code reviewed, tests passing, deployed to staging, ACs verified" is done. Incomplete "done" accumulates as technical debt that always costs more to fix later.

### DoD That Keeps Growing Mid-Sprint
Adding new DoD items during a sprint means stories in progress are now measured against criteria they weren't planned against. Establish DoD at sprint planning and hold it stable for the duration.

---

## Quick Reference

```
DoD vs ACs: ACs verify behavior, DoD verifies craft — both must pass
Non-negotiable DoD items: peer review, tests passing, no linting errors, deployed to staging
DoD is team-owned: agreed at the start of the sprint, not changed mid-sprint
"Done" = ACs verified + DoD checklist complete — not just "code merged"
```
