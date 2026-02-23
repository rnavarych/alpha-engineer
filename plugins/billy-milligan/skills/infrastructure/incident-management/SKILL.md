---
name: incident-management
description: |
  Incident management patterns. Severity levels (SEV1-4), incident commander role, blameless postmortems, chaos engineering, communication templates, MTTR benchmarks.
allowed-tools: Read, Grep, Glob
---

# Incident Management

## When to use

Use when responding to production incidents, building incident response processes, writing postmortems, or planning chaos engineering exercises. Covers the full incident lifecycle from detection to follow-through.

## Core principles

1. Acknowledge fast, resolve carefully — 5 minutes to acknowledge, then methodical triage
2. One incident commander — avoids coordination chaos; others execute
3. Blameless postmortems — systems fail, not people; blame prevents honest reporting
4. Action items with owners — postmortems without follow-up are theater
5. Practice failure — chaos engineering finds weaknesses before customers do

## References available

- `references/incident-response.md` — Severity levels (SEV1-4), IC role, communication templates
- `references/postmortem-guide.md` — Blameless postmortem template, 5 whys, action item quality, follow-through
- `references/incident-metrics.md` — MTTD, MTTR, MTBF benchmarks, SLO error budget tracking, reliability dashboard
- `references/chaos-engineering.md` — Chaos Monkey, Litmus, failure injection, game day planning

## Assets available

- `assets/incident-template.md` — Fill-in incident report template
- `assets/postmortem-template.md` — Fill-in blameless postmortem template
