---
name: incident-management
description: |
  Incident management: severity levels (SEV1-4), incident response process, runbook template,
  blameless postmortem template, MTTR benchmarks (Elite teams: <1 hour), on-call rotations,
  escalation paths, communication templates. Use when responding to incidents or building
  incident response processes.
allowed-tools: Read, Grep, Glob
---

# Incident Management

## When to Use This Skill
- Responding to a production incident
- Building incident response processes and runbooks
- Writing blameless postmortems
- Designing on-call rotation and escalation
- Measuring and improving MTTR

## Core Principles

1. **Acknowledge fast, resolve carefully** — 5 minutes to acknowledge, then methodical triage
2. **Blameless postmortems** — systems fail, not people; blame prevents honest reporting
3. **Communicate status before you know the answer** — silence is worse than "investigating"
4. **One incident commander** — avoids coordination chaos; others execute
5. **Action items from every postmortem** — postmortems without follow-up are theater

---

## Patterns ✅

### Severity Levels

```
SEV1 — Critical: Complete service outage or data loss
  - Examples: Payment processing down, auth service down, database data loss
  - Response: Immediate all-hands, 24/7 response
  - Acknowledge: within 5 minutes
  - Resolution target: 1 hour
  - Communication: Every 15 minutes to stakeholders

SEV2 — High: Major feature broken for all users
  - Examples: Checkout broken, API error rate >5%, significant performance degradation
  - Response: On-call engineer + manager
  - Acknowledge: within 15 minutes
  - Resolution target: 4 hours
  - Communication: Every 30 minutes to stakeholders

SEV3 — Medium: Feature degraded or broken for some users
  - Examples: Slow queries for specific user segment, non-critical feature broken
  - Response: Next business hours or on-call if escalated
  - Acknowledge: within 1 hour
  - Resolution target: 24 hours

SEV4 — Low: Minor issue, workaround available
  - Examples: Dashboard rendering bug, non-blocking warning
  - Response: Normal sprint planning
  - Resolution target: Next sprint
```

### Incident Response Runbook Template

```markdown
# [Service Name] Runbook

## Symptoms
- What users see: [description]
- Alert that triggered: [alert name and condition]
- Dashboard: [link]

## Diagnosis Steps
1. Check service health dashboard: [link]
2. Check error rate: `rate(http_requests_total{status_code=~"5.."}[5m])`
3. Check recent deployments: `kubectl rollout history deployment/[service]`
4. Check logs: `kubectl logs -l app=[service] --tail=100`
5. Check upstream dependencies: [dependency health check URLs]

## Common Issues and Fixes

### High Error Rate After Deploy
Cause: Bad deployment
Fix:
  kubectl rollout undo deployment/[service]
  # Verify rollback: watch deployment status
  kubectl rollout status deployment/[service]

### Database Connection Exhaustion
Symptoms: "too many connections" errors in logs
Fix:
  # Check connection count
  SELECT count(*) FROM pg_stat_activity;
  # Restart PgBouncer if needed
  kubectl rollout restart deployment/pgbouncer

### Memory Leak
Symptoms: Memory grows over time, OOM kills
Fix: Rolling restart (temporary)
  kubectl rollout restart deployment/[service]
Long-term: Identify leak with heap dumps

## Escalation Path
- SEV1/SEV2: Ping @oncall-[team] in #incidents
- Database: @database-oncall
- Infrastructure: @infra-oncall
```

### Blameless Postmortem Template

```markdown
# Incident Postmortem: [Title]

**Date**: [YYYY-MM-DD]
**Duration**: [start] to [end] ([total duration])
**Severity**: SEV[N]
**Incident Commander**: [Name]
**Authors**: [Names]

## Impact
- Users affected: [N users / X% of traffic]
- Revenue impact: [estimate]
- Data impact: [none / description]
- SLO impact: [N minutes of error budget consumed]

## Timeline
All times UTC.

| Time  | Event |
|-------|-------|
| HH:MM | Alert fired: [alert name] |
| HH:MM | On-call acknowledged |
| HH:MM | [Key diagnostic finding] |
| HH:MM | [Mitigation action taken] |
| HH:MM | Service restored |
| HH:MM | Postmortem started |

## Root Cause
[One clear sentence describing the root cause]

Detailed explanation: [2-3 paragraphs]

## Contributing Factors
1. [Factor 1 — often: lack of monitoring, insufficient testing]
2. [Factor 2]
3. [Factor 3]

## What Went Well
- [Specific positive thing: "Alert fired within 2 minutes"]
- [Another positive: "Rollback took only 45 seconds"]

## What Went Poorly
- [Specific issue: "No runbook for this failure mode"]
- [Another: "Alert threshold was too high — missed early warning"]

## Action Items
| Item | Owner | Due Date | Priority |
|------|-------|----------|----------|
| Add monitoring for X | @engineer | 2024-02-01 | P1 |
| Write runbook for Y failure | @engineer | 2024-02-08 | P2 |
| Increase test coverage for Z | @engineer | 2024-02-15 | P2 |
| Review alert thresholds | @sre | 2024-02-22 | P3 |

## Lessons Learned
[2-3 key takeaways for the team]
```

### On-Call Rotation and Escalation

```yaml
# PagerDuty / OpsGenie escalation policy
policy:
  name: "Engineering On-Call"
  steps:
    - delay: 0 minutes
      targets:
        - type: schedule
          name: "Primary On-Call"
    - delay: 10 minutes  # Escalate if not acknowledged in 10 minutes
      targets:
        - type: schedule
          name: "Secondary On-Call"
    - delay: 20 minutes  # Escalate to manager
      targets:
        - type: user
          name: "Engineering Manager"
    - delay: 30 minutes  # VP for SEV1 only
      targets:
        - type: user
          name: "VP Engineering"
          # (Only triggered for SEV1 via additional routing rule)
```

### Communication Templates

```
# Initial acknowledgement (within 5 minutes of SEV1/SEV2)
[INCIDENT] SEV2: Checkout page returning 500 errors
Status: Investigating
Impact: Estimated 30% of checkout attempts failing
ETA: Update in 30 minutes
Incident channel: #incident-2024-0215

# Status update (every 15-30 minutes)
[UPDATE 14:35 UTC] SEV2: Checkout errors
Status: Root cause identified — bad deploy at 14:22 UTC
Action: Rollback in progress
ETA: Resolution expected in 10 minutes

# Resolution
[RESOLVED 14:48 UTC] SEV2: Checkout errors
Duration: 26 minutes (14:22 - 14:48 UTC)
Impact: ~800 failed checkout attempts
Resolution: Rolled back to previous deployment
Postmortem: [link] — scheduled for Friday
```

---

## MTTR Benchmarks (DORA)

```
Elite performers:
  MTTR: < 1 hour

High performers:
  MTTR: < 1 day

Medium performers:
  MTTR: < 1 week

Low performers:
  MTTR: > 1 month

Tip: MTTR is primarily a detection + escalation problem.
Most time is spent: detecting → acknowledging → finding root cause.
Improving runbooks and monitoring reduces MTTR more than team size.
```

---

## Anti-Patterns ❌

### Blame-Based Postmortems
**What breaks**: Engineers hide incidents, delay reporting, write defensive postmortems. Real causes go unfixed because admitting them means blame.
**Fix**: Blameless culture. The question is "what failed in the system?" not "who made the mistake?" People operate within systems that failed them.

### Postmortems Without Action Items
**What breaks**: Team writes 2-page postmortem, feels good, nothing changes. Same incident happens 3 months later.
**Rule**: Every postmortem must have at least 2 action items with owners and due dates. Action items reviewed in the next retrospective.

### On-Call Without Runbooks
**What breaks**: 3 AM alert. Engineer has no context. Spends 45 minutes debugging something that has a 2-minute fix documented nowhere.
**Fix**: Every alert that fires must have a corresponding runbook. "No runbook" is a P1 action item after every postmortem.

---

## Quick Reference

```
SEV1: Complete outage — acknowledge in 5 min, resolve target 1h
SEV2: Major feature broken — acknowledge in 15 min, resolve target 4h
SEV3: Degraded — acknowledge in 1h, resolve in 24h
MTTR elite: <1 hour
Postmortem must-haves: timeline, root cause, action items with owners
Communicate status: every 15 min for SEV1, every 30 min for SEV2
Blameless: system failure, not human failure
```
