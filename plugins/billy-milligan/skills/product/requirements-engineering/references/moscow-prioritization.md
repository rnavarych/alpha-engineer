# MoSCoW Prioritization

## When to load
Load when running a MoSCoW prioritization exercise, negotiating scope with stakeholders, validating that a release is correctly scoped, or checking that capacity allocation follows the 60/20/20 rule.

---

## Category Definitions and Capacity Rules

MoSCoW is a scope negotiation tool, not just a labeling exercise. Every item must be assigned a category WITH a business justification.

| Category | Definition | Target % of capacity |
|----------|-----------|---------------------|
| **Must Have** | Without this, the release fails to meet its core objective. Non-negotiable. | 60% |
| **Should Have** | Important and expected, but the release can ship without it temporarily. Workaround exists. | 20% |
| **Could Have** | Valuable but not critical. Include if capacity permits. Most will slip. | 20% |
| **Won't Have (this time)** | Explicitly deferred. Not "maybe" — definitively not in this release. | 0% (explicitly listed) |

### The 60/20/20 rule
- If Must Haves exceed 60% of your estimated capacity, you are over-scoped. Either cut Musts or extend the timeline.
- If you have no Won't Haves, you have no scope control — everything is implicitly "might have" and the list will grow.
- If everything is Must Have, the team has lost negotiating power with stakeholders.

---

## MoSCoW in Practice: E-Commerce Launch Example

**Must Have (60% capacity — launch blocker if missing):**
- Customer can browse products and view product details
- Customer can add products to cart
- Customer can check out with a credit card (Stripe Elements)
- Customer receives order confirmation email
- Admin can view and update order status
- Orders persist correctly (no data loss)

**Should Have (20% capacity — important, but workaround exists):**
- Customer can create an account and view order history
  - *Workaround: Email receipt contains all order details*
- Customer can apply a discount code
  - *Workaround: Manual refunds for launch promotion*
- Admin can export orders to CSV
  - *Workaround: Direct DB query for operations team*

**Could Have (20% capacity — most will slip, that's OK):**
- Customer can save payment method for future use
- Customer can wishlist products
- Product recommendations on cart page
- Admin dashboard with sales charts

**Won't Have (this release — explicitly committed):**
- Customer loyalty program
- Multi-currency pricing
- B2B bulk ordering
- Mobile app (web only for launch)

---

## Anti-Patterns

### Everything is Must Have
When stakeholders label everything Must Have, MoSCoW has failed as a tool. Force the question: "If we could only ship half of these, which half?" The answer reveals the real Must Haves.

### No Won't Haves
A MoSCoW list with no Won't Have column means nobody has committed to leaving anything out. Every feature is implicitly "maybe" — scope will grow.

### Gold Plating
The team adds features or quality beyond what was asked because it seems like "the right thing." Every unasked-for feature is scope creep from inside the team. Validate with the product owner before building beyond ACs.

---

## Quick Reference

```
MoSCoW capacity split: Must=60%, Should=20%, Could=20%, Won't=explicitly listed
If Must Haves > 60% capacity: over-scoped — cut or extend timeline
No Won't Haves = no scope control
Must Have test: "Would we delay the release or cancel it if this were missing?"
Should Have test: "Is there a manual workaround that buys us time?"
Won't Have: commit to it explicitly — "not this time" is a real decision
```
