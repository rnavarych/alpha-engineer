# Billing Integration

## When to load
Load when implementing Stripe subscriptions, metering, invoicing, or dunning.

## Stripe Subscription Setup

```typescript
// Create product + prices in Stripe (usually via Dashboard or migration)
const product = await stripe.products.create({ name: 'Pro Plan' });
const monthlyPrice = await stripe.prices.create({
  product: product.id,
  unit_amount: 2900, // $29.00
  currency: 'usd',
  recurring: { interval: 'month' },
});
const annualPrice = await stripe.prices.create({
  product: product.id,
  unit_amount: 29000, // $290/year (2 months free)
  currency: 'usd',
  recurring: { interval: 'year' },
});

// Create subscription for customer
const subscription = await stripe.subscriptions.create({
  customer: 'cus_xxx',
  items: [{ price: monthlyPrice.id }],
  payment_behavior: 'default_incomplete',
  expand: ['latest_invoice.payment_intent'],
});
```

## Webhook Handling

```typescript
app.post('/webhooks/stripe', async (req, res) => {
  const event = stripe.webhooks.constructEvent(
    req.body, req.headers['stripe-signature'], process.env.STRIPE_WEBHOOK_SECRET!
  );

  switch (event.type) {
    case 'customer.subscription.created':
    case 'customer.subscription.updated':
      await syncSubscription(event.data.object);
      break;
    case 'customer.subscription.deleted':
      await handleCancellation(event.data.object);
      break;
    case 'invoice.payment_failed':
      await handlePaymentFailure(event.data.object);
      break;
    case 'invoice.paid':
      await handleSuccessfulPayment(event.data.object);
      break;
  }

  res.json({ received: true });
});

// CRITICAL: Make webhook handlers idempotent
async function syncSubscription(sub: Stripe.Subscription) {
  await db.subscriptions.upsert({
    where: { stripeSubscriptionId: sub.id },
    create: { stripeSubscriptionId: sub.id, status: sub.status, /* ... */ },
    update: { status: sub.status, currentPeriodEnd: new Date(sub.current_period_end * 1000) },
  });
}
```

## Dunning (Failed Payment Recovery)

```
Stripe Smart Retries (automatic):
  Day 0: initial charge fails
  Day 1: first retry (different time)
  Day 3: second retry
  Day 5: third retry
  Day 7: final retry → mark subscription as past_due

Your custom emails:
  Day 0: "Payment failed — we'll retry automatically"
  Day 3: "Still having trouble — update your card"
  Day 7: "Last chance — update payment to keep your account"
  Day 14: Cancel subscription, downgrade to free

Recovery rate: 30-50% of failed payments recovered with good dunning
```

## Anti-patterns
- Not handling webhooks idempotently → duplicate charges or missed events
- Checking subscription status on every request → slow; cache locally
- No dunning emails → lost revenue from recoverable failures
- Hardcoding prices → use Stripe price IDs, change via Dashboard

## Quick reference
```
Products + Prices: create in Stripe, reference by ID
Subscriptions: create via API, manage via webhooks
Webhooks: idempotent handlers, verify signature
Dunning: Stripe Smart Retries + custom email sequence
Proration: automatic when changing plans mid-cycle
Cancellation: cancel at period end (not immediately)
Free trial: trial_period_days on subscription create
Metering: stripe.subscriptionItems.createUsageRecord()
```
