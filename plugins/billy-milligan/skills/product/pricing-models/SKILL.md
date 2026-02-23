---
name: pricing-models
description: |
  SaaS pricing models: per-seat, usage-based, tiered, freemium economics. Stripe subscription
  schema (Products, Prices, Subscriptions, Metered billing), upgrade/downgrade proration,
  trial periods, dunning management, LTV:CAC ratio targets. Pricing psychology principles.
  Use when designing pricing strategy, implementing billing, evaluating pricing model fit.
allowed-tools: Read, Grep, Glob
---

# SaaS Pricing Models & Billing

## When to use
- Choosing pricing model for a SaaS product
- Implementing subscription billing with Stripe
- Designing upgrade/downgrade flows with proration
- Setting up usage-based metered billing
- Managing failed payments (dunning)

## Core principles
1. **Pricing is product strategy** — your pricing model determines what behavior you incentivize
2. **Value metric alignment** — the thing you charge for should grow as value delivered grows
3. **Freemium is a distribution strategy, not a pricing model** — conversion rate 1-5% is normal; plan the economics
4. **Metered billing lowers entry cost** — but increases customer unpredictability anxiety
5. **LTV:CAC > 3x is the benchmark** — below 1x is burning cash; below 3x means slow growth

## References available
- `references/saas-pricing.md` — per-seat vs usage-based vs tiered vs flat-rate decision guide, freemium economics
- `references/billing-integration.md` — Stripe subscription schema, proration behavior, dunning retry schedule, trial reminders
- `references/freemium-strategy.md` — conversion benchmarks, activation milestone design, churn targets by segment
