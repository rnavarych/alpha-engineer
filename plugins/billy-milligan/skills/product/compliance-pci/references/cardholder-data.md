# Cardholder Data Handling

## When to load
Load when handling payment card data: PAN, tokenization, scope reduction.

## Never Store Rule

```
NEVER store locally:
  ❌ Full PAN (Primary Account Number)
  ❌ CVV/CVC (Card Verification Value) — never, even encrypted
  ❌ PIN / PIN block
  ❌ Full magnetic stripe data

CAN store (if encrypted):
  ✅ Last 4 digits of PAN (for display: **** **** **** 4242)
  ✅ Cardholder name
  ✅ Expiration date
  ✅ Token from payment processor (always preferred)
```

## Tokenization (Stripe)

```typescript
// CORRECT: Client-side tokenization — PAN never touches your server
// Frontend: Stripe Elements handles card input
const { token } = await stripe.createToken(cardElement);

// Backend: receives only the token, never the card number
const charge = await stripe.charges.create({
  amount: 4999,
  currency: 'usd',
  source: token.id,  // tok_xxx — not a card number
});

// Store for future charges
const customer = await stripe.customers.create({
  email: 'user@example.com',
  source: token.id,
});
// Store customer.id (cus_xxx) — this is your token reference
```

## Scope Reduction Strategies

```
Goal: minimize systems that touch cardholder data = minimize PCI scope.

Level 1: Use hosted checkout (Stripe Checkout, PayPal)
  → Your servers NEVER see card data
  → SAQ A (simplest, ~20 questions)

Level 2: Use client-side tokenization (Stripe Elements)
  → Card entered in Stripe's iframe, token sent to your server
  → SAQ A-EP (~130 questions)

Level 3: Server-side card handling
  → Your server processes raw card numbers
  → SAQ D (300+ questions, annual penetration test)
  → AVOID unless absolutely necessary
```

## Anti-patterns
- Logging request bodies that contain card data → PAN in logs
- Storing card numbers "just for display" → use last 4 digits only
- Using card number as order reference → use processor tokens
- CVV storage for "convenience" → explicitly forbidden by PCI DSS

## Quick reference
```
Never store: full PAN, CVV, PIN, magnetic stripe
Tokenize: Stripe/Braintree/Adyen tokens replace card numbers
SAQ A: hosted checkout, minimal scope (~20 questions)
SAQ A-EP: client-side tokenization (~130 questions)
SAQ D: server-side card handling (~300 questions, avoid)
Last 4: only card reference to store/display locally
Encryption: AES-256 for any stored cardholder data
Key rotation: encryption keys rotated annually
```
