# Alpha-Engineer Plugin Marketplace

A comprehensive Claude Code plugin marketplace providing 24 agents, 189 skills, and 20 commands across 4 industry domains, 9 developer roles, and 1 team plugin.

## Architecture

Four-layer composition model:
- **alpha-core**: Cross-cutting foundation skills (databases, security, APIs, architecture, testing, etc.)
- **Role plugins** (9): Developer persona agents + role-specific skills
- **Domain plugins** (4): Domain expert agents + domain-specific skills
- **billy-milligan**: 5-agent team with 50 skills, 20 commands, and dual memory system

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
Databases, Security, Architecture, Testing, Performance, CI/CD, Observability, Cloud Infrastructure, AI/ML Engineering
