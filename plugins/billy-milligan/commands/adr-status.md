---
name: adr:status
description: |
  Change the status of an Architecture Decision Record.
  Valid transitions: PROPOSED → ACCEPTED → DEPRECATED → SUPERSEDED.
  Simple, surgical update — no discussion needed.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /adr:status — Update ADR Status

## Usage
```
/adr:status 004 ACCEPTED
/adr:status 002 DEPRECATED
/adr:status 003 PROPOSED
```

## Valid Statuses

| Status | Meaning |
|--------|---------|
| `PROPOSED` | Under discussion, not finalized |
| `ACCEPTED` | Decision is in effect |
| `DEPRECATED` | No longer applies, not replaced |
| `SUPERSEDED by ADR-NNN` | Use `/adr:supersede` for this — it handles the full flow |

## Instructions

### Step 1: Find the ADR

Use Glob to find `docs/adr/<number>*.md`.

If not found:
```
ADR-<number> not found. Run /adr:list to see available ADRs.
```

### Step 2: Read Current Status

Show current ADR title and status.

### Step 3: Confirm Change

```
ADR-NNN: <title>
Current status: <current>
New status: <new>

Update status? (y/n)
```

### Step 4: Apply Update

Use Edit to update the Status section in the ADR file:

From:
```markdown
## Status
<current status>
```

To:
```markdown
## Status
<new status>
```

Confirm: `ADR-NNN status updated to <new status>.`

### Step 5: Update README Index

Run: `bash ./plugins/billy-milligan/scripts/adr-list.sh --update-readme`

### Note on SUPERSEDED

If the user tries to set status to `SUPERSEDED`, remind them:
```
To supersede an ADR properly (mark old + create replacement), use:
  /adr:supersede <number> "<new title>"

Or if you just want to mark it superseded without creating a replacement:
  /adr:status <number> "SUPERSEDED by ADR-NNN"
  (include the ADR number that supersedes it)
```

### Important Rules

- Don't validate the "logic" of status transitions — user knows what they're doing
- The status field is plain text — it can say "SUPERSEDED by ADR-007" if needed
- Always update the README index after changing status
