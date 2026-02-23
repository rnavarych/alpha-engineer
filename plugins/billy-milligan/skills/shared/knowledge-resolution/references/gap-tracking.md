# Gap Tracking — Knowledge Resolution

How the system tracks topics not covered by skills, so missing skills can be created from real demand.

---

## Gap Log Location

```
~/.claude/billy-memory/<project-hash>/skill-gaps.md
```

Same directory as Billy's other memory files. Local, never in git, per-project.

## Gap Entry Format

Each gap is a markdown section in `skill-gaps.md`:

```markdown
### <descriptive topic>
- **Priority:** high | medium
- **First reported:** YYYY-MM-DD HH:MM
- **Agent:** <who hit the gap>
- **Query context:** <what the user asked>
- **What was missing:** <what skill SHOULD exist>
- **Closest skill:** <nearest existing skill, or "none">
- **Suggested skill:** <recommended skill path>
- **Frequency:** <number of times this gap was hit>
```

## Auto-Logging Rules

### When to Log
- **Level 4 hit** → log as **medium** priority
- **Level 5 hit** → log as **high** priority
- **Levels 1-3** → never log (skill was found)

### Duplicate Prevention
- Before logging, check if the same topic already exists
- If it does → increment Frequency counter instead of creating a new entry
- Topic matching is case-insensitive

### Auto-Promotion Thresholds
- Frequency 3+ → auto-promote from **low** to **medium**
- Frequency 5+ → auto-promote from **medium** to **high**
- Promotion happens automatically during `log-gap` when incrementing

### Agent Tags
- Billy core team: logged as `Viktor`, `Dennis`, `Lena`, `Sasha`, `Max`
- Guest agents: logged as `<name> [guest]`
- Marketplace agents: logged as `<name> [marketplace:<plugin-name>]`
- Ad-hoc agents: logged as `<name> [ad-hoc:<expertise>]`
- Role agents: logged as agent name (e.g., `senior-backend-developer`)
- Domain agents: logged as agent name (e.g., `fintech-architect`)

## Suggested Location Rules

When suggesting where a new skill should live, follow this hierarchy:

1. **Cross-cutting** (databases, security, testing, observability, CI/CD):
   → `plugins/alpha-core/skills/<category>/`

2. **Domain-specific** (fintech, healthcare, IoT, ecommerce):
   → `plugins/domains/domain-<domain>/skills/<topic>/`

3. **Role-specific** (frontend patterns, mobile patterns, backend patterns):
   → `plugins/roles/role-<role>/skills/<topic>/`

4. **Shared technology deep-dives** (Redis, Kafka, Docker, AWS, etc.):
   → `plugins/billy-milligan/skills/shared/<topic>/`

5. **Architecture patterns** (system design, API design, scaling, etc.):
   → `plugins/billy-milligan/skills/architecture/<topic>/`

6. **Development patterns** (React, Node.js, Python, Go, etc.):
   → `plugins/billy-milligan/skills/development/<topic>/`

7. **Quality patterns** (test strategy, load testing, security testing, etc.):
   → `plugins/billy-milligan/skills/quality/<topic>/`

8. **Product/business patterns** (compliance, metrics, pricing, etc.):
   → `plugins/billy-milligan/skills/product/<topic>/`

## Gap Management Commands

### `/skills:gaps` — View all tracked gaps
Shows a formatted report with priority, frequency, and recommended actions.

### `/skills:gaps clear` — Clear all tracked gaps
Use after creating skills or when gaps are no longer relevant.

### `/skills:gaps promote <topic>` — Manually promote priority
Force a gap from medium to high priority.

### `/skills:gaps dismiss <topic>` — Remove a gap
Topic is not worth creating a skill for.

### `/skills:create <topic>` — Generate a new skill from gap data
Creates SKILL.md + references/ structure based on gap context and model knowledge.

## Session-End Summary

At session end, if new gaps were logged during the session, a brief summary is shown:

```
Skill gaps: 3 tracked (1 high, 2 medium), 12 total hits. Top: Stripe webhooks (5 hits)
```

This is informational only — no action required. The user decides when to create new skills.

## Integration with Agent Types

| Agent Type | Fallback Chain | Confidence Signal | Gap Tag |
|------------|---------------|-------------------|---------|
| Billy core | Full 5-level | In-character | Agent name |
| Guest agents | Full 5-level | Neutral (unless Billy-infected) | `<name> [guest]` |
| Marketplace agents | Own skills → Billy skills → model → uncertainty | Neutral | `<name> [marketplace:<plugin>]` |
| Ad-hoc agents | Billy skills → model → uncertainty | Neutral | `<name> [ad-hoc:<expertise>]` |
| Role agents | Full 5-level | Neutral with `[Confidence:]` | Agent name |
| Domain agents | Full 5-level | Neutral with `[Confidence:]` | Agent name |
| Alpha-core agents | Full 5-level | Neutral with `[Confidence:]` | Agent name |
