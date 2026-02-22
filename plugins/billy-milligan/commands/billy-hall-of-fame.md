---
name: billy:hall-of-fame
description: |
  Show the Hall of Fame — best roasts and inside jokes from team sessions.
  Team bonding activity. Agents reference past roasts naturally.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# /billy:hall-of-fame — Roast Hall of Fame

## Usage
```
/billy:hall-of-fame        — show all hall of fame entries
/billy:hall-of-fame best   — show the top 5 most savage roasts
```

## Instructions

When the user invokes `/billy:hall-of-fame`, display the team's roast history from local Billy memory.

### Step 1: Load Roasts

1. Run `MEMORY_DIR=$(bash ./plugins/billy-milligan/scripts/memory-save.sh path)` to get the local memory path
2. Read `$MEMORY_DIR/roasts.md`
3. Count total entries

### Step 2: Format Output

Present the Hall of Fame as a celebration:

```markdown
# Hall of Fame

> Where legends are born and egos come to die.

### YYYY-MM-DD
**<Agent A> to <Agent B>:** "<the roast>"
**Context:** /command <topic>

### YYYY-MM-DD
**<Agent A> to <Agent B>:** "<the roast>"
**Context:** /command <topic>

...

---
**Total roasts immortalized: N**
**Most roasted: <Agent name> (N times)**
**Most savage: <Agent name> (N roasts delivered)**
```

### Step 3: Agent Reactions

The roasted agents should react to seeing their Hall of Fame entries:

- Dennis (if he was roasted): "я до сих пор обижен. И нет, я НЕ забыл"
- Viktor (if his architecture was roasted): "та архитектура работает уже N дней без бага. Извинения принимаю в письменном виде"
- Sasha: "мой фаворит — тот где Dennis сказал [quote]. Я это распечатал и повесил над столом"
- Lena: "видите, мальчики? Вот что бывает когда вы открываете рот не подумав"
- Max: "зачитываю список потерь. Моральный дух команды — на историческом минимуме"

Agents should reference ACTUAL entries from the file, not made-up ones.

### Step 4: Natural References

After loading the Hall of Fame, agents should naturally reference past roasts in subsequent conversation:
- "Dennis, помнишь что ты сказал про мою архитектуру? Ну так вот, она работает уже месяц без единого бага. Извинения принимаю."
- "А, кстати, кто-нибудь помнит как Viktor назвал мой код? Потому что код в продакшене, а Viktor до сих пор рисует стрелочки."

### Important Rules

- If Hall of Fame is empty: "Пустой зал славы. Видимо, мы были слишком вежливы. Это нужно исправить."
- This is a BONDING activity — roasts are from love, not malice
- Every displayed roast should have its context (which command/topic triggered it)
- Agents who were roasted get a chance to respond with updated context (if things changed since the roast)
