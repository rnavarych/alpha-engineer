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

## When to Use This Skill
- Choosing pricing model for a SaaS product
- Implementing subscription billing with Stripe
- Designing upgrade/downgrade flows with proration
- Setting up usage-based metered billing
- Managing failed payments (dunning)

## Core Principles

1. **Pricing is product strategy** — your pricing model determines what behavior you incentivize
2. **Value metric alignment** — the thing you charge for should grow as value delivered grows
3. **Freemium is a distribution strategy, not a pricing model** — conversion rate 1-5% is normal; plan the economics
4. **Metered billing lowers entry cost** — but increases customer unpredictability anxiety
5. **LTV:CAC > 3× is the benchmark** — below 1× is burning cash; below 3× means slow growth

---

## Patterns ✅

### Pricing Model Decision Guide

```
Per-seat (user-based):
  Good for: B2B collaboration tools, productivity software
  Value metric: number of users (Slack, Linear, Notion)
  Pros: predictable revenue, scales with team growth
  Cons: discourages adoption (users try to share seats), doesn't align with value for solo power users
  Examples: $15/user/month, max 100 users

Usage-based (metered):
  Good for: API services, infrastructure, AI/ML platforms
  Value metric: API calls, GB stored, tokens, emails sent (Twilio, Stripe, AWS)
  Pros: low entry cost, revenue grows with usage, aligns with value
  Cons: unpredictable revenue, customers reduce usage to control costs
  Examples: $0.0001 per token, $0.006/1000 emails

Tiered (feature-based):
  Good for: broad market (SMB + enterprise)
  Value metric: feature access
  Pros: simple to communicate, anchoring effect from high tier
  Cons: hard to pick right tier boundaries
  Examples: Starter ($49/mo), Pro ($199/mo), Enterprise (custom)

Flat-rate:
  Good for: simple products with single segment
  Pros: simplest to communicate
  Cons: undercharges power users, high-touch acquisition needed
  Examples: $99/month for everything

Freemium:
  Good for: product-led growth, viral distribution
  Free tier: enough value to be genuinely useful, not a demo
  Conversion target: 2-5% free → paid is normal
  Economics: 100 free users × $0 + 5 paid × $49 = $245/month per 100 free signups
  Threshold to upgrade: hit a meaningful limit (seats, storage, features)
```

### Stripe Subscription Schema

```typescript
// Stripe data model:
// Product → Price → Subscription → SubscriptionItem

export class BillingService {
  // Create subscription (with trial)
  async createSubscription(customerId: string, priceId: string): Promise<Stripe.Subscription> {
    const stripeCustomer = await this.ensureStripeCustomer(customerId);

    const subscription = await this.stripe.subscriptions.create({
      customer: stripeCustomer.id,
      items: [{ price: priceId }],
      trial_period_days: 14,      // Free trial — no charge until day 14
      payment_behavior: 'default_incomplete',  // Requires payment method confirmation
      payment_settings: {
        save_default_payment_method: 'on_subscription',
      },
      expand: ['latest_invoice.payment_intent'],
    });

    // Store subscription in your DB
    await this.db.insert(subscriptions).values({
      customerId,
      stripeSubscriptionId: subscription.id,
      stripePriceId: priceId,
      status: subscription.status,
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      trialEnd: subscription.trial_end ? new Date(subscription.trial_end * 1000) : null,
    });

    return subscription;
  }

  // Upgrade or downgrade — Stripe handles proration
  async changePlan(subscriptionId: string, newPriceId: string, immediately: boolean): Promise<void> {
    const sub = await this.stripe.subscriptions.retrieve(subscriptionId);
    const currentItem = sub.items.data[0];

    await this.stripe.subscriptions.update(subscriptionId, {
      items: [{ id: currentItem.id, price: newPriceId }],
      proration_behavior: immediately ? 'create_prorations' : 'none',
      // 'create_prorations': charge/credit immediately for rest of billing period
      // 'none': apply at next renewal
    });
  }

  // Metered billing: report usage
  async reportUsage(subscriptionItemId: string, quantity: number): Promise<void> {
    await this.stripe.subscriptionItems.createUsageRecord(subscriptionItemId, {
      quantity,
      timestamp: Math.floor(Date.now() / 1000),
      action: 'increment',  // or 'set' to override
    });
  }
}
```

### Dunning Management (Failed Payment Recovery)

```typescript
// Dunning: recovering failed subscription payments
// Stripe Smart Retries handles timing automatically

// Webhook handler for payment failures
export async function handleInvoicePaymentFailed(invoice: Stripe.Invoice): Promise<void> {
  const subscription = await stripe.subscriptions.retrieve(invoice.subscription as string);
  const attemptCount = invoice.attempt_count;

  // Get customer from your DB
  const customer = await db.query.customers.findFirst({
    where: eq(customers.stripeCustomerId, invoice.customer as string),
  });
  if (!customer) return;

  if (attemptCount === 1) {
    // First failure — friendly email, don't restrict access yet
    await emailService.send(customer.email, 'payment_failed_first', {
      invoiceUrl: invoice.hosted_invoice_url,
      amount: formatCurrency(invoice.amount_due, invoice.currency),
      nextRetry: new Date((invoice.next_payment_attempt ?? 0) * 1000),
    });
  } else if (attemptCount === 2) {
    // Second failure — more urgent, soft restriction warning
    await emailService.send(customer.email, 'payment_failed_urgent', {
      invoiceUrl: invoice.hosted_invoice_url,
    });
    await db.update(customers)
      .set({ billingStatus: 'past_due' })
      .where(eq(customers.id, customer.id));
  } else if (attemptCount >= 3) {
    // Third failure — restrict access, keep data for 30 days
    await db.update(customers)
      .set({ billingStatus: 'suspended' })
      .where(eq(customers.id, customer.id));
    await emailService.send(customer.email, 'account_suspended', {
      invoiceUrl: invoice.hosted_invoice_url,
      reactivateUrl: `${process.env.APP_URL}/billing`,
    });
  }
}

// Stripe recommended retry schedule (Smart Retries):
// Day 0: Initial failure
// Day 3: First retry
// Day 5: Second retry
// Day 7: Third retry (final — then mark subscription as unpaid/canceled)
```

### Trial → Paid Conversion Optimization

```typescript
// Key: send trial expiry reminders at the right time

export class TrialService {
  async scheduleTrialReminders(subscriptionId: string, trialEnd: Date): Promise<void> {
    const reminders = [
      { daysBeforeEnd: 7, template: 'trial_reminder_7_days' },
      { daysBeforeEnd: 3, template: 'trial_reminder_3_days' },
      { daysBeforeEnd: 1, template: 'trial_reminder_1_day' },
      { daysBeforeEnd: 0, template: 'trial_ended' },   // On the day
    ];

    for (const reminder of reminders) {
      const sendAt = subDays(trialEnd, reminder.daysBeforeEnd);
      if (sendAt > new Date()) {
        await this.scheduler.schedule({
          at: sendAt,
          job: 'send_trial_reminder',
          payload: { subscriptionId, template: reminder.template },
        });
      }
    }
  }

  // Check if trial user has hit activation milestones
  // Users who activate have 3× higher trial→paid conversion
  async checkActivationStatus(userId: string): Promise<ActivationStatus> {
    const events = await db.query.events.findMany({
      where: and(
        eq(events.userId, userId),
        inArray(events.event, ['document_created', 'team_member_invited', 'integration_connected'])
      ),
    });

    return {
      hasCreatedDocument: events.some(e => e.event === 'document_created'),
      hasInvitedTeamMember: events.some(e => e.event === 'team_member_invited'),
      hasConnectedIntegration: events.some(e => e.event === 'integration_connected'),
      activationScore: events.length,  // 3 = fully activated
    };
  }
}
```

---

## Anti-Patterns ❌

### Feature-Gating Core Value
**What it is**: Free tier so restricted it provides no real value (e.g., "1 document" limit).
**What breaks**: Users never experience the value, so there's no reason to upgrade. Conversion <0.5%.
**Fix**: Free tier should be genuinely useful. Limit on collaboration, storage, or advanced features — not core functionality.

### Hiding Pricing
**What it is**: No pricing page; "Contact sales" for everything.
**What breaks**: B2B buyers evaluate 3–5 solutions before talking to sales. No pricing = skipped in evaluation.
**Fix**: Publish pricing for self-serve tiers. Enterprise custom pricing is fine, but show a baseline.

### Ignoring Churn Until It's a Crisis
**What it is**: Focusing only on acquisition, not tracking monthly churn rate.
**What breaks**: 5% monthly churn = ~46% annual churn. You're replacing half your revenue every year just to stay flat.
**Calculation**: If MRR is $10k with 5% monthly churn, you lose $500/month and need $500+ in new MRR just to stay flat.
**Fix**: Track MRR churn monthly. Target <2% monthly churn for B2B SaaS (= ~22% annual).

---

## Quick Reference

```
LTV:CAC target: >3× (healthy), >5× (excellent)
Payback period target: <12 months (B2B), <6 months (SMB)
Freemium conversion: 2-5% free → paid is normal
Trial conversion: 15-25% trial → paid is good
Monthly churn target: <2% B2B SaaS, <5% B2C
Dunning retry schedule: Day 0, 3, 5, 7 (Stripe Smart Retries)
Proration: 'create_prorations' for immediate upgrade, 'none' for end-of-period
Trial length: 7 days (low-complexity), 14 days (most SaaS), 30 days (enterprise)
Value metric examples: users, documents, API calls, seats, storage, revenue %
```
