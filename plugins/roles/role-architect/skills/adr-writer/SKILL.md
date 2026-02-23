---
name: adr-writer
description: |
  Architecture Decision Record writing expertise including structured format,
  ADR numbering and indexing, status lifecycle management, lightweight ADRs,
  linking related decisions, and team review processes.
allowed-tools: Read, Grep, Glob, Bash
---

# ADR Writer

## When to use
- Writing a new Architecture Decision Record for a significant design choice
- Deciding between a full ADR and a lightweight ADR for a smaller decision
- Managing ADR status transitions (Proposed, Accepted, Deprecated, Superseded)
- Setting up ADR numbering, file naming, and the index table
- Linking related ADRs with bidirectional dependency and supersession references
- Running an asynchronous team review process for a proposed decision

## Core principles
1. **Title states the decision, not the question** — imperative mood, not interrogative
2. **Context is specific, not generic** — include concrete numbers, constraints, and what changed now
3. **Consequences must include negatives** — a consequences section with only positives is incomplete
4. **Never delete a superseded ADR** — the history of wrong turns is as valuable as the right ones
5. **ADR formalizes the conversation, not starts it** — discuss informally first, document after alignment

## Reference Files
- `references/adr-format-and-lifecycle.md` — full ADR structure (Title, Status, Context, Decision, Consequences), good vs bad title examples, ADR numbering convention, index table format, file naming pattern, Proposed/Accepted/Deprecated/Superseded status lifecycle with transition rules, lightweight ADR format and when to use it, and bidirectional linking with relationship types (Depends on, Supersedes, Informed by, Enables)
- `references/adr-team-review-process.md` — pre-writing data gathering, asynchronous PR-based review process, reviewer selection criteria, review deadline convention (3-5 business days), post-acceptance communication and onboarding integration, and 6-month review checkpoint scheduling for high-impact decisions
