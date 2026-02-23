# Story Splitting

## When to load
Load when a story is too large to estimate confidently, estimate is 8+ points, a story covers multiple workflow steps or input variations, or you need to decompose an epic into shippable vertical slices.

---

## Splitting Strategies

When a story is too big, apply these patterns in order:

### 1. Split by workflow step
```
Too big: "User can complete checkout"

Split by step:
  - User can enter shipping address and proceed
  - User can select shipping method
  - User can enter payment information
  - User can review and place order
  - User receives order confirmation email
```

### 2. Split by data type or input variation
```
Too big: "User can log in"

Split by method:
  - User can log in with email and password
  - User can log in with Google OAuth
  - User can log in with magic link (passwordless)
```

### 3. Split by business rule variation
```
Too big: "User can apply a discount code"

Split by rule:
  - User can apply a percentage discount code
  - User can apply a fixed-amount discount code
  - User can apply a free-shipping discount code
  - System rejects expired or invalid codes with descriptive error
```

### 4. Split by happy path vs. edge cases
```
Too big: "User can upload a profile photo"

Split:
  - User can upload a JPEG or PNG under 5MB and see it as their avatar
  - System rejects files over 5MB with a clear error message
  - System rejects non-image files (PDF, EXE) with a clear error message
  - User can remove their profile photo and revert to default avatar
```

### 5. Split by CRUD operations
```
Too big: "Admin can manage users"

Split:
  - Admin can view a paginated list of users with search
  - Admin can view a single user's profile and activity
  - Admin can deactivate a user account
  - Admin can reset a user's password and send them a reset email
```

### 6. Split by performance / quality tier
```
Too big: "Product search works at scale"

Split:
  - Product search returns results from a text index (functional baseline)
  - Product search returns in under 200ms for 95th percentile (performance)
  - Product search uses synonym expansion for common misspellings (quality)
```

---

## Anti-Patterns

### The Bloat Story
"User can manage their account" covers: change password, change email, update profile, manage notifications, view billing, cancel subscription, download data. That's eight stories minimum. Split it.

### Splitting into horizontal layers
Splitting "User can search products" into "Build search API" + "Build search UI" creates two stories that each deliver zero user value alone. Split vertically — each piece must be independently shippable and valuable.

### Accepting 13-point stories into a sprint
A 13-point story means the scope is unclear or too large for one sprint. Either split it or run a spike first to reduce uncertainty. A sprint full of 13-point stories is a sprint that will fail.

---

## Quick Reference

```
Split triggers: estimate >8 points, "we'll need the whole sprint", unclear ACs
Split patterns: workflow step, data variation, business rule, happy/edge, CRUD, quality tier
Vertical slice rule: every split story must deliver user value independently — no horizontal layers
Spike first: if the split itself is unclear, time-box 1-2 days to understand the problem before splitting
13 points: always split or spike — never carry into a sprint as-is
```
