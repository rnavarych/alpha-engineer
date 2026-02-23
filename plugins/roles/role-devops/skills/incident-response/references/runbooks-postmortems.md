# Runbooks, Postmortems, Status Pages, and Severity Levels

## When to load
Load when writing runbooks for alerts, conducting postmortems, managing public status pages,
defining severity levels, or establishing escalation policies and on-call rotation design.

## Runbook Creation

- Every alert must link to a runbook. A runbook is a step-by-step guide that enables any on-call engineer to diagnose and resolve the issue, even without prior context.
- Structure every runbook with these sections:
  1. **Summary** — What this runbook covers and when to use it.
  2. **Symptoms** — Observable indicators (alert name, dashboard panel, error messages, user reports).
  3. **Impact** — What is affected: which services, which users, what is the blast radius.
  4. **Diagnosis Steps** — Commands and queries to run for investigation. Include exact `kubectl`, `aws`, or `gcloud` commands.
  5. **Resolution Steps** — Concrete actions to fix the issue, ordered by likelihood. Include rollback procedures.
  6. **Escalation** — When and to whom to escalate if initial steps do not resolve the issue.
  7. **Prevention** — Links to follow-up tasks or architecture changes that would prevent recurrence.
- Store runbooks in version control alongside infrastructure code. Link them from alert annotations and dashboard panels.
- Review and update runbooks quarterly or after every incident that reveals gaps.

## Postmortem Templates

- Conduct a blameless postmortem for every Severity 1 and Severity 2 incident within 48 hours of resolution.
- Use this template structure:

```markdown
# Postmortem: [Incident Title]
**Date:** YYYY-MM-DD | **Duration:** Xh Ym | **Severity:** S1/S2
**Author:** [Name] | **Reviewers:** [Names]

## Summary
One-paragraph description of what happened and the customer impact.

## Timeline (all times UTC)
- HH:MM - First alert fires / customer report received
- HH:MM - On-call acknowledges, begins investigation
- HH:MM - Root cause identified
- HH:MM - Fix deployed / mitigation applied
- HH:MM - Incident declared resolved

## Root Cause
Detailed technical explanation of why the incident occurred.

## Contributing Factors
Other conditions that enabled or worsened the incident.

## What Went Well
Things that worked during the response (detection, tooling, communication).

## What Went Poorly
Things that hindered the response (gaps in monitoring, unclear ownership).

## Action Items
| Action | Owner | Priority | Due Date |
|--------|-------|----------|----------|
| [Specific task] | [Name] | P1/P2 | YYYY-MM-DD |
```

- Publish postmortems internally so the entire engineering organization can learn from incidents.

## Status Page Management

- Maintain a public status page (Statuspage.io, Cachet, Instatus, or a custom page) for customer-facing services.
- Define component categories: API, Web Application, Database, Authentication, Third-Party Integrations.
- Use clear status levels: **Operational**, **Degraded Performance**, **Partial Outage**, **Major Outage**.
- Post updates at regular intervals during incidents (every 15-30 minutes) even if there is no new information. Customers need to know the team is actively working.
- After resolution, post a customer-facing summary that avoids internal jargon.

## Escalation Policies and Severity Levels

- Define severity levels with clear criteria:
  - **S1 (Critical)** — Complete service outage or data loss. All hands on deck. Customer-facing impact.
  - **S2 (Major)** — Significant degradation. Primary on-call plus team lead. Visible customer impact.
  - **S3 (Minor)** — Limited impact. Primary on-call handles. Minimal customer visibility.
  - **S4 (Low)** — Cosmetic or non-urgent. Handled during business hours.
- Escalation timing: S1 auto-escalates after 5 minutes unacknowledged. S2 after 15 minutes. S3 after business hours.
- Designate an **Incident Commander** for S1/S2 incidents who coordinates communication, not debugging.

## On-Call Rotation

- Design rotations with adequate coverage: primary and secondary on-call. Rotate weekly to distribute burden.
- Ensure on-call engineers have access to all necessary tools: VPN, cloud consoles, dashboards, Slack channels, PagerDuty.
- Compensate on-call time with time-off or additional pay. Burnout from unsustainable on-call is a reliability risk.
- Track on-call metrics: number of pages, time to acknowledge, time to resolve. Review monthly to identify noisy alerts.
- Schedule on-call handoffs with a brief sync: outgoing engineer briefs incoming on active issues and recent changes.
