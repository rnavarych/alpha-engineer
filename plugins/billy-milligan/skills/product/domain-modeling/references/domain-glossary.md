# Domain Glossary

## When to load
Load when building or maintaining a domain glossary, writing new glossary entries, onboarding team members to domain concepts, or checking whether a new term needs a formal definition before it enters the codebase.

---

## Glossary Entry Format

```markdown
## [Term]
**Context:** [Which bounded context this definition belongs to]
**Definition:** [Plain language definition — what it means in this business]
**Distinguished from:** [Terms it might be confused with and how they differ]
**Code representation:** [Class/type name, table name, field names]
**Example:** [Concrete example of the concept in use]
**Invalid uses:** [Common misuses or incorrect synonyms to avoid]
```

---

## E-Commerce Domain Examples

---

**Customer**
Context: Orders, Payments
Definition: A person or organization that has placed at least one paid order. Distinguished from a Visitor (browsing without account) and a Prospect (account without purchase).
Distinguished from: User (a user is a login credential; a customer is a business relationship — one user can be a customer in multiple organizations)
Code representation: `Customer` entity, `customers` table, `customerId` field
Example: "Customer C-4421 has placed 7 orders totaling $1,240 in the last 6 months."
Invalid uses: Do not use "User" when you mean the paying customer. Do not use "Client" (reserved for B2B enterprise accounts).

---

**Order**
Context: Orders
Definition: A confirmed intent to purchase one or more products, with a specific price, shipping address, and payment method. An Order exists from the moment a customer completes checkout through the end of the return window.
Distinguished from: Cart (not yet committed, no price guarantee), Quote (a proposed order pending approval, used in B2B flow)
Code representation: `Order` aggregate, `orders` table, `OrderStatus` enum
Example: "Order ORD-8821: 3 items, $149.00, placed 2024-03-15, currently shipped."
Invalid uses: Do not call a Cart an Order. Do not call an Order a "Transaction" (Transaction is a Payment concept).

---

**Payment**
Context: Payments
Definition: A financial transaction that transfers funds from a Customer to the business in exchange for fulfillment of an Order. A Payment can succeed, fail, or be refunded.
Distinguished from: Charge (Stripe's internal term — map to Payment in our domain via ACL), Invoice (a request for payment, not the payment itself)
Code representation: `Payment` aggregate, `payments` table, `PaymentStatus` enum
Example: "Payment PAY-7723 for $149.00 succeeded via Visa ****4242 at 2024-03-15T10:22:01Z."
Invalid uses: Do not use "Transaction" for both Payment and Order — they are different concepts. Do not use Stripe's `Charge` object directly in domain code.

---

**Fulfillment**
Context: Shipping, Operations
Definition: The process of picking, packing, and delivering the physical goods in an Order to the Customer's shipping address. Fulfillment begins after successful Payment and ends with Delivery.
Distinguished from: Shipping (the act of handing packages to the carrier — one step within Fulfillment), Delivery (the act of the package arriving — the end of Fulfillment)
Code representation: `Fulfillment` entity, `fulfillments` table, `FulfillmentStatus` enum
Example: "Fulfillment FULFIL-1123 for Order ORD-8821: status 'in_transit', carrier DHL, expected delivery 2024-03-18."
Invalid uses: Do not use "Fulfillment" to mean just "Shipping." Do not use "Delivery" when you mean the whole fulfillment process.

---

**Refund**
Context: Payments
Definition: A reversal of all or part of a Payment, returning funds to the Customer's original payment method. A Refund is distinct from a Credit (store credit, not returned to card) and a Chargeback (customer-initiated dispute through the card network).
Distinguished from: Credit (stored value in the customer's account, not returned to card), Chargeback (initiated by the card issuer, not by us), Return (the physical act of sending goods back — may or may not result in a Refund)
Code representation: `Refund` entity, `refunds` table, linked to `Payment` by `paymentId`
Example: "Refund REF-445 for $29.99 issued to Visa ****4242, processing time 3-5 business days."

---

## Glossary Maintenance

### When to update the glossary
- New concept discovered during event storming
- Term conflict surfaces in code review or planning
- Domain expert corrects your understanding of a concept
- New bounded context introduced that redefines a term within its boundary

### Glossary ownership
The glossary is owned by the product team and domain experts, not engineering. Engineering maintains the code to reflect it. When the glossary changes, code follows.

### Review cadence
- Quarterly: review all terms for accuracy
- On every event storming session: capture new terms immediately
- On every API design review: ensure API terms match glossary

---

## Anti-Patterns

### "Everyone Knows What This Means"
Assuming shared understanding of ambiguous terms. "Customer", "product", "account" — everyone on the team uses these daily and everyone means something slightly different. Write the glossary entry.

---

## Quick Reference

```
Glossary entry fields: term, context, definition, distinguished from, code representation, example, invalid uses
Ownership: domain experts and product own the glossary; engineering implements it
When to add an entry: when a new concept appears in event storming or causes confusion in review
Review cadence: quarterly + every event storming session + every API design review
Conflict resolution: see term-conflict-resolution.md
```
