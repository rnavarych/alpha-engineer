---
name: billy:context
description: |
  Show what the team knows about the user and project.
  Loads context.md from local Billy memory — accumulated knowledge from past sessions.
  Update it with /billy:save context "<note>" when new things are learned.
user-invocable: true
allowed-tools: Read, Bash, Glob
---

# /billy:context — What the Team Knows

## Usage
```
/billy:context             — show all accumulated knowledge about user and project
/billy:context user        — show only user profile section
/billy:context project     — show only project context section
```

## Instructions

When the user invokes `/billy:context`, load and display the team's accumulated knowledge.

### Step 1: Resolve Memory Path

```bash
MEMORY_DIR=$(bash ./plugins/billy-milligan/scripts/memory-save.sh path)
```

### Step 2: Load Context

Read `$MEMORY_DIR/context.md`.

If it doesn't exist or is empty:
```
No team context yet. The team will build a picture of you and the project over time.
Start a /plan or /debate to begin accumulating context.
```

### Step 3: Format Output

Present the context naturally:

```markdown
## What the Team Knows

### About You
[User profile — preferences, working style, strengths]

### About the Project
[Stack, stage, key decisions, pain points]

### Architecture Facts
[Key technical constraints and decisions already made]

### What's Still Unknown
[Things the team hasn't figured out yet]
```

### Step 4: Agent Commentary

One agent should comment on the context naturally:

- Lena: "видишь? Мы тебя знаем лучше чем ты думаешь, дорогуша."
- Dennis: "прочитай внимательно секцию про backend. Я это написал. С любовью."
- Viktor: "контекст хорошо описан. Кроме архитектурной части. Там нужно добавить."
- Sasha: "security constraints не отражены. Я недоволен."
- Max: "это всё, что нам нужно знать. Остальное выясним по ходу."

### Step 5: Suggest Updates

If context seems stale (last update >7 days ago), note:
```
Context last updated: <date>.
Use /billy:save context "<note>" to add new information.
```

### Important Rules

- Context.md is for INFORMAL team knowledge — preferences, vibes, working style
- Do NOT include formal ADR decisions here — those live in docs/adr/
- Do NOT reveal internal team relationship tensions to the user (those are in relationships.md)
- Context should be presented as the team's natural awareness, not as "data from a file"
