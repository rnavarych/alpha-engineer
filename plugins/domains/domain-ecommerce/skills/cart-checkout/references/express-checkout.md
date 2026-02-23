# Express Checkout

## When to load
Load when implementing Apple Pay, Google Pay, Shop Pay, Amazon Pay, or any one-tap checkout flow.

## Apple Pay
- Display button on product pages, cart, and checkout for one-tap purchase.
- Payment Request API (web) or PassKit (iOS) integration.
- Retrieve shipping address and contact info — skip address entry forms.
- Dynamically calculate shipping options and tax from Apple Pay-provided address.
- Merchant domain verification and certificate configuration required.
- Flow: button click → sheet with address/shipping/payment → authorize → capture.

## Google Pay
- Show button with `isReadyToPay` check for device/browser support.
- Retrieve payment token, shipping address, and email.
- Gateway tokenization (recommended) or direct tokenization.
- Configure payment data request: supported networks, merchant info, transaction details.
- Dynamic shipping cost and tax via `onPaymentDataChanged` callback.

## Shop Pay
- Shopify accelerated checkout: returning buyers complete purchase in one tap.
- Shop Pay Installments: BNPL via Affirm (4 interest-free payments for eligible orders).
- Available on Shopify Checkout and through Shopify Payments.
- Cross-merchant buyer recognition via the Shop app.

## Amazon Pay
- Button on cart and checkout pages; buyer uses their Amazon account address and payment.
- Headless API integration or hosted widgets for address/payment selection.
- Automatic Payments for subscriptions and recurring orders.
- A-to-z Guarantee for buyer protection.

## Express Checkout Best Practices
- Display express buttons above the fold on cart page, before the standard checkout button.
- Show express options on product detail pages for impulse purchases.
- Support multiple methods simultaneously (Apple Pay + Google Pay + Shop Pay).
- Ensure express checkout total matches standard checkout total (tax + shipping must match).
- Handle failed express gracefully: fall back to standard checkout with pre-filled data.
