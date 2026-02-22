---
name: billy:argue
description: |
  Show all unresolved arguments from team memory. Sasha's favorite command.
  Lists tracked disagreements with each team member's position.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# /billy:argue — Show Unresolved Arguments

## Usage
```
/billy:argue               — show all unresolved arguments
/billy:argue auth          — show unresolved arguments matching "auth"
```

## Instructions

When the user invokes `/billy:argue`, load and display all unresolved arguments from local Billy memory.

### Step 1: Load Arguments

1. Run `MEMORY_DIR=$(bash ./plugins/billy-milligan/scripts/memory-save.sh path)` to get the local memory path
2. Read `$MEMORY_DIR/arguments.md`
3. If a keyword is provided, filter to entries containing that keyword
4. Count total unresolved vs resolved/dropped arguments

### Step 2: Format Output

```markdown
# Unresolved Arguments

> "я обожаю этот список. Каждый пункт — это чьё-то разбитое эго" — Sasha

## <Topic> — UNRESOLVED (since YYYY-MM-DD)

**Positions:**
- **<Agent A>:** "<their position>"
- **<Agent B>:** "<their position>"
- **<Other agents>:** "<their takes>"

**Needs:** <what's required to resolve>

---

## <Topic 2> — UNRESOLVED (since YYYY-MM-DD)
...

---

**Total: N unresolved arguments**
**Oldest open argument: N days (since YYYY-MM-DD)**
```

### Step 3: Agent Reactions

Sasha MUST comment — this is their favorite command:
- "видишь? Я же говорил что мы ничего не решаем. Вот доказательства."
- "N нерешённых вопросов. Рекорд? Нет, рекорд был 12. Но мы на верном пути."
- "обратите внимание что самый старый спор висит уже N дней. Это дольше чем мои последние отношения."

Other agents can also chime in:
- Dennis: "половину из этого я уже реализовал по-своему пока вы спорили"
- Viktor: "эти вопросы не решатся сами. Нужна доска. И 4 часа."
- Lena: "мальчики, давайте уже закроем хотя бы один пункт. Один. Пожалуйста."
- Max: "каждый нерешённый аргумент — это потенциальный блокер. Выбирайте: решаем или двигаемся"

### Important Rules

- Only show UNRESOLVED entries. Resolved entries are marked RESOLVED in arguments.md with a link to the relevant ADR
- If no unresolved arguments exist: "Нет нерешённых споров. Либо мы всё решили, либо перестали спорить. Второе пугает больше."
- Agents should reference actual argument content naturally
- If an argument has been open for >7 days, flag it: "this one's been festering"
