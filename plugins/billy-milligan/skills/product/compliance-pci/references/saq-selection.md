# SAQ Selection Guide

## When to load
Load when determining which PCI Self-Assessment Questionnaire applies to your integration.

## SAQ Decision Tree

```
Does your server ever see raw card numbers?
  │
  ├─ YES → SAQ D (full PCI assessment, ~300 questions)
  │         You handle card data server-side.
  │         Requires: annual penetration test, quarterly ASV scan.
  │
  └─ NO → Does the customer enter card data on YOUR page?
          │
          ├─ NO → SAQ A (~20 questions, simplest)
          │        Fully hosted checkout (Stripe Checkout, PayPal).
          │        Card entry happens entirely on processor's domain.
          │        Your page redirects to processor or uses iframe.
          │
          └─ YES → SAQ A-EP (~130 questions)
                   Client-side tokenization (Stripe Elements, Braintree Drop-in).
                   Card entered on your page but in processor's iframe/JS.
                   Token sent to your server (never raw card data).
```

## Integration Comparison

| Integration | SAQ | Effort | Card Touch | Example |
|------------|-----|--------|------------|---------|
| Hosted checkout | A | Low | None | Stripe Checkout, PayPal |
| Payment links | A | Low | None | Stripe Payment Links |
| Client-side Elements | A-EP | Medium | Token only | Stripe Elements in iframe |
| Direct API | D | High | Full PAN | stripe.charges.create with raw card |

## Stripe Integration for SAQ A

```typescript
// Redirect to Stripe Checkout — SAQ A (simplest)
const session = await stripe.checkout.sessions.create({
  payment_method_types: ['card'],
  line_items: [{ price: 'price_xxx', quantity: 1 }],
  mode: 'payment',
  success_url: 'https://yoursite.com/success?session_id={CHECKOUT_SESSION_ID}',
  cancel_url: 'https://yoursite.com/cancel',
});
// Redirect customer to session.url
// Your server NEVER sees card data
```

## Stripe Elements for SAQ A-EP

```typescript
// Card input rendered by Stripe's JS in an iframe on YOUR page
// Frontend
const elements = stripe.elements();
const cardElement = elements.create('card');
cardElement.mount('#card-element');

// On submit: tokenize client-side
const { paymentMethod } = await stripe.createPaymentMethod({
  type: 'card',
  card: cardElement,
});
// Send paymentMethod.id to your server (NOT card number)
```

## Anti-patterns
- Using SAQ A when you have Elements on your page → actually SAQ A-EP
- Server-side card processing when tokenization works → unnecessary scope
- No quarterly ASV scan when required → non-compliant
- Assuming PCI doesn't apply because you use Stripe → wrong, SAQ still required

## Quick reference
```
SAQ A: hosted checkout, ~20 questions, easiest
SAQ A-EP: client-side tokenization, ~130 questions
SAQ D: server-side card handling, ~300 questions, avoid
Stripe Checkout: SAQ A (recommended for most)
Stripe Elements: SAQ A-EP (when custom UI needed)
ASV scan: quarterly for SAQ A-EP and D
Penetration test: annual for SAQ D only
Compliance: submit SAQ annually to acquiring bank
```
