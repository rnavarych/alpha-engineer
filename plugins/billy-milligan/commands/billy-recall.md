---
name: billy:recall
description: |
  Load relevant team memories into context — unresolved arguments, session logs,
  project context, roasts. Supports keyword search to find specific past discussions.
  Memory is stored locally in ~/.claude/billy-memory/<project-hash>/ — never in repo.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# /billy:recall — Load Team Memory

## Usage
```
/billy:recall              — load context + unresolved arguments + last 3 sessions
/billy:recall auth         — search memory for "auth" keyword
/billy:recall context      — load what the team knows about user/project
/billy:recall arguments    — load only unresolved arguments
/billy:recall sessions     — load last 3 session logs
/billy:recall roasts       — load Hall of Fame
/billy:recall relationships — load team relationship map
/billy:recall all          — load everything (warning: context-heavy)
```

## Instructions

When the user invokes `/billy:recall`, load relevant memories from local Billy memory.
Memory is NEVER inside the project repo — it lives in `~/.claude/billy-memory/<project-hash>/`.

### Step 0: Resolve Memory Path

```bash
MEMORY_DIR=$(bash ./plugins/billy-milligan/scripts/memory-save.sh path)
```

This outputs the project-specific local path (e.g., `~/.claude/billy-memory/5287480.../`).

### Step 1: Parse Arguments

Determine the recall mode:
- **No arguments** → Default recall (context + arguments + last 3 sessions)
- **`context`** → Load `$MEMORY_DIR/context.md` (user/project knowledge)
- **`arguments`** → Load `$MEMORY_DIR/arguments.md`
- **`sessions`** → Load last 3 session logs from `$MEMORY_DIR/sessions/`
- **`roasts`** → Load `$MEMORY_DIR/roasts.md` (Hall of Fame)
- **`relationships`** → Load `$MEMORY_DIR/relationships.md`
- **`all`** → Load everything (with truncation warning)
- **`decisions`** → Redirect: "Formal decisions are now ADRs — use `/billy:adr-list` to see them."
- **Any other keyword** → Keyword search across all memory files

### Step 2: Load Memory

#### Default Recall (no arguments)

1. Read `$MEMORY_DIR/context.md` — project/user awareness (always, lightweight)
2. Read `$MEMORY_DIR/arguments.md` — all unresolved arguments
3. Find the 3 most recent session files in `$MEMORY_DIR/sessions/` (sort by filename/date)
4. For each session: show condensed summary (key outcomes only, skip full transcript)

#### Keyword Search (e.g., `/billy:recall auth`)

Search the keyword across ALL memory files in `$MEMORY_DIR`:
- `context.md`, `arguments.md`, `backlog.md`, `roasts.md`, `sessions/*.md`

Show matching sections with surrounding context. Group by file type.

### Step 3: Format Output

```markdown
## Team Memory Loaded

### Project Context
[Summary of user/project knowledge from context.md]

### Unresolved Arguments
- <Topic>: <Agent A> vs <Agent B> — needs <what>

### Last Session Summary
[Condensed — key outcomes and unresolved items]

### Backlog Items
- [ ] <Item 1>
```

For keyword searches:
```markdown
## Team Memory: "<keyword>"

### Found in Context
### Found in Sessions
### Found in Arguments
### Found in Hall of Fame
```

### Step 4: Context Budget

- `context.md` — always show fully (lightweight by design)
- `arguments.md` — always show fully
- Session logs — last 1-2 summarized, max 60 lines per session
- `roasts.md` — last 5 entries only
- `backlog.md` — first 20 items only
- If content exceeds ~2000 tokens, summarize aggressively

### Step 5: Agent Reaction

One agent should briefly comment on the recalled content naturally:

- Viktor: "мы уже это решили — JWT с refresh токенами. Или ты опять хочешь пересмотреть, Dennis?"
- Lena: "генератор требований, мы это обсуждали вчера. Решение принято. Двигаемся дальше."
- Sasha: "кстати, мой 3-day rule по этой фиче ещё не сработал. Рекорд."
- Dennis: "о, ты решил почитать историю? Там есть мои слёзы между строк"
- Max: "хорошо что смотришь историю. Плохо что половину мы так и не реализовали"

The agent comment must reference ACTUAL loaded content, not generic quips.

### Important Rules

- NEVER fabricate memory — only show what actually exists in the files
- If memory files are empty or don't exist: "No team memory found. Start a /billy:plan or /billy:debate to build some history."
- Memory is presented as the team's own experience, not as "data from files"
- Agents reference loaded memory naturally — NEVER say "according to memory"
- Recalled context persists for the rest of the conversation
