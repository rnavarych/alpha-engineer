---
name: metrics-analytics
description: |
  Product analytics: AARRR framework, North Star Metric, A/B testing with statistical
  significance (95% confidence, minimum detectable effect), PostHog event tracking,
  funnel analysis, retention cohorts, feature flags for experiments. Vanity metrics vs
  actionable metrics. Use when defining KPIs, designing experiments, interpreting data.
allowed-tools: Read, Grep, Glob
---

# Product Metrics & Analytics

## When to use
- Defining KPIs and North Star Metric for a product
- Designing A/B tests with proper statistical rigor
- Implementing event tracking architecture
- Interpreting funnel drop-off and cohort retention
- Avoiding vanity metrics that feel good but don't drive decisions

## Core principles
1. **North Star Metric is singular** — the one number that best captures value delivered to users; everything else is a lever
2. **Actionable > vanity** — "weekly active writers" beats "total registered users"; you can act on the former
3. **A/B tests need pre-registered sample sizes** — running until you see p<0.05 is p-hacking
4. **Events track actions, not pages** — `document_published` reveals intent; `/dashboard` does not
5. **Retention is the metric that matters most** — acquisition without retention is a leaky bucket

## References available
- `references/aarrr-funnel.md` — AARRR stage definitions, benchmark targets, North Star examples by product type
- `references/ab-testing.md` — sample size calculation, significance levels, sequential testing, peeking problem
- `references/event-tracking.md` — event taxonomy ([object]_[verb]), PostHog setup, funnel SQL, cohort retention queries

## Assets available
- `assets/metrics-dashboard-template.md` — North Star + input metrics dashboard layout, KPI tracking table
