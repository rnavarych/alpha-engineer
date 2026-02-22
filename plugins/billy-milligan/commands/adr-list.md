---
name: adr:list
description: |
  Show all Architecture Decision Records with their status.
  Works whether Billy is ON or OFF. Clean, professional output.
user-invocable: true
allowed-tools: Read, Bash, Glob, Grep
---

# /adr:list — List All Architecture Decision Records

## Usage
```
/adr:list
```

## Instructions

When the user invokes `/adr:list`, show all ADRs from `docs/adr/`.

### Step 1: Check ADR Directory

If `docs/adr/` does not exist or contains no ADR files:
```
No Architecture Decision Records found.
Run /adr:new "<title>" to create the first one.
```

### Step 2: Run List Script

```bash
bash ./plugins/billy-milligan/scripts/adr-list.sh
```

### Step 3: Format Output

The script outputs the formatted list. Present it cleanly:

```
Architecture Decision Records
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

001  Database Choice                              ✅ ACCEPTED            2025-02-19
002  Authentication Approach                      ✅ ACCEPTED            2025-02-20
003  Frontend Styling Approach                    ✅ ACCEPTED            2025-02-21
004  API Versioning Strategy                      📋 PROPOSED            2026-02-22

Total: 4 ADR(s)
```

### Step 4: Billy Commentary (if Billy is ON)

If Billy is active, one agent may briefly comment on the ADR list — but NOT in a way
that reveals informal discussion content. Keep it light and work-appropriate:

- Viktor: "четыре решения задокументировано. Сколько ещё висит без документации — другой вопрос."
- Max: "ADR-003 всё ещё PROPOSED. Кто-то должен это закрыть."
- Dennis: "смотри, формально всё выглядит нормально. Неформально — другой разговор."

### Available Actions

After listing, suggest relevant next steps:
```
Available commands:
  /adr:new "<title>"          — create a new ADR
  /adr:review <number>        — review an existing ADR
  /adr:status <number> <status> — update ADR status
  /adr:supersede <old> "<new title>" — supersede an ADR
```

### Important Rules

- Output is always clean and professional regardless of Billy state
- Show ALL ADRs including DEPRECATED and SUPERSEDED ones (they're historical record)
- SUPERSEDED ADRs should be visually de-emphasized but still visible
