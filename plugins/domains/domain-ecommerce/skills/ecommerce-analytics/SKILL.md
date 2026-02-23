---
name: ecommerce-analytics
description: |
  E-commerce analytics: conversion funnel tracking (browse to purchase), revenue attribution,
  cohort analysis, customer lifetime value (CLV), RFM segmentation, A/B test analysis
  (statistical significance), and key metrics (AOV, conversion rate, cart abandonment rate,
  repeat purchase rate).
allowed-tools: Read, Grep, Glob, Bash
---

# E-Commerce Analytics

## When to use
- Building or debugging conversion funnel tracking (browse → product view → cart → checkout → purchase)
- Implementing revenue attribution models (last click, first click, linear, data-driven)
- Running cohort retention analysis to compare acquisition cohorts over time
- Calculating or predicting customer lifetime value (CLV) for CAC decisions
- Segmenting customers with RFM (Recency, Frequency, Monetary) scoring
- Designing or analyzing A/B tests with proper statistical rigor
- Setting up a core e-commerce metrics dashboard with anomaly alerting

## Core principles
1. **Segment every funnel** — aggregate conversion rates hide the signal; break by device, source, and customer type
2. **CLV must outpace CAC 3:1** — anything lower and the acquisition engine is destroying value, not creating it
3. **Sample size before peeking** — underpowered A/B tests produce false winners; calculate required n before starting
4. **RFM actions must differ per segment** — Champions and Lost customers cost the same to email but have opposite expected ROI
5. **Alert on rate drops, not absolute counts** — seasonal volume swings mask conversion rate problems in absolute metrics

## Reference Files
- `references/funnel-attribution-cohorts.md` — funnel stage definitions, tracking implementation, bottleneck diagnosis, attribution models, cohort analysis, CLV calculation
- `references/rfm-abtesting-metrics.md` — RFM dimension scoring, segment actions, A/B test statistical design and reporting, core and operational KPI dashboard
