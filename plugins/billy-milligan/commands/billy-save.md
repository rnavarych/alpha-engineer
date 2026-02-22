---
name: billy:save
description: |
  Save team notes, roasts, arguments, and session summaries to persistent Billy memory.
  Memory is stored locally in ~/.claude/billy-memory/<project-hash>/ — never committed to git.
  For formal architectural decisions, use /adr:new instead.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /billy:save — Save to Team Memory

## Usage
```
/billy:save                                    — save a session summary (interactive)
/billy:save note "добавить rate limiting"       — save a backlog note
/billy:save roast "Dennis to Viktor: ..."      — save a roast to Hall of Fame
/billy:save context "user prefers short TTLs"  — update team knowledge about user/project
```

**For formal architectural decisions, use `/adr:new "<title>"` instead.**
Billy memory is for informal team knowledge — roasts, arguments, context, vibes.

## Instructions

When the user invokes `/billy:save`, persist information to local Billy memory.
Memory lives in `~/.claude/billy-memory/<project-hash>/` — LOCAL ONLY, never in the repo.

### Step 0: Resolve Memory Path

```bash
MEMORY_DIR=$(bash ./plugins/billy-milligan/scripts/memory-save.sh path)
```

### Mode 1: Save a Backlog Note

If the user writes `/billy:save note "<text>"`:
1. Run `bash ./plugins/billy-milligan/scripts/memory-save.sh note "<text>"`
2. Confirm: "Added to backlog."

### Mode 2: Save a Roast

If the user writes `/billy:save roast "<text>"`:
1. Run `bash ./plugins/billy-milligan/scripts/memory-save.sh roast "<text>"`
2. Confirm in character — one agent reacts to their roast being immortalized

### Mode 3: Update Context

If the user writes `/billy:save context "<text>"`:
1. Run `bash ./plugins/billy-milligan/scripts/memory-save.sh context-update "<text>"`
2. Confirm: "Context updated."

Use this when the team learns something new about the user or project worth remembering.

### Mode 4: Session Summary Save (Interactive)

If the user invokes `/billy:save` with no arguments, create a summary of the current session:

1. Get today's session file path:
   ```bash
   SESSION_FILE=$(bash ./plugins/billy-milligan/scripts/memory-save.sh session-entry)
   ```
2. Analyze the current conversation for:
   - What commands were run (/plan, /debate, /review, /roast)
   - Key outcomes (informal — what was decided, who won, who lost)
   - Unresolved disagreements
   - Action items assigned
   - Best roasts
   - Links to formal ADRs created this session
3. Write a session entry to the session file:

```markdown
## Session HH:MM — /command topic

**Participants:** <agents who participated>

**Key outcomes:**
- <outcome 1> (<who won, who lost>)
- <outcome 2>

**Formal decisions recorded:** → ADR-NNN: <title> (if an ADR was created)

**Unresolved:**
- <disagreement — who holds which position>

**Action items:**
- <Agent>: <task>

**Best roast of the session:**
- <Agent> to <Agent>: "<the roast>"
```

4. If unresolved arguments emerged, save them:
   ```bash
   bash ./plugins/billy-milligan/scripts/memory-save.sh argument "<topic>"
   ```
   Then edit `$MEMORY_DIR/arguments.md` to fill in the positions.
5. If great roasts happened, save them:
   ```bash
   bash ./plugins/billy-milligan/scripts/memory-save.sh roast "<text>"
   ```

### Auto-Save (called by team commands)

Triggered automatically at the END of `/plan`, `/debate`, `/review`, `/roast`.

1. Create the session entry (same format as Mode 4)
2. Save unresolved arguments to `arguments.md`
3. Save the best roast to `roasts.md`
4. If a formal decision was made → mention it and prompt: "записать ADR? (/adr:new)"
5. Do NOT ask for user confirmation — save silently
6. Show a brief confirmation: "Session saved to memory." (no fanfare)

### Important Rules

- Memory files are plain markdown — user can read/edit them directly
- NEVER overwrite existing entries — always APPEND
- NEVER save formal decisions to Billy memory — those go in `docs/adr/` via `/adr:new`
- When an argument gets resolved via a formal ADR, mark it RESOLVED in `arguments.md` with a link to the ADR
- Agents should react naturally to saves — Dennis: "великолепно, сохранили ещё один беспорядок"
