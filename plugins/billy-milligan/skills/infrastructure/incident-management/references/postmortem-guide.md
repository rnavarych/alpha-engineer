# Postmortem Guide

## When to load
Load when writing a postmortem, facilitating a post-incident review, applying 5 Whys analysis,
or establishing the follow-through process for action items.

## Blameless Postmortem Principles

```
1. Focus on SYSTEMS, not people
   Bad:  "John deployed broken code"
   Good: "The deployment pipeline lacked integration tests for the payment module"

2. Assume good intent
   Everyone involved was doing their best with the information they had.

3. No counterfactuals
   Bad:  "If we had tested more, this wouldn't have happened"
   Good: "The test suite did not cover the edge case of concurrent cart updates"

4. Multiple contributing factors
   Incidents rarely have a single root cause. List all contributing factors.

5. Action items are the point
   A postmortem without action items is documentation theater.
```

## Postmortem Structure

```markdown
# Incident Postmortem: {Title}

**Date**: YYYY-MM-DD
**Duration**: HH:MM to HH:MM UTC (X hours Y minutes)
**Severity**: SEV{N}
**Incident Commander**: {Name}
**Authors**: {Names}

## Impact
- Users affected: {N users / X% of traffic}
- Revenue impact: {estimate or "none"}
- Data impact: {none / description}
- SLO impact: {N minutes of error budget consumed}

## Timeline (all times UTC)
| Time  | Event |
|-------|-------|
| HH:MM | {triggering event} |
| HH:MM | Alert fired: {alert name} |
| HH:MM | On-call acknowledged |
| HH:MM | IC assigned |
| HH:MM | {diagnostic finding} |
| HH:MM | {mitigation action} |
| HH:MM | Service restored |
| HH:MM | All-clear declared |

## Root Cause
{One clear sentence.}

{2-3 paragraphs of detailed explanation.}

## Contributing Factors
1. {Factor: lack of test coverage for X}
2. {Factor: no alert for Y condition}
3. {Factor: runbook missing for Z scenario}

## What Went Well
- {Positive: "Alert fired within 2 minutes of impact"}
- {Positive: "Rollback completed in 45 seconds"}
- {Positive: "IC communication was clear and timely"}

## What Went Poorly
- {Issue: "No runbook for this failure mode"}
- {Issue: "Alert threshold too high, missed early warning"}
- {Issue: "Took 20 minutes to identify which deploy caused the issue"}

## Action Items
| # | Item | Owner | Due Date | Priority | Status |
|---|------|-------|----------|----------|--------|
| 1 | {Specific action} | @name | YYYY-MM-DD | P1 | Open |
| 2 | {Specific action} | @name | YYYY-MM-DD | P2 | Open |
| 3 | {Specific action} | @name | YYYY-MM-DD | P2 | Open |

## Lessons Learned
{2-3 key takeaways}
```

## 5 Whys Technique

```
Problem: Users received duplicate order confirmation emails

Why 1: The email service sent the confirmation twice
Why 2: The order-completed event was published twice
Why 3: The order service retried after a timeout, but the first request had succeeded
Why 4: The payment gateway response took 35 seconds (timeout was 30s)
Why 5: The payment gateway was experiencing degraded performance due to a database migration

Root cause: Missing idempotency key on order completion, combined with
tight timeout on payment gateway call.

Action items:
  1. Add idempotency key to order completion (prevent duplicates)
  2. Increase payment gateway timeout to 60s
  3. Add circuit breaker for payment gateway
  4. Add alert for payment gateway latency > 10s
```

## Action Item Quality

```
Good action items:
  - Specific: "Add integration test for concurrent cart update scenario"
  - Measurable: "Reduce MTTR for payment incidents from 45m to 15m"
  - Have an owner: "@alice"
  - Have a deadline: "2024-03-01"
  - Have a priority: P1 (prevents recurrence), P2 (improves detection)

Bad action items:
  - "Be more careful" (not actionable)
  - "Improve testing" (not specific)
  - "Fix the bug" (already done, not preventive)
  - No owner assigned (nobody accountable)
  - No deadline (never completed)
```

## Follow-Through Process

```
Postmortem meeting: within 48 hours of incident resolution
  Attendees: IC, responders, affected team leads
  Duration: 30-60 minutes
  Output: reviewed postmortem document with approved action items

Action item tracking:
  - Enter action items into issue tracker (Jira, Linear, GitHub Issues)
  - Tag with "postmortem" label
  - Review progress in weekly team standup
  - Review completion in monthly reliability review

Closure criteria:
  - All P1 items completed within 2 weeks
  - All P2 items completed within 1 month
  - Postmortem document archived in team wiki
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Blame individuals | Focus on system failures and processes |
| No action items | Minimum 2 action items with owners and dates |
| Action items without follow-up | Track in issue tracker, review weekly |
| Postmortem delayed > 1 week | Schedule within 48 hours while memory is fresh |
| Only IC writes postmortem | Collaborative: all responders contribute |

## Quick Reference

- Schedule postmortem: **within 48 hours**
- Minimum action items: **2** with owners and deadlines
- P1 action items: complete within **2 weeks**
- P2 action items: complete within **1 month**
- 5 Whys: keep asking until you reach a systemic cause
- Blameless: systems fail, not people
- Severity classification and MTTR benchmarks: see incident-metrics.md
