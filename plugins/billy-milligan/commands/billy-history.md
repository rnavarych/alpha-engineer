---
name: billy:history
description: |
  Show a timeline of all team decisions, sessions, and key events.
  Chronological view of the team's history in this project.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# /billy:history — Team Timeline

## Usage
```
/billy:history             — show full timeline of decisions and sessions
/billy:history decisions   — show only decision timeline
/billy:history sessions    — show only session timeline
/billy:history last 7      — show last 7 days only
```

## Instructions

When the user invokes `/billy:history`, compile a chronological timeline from all memory files.

### Step 1: Gather Data

1. Read `.claude/billy-memory/decisions.md` — extract all `## [date] Title` entries with their status
2. List all session files in `.claude/billy-memory/sessions/` using Glob `*.md`
3. Read `.claude/billy-memory/arguments.md` — extract entries with their dates
4. Read `.claude/billy-memory/roasts.md` — extract dated entries

### Step 2: Build Timeline

Sort everything chronologically (newest first) and format:

```markdown
# Team History

## Timeline

### YYYY-MM-DD
- **Decision:** <title> — <status> (proposed by <agent>)
- **Session:** /command <topic> — <brief outcome>
- **Argument opened:** <topic> — <who vs who>
- **Hall of Fame:** <who> to <who>: "<roast snippet>"

### YYYY-MM-DD (previous day)
- **Decision:** ...
- **Argument resolved:** <topic> — moved to decisions
...

## Stats
- Total decisions: N (M active, K superseded)
- Unresolved arguments: N
- Sessions logged: N
- Hall of Fame entries: N
- Most active day: YYYY-MM-DD (N events)
```

### Step 3: Filter by Arguments

- `/billy:history decisions` — show only decision entries
- `/billy:history sessions` — show only session entries with their summaries
- `/billy:history last N` — show only the last N days

### Step 4: Agent Commentary

Max should deliver the timeline like a military briefing:
- "Вот хронология наших побед и поражений, шеф. В основном поражений."
- "За последнюю неделю — N решений принято, M ещё висят. Темп нормальный."
- "Обратите внимание на дыру между [date] и [date]. Там мы просто молча страдали."

### Important Rules

- Show superseded decisions with strikethrough: ~~old decision~~ SUPERSEDED
- Highlight unresolved arguments with a marker
- Keep the timeline scannable — one line per event maximum
- If history is very long (>50 events), paginate or show summary + "use /billy:recall for details"
