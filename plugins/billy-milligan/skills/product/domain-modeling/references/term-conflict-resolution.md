# Term Conflict Resolution

## When to load
Load when two people use the same word for different things, different words for the same thing, or when the same term means something different in two bounded contexts and that ambiguity is causing confusion in code, reviews, or planning.

---

## Conflict Resolution Protocol

### Step 1: Surface the conflict
```
"Wait — when you say 'customer', do you mean someone who has an account,
or someone who has made a purchase? I've been hearing it used both ways."
```

### Step 2: Map the divergence
Document both usages side by side. Usually you'll find they're actually two different concepts that share a name.

```
Sales team "customer":   anyone with an account
Support team "customer": anyone who contacts them (including non-account holders)
Finance team "customer": anyone who has made a payment

These are actually three concepts:
  Visitor:  browsing without an account
  Prospect: has an account, no purchases
  Customer: has made at least one paid purchase
```

### Step 3: Propose canonical terms with stakeholder buy-in
The domain experts must agree — engineering cannot unilaterally name concepts. The goal is for business experts to naturally use the code terms in meetings.

### Step 4: Record in the glossary
Document the decision with the rationale. Future team members need to know not just what the terms mean, but why the distinction exists.

### Step 5: Update all occurrences
```bash
# When a term is renamed, update it everywhere:
# - Code (classes, methods, variables, database columns)
# - Tests
# - API endpoints and response fields
# - Documentation
# - Event names (this is a breaking change — version your events)
# - Database migrations to rename columns
```

---

## Cross-Context Term Disambiguation

The same word can mean different things in different bounded contexts. This is expected. Document it explicitly.

```markdown
## "Product"

### Catalog Context
A fully described item available for sale. Includes current price, current inventory,
images, description, variants, and active status. Mutable — changes frequently.
Code: `CatalogProduct` class, `catalog_products` table.

### Orders Context
An immutable snapshot of a product at the time of purchase. Price is locked.
Name is locked. Catalog changes after the order was placed do not affect this.
Code: `OrderProductSnapshot` value object, stored within `order_items` table.

### Shipping Context
A physical item with dimensions and weight relevant to carrier routing.
Does not include price or catalog information.
Code: `ShippableItem` value object within `Shipment` aggregate.

### Payments Context
Not a relevant concept. Payments deal with monetary amounts, not what was purchased.
```

---

## Anti-Patterns

### Unilateral Renaming by Engineering
Engineering renames a concept in code without consulting domain experts. The glossary and the codebase diverge again within a sprint. Engineering cannot own naming decisions — they can propose and implement, but domain experts must ratify.

### Tolerating Synonyms "For Now"
"We all know Order and Purchase mean the same thing here." Left unresolved, both terms proliferate. In 6 months, a new team member doesn't know which one to use and writes code that uses both.

---

## Quick Reference

```
Conflict resolution steps: surface → map divergence → propose canonical terms → stakeholder buy-in → update everywhere
Cross-context disambiguation: same word in different contexts is expected and correct — document it
Event renames: breaking change — version your events before renaming
Engineering cannot unilaterally name domain concepts — propose, don't decide alone
Synonym tolerance: zero — resolve conflicts immediately, not "for now"
```
