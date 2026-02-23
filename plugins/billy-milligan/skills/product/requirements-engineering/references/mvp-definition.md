# MVP Definition

## When to load
Load when defining what belongs in an MVP, writing a product hypothesis, deciding whether to build or fake a feature, or challenging scope that doesn't directly test the core assumption.

---

## The Hypothesis-First Approach

MVP is not "minimum features" — it is "minimum learning." An MVP tests a specific hypothesis.

Before defining MVP scope, write the hypothesis:

```
We believe that [target user] will [take this action / achieve this outcome]
because [core value proposition].
We'll know we're right when [specific metric] reaches [specific threshold]
within [time period] of launch.
```

Example:
```
We believe that independent freelancers will pay $29/month
to send professional invoices through our platform
because they currently lose 3–5 hours per month on invoice creation and follow-up.
We'll know we're right when 100 paying customers each send at least 3 invoices
within 60 days of their trial ending.
```

**MVP scope follows from the hypothesis.** If a feature doesn't help test the hypothesis, it's not in MVP.

---

## MVP Scope Decision Table

| Question | If YES | If NO |
|----------|--------|-------|
| Does this feature test our core hypothesis? | Strong candidate for Must Have | Not in MVP unless it unblocks something that does |
| Can a user get the core value without this? | Can Have or Should Have | Likely Must Have |
| Can we fake this manually for the first 10 customers? | Should or Could Have — automate later | Must Have |
| Would we rather launch without this than delay 2 weeks? | Could Have | Must Have or extend timeline |
| Can a first-time user complete the core task without this? | Could Have | Must Have |

---

## The Wizard of Oz Test

Before building it, ask: can we fake it? If yes, defer the technical implementation.

Examples of things you can fake at MVP:
- Recommendation engine → manual curation by the team
- Automated email sequences → person manually sending emails
- Admin dashboard → spreadsheet + direct DB queries
- Search → browse by category only
- Notifications → email only, no push
- Payment plan → manual invoicing

---

## Anti-Patterns

### The Infinite Backlog
Backlog with 400 items, none of it prioritized, all of it "important." A backlog is a prioritized list of things you intend to build. If you don't intend to build it in the next 3 months, archive it. Infinite backlogs hide real priorities.

### MVP Without a Hypothesis
"Let's build the minimum and see what happens" is not a product hypothesis. Without a specific, falsifiable hypothesis, you can't know if the MVP succeeded or failed — and you'll keep building instead of learning.

---

## Quick Reference

```
MVP = minimum learning, not minimum features — what hypothesis does this test?
Hypothesis format: We believe [user] will [action] because [value]. We'll know when [metric].
Decision rule: if a feature doesn't test the hypothesis, it probably isn't in MVP
Wizard of Oz: can we fake it manually for the first 10 customers? If yes, defer it.
Scope lock: define what MVP is NOT — explicit Won't Haves prevent scope drift
```
