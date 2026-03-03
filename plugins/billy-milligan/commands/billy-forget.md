---
name: billy:forget
description: |
  Mark a decision as SUPERSEDED or remove an obsolete entry from team memory.
  Never actually deletes — marks entries with status and reason.
  Safety-first approach to memory management.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /billy:forget — Mark Memory as Obsolete

## Usage
```
/billy:forget argument "token TTL"     — mark an argument as RESOLVED or DROPPED
/billy:forget backlog "rate limiting"  — remove a backlog item
/billy:forget context "<topic>"        — remove outdated info from context.md
```

**For formal ADR decisions, use `/billy:adr-status <number> DEPRECATED` or `/billy:adr-supersede` instead.**

## Instructions

When the user invokes `/billy:forget`, mark entries as obsolete. NEVER delete content — mark it.

### Step 0: Resolve Memory Path

```bash
MEMORY_DIR=$(bash ./plugins/billy-milligan/scripts/memory-save.sh path)
```

### Step 1: Find the Entry

1. Parse the user's description to identify what to forget
2. Search across memory files in `$MEMORY_DIR` for matching entries
3. If multiple matches found, show them and ask the user to be more specific
4. If no matches found, say so: "Nothing matching that in team memory."

### Step 2: Mark as Obsolete

#### For Arguments (arguments.md)

Find the matching `## Topic — UNRESOLVED` section and update:
- Change `UNRESOLVED` to `DROPPED`
- Add `**Dropped:** YYYY-MM-DD — <reason>`
- Do NOT move to decisions.md (that's for resolved arguments, not dropped ones)

#### For Backlog (backlog.md)

Find the matching `- [ ]` entry and change to:
- `- [x] ~~original text~~ (dropped YYYY-MM-DD)`

### Step 3: Agent Reaction

An agent should comment naturally:

- Dennis: "наконец-то. Я это имплементировать не собирался anyway"
- Viktor: "решение устарело? Или вы наконец поняли что я был прав?"
- Sasha: "ага, ещё одно решение которое не пережило продакшен. Кто бы мог подумать"
- Lena: "дорогуша, а мы точно уверены что это можно забыть? Я помню как мы это обсуждали..."
- Max: "закрыто. Двигаемся дальше. Не оглядываемся"

### Important Rules

- NEVER actually delete content from memory files
- Always mark with a date and reason
- If the user tries to forget a formal decision, redirect: "Formal decisions live in docs/adr/ — use `/billy:adr-status` or `/billy:adr-supersede` instead."
- After marking, suggest `/billy:recall` to verify the change
