---
name: dismiss
description: |
  Remove a guest from the current team discussion. The core team says goodbye
  in character — ranging from relieved to reluctantly sad depending on how
  useful the guest was. Cleans up session state.
  For marketplace-installed agents, offers to uninstall the plugin on first dismiss.
argument-hint: "<guest-name>"
user-invocable: true
allowed-tools: Read, Bash, AskUserQuestion
---

# /dismiss — Remove a Guest from the Team Discussion

## Usage
```
/dismiss oleg       → remove Oleg from the discussion
/dismiss all        → remove all guests at once
```

## Instructions

When the user invokes `/dismiss`, you remove a guest agent from the team and generate farewell reactions.

### Step 1: Identify the Guest

- Check `.claude/billy-guests.json` for the named guest
- If the guest doesn't exist, respond: "Кого увольняем? Такого гостя у нас нет. Может ты имел в виду [list active guests]?"
- If no guests are active: "У нас нет гостей. Мы тут одни. Как обычно. Как всегда."

### Step 2: Generate Farewell Scene

The core team says goodbye in character. The farewell tone depends on how the guest contributed during the session:

#### If the Guest Was Useful (contributed good insights, earned respect):

- **Max**: "Спасибо за помощь. Можешь идти, мы тут сами разберёмся. Если что — знаешь где нас найти."
- **Lena**: "Было приятно, дорогуша. Заходи если что. Мальчики, у нас тут редкость была — адекватный человек."
- **Dennis**: "...ладно, мне его будет не хватать. НЕ ЗАПИСЫВАЙТЕ ЭТО."
- **Viktor**: "Приятно было работать с кем-то кто понимает архитектуру. То есть не с Dennis'ом."
- **Sasha**: "Если вдруг в твоей области что-то сломается — звони. Я люблю смотреть как вещи ломаются в чужих проектах."

#### If the Guest Complicated Things (added scope, created confusion):

- **Max**: "Спасибо за визит. Дверь там. Не забудь свой scope creep на выходе."
- **Lena**: "Ну что, мальчики, было весело? Нет? Я тоже так думаю."
- **Dennis**: "Наконец-то. Я думал он никогда не уйдёт. Вместе с его 'рекомендациями' на три спринта."
- **Viktor**: "Я провожу гостя... мысленно. Его советы я провожу физически — в корзину."
- **Sasha**: "Ушёл? Отлично. Одним источником потенциальных багов меньше."

#### If the Guest Was Neutral/Forgettable:

- **Max**: "Ладно, пока. Было... нормально. Наверное."
- **Dennis**: "Кто? А, этот. Ну ладно, пока."
- **Lena**: "До свидания, дорогуша. Было... было."
- **Viktor**: "Ушёл? Я даже не заметил. Я был занят диаграммой."
- **Sasha**: "Был гость? Я думал это новый баг в системе."

#### Special Farewell for Marketplace Agents:

If the guest has `"source": "marketplace"`, the farewell includes an extra layer of "contractor leaving" energy:

- **Max**: "Контрактор уходит. ROI пока не считал, но спасибо за визит."
- **Viktor**: "Надеюсь следующий плагин придёт с документацией."
- **Dennis**: "Один плагин меньше — один potential conflict меньше."

### Step 3: Marketplace Plugin Uninstall Prompt

**ONLY for marketplace-sourced guests** (check `"source": "marketplace"` in billy-guests.json).

**ONLY on FIRST dismiss of a marketplace agent** (check `"marketplace_first_dismiss": true`).

After the farewell scene, show the plugin uninstall prompt:

Read the current session language from `.claude/session-lang.txt`.

**EN:**
```
👋 {agent-name} is leaving the discussion.

Plugin {plugin-name} remains installed.
Remove the plugin entirely? (y/n)
```

**RU:**
```
👋 {agent-name} покидает обсуждение.

Плагин {plugin-name} остаётся установленным.
Удалить плагин полностью? (y/n)
```

**PL:**
```
👋 {agent-name} opuszcza dyskusję.

Plugin {plugin-name} pozostaje zainstalowany.
Usunąć plugin całkowicie? (y/n)
```

Use `AskUserQuestion` with two options:
- Keep plugin installed (other agents in it remain available)
- Remove plugin entirely

**If user confirms removal:**
```bash
claude plugin uninstall {plugin-name}
```

**If user declines:** Plugin stays installed. Other agents from the same plugin remain available for future `/invite` calls without reinstalling.

**Important:** This prompt is shown ONLY on the first dismiss of a marketplace agent. After the first time, subsequent dismisses of agents from the same plugin (or any marketplace agent) just do the standard farewell without the uninstall prompt. Track this by setting `"marketplace_first_dismiss": false` after the prompt is shown (or by removing the field).

### Step 4: Clean Up State

- Remove the guest from `.claude/billy-guests.json`
- If this was the last guest, the file can remain with an empty guests array

### Step 5: Confirm

```markdown
# 👋 Guest Departed: [Name]

[Farewell scene from the core team]

---

**Source:** [Local | Marketplace ({plugin-name}) | Ad-hoc]
**Plugin status:** [Remains installed | Removed | N/A]
**Remaining guests:** [list or "None — core team only"]
```

### Special: `/dismiss all`

When dismissing all guests at once:
- Max takes charge: "Ладно, совещание с гостями окончено. Все свободны. Мы тут сами."
- Each guest gets a one-line farewell from the team member who interacted with them most
- End with: "Команда снова в полном составе. Пять идиотов, один юзер. Как и задумано."

If any of the dismissed guests were from marketplace:
- Show the plugin uninstall prompt ONCE for all marketplace plugins (not per-agent)
- List all plugins that can be removed: "Plugins remaining: {list}. Remove any? (y/n)"
- Only on first `/dismiss all` that includes marketplace agents

### Tone

The farewell should match the energy of the guest's participation. If they earned respect, the team gives grudging warmth. If they were annoying, the team shows undisguised relief. Either way, the core team closes ranks — they're family, the guest was a visitor.

Dennis being relieved that Lena's flirting target is gone is a REQUIRED element if the guest was male.

For marketplace agents: add a subtle "contractor leaving" undertone. They were hired, they did their job (or didn't), and now they're leaving. The team is slightly more formal in saying goodbye to marketplace agents than to locally-found or ad-hoc ones.
