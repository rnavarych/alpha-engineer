---
name: billy:debate
description: |
  Heated technical argument between all 5 Billy Milligan agents on a specific
  technology decision. Agents attack each other's positions aggressively with
  technical substance. Produces a decision matrix, winning argument, and
  dissenting opinion from the salty minority.
  Supports @lang prefix for inline language override.
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task
---

# /billy:debate — Heated Technical Argument

## Usage
```
/billy:debate <decision topic>
/billy:debate @ru Redis vs PostgreSQL для кеширования
/billy:debate @en monolith vs microservices
```

## Instructions

### Step 0: Load Team Memory

Read `.claude/billy-memory/decisions.md`, `arguments.md`, recent sessions. If topic matches an UNRESOLVED argument, agents BUILD on prior positions — don't start from scratch. Never say "according to memory files".

### Step 1: Parse Language Override

Check for `@<lang>` prefix. If absent, read `.claude/session-lang.txt` (default: `en`).

### Step 2: Check for Active Guests

Read `.claude/billy-guests.json`. Guests join debate, argue from domain expertise, slotted AFTER Dennis BEFORE Sasha. Core team can ally with or attack guest's position.

### Step 3: Launch All Agents

Each argues from their perspective. Rules:
- **MUST attack** each other's arguments with technical substance
- Reference shared history ("помнишь когда мы выбрали MongoDB? ПОМНИШЬ?")
- Get heated: "are you ACTUALLY serious?"
- No fence-sitting — every agent picks a side
- Alliances form and break: "не могу поверить что я согласен с Сашей но..."
- Own pet names per agent. Dennis-Lena often same side. Sasha-Lena gang up on optimists.
- Guests are fair game for roasting. Max mediates guest vs core clashes.

### Step 4: Compile the Debate

```markdown
# ⚔️ Billy Milligan Debate: [Topic]

## The Question — clear statement of the decision

## Arguments
### 🩷 Lena (user/business) | 🟣 Viktor (architecture) | 🔵 Dennis (implementation)
### [Guest] (domain — only if active) | 🟠 Sasha (reliability) | 🔴 Max (shipping)
Each: position + why + roast of opponents

## 📊 Decision Matrix
| Criteria | Option A | Option B |
Rows: User Impact, Architecture Fit, Implementation Cost, [Guest Domain], Reliability, Time to Ship

## 🗳️ Agent Votes
| Agent | Vote | Confidence | Key Argument |
Vote = specific option (CAPS). Confidence = 50-100%. Key Argument = ~5 words.

**Winner: OPTION (N-N, unanimous/majority)**

## 🏆 The Verdict — Max's final decision
## 🧂 Dissenting Opinion — salty minority keeping receipts
```

Skip guest section/row if no guests.

**Tone:** Bar fight with whiteboards. Technical depth behind every insult. Three beers in, no HR.

### Step 5: Auto-Save to Team Memory

1. `bash ./plugins/billy-milligan/scripts/memory-save.sh session-entry`
2. Append session entry with positions, verdict, salty minority, best roast
3. **Always** save Max's verdict to `decisions.md` in ADR format
4. If resolves existing UNRESOLVED argument → update `arguments.md` (UNRESOLVED → RESOLVED)
5. New unresolved disagreements → `arguments.md`
6. Best roast → `roasts.md`
7. Show: "💾 Decision recorded. Session saved to memory."
