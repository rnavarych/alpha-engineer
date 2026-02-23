---
name: git-workflows
description: |
  Git workflows: trunk-based development vs GitFlow, Conventional Commits specification,
  PR templates, branch protection rules, merge strategies (squash vs merge vs rebase),
  interactive rebase for clean history, git bisect for debugging, monorepo patterns.
  Use when setting up team git workflow, writing commit messages, reviewing PR process.
allowed-tools: Read, Grep, Glob
---

# Git Workflows

## When to Use This Skill
- Choosing between trunk-based development and GitFlow
- Writing Conventional Commits for automatic changelogs
- Setting up branch protection and PR review requirements
- Cleaning up commit history before merging
- Debugging regressions with git bisect

## Core Principles

1. **Trunk-based development for speed** — long-lived branches cause merge hell; merge to main daily
2. **Conventional Commits enable automation** — `feat:`, `fix:`, `chore:` → automatic semantic versioning and changelogs
3. **Squash merge for feature branches** — one commit per feature on main = clean, bisectable history
4. **Feature flags over long branches** — merge incomplete code behind a flag; avoid 3-week branches
5. **Branch protection is non-negotiable** — no direct push to main; required reviews and CI passing

## References available
- `references/branching-strategies.md` — trunk-based workflow, branch naming conventions, PR template, branch protection rules, git bisect, interactive rebase
- `references/conventional-commits.md` — full type reference, breaking changes, examples, semantic versioning trigger rules
- `references/monorepo-strategies.md` — Turborepo, Nx, affected package detection, shared commit scopes
