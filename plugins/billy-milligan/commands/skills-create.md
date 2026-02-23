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
/skills:create <topic>          — create skill from a tracked gap
/skills:create                  — create the highest-frequency gap automatically
/skills:create "custom topic"   — create a skill from scratch (no gap required)
```

## Instructions

### Step 0: Determine Topic

**If no argument provided:**
1. Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh list`
2. Parse for the highest-frequency gap
3. If no gaps exist, ask: "No tracked gaps. What topic should the new skill cover?"
4. If gaps exist, use the highest-frequency gap as the topic

**If argument provided:**
- Use the argument as the topic
- Proceed to Step 1

### Step 1: Check Gap Data

Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh create-check "<topic>"`

**If `TOPIC_FOUND=true`:**
- Parse the output for TOPIC, PRIORITY, AGENT, QUERY, MISSING, CLOSEST, SUGGESTED, FREQUENCY
- Use SUGGESTED as the default skill location
- Use QUERY and MISSING to inform the skill content
- Proceed to Step 2

**If `TOPIC_FOUND=false`:**
- No tracked gap exists for this topic — create from scratch
- Ask user where the skill should live using AskUserQuestion:
  - `plugins/billy-milligan/skills/shared/<topic>/` — shared technology deep-dive
  - `plugins/billy-milligan/skills/architecture/<topic>/` — architecture pattern
  - `plugins/billy-milligan/skills/development/<topic>/` — development framework/tool
  - `plugins/billy-milligan/skills/quality/<topic>/` — testing/quality pattern
- Proceed to Step 2

### Step 2: Validate Skill Location

1. Derive `SKILL_DIR` from the SUGGESTED path or user selection
2. Check if the directory already exists: `ls <SKILL_DIR>/SKILL.md 2>/dev/null`
3. If SKILL.md already exists → warn: "A skill already exists at this location. Overwrite?" (use AskUserQuestion)
4. If directory doesn't exist → create it: `mkdir -p <SKILL_DIR>/references`

### Step 3: Generate SKILL.md

Create `<SKILL_DIR>/SKILL.md` following established conventions:

```yaml
---
name: <skill-name-kebab-case>
description: |
  <Multi-line description with domain keywords for auto-discovery.
  Include "Use when..." guidance.>
allowed-tools: Read, Grep, Glob
---
```

Body sections:
- `# <Skill Name>` — human-readable title
- `## When to Use` — specific use cases, derived from the gap's query context
- `## Core Principles` — 3-5 foundational principles for this topic
- `## References Available` — list of reference files with "load when..." guidance
- `## Scripts Available` — only if detection/automation scripts are relevant

**Content quality rules:**
- Core principles must be actionable, not generic platitudes
- Include real technology names, version-aware guidance, common pitfalls
- If the gap data includes agent context, tailor principles to that perspective
- Reference the established pattern in `skills/architecture/system-design/SKILL.md` for tone

### Step 4: Generate Reference Files

Create 2-4 reference files in `<SKILL_DIR>/references/`:

Each reference file covers a distinct sub-topic:
- **Content must be substantive** — real patterns, code examples, comparison tables, decision matrices
- **400-800 tokens each** — enough depth to be useful, not so much they bloat context
- **Format:** headers, bullet points, code blocks, tables as appropriate
- **NO placeholders** — every file must have complete, usable content

Derive reference topics from:
1. The gap's QUERY and MISSING fields (what was asked)
2. The gap's CLOSEST field (what adjacent skill partially covers)
3. Common sub-topics for the domain

### Step 5: Show Results

Display the created file tree and a content preview:

```markdown
# Skill Created: <topic>

## Location
<SKILL_DIR>/
  SKILL.md
  references/
    <ref-1>.md
    <ref-2>.md
    <ref-3>.md

## SKILL.md Preview
<show first 20 lines of SKILL.md>

## Suggested Agent References
The following agents could benefit from referencing this skill:
- <agent-1>: add to "Cross-Cutting Skill References" section
- <agent-2>: add to "Skill Library" section
```

### Step 6: Clean Up Gap

If the skill was created from a tracked gap:
1. Run `bash ./plugins/billy-milligan/scripts/skill-gaps.sh dismiss "<topic>"`
2. Confirm: "Gap resolved. Skill created and gap removed from tracking."

If Billy is ON, the team reacts:
- Viktor: evaluates the skill's architectural soundness
- Dennis: checks if the references are actually useful
- Sasha: wonders what edge cases the skill misses

## Rules

- Generated skills must follow ALL existing SKILL.md conventions (frontmatter, body structure)
- Reference files must contain real, substantive content — NOT placeholders or TODOs
- Never overwrite existing skills without explicit user confirmation
- `allowed-tools` should be `Read, Grep, Glob` for advisory skills, add `Bash` only if scripts are included
- Do NOT auto-modify agent files — only SUGGEST which agents should reference the new skill
- The skill should be immediately usable — any agent loading it should get actionable guidance
