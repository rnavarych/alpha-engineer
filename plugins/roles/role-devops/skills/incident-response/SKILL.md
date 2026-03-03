---
name: role-devops:incident-response
description: |
  Incident response expertise covering runbook creation, postmortem templates,
  status page management, on-call rotation design, escalation policies,
  chaos engineering practices, and game day exercises.
allowed-tools: Read, Grep, Glob, Bash
---

# Incident Response

## When to use
- Writing or reviewing runbooks for existing alerts
- Conducting a postmortem after an S1 or S2 incident
- Defining severity levels and escalation policies for a new team or service
- Designing on-call rotation structure and compensation policy
- Planning chaos engineering experiments or game day exercises
- Setting up or improving a public status page

## Core principles
1. **Every alert has a runbook** — no orphan alerts, no alert without next steps
2. **Blameless postmortems** — systems fail, people respond; find the system gap
3. **Chaos before incidents do** — controlled experiments beat production surprises
4. **Incident Commander separates concerns** — someone coordinates, others debug
5. **Status page is not optional** — customers need to know you know it's broken

## Reference Files

- `references/runbooks-postmortems.md` — Runbook 7-section structure with exact commands, blameless postmortem template (timeline, root cause, action items table), public status page component model and update cadence, severity level definitions (S1-S4) with escalation timing, on-call rotation design and handoff protocol
- `references/chaos-gamedays.md` — Chaos engineering steady-state hypothesis model, Litmus/Chaos Mesh/Gremlin/AWS FIS tooling, experiment design checklist and common scenarios (pod kill, network partition, AZ failure, DB failover), game day structure (pre-brief, inject, respond, debrief), MTTD/MTTA/MTTR tracking across exercises

## Best Practices Checklist
1. Every alert links to an up-to-date runbook
2. Blameless postmortems within 48 hours of S1/S2 incidents
3. Public status page with defined components and statuses
4. On-call rotation with primary and secondary coverage
5. Severity levels and escalation timing documented
6. Chaos experiments run regularly in staging
7. Quarterly game days with cross-functional participation
8. Postmortem action items tracked to completion
