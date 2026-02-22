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

## When to Use This Skill
- Defining KPIs and North Star Metric for a product
- Designing A/B tests with proper statistical rigor
- Implementing event tracking architecture
- Interpreting funnel drop-off and cohort retention
- Avoiding vanity metrics that feel good but don't drive decisions

## Core Principles

1. **North Star Metric is singular** — the one number that best captures value delivered to users; everything else is a lever
2. **Actionable > vanity** — "weekly active writers" beats "total registered users"; you can act on the former
3. **A/B tests need pre-registered sample sizes** — running until you see p<0.05 is p-hacking
4. **Events track actions, not pages** — `document_published` reveals intent; `/dashboard` does not
5. **Retention is the metric that matters most** — acquisition without retention is a leaky bucket

---

## Patterns ✅

### North Star Metric Framework

```
North Star = single metric capturing value exchange between users and product

Examples by product type:
  Messaging app:   Daily active users sending messages (>1/day)
  E-commerce:      Weekly revenue per active buyer
  SaaS productivity: Documents created per active workspace
  Marketplace:     Successful transactions per month
  Media:           Total time spent on quality content (minutes/session × sessions/week)

Input metrics (levers that drive North Star):
  ┌─────────────────────────────────────────┐
  │         North Star: Weekly Revenue      │
  │  Input 1: Conversion rate (visit→buy)   │
  │  Input 2: Average order value           │
  │  Input 3: Repeat purchase rate          │
  │  Input 4: Traffic (new users)           │
  └─────────────────────────────────────────┘

Anti-pattern: "Revenue" as North Star
  Revenue is a lagging indicator. By the time it drops, users have already left.
  Better: "Successful orders per active buyer" — captures retention AND value.
```

### AARRR Funnel Metrics

```
Acquisition:  How do users find you?
  Metrics: CAC by channel, traffic by source, signup rate by source
  Actionable: cut channels with CAC > 3× LTV

Activation:   Do users have their "aha moment"?
  Metrics: % completing onboarding, time to first value (TTFV)
  Good benchmark: >40% activation within 7 days

Retention:    Do users come back?
  Metrics: Day 1/7/30 retention, monthly cohort retention curves
  Good benchmark (SaaS): >20% Day 30 retention

Revenue:      Does usage convert to revenue?
  Metrics: MRR, ARPU, LTV, LTV:CAC ratio
  Healthy: LTV:CAC > 3×; payback < 12 months

Referral:     Do users bring others?
  Metrics: NPS, viral coefficient, referral conversion rate
  Viral: coefficient > 1 means organic growth
```

### A/B Testing with Statistical Rigor

```typescript
// Pre-register sample size BEFORE running the test — never run until you see significance

// Sample size calculation
// Effect size: minimum meaningful improvement (e.g., 10% lift in conversion)
// Significance level: 0.05 (5% false positive rate)
// Power: 0.80 (80% chance to detect real effect)

function calculateSampleSize(
  baselineConversionRate: number,  // e.g., 0.03 (3%)
  minimumDetectableEffect: number, // e.g., 0.20 (20% relative lift → 3.6%)
  alpha: number = 0.05,
  power: number = 0.80
): number {
  // Simplified formula for two-proportion z-test
  const p1 = baselineConversionRate;
  const p2 = p1 * (1 + minimumDetectableEffect);
  const pAvg = (p1 + p2) / 2;

  const zAlpha = 1.96;   // z-score for alpha = 0.05 (two-tailed)
  const zBeta = 0.842;   // z-score for power = 0.80

  const n = (
    Math.pow(zAlpha * Math.sqrt(2 * pAvg * (1 - pAvg)) +
             zBeta * Math.sqrt(p1 * (1 - p1) + p2 * (1 - p2)), 2)
  ) / Math.pow(p2 - p1, 2);

  return Math.ceil(n);
}

// Example:
// Baseline: 3% checkout conversion
// MDE: 20% relative (want to detect 0.6% absolute lift → 3.6%)
// Sample size: ~4,400 per variant → 8,800 total
// At 100 checkouts/day: run for 88 days

// Never peek early — set the end date and don't look until it's reached
const sampleSize = calculateSampleSize(0.03, 0.20);
console.log(`Run until ${sampleSize} users per variant`);
```

### PostHog Event Tracking Architecture

```typescript
// Event taxonomy: [object]_[verb] pattern
// Good: document_created, checkout_started, payment_failed
// Bad: page_view /checkout (too vague), user_did_something (meaningless)

import PostHog from 'posthog-node';

const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: 'https://eu.posthog.com',  // EU data residency for GDPR
  flushAt: 20,     // Batch size
  flushInterval: 10_000,  // Flush every 10s
});

// Server-side event tracking (authoritative — can't be blocked by ad blockers)
export class AnalyticsService {
  trackEvent(userId: string, event: string, properties: Record<string, unknown> = {}): void {
    posthog.capture({
      distinctId: userId,
      event,
      properties: {
        ...properties,
        $timestamp: new Date().toISOString(),
      },
    });
  }

  // Key events to track
  trackOrderPlaced(userId: string, order: Order): void {
    this.trackEvent(userId, 'order_placed', {
      orderId: order.id,
      total: order.total.amount,
      currency: order.total.currency,
      itemCount: order.items.length,
      isFirstOrder: order.isFirstOrder,
    });
  }

  trackCheckoutAbandoned(userId: string, step: string, cartValue: number): void {
    this.trackEvent(userId, 'checkout_abandoned', { step, cartValue });
  }

  // User identification (on login/signup)
  identifyUser(userId: string, properties: UserProperties): void {
    posthog.identify({
      distinctId: userId,
      properties: {
        email: properties.email,
        plan: properties.plan,
        createdAt: properties.createdAt,
        // Don't include PII beyond what's needed
      },
    });
  }
}
```

### Funnel Analysis & Cohort Retention

```sql
-- Checkout funnel analysis
-- Shows drop-off at each step

WITH funnel AS (
  SELECT
    date_trunc('week', first_step.timestamp) AS week,
    COUNT(DISTINCT first_step.user_id)  AS checkout_started,
    COUNT(DISTINCT second_step.user_id) AS shipping_entered,
    COUNT(DISTINCT third_step.user_id)  AS payment_entered,
    COUNT(DISTINCT fourth_step.user_id) AS order_placed
  FROM events first_step
  LEFT JOIN events second_step
    ON first_step.user_id = second_step.user_id
    AND second_step.event = 'shipping_entered'
    AND second_step.timestamp > first_step.timestamp
    AND second_step.timestamp < first_step.timestamp + INTERVAL '1 hour'
  LEFT JOIN events third_step
    ON first_step.user_id = third_step.user_id
    AND third_step.event = 'payment_entered'
    AND third_step.timestamp > first_step.timestamp
  LEFT JOIN events fourth_step
    ON first_step.user_id = fourth_step.user_id
    AND fourth_step.event = 'order_placed'
    AND fourth_step.timestamp > first_step.timestamp
  WHERE first_step.event = 'checkout_started'
    AND first_step.timestamp > NOW() - INTERVAL '8 weeks'
  GROUP BY week
)
SELECT
  week,
  checkout_started,
  ROUND(100.0 * shipping_entered / NULLIF(checkout_started, 0), 1) AS pct_shipping,
  ROUND(100.0 * payment_entered / NULLIF(checkout_started, 0), 1) AS pct_payment,
  ROUND(100.0 * order_placed / NULLIF(checkout_started, 0), 1) AS pct_completed
FROM funnel
ORDER BY week DESC;
```

---

## Anti-Patterns ❌

### Vanity Metrics
**What it is**: Tracking numbers that grow but don't predict business health.
```
Vanity:    Total registered users (includes dormant accounts, test accounts, bots)
Actionable: Monthly active users who completed a core action in last 30 days

Vanity:    Total page views
Actionable: % of sessions where user completed primary intent

Vanity:    Total revenue (includes one-time, refunds, churn)
Actionable: Net MRR (new + expansion - churn - contraction)
```

### Running A/B Tests Too Short (Peeking)
**What it is**: Checking results daily and stopping when p<0.05.
**What breaks**: False positive rate is 26% (not 5%) when you peek at 5 looks during a test. You ship changes that don't actually work.
**Fix**: Calculate sample size first. Set a calendar end date. Don't look until the test ends. Use sequential testing (mSPRT) if you need early stopping.

### Tracking Events Without Taxonomy
**What it is**: Every team tracks their own events with different naming conventions.
**What breaks**: `checkout_started`, `CheckoutStart`, `began_checkout`, `checkout_begin` — four events for the same action. Funnel analysis impossible.
**Fix**: Event taxonomy doc. `[object]_[verb]` convention. Review new events before shipping.

---

## Quick Reference

```
North Star: single number capturing user value; update quarterly
AARRR: Acquisition → Activation → Retention → Revenue → Referral
A/B test: pre-register sample size, 95% confidence, 80% power, no peeking
Minimum detectable effect: 10-20% relative lift (smaller = longer test)
Retention benchmarks: Day 7 >20%, Day 30 >10% (consumer); Day 30 >40% (SaaS)
Event naming: [object]_[verb] — order_placed, checkout_abandoned, payment_failed
PostHog EU: eu.posthog.com for GDPR data residency
Funnel attribution window: define per funnel (e.g., checkout: 1 hour)
```
