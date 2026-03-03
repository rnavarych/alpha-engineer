---
name: billy:skills-gaps
description: |
  View, manage, and clear skill gaps logged by the knowledge resolution chain.
  Shows topics where agents fell back to model knowledge or honest uncertainty.
  Gaps inform which skills to create next. Supports subcommands: clear, promote, dismiss.
user-invocable: true
allowed-tools: Read, Bash, Glob, Grep
---

# /billy:skills-gaps — Skill Gap Report

## Usage
```
/billy:skills-gaps                    — show full gap report
/billy:skills-gaps clear              — clear all tracked gaps
/billy:skills-gaps promote <topic>    — promote gap priority (low->medium, medium->high)
/billy:skills-gaps dismiss <topic>    — remove a gap from tracking
```

## Instructions

When the user invokes `/billy:skills-gaps`, determine the mode from the argument.

### Mode 1: Show Gap Report (default — no arguments)

1. Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh list`
2. If output says "No skill gaps recorded", respond:
   - Billy ON: Max says something like "No gaps. Either we're that good, or nobody's asking hard questions."
   - Billy OFF: "No skill gaps recorded. Knowledge coverage is holding up."
3. If gaps exist, format them as a structured report:

```markdown
# Skill Gaps Report

## HIGH Priority (agent couldn't answer confidently)

| # | Topic | Agent | Frequency | Closest Match | Suggested Skill |
|---|-------|-------|-----------|---------------|-----------------|
| 1 | ...   | ...   | ...       | ...           | ...             |

## MEDIUM Priority (answered from model knowledge)

| # | Topic | Agent | Frequency | Closest Match | Suggested Skill |
|---|-------|-------|-----------|---------------|-----------------|
| 1 | ...   | ...   | ...       | ...           | ...             |

---

**Total:** N gaps tracked, M total hits
**Top suggestion:** create `<path>` (N hits across K agents)

**Actions:**
- `/billy:skills-create <topic>` — generate a new skill from a gap
- `/billy:skills-gaps promote <topic>` — promote priority
- `/billy:skills-gaps dismiss <topic>` — remove a gap
- `/billy:skills-gaps clear` — clear all gaps
```

### Mode 2: Clear All Gaps

If the argument is `clear`:
1. Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh clear`
2. Respond:
   - Billy ON: Sasha reacts — "Clearing the gaps? Brave. Or reckless. I'll track which one."
   - Billy OFF: "All skill gaps cleared."

### Mode 3: Promote Priority

If the argument starts with `promote`:
1. Extract the topic from after "promote " in the argument
2. Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh promote "<topic>"`
3. If successful, confirm the new priority level
4. If gap not found, list available topics

### Mode 4: Dismiss Gap

If the argument starts with `dismiss`:
1. Extract the topic from after "dismiss " in the argument
2. Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh dismiss "<topic>"`
3. If successful, confirm dismissal
4. If gap not found, list available topics

## Rules

- The gap report is LOCAL data — never mention it's stored in billy-memory
- Present gaps as "topics the team hasn't built deep expertise in yet" (not "skill gaps")
- When Billy is ON, agents can react in character to the gap report
- When Billy is OFF, keep it clean and professional
- Frequency is the priority signal — high-frequency gaps deserve attention
- Always show the `/billy:skills-create` suggestion for the highest-frequency gap
