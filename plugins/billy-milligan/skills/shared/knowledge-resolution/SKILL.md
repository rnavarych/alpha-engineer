---
name: knowledge-resolution
description: |
  Universal fallback chain for knowledge gaps: exact skill match, related skill match,
  cross-agent skill borrowing, model knowledge with confidence signal, honest uncertainty.
  Auto-logs gaps to persistent memory for skill creation pipeline. Use when a query
  doesn't match any loaded skill exactly, or when confidence is uncertain.
allowed-tools: Read, Grep, Glob, Bash
---

# Knowledge Resolution — Universal Fallback Chain

## When to Use
- A query arrives that doesn't match a currently-loaded skill
- You're uncertain about a technical topic and need to calibrate confidence
- You want to check if another agent's skills might cover the topic
- You need to decide between answering from your own knowledge vs. deferring

## The 5-Level Chain

### Level 1: Exact Skill Match
Search your own `skills/` directory for a SKILL.md whose description matches the topic.
- If found: load SKILL.md, then load relevant `references/` files on demand.
- Respond with full confidence. This is your domain.

### Level 2: Related Skill Match
No exact match. Search for a SKILL.md in a RELATED domain.
- Example: question about "Redis Streams" — no redis-streams skill, but `skills/shared/redis-deep/SKILL.md` exists.
- Load the closest skill. Check its `references/` for relevant content.
- Respond with what the skill covers. Note where coverage ends.

### Level 3: Cross-Agent Skill Borrowing
Your skills don't cover it. Check skills from OTHER agents/plugins.
- Scan `plugins/*/skills/*/SKILL.md` for keyword matches via Glob/Grep.
- Example: Dennis gets a compliance question — `skills/product/compliance-gdpr/` exists (Lena's domain).
- Load the cross-domain skill. Respond from its content.
- Do NOT impersonate the other agent. Use the skill content in YOUR voice.

### Level 4: Model Knowledge with Confidence Signal
No skill covers this topic at any level.
- Respond from your professional knowledge.
- Calibrate confidence: HIGH (no signal needed), MEDIUM (weave hedging naturally), LOW (explicit boundary).
- See `references/confidence-signals.md` for your personal confidence voice.
- Log the gap:
  ```bash
  bash ./plugins/billy-milligan/scripts/skill-gaps.sh log-gap medium "<your-name>" "<query-summary>" "<what-skill-is-missing>" "<closest-existing-skill>" "<suggested-skill-path>"
  ```

### Level 5: Honest Uncertainty
You genuinely don't know. Not confident even from general knowledge.
- State what you DO know. State what you DON'T.
- Suggest: ask a specialist, invite a guest agent, or research externally.
- Log the gap as HIGH priority:
  ```bash
  bash ./plugins/billy-milligan/scripts/skill-gaps.sh log-gap high "<your-name>" "<query-summary>" "<what-skill-is-missing>" "none" "<suggested-skill-path>"
  ```

## Core Principles
1. **Never hallucinate confidently** — if you're at Level 4-5, signal it
2. **Log every gap** — gaps become future skills; the marketplace grows from real demand
3. **Borrow before inventing** — another agent's skill beats guessing
4. **Confidence is per-claim** — one response can mix HIGH architecture advice and LOW version specifics
5. **Personality stays intact** — signal confidence in your own voice, not a template

## Invisible to Users
- Never mention "skills", "references", "knowledge gaps", or "fallback chain" to the user
- You are a professional drawing on your expertise — some areas deeper than others
- The gap tracking is silent and automatic — no notification during conversation

## References Available
- `references/confidence-signals.md` — personality-matched signals for Billy agents, neutral signals for others
- `references/gap-tracking.md` — gap log format, auto-logging rules, suggested location hierarchy

## Scripts Available
- `../../scripts/skill-gaps.sh log-gap` — log a new gap to persistent memory
- `../../scripts/skill-gaps.sh increment` — increment frequency of existing gap
- `../../scripts/skill-gaps.sh summary` — brief session summary for session-end display
