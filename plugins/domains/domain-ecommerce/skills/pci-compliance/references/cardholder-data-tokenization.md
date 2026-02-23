# Cardholder Data Handling and Tokenization

## When to load
Load when determining PCI compliance scope, understanding what card data can be stored, or implementing tokenization and secure payment forms.

## Compliance Levels

### Self-Assessment Questionnaires (SAQ)
- **SAQ A**: fully outsourced payment page (Stripe Checkout, PayPal hosted). Card data never touches your servers. Simplest path — ~20 requirements.
- **SAQ A-EP**: payment page on your domain, card data collected via JavaScript sent directly to gateway (Stripe Elements, Braintree Hosted Fields). Your page hosts the JS but card data bypasses your server. ~140 requirements.
- **SAQ D**: you directly handle, process, or store card data on your servers. Full PCI DSS assessment — ~300 requirements. Avoid unless absolutely necessary.

### Choosing the Right Level
- Prefer SAQ A (hosted payment page) for the simplest compliance burden.
- Use SAQ A-EP for custom checkout UX without handling card data server-side.
- Only accept SAQ D if a specific business requirement demands raw card number handling (rare).

## Cardholder Data Rules

### What You Must Never Do
- Never store CVV/CVC/CVV2 after authorization — even encrypted.
- Never log full card numbers (PAN) in application logs, error tracking, or analytics.
- Never transmit card data over unencrypted channels.
- Never store card data in cookies, local storage, or URL parameters.

### What You Can Store
- Truncated PAN (first 6 and last 4 digits) for display and customer identification.
- Tokenized references (gateway tokens) that map to the card on the provider's systems.
- Expiration date only alongside truncated PAN — never with a full PAN.

## Tokenization

### How It Works
- Gateway collects card details and returns a token (`pm_xxx` in Stripe, nonce in Braintree).
- Your server handles only the token — never the raw card number.
- Tokens are scoped to your merchant account; unusable by other merchants.

### Implementation per Gateway
- **Stripe**: `PaymentMethod` or `Token` objects. Attach to a `Customer` for reuse.
- **Braintree**: `paymentMethodNonce` from client SDK. Vault the nonce for recurring charges.
- **Adyen**: `storedPaymentMethodId` after initial tokenization via Components SDK.
- Always create tokens client-side (browser or mobile) and send only the token to your server.

## Secure Payment Forms

### Iframes (Stripe Elements, Braintree Hosted Fields)
- Card input fields render inside an iframe hosted by the payment provider.
- Your page's JavaScript cannot access iframe contents (same-origin policy).
- Card data sent directly from iframe to provider — never passes through your server.
- Customize look and feel via provider APIs to match your site's design.

### Hosted Payment Pages
- Redirect customer to a payment page hosted entirely by provider (Stripe Checkout, PayPal).
- Customer enters card details on provider's domain.
- After payment, customer redirected back with a session/token reference.
- Lowest PCI scope — your servers have zero contact with card data.
