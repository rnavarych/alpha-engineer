---
name: compliance-pci
description: |
  PCI DSS compliance: SAQ A vs SAQ D scope, Stripe Elements for card data isolation,
  tokenization patterns, cardholder data environment (CDE) scoping, network segmentation,
  encryption in transit/at rest, audit logging requirements. Never store raw card data.
  Use when implementing payment systems, reviewing card data handling, PCI scope reduction.
allowed-tools: Read, Grep, Glob
---

# PCI DSS Compliance

## When to Use This Skill
- Implementing payment card processing
- Reducing PCI scope with hosted fields / Elements
- Reviewing what data can/cannot be stored
- Designing network segmentation for CDE
- Choosing SAQ level for annual assessment

## Core Principles

1. **Never store raw card data** — full PAN, CVV, magnetic stripe data must never touch your servers
2. **Reduce scope, don't solve scope** — use Stripe Elements / Braintree Hosted Fields to push scope to the processor
3. **Tokenize, never transmit** — use processor tokens (`pm_xxx`, `tok_xxx`); your app never sees raw card numbers
4. **CVV must never be stored** — not even transiently in logs; PCI Req 3.3 is absolute
5. **SAQ A is achievable for most SaaS** — if you use hosted card collection, you avoid SAQ D's 300+ controls

---

## Patterns ✅

### SAQ A vs SAQ D — Scope Decision

```
SAQ A (simplest — ~22 controls):
  ✓ Card data entry: fully hosted by payment processor (Stripe Elements, Braintree Hosted Fields)
  ✓ Your application never sees card numbers, expiry, CVV
  ✓ Only tokenized payment method IDs touch your servers
  ✓ All pages serving payment forms are HTTPS
  Achievable with: Stripe Elements, Checkout, PaymentElement

SAQ A-EP (intermediate — ~192 controls):
  ✓ Your page hosts the payment form but uses JavaScript from the processor
  ✓ Card data goes directly from browser to processor (not through your server)
  Risk: XSS on your site could capture card data before submission

SAQ D (full — ~300+ controls):
  ✗ Your server receives or processes card data
  ✗ Requires: network segmentation, file integrity monitoring, quarterly scans,
              penetration testing, WAF, intrusion detection, log management
  Avoid unless you have dedicated PCI compliance team
```

### Stripe Elements Implementation (SAQ A)

```typescript
// Frontend: Stripe Elements — card data never touches your server

// React component using Stripe PaymentElement
import { Elements, PaymentElement, useStripe, useElements } from '@stripe/react-stripe-js';

export function CheckoutForm({ clientSecret }: { clientSecret: string }) {
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!stripe || !elements) return;

    // confirmPayment sends card data DIRECTLY to Stripe — never to your server
    const { error } = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}/order/confirmation`,
      },
    });

    if (error) {
      // error.type === 'card_error' || 'validation_error'
      // Safe to display: error.message is user-friendly
      setErrorMessage(error.message ?? 'Payment failed');
    }
    // On success, Stripe redirects to return_url with payment_intent_client_secret
  };

  return (
    <form onSubmit={handleSubmit}>
      <PaymentElement />  {/* Hosted by Stripe — PCI compliant */}
      <button type="submit" disabled={!stripe}>Pay</button>
    </form>
  );
}
```

```typescript
// Backend: create PaymentIntent — no card data involved

export class PaymentService {
  async createPaymentIntent(orderId: string, amount: Money): Promise<{ clientSecret: string }> {
    const order = await this.orderRepo.findById(orderId);
    if (!order) throw new NotFoundError('Order not found');

    const paymentIntent = await this.stripe.paymentIntents.create({
      amount: amount.cents,           // In cents — never floats
      currency: amount.currency.toLowerCase(),
      metadata: {
        orderId,
        customerId: order.customerId,
      },
      // Idempotency key prevents double charges on retry
    }, {
      idempotencyKey: `order_${orderId}_${amount.cents}`,
    });

    // Store payment intent ID — never store card data
    await this.db.update(orders)
      .set({ stripePaymentIntentId: paymentIntent.id })
      .where(eq(orders.id, orderId));

    return { clientSecret: paymentIntent.client_secret! };
  }

  // Save card for future use — tokenization only
  async savePaymentMethod(customerId: string, stripePaymentMethodId: string): Promise<void> {
    // Attach to Stripe Customer — your DB only stores the token
    await this.stripe.paymentMethods.attach(stripePaymentMethodId, {
      customer: await this.getStripeCustomerId(customerId),
    });

    // Store token, NOT card data
    await this.db.insert(paymentMethods).values({
      customerId,
      stripePaymentMethodId,   // pm_xxx — safe to store
      last4: '4242',           // Display hint only — not card data
      brand: 'visa',
      expiryMonth: 12,
      expiryYear: 2027,
      // NEVER store: full PAN, CVV, track data
    });
  }
}
```

### Webhook Security (Stripe)

```typescript
// Stripe webhooks must be verified — never process unverified webhooks

app.post('/webhooks/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
  const signature = req.headers['stripe-signature'] as string;

  let event: Stripe.Event;
  try {
    // Verify signature using webhook secret — prevents spoofed events
    event = stripe.webhooks.constructEvent(
      req.body,                          // Raw body — must not be parsed yet
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    logger.warn({ err }, 'Invalid Stripe webhook signature');
    return res.status(400).send('Invalid signature');
  }

  // Process event idempotently
  const processed = await redis.set(
    `webhook:${event.id}`, '1', 'NX', 'EX', 86400
  );
  if (!processed) {
    return res.status(200).json({ received: true });  // Already processed
  }

  switch (event.type) {
    case 'payment_intent.succeeded':
      await handlePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
      break;
    case 'payment_intent.payment_failed':
      await handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
      break;
    case 'customer.subscription.deleted':
      await handleSubscriptionCancelled(event.data.object as Stripe.Subscription);
      break;
  }

  res.status(200).json({ received: true });
});
```

### What to Store vs What NOT to Store

```
ALLOWED to store (tokenized references):
  ✓ stripe_customer_id: "cus_xxx"
  ✓ stripe_payment_method_id: "pm_xxx"
  ✓ stripe_payment_intent_id: "pi_xxx"
  ✓ Last 4 digits: "4242" (display only)
  ✓ Card brand: "visa", "mastercard"
  ✓ Expiry month/year: 12/2027 (display only)

FORBIDDEN to store (PCI violation):
  ✗ Full card number (PAN): "4242 4242 4242 4242"
  ✗ CVV/CVC: "123"
  ✗ Magnetic stripe data
  ✗ PIN
  ✗ Even in logs, temp tables, or cache
```

---

## Anti-Patterns ❌

### Logging Card Data
**What it is**: Express request logger logs `req.body` including card details from API endpoints.
**PCI violation**: Req 3.3 — sensitive authentication data must never be logged, even temporarily.
**Fix**: Redact payment fields from all logs. Use Stripe Elements — card data never reaches your server.

```typescript
// Wrong — logs entire request body including sensitive fields
app.use(morgan('combined'));

// Right — redact sensitive fields
app.use((req, res, next) => {
  const sanitized = {
    ...req.body,
    cardNumber: req.body.cardNumber ? '[REDACTED]' : undefined,
    cvv: req.body.cvv ? '[REDACTED]' : undefined,
  };
  // ... log sanitized
  next();
});
// Even better: use Stripe Elements so card data never appears in req.body
```

### Custom Card Form (SAQ D Scope)
**What it is**: Building your own `<input type="text" name="cardNumber">` and submitting to your backend.
**What breaks**: Your server receives raw card data → full CDE scope → SAQ D (300+ controls, quarterly scans, pen tests).
**Fix**: Use Stripe Elements, PaymentElement, or Checkout. Card data goes browser → Stripe. Your server never sees it.

### Storing CVV "Just for Retry"
**What it is**: Storing CVV in session or database to retry failed payments without asking user again.
**PCI violation**: Absolute prohibition. No business justification permitted.
**Fix**: Ask user to re-enter CVV on retry. This is the only compliant option.

---

## Quick Reference

```
SAQ A: Hosted Elements only, ~22 controls — achievable for most SaaS
SAQ D: Server-side card processing, 300+ controls — avoid unless legally required
Never store: full PAN, CVV, magnetic stripe, PIN — even in logs or temp tables
Store only: Stripe tokens (pm_xxx, cus_xxx, pi_xxx), last4, brand, expiry
Webhook verification: always verify Stripe-Signature header before processing
Idempotency: use Stripe idempotency keys to prevent double charges
Encryption in transit: TLS 1.2 minimum, TLS 1.3 preferred
Annual assessment: SAQ self-assessment + quarterly network scans (Approved Scanning Vendor)
```
