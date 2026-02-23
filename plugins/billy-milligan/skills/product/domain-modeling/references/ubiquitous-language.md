# Ubiquitous Language

## When to load
Load when enforcing consistent terminology in code, auditing a codebase for synonym drift, establishing naming conventions for domain elements, or onboarding new team members to domain concepts.

---

## What Ubiquitous Language Is

Ubiquitous language is a shared vocabulary used consistently across code, documentation, tests, conversations, and domain expert discussions. The same word means the same thing everywhere. No synonyms. No translations between "business speak" and "tech speak."

**The rule:** If a domain expert says "Invoice" and your code says `Bill`, you are translating. Every translation is a potential bug.

---

## Naming Convention Rules

### Enforce ubiquitous language in code

```typescript
// Bad: mixing synonyms
class UserService {
  async getClient(userId: string): Promise<Account> { ... }
  //     ^ "User"                   ^ "Client"   ^ "Account" — three names for one concept
}

// Good: one name, used everywhere
class CustomerService {
  async getCustomer(customerId: CustomerId): Promise<Customer> { ... }
}
```

### Naming rules by element type

| Element | Convention | Example |
|---------|-----------|---------|
| Aggregate | Noun, singular, domain term | `Order`, `Payment`, `Shipment` |
| Domain Event | Noun + past participle | `OrderPlaced`, `PaymentFailed`, `ShipmentCreated` |
| Command | Verb phrase | `PlaceOrder`, `CancelPayment`, `CreateShipment` |
| Value Object | Domain noun | `Money`, `Email`, `ShippingAddress`, `OrderId` |
| Repository interface | `[Aggregate]Repository` | `OrderRepository`, `CustomerRepository` |
| Service | `[Domain capability]Service` | `OrderCancellationService`, `RefundCalculationService` |
| Policy/Rule | `[Business rule] Policy` | `LateReturnPolicy`, `BulkDiscountPolicy` |

### What to avoid

```
Avoid these generic terms in domain code — they hide meaning:

"data"      → what kind of data? OrderData, PaymentData? Just use Order, Payment
"info"      → CustomerInfo → Customer. ShippingInfo → ShippingAddress
"manager"   → OrderManager → OrderService or just methods on Order aggregate
"handler"   → too generic. What does it handle? Name the specific domain concern.
"processor" → PaymentProcessor is sometimes OK, but StripePaymentProcessor is better
"helper"    → if it has domain logic, give it a domain name. If it doesn't, it's a utility.
"utils"     → fine for infrastructure utilities, never for domain logic

Avoid synonyms:
"User" and "Customer" → pick one for each context
"Order" and "Purchase" → pick one
"Cancel" and "Delete" → in domain context, these mean different things:
                         Cancel is a domain operation; Delete is an infrastructure operation
```

---

## Anti-Patterns

### The Translation Layer in Engineers' Heads
When engineers mentally translate "what the business calls X" into "what the code calls Y." This translation lives only in the engineer's head. New team members don't know it. Bugs happen when the translation is imperfect or inconsistent.

### Premature Technical Naming
Naming concepts after their implementation: `UserRecord`, `OrderRow`, `PaymentDocument`. These names leak persistence details into the domain model. What is a `UserRecord` vs. a `User`? Use domain terms; the persistence layer adapts.

### Glossary Without Code Enforcement
Maintaining a beautiful glossary document that nobody checks during code review. The glossary must be enforced: code review should flag `Bill` when the glossary says `Invoice`.

---

## Quick Reference

```
Rule: if code uses different words than the domain expert, there's a translation — translations are bugs
Synonym policy: zero tolerance — one concept, one name per bounded context
Naming: Aggregate = noun, Event = past tense verb, Command = imperative verb
Avoid: "data", "info", "manager", "handler", "utils" in domain code — they hide meaning
Ownership: glossary owned by domain experts and product; engineering implements it
Same word in different contexts: document explicitly per bounded context — expected and correct
```
