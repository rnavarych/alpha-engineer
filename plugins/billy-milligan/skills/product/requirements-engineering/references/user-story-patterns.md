# User Story Patterns

## When to load
Load when writing user stories, evaluating backlog quality against INVEST criteria, choosing the right story format, or running a story mapping session to organize the backlog spatially.

---

## INVEST Criteria — Full Decision Table

| Criterion | Test Question | Failing Signal | Fix |
|-----------|--------------|----------------|-----|
| **Independent** | Can this story be built and deployed without another story being done first? | "Needs the auth story first", "blocked by API work" | Split at a seam that lets both ship independently, or merge the dependency into this story |
| **Negotiable** | Is the HOW flexible? Can we achieve the same goal a different way? | "Implement Redis cache", "Use PostgreSQL full-text search" — implementation prescribed | Rewrite to outcome: "Product search returns results in <300ms" |
| **Valuable** | Does this deliver value to the end user OR the business? | "Refactor service layer", "Add indexes to orders table" — technical work with no user-facing value | Frame as enabler tied to a user outcome, or park it as a tech debt story with explicit business justification |
| **Estimable** | Can the team give a relative estimate? | "Too many unknowns", "Depends on what the API returns", "We've never done this before" | Run a time-boxed spike (research story) first; split unknowns from known work |
| **Small** | Can one developer (or pair) complete it in 1–5 days? | Estimate > 8 story points, or "we'll need the whole sprint" | Apply splitting strategies — see story-splitting.md |
| **Testable** | Do acceptance criteria exist and can QA verify them without asking the author? | "Should feel fast", "Good user experience", no ACs written yet | Write Given-When-Then before estimation; if you can't write ACs, the story isn't ready |

---

## User Story Format

### Standard format
```
As a [specific user role with context]
I want to [accomplish this concrete goal]
So that [I receive this measurable value]
```

### Role specificity matters

| Too generic | Better |
|------------|--------|
| As a user | As a customer who added items to cart but didn't check out |
| As an admin | As a fraud operations analyst reviewing flagged transactions |
| As a manager | As a warehouse shift supervisor allocating pick tasks |

The more specific the role, the clearer the acceptance criteria become, and the more likely the team will discover edge cases before implementation.

### Story templates by type

**New feature story:**
```
As a [role]
I want to [action]
So that [benefit]

Notes:
- [Known constraint or design consideration]
- [Related story or dependency]

Acceptance Criteria:
[See acceptance-criteria.md]
```

**Improvement story:**
```
As a [role who currently suffers from the problem]
I am currently experiencing [the pain or friction]
I want to [improved behavior]
So that [I can stop worrying about / losing time on / paying for X]
```

**Spike (research) story:**
```
Explore: [topic or technology question]
We need to understand: [specific unknowns]
Output expected: [decision document / proof of concept / estimate / recommendation]
Time-box: [N] days
```

---

## Story Mapping

Story mapping organizes stories spatially — horizontal axis is user journey, vertical axis is priority. It prevents the trap of building everything at depth before delivering any breadth.

### Structure
```
User Journey (horizontal):
  Discover → Register → Browse → Add to Cart → Checkout → Receive Order → Return

Release slices (vertical — each horizontal band is one release):

  MVP (Release 1 — minimum viable):
    [Search product] [View product] [Guest checkout] [Email confirmation]

  Release 2 — must complete:
    [Filter by category] [Save to wishlist] [Account registration] [Order history]

  Release 3 — growth:
    [Product reviews] [Recommendations] [Saved cards] [Returns portal]
```

### How to run a story mapping session
1. **Write user activities** — 1 sticky per major activity (not features, not tasks — activities a user does)
2. **Sequence the activities** left to right as the user would experience them
3. **Write user tasks** under each activity — what specifically does the user do to accomplish it?
4. **Identify the MVP slice** — draw a horizontal line. Everything above the line is MVP. Question everything below the line for release 1.
5. **Group below the line** into release 2, release 3 — force the conversation about what's truly required now

---

## Anti-Patterns

### "Backend Story" or "Frontend Story"
Horizontal slice — delivers no user value until both layers are done. Use vertical slices that cut through all layers but deliver a thin working feature.

### "As a developer, I want..."
Developers are not the end user of a feature. Technical tasks belong in spike stories, tech debt stories, or as implementation subtasks — not as user stories claiming user value.

### AC Written After Estimation
Acceptance criteria written after the estimate means the team estimated a story they didn't fully understand. ACs must exist before estimation — they are the spec.

---

## Quick Reference

```
INVEST: Independent, Negotiable, Valuable, Estimable, Small, Testable
Role: specific person with context, not "a user"
Story map: horizontal = user journey, vertical = priority/release slices
Split triggers: estimate >8 points, "we'll need the whole sprint", "depends on..."
Spike: time-boxed research — 1-3 days max; output is a decision, not a feature
ACs must exist BEFORE estimation — if you can't write them, the story isn't ready
```
