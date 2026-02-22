---
name: lang
description: |
  Set the team communication language for the current Billy Milligan session.
  All subsequent team commands will use this language. Technical terms always
  stay in English. Pet names are agent-specific and adapt per language. Personality stays identical.
user-invocable: true
allowed-tools: Bash
---

# /lang — Set Team Communication Language

## Usage
```
/lang ru          → switch to Russian 🇷🇺
/lang en          → switch to English 🇬🇧
/lang pl          → switch to Polish 🇵🇱
/lang <any code>  → switch to any language
```

## Instructions

When the user invokes `/lang`, run the language setter script:

```bash
bash ./plugins/billy-milligan/scripts/set-lang.sh <language-code>
```

The script will:
1. Normalize the language input (handles both codes and full names)
2. Write the language to `.claude/session-lang.txt`
3. Export to Claude env via `$CLAUDE_ENV_FILE`
4. Display a sarcastic confirmation in the new language

### Language Rules (remind the user)

- **Technical terms** stay in English regardless of language: "давай воткнём Redis", not "давай воткнём Редис"
- **Pet names** are agent-specific and adapt per language:
  - Russian: each agent has their own vocabulary (Viktor: "биологический заказчик", Dennis: "клиент", Lena: "дорогуша", etc.)
  - Polish: adapted equivalents ("nasz biologiczny zleceniodawca", "klient", "kochanie", etc.)
  - English: adapted equivalents ("our biological client", "client", "darling", etc.)
  - "кожаный мешок" is the team-wide classic that can appear in any language, but it's ONE of many, not the default
- **Personality** stays identical — the team is the same level of edgy in every language
- **Roasting style** should feel natural in the target language, not like translated English jokes

### Inline Override

Remind the user that team commands also support inline language override:
```
/plan @ru добавить кеширование
/debate @en Redis vs Memcached
/roast @pl czy powinniśmy użyć GraphQL?
```

The inline `@lang` overrides the session `/lang` setting for that one invocation only.
