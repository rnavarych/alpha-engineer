# Incident Response

## Severity Levels

```
SEV1 -- Critical: Complete service outage or data loss
  Examples: payment processing down, auth service down, database data loss
  Response: immediate all-hands, 24/7
  Acknowledge: within 5 minutes
  Resolution target: 1 hour
  Communication: every 15 minutes to stakeholders
  Escalation: VP Engineering notified

SEV2 -- High: Major feature broken for all users
  Examples: checkout broken, API error rate >5%, significant performance degradation
  Response: on-call engineer + manager
  Acknowledge: within 15 minutes
  Resolution target: 4 hours
  Communication: every 30 minutes to stakeholders

SEV3 -- Medium: Feature degraded or broken for some users
  Examples: slow queries for specific segment, non-critical feature broken
  Response: next business hours or on-call if escalated
  Acknowledge: within 1 hour
  Resolution target: 24 hours

SEV4 -- Low: Minor issue, workaround available
  Examples: dashboard rendering bug, non-blocking warning
  Response: normal sprint planning
  Resolution target: next sprint
```

## Incident Commander (IC) Role

```
IC responsibilities:
  1. Own the incident from acknowledgement to resolution
  2. Coordinate responders (assign tasks, not do everything)
  3. Communicate status updates on schedule
  4. Make decisions: rollback now or debug further?
  5. Declare incident resolved
  6. Schedule postmortem

IC does NOT:
  - Debug code (unless alone)
  - Get pulled into implementation details
  - Make changes without communicating
  - Forget to update stakeholders

IC rotation:
  Primary IC: on-call engineer
  Backup IC: secondary on-call or engineering manager
  Escalation: engineering manager takes IC role for SEV1
```

## Communication Templates

### Initial Acknowledgement (within 5 min for SEV1/SEV2)

```
[INCIDENT] SEV{N}: {one-line description}
Status: Investigating
Impact: {estimated scope -- N users, X% of requests}
IC: {name}
Channel: #incident-{YYYY-MMDD}-{short-name}
ETA for next update: {time}
```

### Status Update (every 15-30 min)

```
[UPDATE {HH:MM UTC}] SEV{N}: {title}
Status: {Investigating | Identified | Mitigating | Monitoring}
Current understanding: {what we know}
Action: {what we are doing right now}
ETA: {when we expect next update or resolution}
```

### Resolution

```
[RESOLVED {HH:MM UTC}] SEV{N}: {title}
Duration: {total time}
Impact: {confirmed scope}
Resolution: {what fixed it}
Postmortem: {link} -- scheduled for {date}
```

## Incident Response Flowchart

```
Alert fires
  |
  v
Acknowledge (5 min for SEV1)
  |
  v
Assess severity (SEV1-4)
  |
  v
Open incident channel (#incident-YYYY-MMDD-name)
  |
  v
Post initial status update
  |
  +--> Is it a recent deploy? --> Yes --> Rollback
  |                                        |
  +--> Known issue with runbook? --> Yes --> Follow runbook
  |                                          |
  +--> Unknown issue --> Triage              |
       |                                     v
       v                              Monitor for 15 min
  Investigate logs, metrics, traces         |
       |                                     v
       v                              Resolved? --> Yes --> Post resolution
  Identify root cause                                        |
       |                                                     v
       v                                              Schedule postmortem
  Apply fix (deploy or config change)
       |
       v
  Monitor for 15 min
       |
       v
  Resolved --> Post resolution --> Schedule postmortem
```

## Escalation Policy

```yaml
# PagerDuty / OpsGenie escalation
steps:
  - delay: 0 min
    target: Primary on-call
  - delay: 10 min   # Unacknowledged
    target: Secondary on-call
  - delay: 20 min   # Still unacknowledged
    target: Engineering Manager
  - delay: 30 min   # SEV1 only
    target: VP Engineering
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| No incident channel | Always create dedicated channel for SEV1/SEV2 |
| Everyone debugging at once | IC assigns tasks, coordinates work |
| No status updates | Post on schedule even if status is "still investigating" |
| Fixing root cause during incident | Mitigate first (rollback), investigate after |
| No severity classification | Classify immediately; upgrade if impact increases |

## Quick Reference

- SEV1 acknowledge: **5 min**, resolve: **1 hour**
- SEV2 acknowledge: **15 min**, resolve: **4 hours**
- Status updates: **every 15 min** (SEV1), **every 30 min** (SEV2)
- First action on bad deploy: **rollback** (not debug)
- IC role: coordinate, communicate, decide
- Post-incident: postmortem within **48 hours**
