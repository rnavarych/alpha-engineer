---
name: billy:lang
description: |
  Set the team communication language for the current Billy Milligan session.
  All subsequent team commands will use this language. Technical terms always
  stay in English. Pet names are agent-specific and adapt per language. Personality stays identical.
user-invocable: true
allowed-tools: Bash
---

# /billy:lang — Set Team Communication Language

## Usage
```
/billy:lang ru          → switch to Russian 🇷🇺
/billy:lang en          → switch to English 🇬🇧
/billy:lang pl          → switch to Polish 🇵🇱
/billy:lang <any code>  → switch to any language
```

## Instructions

When the user invokes `/billy:lang`, run the language setter script:

```bash
bash ./plugins/billy-milligan/scripts/set-lang.sh <language-code>
```

The script will:
1. Normalize the language input (handles both codes and full names)
2. Write the language to `.claude/session-lang.txt`
3. Export `TEAM_LANG` and `BILLY_VOICE_SKILL` to Claude env via `$CLAUDE_ENV_FILE`
4. Display a confirmation in the NEW language
5. Next agent invocation picks up `skills/billy-voice-{lang}/SKILL.md` automatically

### Language Skill System

Each language has a dedicated calibration skill:
- `skills/billy-voice-en/SKILL.md` — English (default)
- `skills/billy-voice-ru/SKILL.md` — Russian
- `skills/billy-voice-pl/SKILL.md` — Polish

Only ONE language skill is loaded at a time. The skill provides:
- Native speech patterns and filler words
- Swearing vocabulary at appropriate intensity
- Pet name styles and anchor examples per agent
- Cultural context (e.g., Friday deploy memes for PL)

### Language Rules (remind the user)

- **Technical terms** stay in English regardless of language
- **User address** is improvised per-context — agents generate fresh terms each time from the active language skill
- **Personality DNA** stays identical — the team is the same characters in every language
- **Voice** changes completely — speech patterns, swearing, humor style feel native, not translated

### Inline Override

Remind the user that team commands also support inline language override:
```
/billy:plan @ru добавить кеширование
/billy:debate @en Redis vs Memcached
/billy:roast @pl czy powinniśmy użyć GraphQL?
```

The inline `@lang` overrides the session `/lang` setting for that one invocation only — it loads a DIFFERENT language skill for that single command.
