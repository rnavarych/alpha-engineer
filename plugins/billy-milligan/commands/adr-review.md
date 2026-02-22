---
name: adr:review
description: |
  Review an existing Architecture Decision Record.
  With Billy ON: team reviews and roasts it, but suggested changes are written formally.
  With Billy OFF: standard professional review with structured feedback.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /adr:review — Review an Architecture Decision Record

## Usage
```
/adr:review 002
/adr:review 002 "is the TTL decision still valid?"
```

## Instructions

When the user invokes `/adr:review <number>`, read and review the specified ADR.

### Step 1: Find the ADR

Use Glob to find `docs/adr/<number>*.md` (e.g., `docs/adr/002-*.md`).

If not found:
```
ADR-<number> not found. Run /adr:list to see all available ADRs.
```

### Step 2A: If Billy is ON — Team Review

The team reviews the ADR and provides feedback in their natural voices.
The content of the review should focus on the actual decision, not meta-commentary.

**Example review of ADR-002 (Authentication):**

> **Sasha:** "секция Consequences — хорошая. Но не упоминается что мы должны инвалидировать refresh токены при смене пароля. Это дыра."
>
> **Viktor:** "Rationale немного поверхностный. Не объясняет почему мы выбрали PostgreSQL для хранения refresh токенов вместо Redis. Это нетривиальное решение."
>
> **Dennis:** "Options: три варианта, но нет option D — сессии с Redis. Я понимаю почему его нет, но читатель должен понимать что мы рассмотрели."
>
> **Lena:** "Context не упоминает что у нас будут мобильные клиенты. А это было ключевым аргументом."
>
> **Max:** "в целом — нормально. Одно критическое замечание: секция Consequences говорит 'race condition' но не описывает как мы её решаем."

After discussion, summarize the feedback in a professional format.

### Step 2B: If Billy is OFF — Professional Review

Provide structured feedback:

**Review Checklist:**
- [ ] Context clearly explains the problem and constraints
- [ ] All viable options are documented with honest pros/cons
- [ ] Decision statement is clear and unambiguous
- [ ] Rationale connects to specific stated requirements
- [ ] Consequences include both positive and negative implications
- [ ] Related ADRs are linked
- [ ] Status is current and accurate

### Step 3: Suggested Changes

If changes are warranted, present them formally:

```markdown
## Review: ADR-002 Authentication Approach

**Status:** ACCEPTED (valid, no status change needed)

### Suggested Improvements

**1. Missing consequence: password change invalidation**
Add to Consequences section:
> "Password changes must invalidate all existing refresh tokens for the user."

**2. Context: add mobile client requirement**
Add to Context:
> "Mobile clients are planned within 6 months, requiring a platform-agnostic auth approach."

**3. Rationale: explain PostgreSQL for refresh token storage**
Add to Rationale:
> "Refresh tokens stored in PostgreSQL (vs Redis) leverages existing infrastructure per ADR-001
> and avoids adding an in-memory cache dependency for a low-frequency operation."

Apply changes? (y/n)
```

### Step 4: Apply Changes (if confirmed)

If the user approves, use Edit to apply the suggested changes to the ADR file.

### Important Rules

- NEVER add informal content to the ADR file during review
- Billy team commentary is verbal only — it informs the review but does not appear in the file
- If a review reveals the ADR is fundamentally outdated, suggest `/adr:supersede` instead of patching
- Keep the ADR as the authoritative, clean document it's meant to be
