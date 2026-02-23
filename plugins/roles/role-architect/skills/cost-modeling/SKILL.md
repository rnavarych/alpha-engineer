---
name: cost-modeling
description: |
  Cost modeling expertise including infrastructure cost estimation, TCO calculation,
  build vs buy analysis, pricing model comparison, ROI projection,
  cost growth modeling, and breakeven analysis.
allowed-tools: Read, Grep, Glob, Bash
---

# Cost Modeling

## When to use
- Estimating infrastructure costs before committing to an architecture
- Calculating 3-year TCO to compare two architectural approaches or vendors
- Deciding whether to build a capability in-house or buy an existing solution
- Comparing per-seat, usage-based, flat-rate, and hybrid pricing models for a tool
- Projecting ROI on a proposed investment with sensitivity analysis
- Modeling how costs will scale as the primary cost driver (users, transactions, data) grows
- Performing breakeven analysis for a migration or build-vs-buy decision

## Core principles
1. **Egress is always the surprise** — model data transfer costs separately before everything else
2. **3-year horizon reveals the truth** — build looks cheaper in year 1; maintenance changes that by year 3
3. **Cost per unit, not total cost** — if cost per user is rising, there is a scaling architecture problem
4. **ROI needs a pessimistic scenario** — if the investment goes negative under realistic downside assumptions, it is risky
5. **Opportunity cost belongs in the model** — time spent building is time not spent on revenue features

## Reference Files
- `references/estimation-tco-build-vs-buy.md` — compute/storage/network/managed service cost estimation, 5-category 3-year TCO structure (license + infrastructure + operations + training + migration), build vs. buy decision criteria and 3-year quantification, and per-seat/usage-based/flat-rate/hybrid pricing model comparison
- `references/roi-growth-breakeven.md` — ROI formula and time-to-ROI calculation, sensitivity analysis (+/- 20% assumptions), linear/sublinear/superlinear cost growth modeling, cost-per-unit trending, cost optimization checkpoint thresholds, and breakeven crossover chart methodology for build-vs-buy and migration decisions
