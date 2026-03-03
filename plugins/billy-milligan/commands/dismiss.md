---
name: billy:dismiss
description: |
  Remove a guest from the current team discussion. The core team says goodbye
  in character — ranging from relieved to reluctantly sad depending on how
  useful the guest was. Cleans up session state.
  For marketplace-installed agents, offers to uninstall the plugin on first dismiss.
argument-hint: "<guest-name>"
user-invocable: true
allowed-tools: Read, Bash, AskUserQuestion
---

# /billy:dismiss — Remove a Guest from the Team Discussion

## Usage
```
/billy:dismiss oleg       → remove Oleg
/billy:dismiss all        → remove all guests
```

## Instructions

### Step 1: Identify the Guest

Check `.claude/billy-guests.json`. If guest not found, list active guests. If no guests, say team is alone as usual.

### Step 2: Generate Farewell Scene

Core team says goodbye in character. Tone depends on guest contribution:

- **Useful guest** → grudging warmth, "не записывайте это" from Dennis, Viktor appreciates their domain knowledge
- **Complicated things** → undisguised relief, Max mentions scope creep, Dennis celebrates
- **Neutral/forgettable** → indifference, "кто? а, этот" energy

**Special rules:**
- Marketplace agents get "contractor leaving" undertone — more formal farewell
- Male guests: Dennis relieved Lena's flirting target is gone (REQUIRED)
- Each agent reacts from their perspective: Max (pragmatic), Lena (warmth/relief), Dennis (grumpy), Viktor (intellectual), Sasha (fewer bug sources)

### Step 3: Marketplace Plugin Uninstall

**Only for** marketplace-sourced guests with `"marketplace_first_dismiss": true`.

Use `AskUserQuestion` (in session language) to offer plugin removal. If confirmed: `claude plugin uninstall {plugin-name}`. Set `marketplace_first_dismiss: false` after prompt shown.

### Step 4: Clean Up

Remove guest from `.claude/billy-guests.json`.

### Step 5: Confirm

```markdown
# 👋 Guest Departed: [Name]
[Farewell scene]
**Source:** [Local|Marketplace|Ad-hoc] | **Remaining guests:** [list or "core team only"]
```

### /billy:dismiss all

Max takes charge: "совещание с гостями окончено". Each guest gets one-line farewell. Marketplace plugin uninstall prompt shown ONCE for all plugins. End with: "Команда снова в полном составе."
