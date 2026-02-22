---
name: adr:supersede
description: |
  Mark an existing ADR as superseded and create its replacement.
  Updates the old ADR's status and creates a new ADR that references the old one.
  Sequential numbering — never reuses old numbers.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /adr:supersede — Supersede an Architecture Decision Record

## Usage
```
/adr:supersede 002 "Authentication Approach v2 — PKCE with OAuth"
/adr:supersede 001 "Switch to CockroachDB"
```

## Instructions

When the user invokes `/adr:supersede <old-number> "<new-title>"`, this:
1. Marks the old ADR as SUPERSEDED
2. Creates a new ADR that references the old one
3. Updates the README index

### Step 1: Find the Old ADR

Use Glob to find `docs/adr/<number>*.md`.

If not found:
```
ADR-<number> not found. Run /adr:list to see available ADRs.
```

### Step 2: Confirm with User

Show the old ADR's title and status, confirm the action:
```
About to supersede:
  ADR-<old>: <old title> (currently: ACCEPTED)

With new ADR:
  ADR-<new>: <new title> (will be created as PROPOSED)

This will:
  1. Change ADR-<old> status to "SUPERSEDED by ADR-<new>"
  2. Create docs/adr/<new>-<slug>.md
  3. Update docs/adr/README.md index

Proceed? (y/n)
```

### Step 3: Mark Old ADR as Superseded

Run:
```bash
bash ./plugins/billy-milligan/scripts/adr-new.sh "<new-title>" PROPOSED
```
Capture the new ADR number and path.

Then update the old ADR's Status section:

From:
```markdown
## Status
ACCEPTED
```

To:
```markdown
## Status
SUPERSEDED by ADR-NNN
```

Also add a note at the bottom of the old ADR:
```markdown
---
*This ADR was superseded by [ADR-NNN: <new title>](NNN-<slug>.md) on YYYY-MM-DD.*
```

### Step 4: Write the New ADR

Open the new ADR file (created by the script) and populate it properly.

Include in the new ADR's Context section:
```markdown
This ADR supersedes ADR-<old>: [<old title>](<old-file>.md).
The previous approach was [brief reason it's being replaced].
```

Include in the new ADR's Related section:
```markdown
- Supersedes: ADR-<old> ([<old title>](<old-file>.md))
```

### Step 5: Update README Index

Run: `bash ./plugins/billy-milligan/scripts/adr-list.sh --update-readme`

### Step 6: Billy Commentary (if Billy is ON)

If Billy is active, the team may briefly note the change in their voices:
> **Viktor:** "ADR-002 отправлен на пенсию. Новый будет лучше. Обещаю."
> **Dennis:** "ещё один ADR который мне предстоит переимплементировать. Нормально."

This commentary is verbal only — it does NOT appear in any ADR file.

### Important Rules

- Superseded ADRs are NEVER deleted — they're historical record
- The replacement ADR gets the NEXT sequential number, never the old number
- Both old and new ADRs must cross-reference each other
- Never rename or move the old ADR file — existing links may depend on it
- ADR numbers are never reused, ever
