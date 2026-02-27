---
name: skills:create
description: |
  Generate a new skill from a tracked gap or from scratch. Creates SKILL.md + references/
  structure with substantive content scaffolded from gap data and model knowledge.
  The skill is placed in the suggested location following existing directory conventions.
argument-hint: "<topic>"
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /skills:create — Create a New Skill from Gap Data

## Usage
```
/skills:create <topic>          — from tracked gap
/skills:create                  — highest-frequency gap automatically
/skills:create "custom topic"   — from scratch (no gap required)
```

## Instructions

### Step 0: Determine Topic

No argument → run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh list`, pick highest-frequency gap. If none, ask user.

### Step 1: Check Gap Data

Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh create-check "<topic>"`

**Found:** parse TOPIC, PRIORITY, AGENT, QUERY, MISSING, CLOSEST, SUGGESTED, FREQUENCY. Use SUGGESTED as location.
**Not found:** use AskUserQuestion to pick: `skills/shared/`, `skills/architecture/`, `skills/development/`, or `skills/quality/`.

### Step 2: Validate Location

Check if SKILL.md already exists. If yes, warn + confirm overwrite. If no, `mkdir -p <SKILL_DIR>/references`.

### Step 3: Generate SKILL.md

```yaml
---
name: <kebab-case>
description: |
  <Domain keywords for auto-discovery. "Use when..." guidance.>
allowed-tools: Read, Grep, Glob
---
```

Body: `# Title` → `## When to Use` → `## Core Principles` (3-5, actionable, version-aware) → `## References Available` → `## Scripts Available` (if relevant).

Content must be real, not generic. Reference `skills/architecture/system-design/SKILL.md` for tone.

### Step 4: Generate Reference Files

2-4 files in `references/`, 400-800 tokens each. Real patterns, code examples, comparison tables. NO placeholders. Derive topics from gap's QUERY, MISSING, CLOSEST fields.

### Step 5: Show Results

Display file tree, SKILL.md preview (first 20 lines), suggest which agents should reference the new skill.

### Step 6: Clean Up Gap

If from tracked gap: `bash ./plugins/billy-milligan/scripts/skill-gaps.sh dismiss "<topic>"`.
If Billy ON — team reacts (Viktor: architecture, Dennis: usefulness, Sasha: edge cases).

## Rules

- Follow ALL existing SKILL.md conventions. Reference files must be substantive — NOT placeholders.
- Never overwrite without confirmation. `allowed-tools: Read, Grep, Glob` for advisory, add `Bash` only if scripts needed.
- Do NOT auto-modify agent files — only SUGGEST references. Skill must be immediately usable.
