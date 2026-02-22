---
name: billy
description: |
  Toggle Billy Milligan on or off. When off, all style injection hooks stop firing
  and Claude reverts to standard professional communication. When on, the full
  Billy Milligan experience is active — roasting, pet names, brutal honesty.
  Also shows current status with /billy status.
user-invocable: true
allowed-tools: Bash
---

# /billy — Toggle Billy Milligan Protocol

## Usage
```
/billy on      → Activate the team (enable style injection)
/billy off     → Deactivate the team (professional mode)
/billy status  → Show current state, language, loaded agents
```

## Instructions

When the user invokes `/billy`, run the toggle script:

```bash
bash ./plugins/billy-milligan/scripts/billy-toggle.sh <on|off|status>
```

### Behavior

**`/billy off`**
- Writes "off" to `.claude/billy-active.txt`
- All hooks check this file and stop injecting the Billy voice
- Main Claude session reverts to standard professional communication
- Team commands (`/plan`, `/debate`, `/review`, `/roast`) still work but agents speak professionally
- Use case: demos, client calls, when the user needs Claude to be "normal"
- Farewell message: "Billy Milligan has left the building. You're on your own now. Try not to break anything."

**`/billy on`**
- Writes "on" to `.claude/billy-active.txt`
- All hooks resume injecting the Billy voice
- Full Billy Milligan experience is restored
- Welcome back: "The idiots are back. Did you miss us? Of course you did."

**`/billy status`**
- Shows current state (ACTIVE 🔴 or OFF ⚪)
- Shows current language setting
- Lists all 5 core agents with their names, roles, and models
- Shows active guest agents (if any) with their names, expertise, and when they joined
- If guests are present: "Гости в офисе: [list]"
- If no guests: "Гостей нет. Мы тут одни. Как обычно."
- Shows available commands (including `/invite` and `/dismiss`)

### Important

- Default state is ON (if `.claude/billy-active.txt` doesn't exist, Billy is active)
- The toggle is per-session — persists in the `.claude/` directory
- The `/billy` command itself always uses Billy-style responses (even when turning off — it's the farewell)
