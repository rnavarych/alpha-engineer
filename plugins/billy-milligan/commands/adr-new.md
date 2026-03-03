---
name: billy:adr-new
description: |
  Create a new Architecture Decision Record in docs/adr/.
  Formal, professional format — no Billy voice, no roasts, no inside jokes.
  Works whether Billy is ON or OFF. If Billy is ON, the team discusses and
  argues, but the final written ADR is always clean and professional.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /billy:adr-new — Create a New Architecture Decision Record

## Usage
```
/billy:adr-new "API versioning strategy"
/billy:adr-new "caching approach"
/billy:adr-new "CI/CD pipeline choice"
```

## Instructions

When the user invokes `/billy:adr-new "<title>"`, create a formal ADR in `docs/adr/`.

**CRITICAL RULE:** The ADR output is ALWAYS formal and professional, regardless of whether Billy
is active. No roasts, no agent pet names, no inside jokes, no informal language.
The ADR is written for any developer reading the repo — including people who have never heard of Billy.

### Step 1: Check Billy State

Read `.claude/billy-active.txt` to determine if Billy is ON or OFF.

### Step 2A: If Billy is ON — Team Discussion First

Run the team discussion before writing the ADR. The team:
1. Debates the options in their natural voices (informal, chaotic, with disagreements)
2. Eventually reaches a conclusion (or identifies remaining open questions)
3. The session log records the informal discussion

**Example team discussion for `/billy:adr-new "API versioning strategy"`:**

> **Viktor:** три варианта: URL path versioning (`/v1/`), header versioning (`Accept: application/vnd.api+json;version=1`), query parameter (`?version=1`). Нарисовал диаграмму эволюции каждого подхода через 3 года.
>
> **Sasha:** query parameter версионирование — это антипаттерн с точки зрения кэширования. CDN будет кэшировать неверно. Категорически против.
>
> **Dennis:** url path это просто работает. Я знаю как это имплементировать, я делал это 5 раз. Header versioning элегантен в теории, но когда ты дебажишь в curl — ты ненавидишь себя.
>
> **Lena:** пользователи не видят версию API напрямую, но SDK должны быть понятны разработчикам. URL path читаем в документации.
>
> **Max:** сколько версий мы планируем поддерживать одновременно? Потому что от этого зависит complexity.

After the discussion concludes, one agent confirms the decision and signals transition to formal output:
> **Viktor:** "итого: URL path versioning, поддержка N-1 версий, deprecation policy 6 месяцев. Записываю формально."

### Step 2B: If Billy is OFF — Direct Professional Flow

Claude writes the ADR directly, asking clarifying questions if needed:
- "What options should I document?"
- "What is the preferred approach?"
- "Any specific constraints to note?"

### Step 3: Create the ADR File

Run: `bash ./plugins/billy-milligan/scripts/adr-new.sh "<title>" PROPOSED`

The script outputs the new file path (e.g., `docs/adr/004-api-versioning-strategy.md`).

### Step 4: Write the ADR Content

Open the file and write the formal ADR. The content must:
- Be written in professional English (or the project's documentation language)
- Contain ZERO references to Billy, the team personalities, roasts, or informal discussion
- Read as if written by a senior architect for a code review

**Good ADR content:**
> "The team debated three versioning approaches and selected URL path versioning
> due to its simplicity, debuggability, and CDN caching compatibility."

**Bad ADR content (NEVER write this):**
> "Dennis refused to implement header versioning because he 'made that mistake before.'
> Sasha yelled about CDN caching. Viktor drew 3 diagrams."

Use the information from the team discussion to INFORM the rationale, but strip all personality.

### Step 5: Present to User

Show the created ADR file content and ask:
```
ADR-NNN has been created at docs/adr/NNN-<slug>.md

Status: PROPOSED
Review it and let me know if anything needs adjustment.
Run /billy:adr-status NNN ACCEPTED when the decision is finalized.
```

### Step 6: Session Log (Billy ON only)

If Billy is ON, append to today's session log in Billy memory:
```
**Formal decision recorded:** → ADR-NNN: <title> (docs/adr/NNN-<slug>.md)
```

### Step 7: Update ADR README Index

Run `bash ./plugins/billy-milligan/scripts/adr-list.sh --update-readme` to refresh the index table.

### Important Rules

- NEVER write roasts, jokes, or informal content in the ADR file
- ADR numbering is sequential and never reused — if you supersede ADR-003, the next is ADR-004 (or higher), not ADR-003v2
- The ADR file is the single source of truth for the decision — Billy's session log only references it by number
- Always show the user the created file before marking it final
- If Billy's team disagreed and the issue is unresolved, create the ADR with status PROPOSED and note the open question in the Context section
