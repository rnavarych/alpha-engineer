---
name: capacity-planning
description: |
  Capacity planning expertise including traffic estimation, resource sizing,
  growth modeling, peak load planning, infrastructure runway calculation,
  and load testing correlation.
allowed-tools: Read, Grep, Glob, Bash
---

# Capacity Planning

## When to use
- Estimating infrastructure needs for a new service before launch
- Sizing CPU, memory, storage, and network for a given traffic profile
- Planning for seasonal peaks, product launches, or viral traffic events
- Calculating how much runway remains before current infrastructure reaches capacity
- Correlating load test results to real capacity thresholds and SLA boundaries
- Integrating continuous load testing into CI/CD pipelines

## Core principles
1. **DAU to QPS is the foundation** — business metrics drive infrastructure math, not gut feel
2. **Plan for 2x, stress-test for 5x** — expected case determines the design; worst case tests it
3. **Shortest runway is the binding constraint** — CPU, memory, storage, and network all need their own runway calculation
4. **Revalidate quarterly** — growth projections are always wrong; the question is by how much
5. **Load tests are perishable** — capacity baselines stale within a release cycle without continuous testing

## Reference Files
- `references/traffic-and-resource-sizing.md` — DAU-to-QPS conversion, peak multipliers by app type, traffic composition (read/write ratios), CPU/memory/storage/network sizing rules, target utilization headroom percentages, and linear/exponential/step-function growth modeling
- `references/peak-load-and-load-testing.md` — seasonal and event-driven peak planning, thundering herd mitigation, infrastructure runway formula and minimum thresholds, load test baseline establishment at current/2x/projected peak, capacity ceiling identification, and continuous load testing integration with CI/CD
