# Incident Postmortem: [TITLE]

**Date**: YYYY-MM-DD
**Duration**: HH:MM to HH:MM UTC ([X hours Y minutes])
**Severity**: SEV[1/2/3/4]
**Incident Commander**: [Name]
**Authors**: [Names of all contributors]
**Review Date**: YYYY-MM-DD

---

## Impact

- Users affected: [N users / X% of traffic]
- Revenue impact: [$ estimate or "none"]
- Data impact: [none / description of any data loss or corruption]
- SLO impact: [N minutes of error budget consumed out of M monthly budget]

## Timeline (all times UTC)

| Time  | Event |
|-------|-------|
| HH:MM | [Triggering event] |
| HH:MM | Alert fired: [alert name and condition] |
| HH:MM | On-call acknowledged |
| HH:MM | IC assigned: [name] |
| HH:MM | [Key diagnostic finding #1] |
| HH:MM | [Key diagnostic finding #2] |
| HH:MM | [Mitigation action taken] |
| HH:MM | Service restored |
| HH:MM | All-clear declared |
| HH:MM | Postmortem meeting scheduled |

## Root Cause

[One clear sentence summarizing the root cause]

[2-3 paragraphs of detailed technical explanation. Include relevant code, configuration, or architecture details. Be specific enough that someone unfamiliar with the system can understand.]

## 5 Whys Analysis

1. Why? [First-level cause]
2. Why? [Second-level cause]
3. Why? [Third-level cause]
4. Why? [Fourth-level cause]
5. Why? [Systemic root cause]

## Contributing Factors

1. [Factor: e.g., "No integration test covered this code path"]
2. [Factor: e.g., "Alert threshold was set too high"]
3. [Factor: e.g., "Runbook did not exist for this failure mode"]

## What Went Well

- [Positive outcome: e.g., "Alert fired within 2 minutes of impact"]
- [Positive outcome: e.g., "Rollback completed in under 1 minute"]
- [Positive outcome: e.g., "Communication was clear and timely"]

## What Went Poorly

- [Issue: e.g., "Took 25 minutes to identify the failing service"]
- [Issue: e.g., "No runbook for database connection exhaustion"]
- [Issue: e.g., "Status page was not updated until 30 minutes after impact"]

## Where We Got Lucky

- [Lucky break: e.g., "Incident happened during business hours, not 3 AM"]
- [Lucky break: e.g., "Only staging database was affected, not production"]

## Action Items

| # | Item | Owner | Due Date | Priority | Ticket |
|---|------|-------|----------|----------|--------|
| 1 | [Specific preventive action] | @name | YYYY-MM-DD | P1 | [LINK] |
| 2 | [Specific detection improvement] | @name | YYYY-MM-DD | P1 | [LINK] |
| 3 | [Specific process improvement] | @name | YYYY-MM-DD | P2 | [LINK] |
| 4 | [Specific documentation update] | @name | YYYY-MM-DD | P2 | [LINK] |

**Priority definitions**:
- P1: Prevents recurrence. Complete within 2 weeks.
- P2: Improves detection or response. Complete within 1 month.
- P3: Nice to have. Complete within quarter.

## Lessons Learned

1. [Key takeaway #1]
2. [Key takeaway #2]
3. [Key takeaway #3]

---

**Postmortem reviewed by**: [Names and date]
**Action items tracked in**: [Link to issue tracker filter]
**Next review date**: YYYY-MM-DD
