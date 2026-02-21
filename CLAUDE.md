# Alpha-Engineer Plugin Marketplace

A comprehensive Claude Code plugin marketplace providing 17 agents, 106 skills across 4 industry domains and 7 developer roles.

## Architecture

Three-layer composition model:
- **alpha-core**: Cross-cutting foundation skills (databases, security, APIs, architecture, testing, etc.)
- **Role plugins** (7): Developer persona agents + role-specific skills
- **Domain plugins** (4): Domain expert agents + domain-specific skills

## Conventions

- All SKILL.md files use YAML frontmatter with `name`, `description`, `allowed-tools`
- Agent .md files use frontmatter with `name`, `description`, `tools`, `model`
- Read-only skills use `allowed-tools: Read, Grep, Glob, Bash`
- Implementation agents add `Edit, Write` to tools
- Role agents use `model: inherit`, domain advisors use `model: sonnet`, critical domain architects use `model: opus`
- Every role agent's system prompt includes cross-cutting skill references and domain context adaptation sections
- Skill descriptions include domain keywords for auto-discovery by Claude

## Competency Matrix

Skills are informed by the "Software Engineer by RN" competency matrix covering:
Databases, Security, Architecture, Testing, Performance, CI/CD, Observability, Cloud Infrastructure
