# SaaS Pricing Models

## When to load
Load when choosing pricing model, structuring tiers, or designing upgrade paths.

## Model Comparison

| Model | Best For | Example | Pros | Cons |
|-------|---------|---------|------|------|
| Flat-rate | Simple products | Basecamp ($99/mo) | Easy to understand | No expansion revenue |
| Per-seat | Collaboration tools | Slack ($8/user/mo) | Predictable, scales with team | Discourages adoption |
| Usage-based | APIs, infrastructure | Twilio (per message) | Aligns with value | Unpredictable revenue |
| Tiered | Most SaaS | GitHub (Free/Pro/Enterprise) | Captures segments | Complex to optimize |
| Hybrid | Mature products | Vercel (seats + usage) | Maximum capture | Complex to explain |

## Tier Design

```
Free tier (acquisition):
  Purpose: remove friction, build habit
  Limits: enough to experience core value
  Example: 3 projects, 1 user, 100 API calls/day

Pro tier ($29-99/mo):
  Purpose: individual professionals, small teams
  Unlock: more projects, team features, integrations
  Target: 60-70% of paying customers

Team tier ($99-299/mo):
  Purpose: growing teams
  Unlock: admin controls, SSO, priority support
  Target: 25-30% of paying customers

Enterprise (custom):
  Purpose: large organizations
  Unlock: SLA, dedicated support, custom integrations, SOC 2 report
  Target: 5-10% of customers, 40-60% of revenue
```

## Pricing Psychology

```
1. Anchoring: show Enterprise first, makes Pro look reasonable
2. Decoy: middle tier should be obviously best value
3. Annual discount: 2 months free (17% discount) for annual billing
4. Usage limits on free: create natural upgrade triggers
5. Price ending: $29 vs $30 (odd pricing feels like a deal)
6. Feature comparison table: make differences visually obvious
```

## Anti-patterns
- Per-seat pricing for developer tools → discourages adoption
- No free tier for self-serve products → kills top-of-funnel
- Pricing page requires "Contact Sales" → friction for SMB
- Too many tiers (5+) → decision paralysis
- No annual discount → higher churn, worse cash flow

## Quick reference
```
Default: 3 tiers (Free, Pro, Enterprise) + annual discount
Per-seat: good for collaboration, bad for dev tools
Usage-based: align with value delivery, budget unpredictability
Hybrid: seats for base + usage for scaling
Annual: 2 months free (17%) standard discount
Enterprise: always custom, always includes SLA + SSO
Price increase: grandfather existing customers for 6-12 months
```
