# AARRR Pirate Metrics

## When to load
Load when defining product metrics, building funnels, or tracking growth.

## The Funnel

```
Acquisition  → How do users find you?
Activation   → Do they have a great first experience?
Retention    → Do they come back?
Revenue      → Do they pay?
Referral     → Do they tell others?
```

## Metrics by Stage

| Stage | Metric | Target | Tool |
|-------|--------|--------|------|
| Acquisition | Visitors/month | Growing | GA4, Plausible |
| Acquisition | CAC (Customer Acquisition Cost) | < 1/3 LTV | Attribution |
| Activation | Signup → first value action | > 40% in 7 days | PostHog, Amplitude |
| Activation | Time to first value | < 5 minutes | Event tracking |
| Retention | D7 retention | > 20% (SaaS) | Cohort analysis |
| Retention | D30 retention | > 10% (SaaS) | Cohort analysis |
| Retention | Monthly churn | < 5% (SaaS) | Subscription data |
| Revenue | MRR (Monthly Recurring Revenue) | Growing | Stripe, ChartMogul |
| Revenue | ARPU (Avg Revenue Per User) | Growing | Stripe |
| Revenue | LTV:CAC ratio | > 3:1 | Calculated |
| Referral | NPS (Net Promoter Score) | > 50 | Survey |
| Referral | Viral coefficient | > 0.5 | Invite tracking |

## Activation: Finding the "Aha Moment"

```
Method:
1. Define candidate activation events:
   - Completed onboarding
   - Created first [core object]
   - Invited first team member
   - Used core feature 3 times

2. Correlate each event with D30 retention:
   Event                        | D30 retention
   Completed onboarding         | 15%
   Created first project        | 35%  ← likely "aha moment"
   Invited team member           | 55%  ← strong signal
   Used feature 3x in first week| 60%  ← strongest signal

3. Optimize funnel toward the strongest activation event
```

## Cohort Retention Table

```
         Week 0  Week 1  Week 2  Week 3  Week 4
Jan cohort  100%    45%     30%     25%     22%
Feb cohort  100%    48%     33%     28%     25%
Mar cohort  100%    52%     38%     32%     30%  ← improving

Reading: "Of users who signed up in March, 52% came back in Week 1"
Goal: each new cohort should retain better than the previous one
```

## Anti-patterns
- Tracking vanity metrics (page views, total signups) → doesn't predict growth
- No activation metric → can't optimize onboarding
- Measuring retention without cohorts → average hides trends
- Optimizing acquisition before retention → filling a leaky bucket

## Quick reference
```
AARRR: Acquisition → Activation → Retention → Revenue → Referral
North Star: one metric that best captures core value delivery
Activation: correlate events with D30 retention to find "aha moment"
Retention: cohort-based, D7 > 20% and D30 > 10% for SaaS
Revenue: LTV:CAC > 3:1, monthly churn < 5%
Referral: viral coefficient > 0.5 = organic growth
Fix order: retention → activation → acquisition (bottom-up)
```
