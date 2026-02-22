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

---

## Patterns ✅

### Conventional Commits

```
Format: <type>(<scope>): <description>
         [optional body]
         [optional footer]

Types:
  feat:     New feature (triggers minor version bump: 1.2.0 → 1.3.0)
  fix:      Bug fix (triggers patch bump: 1.2.0 → 1.2.1)
  chore:    Tooling, dependencies, no production code change
  docs:     Documentation only
  style:    Formatting, whitespace — no logic change
  refactor: Code restructure, no feature/fix
  test:     Adding or fixing tests
  perf:     Performance improvement
  ci:       CI/CD configuration change
  build:    Build system or external dependency change

Breaking change: add "!" or BREAKING CHANGE footer
  feat!: remove support for Node.js 14  →  major version bump (1.2.0 → 2.0.0)

Examples:
  feat(orders): add cursor pagination to order listing
  fix(auth): prevent timing attack in password comparison
  feat!: remove deprecated /v1/users endpoint
  chore(deps): upgrade Drizzle ORM to 0.30.0

  refactor(payments): extract charge logic into PaymentService

  feat(billing): add metered usage reporting

  BREAKING CHANGE: removed stripeChargeId field from Order response.
  Use stripePaymentIntentId instead.
```

### Trunk-Based Development Workflow

```
Daily workflow:
  1. Pull latest main
  2. Create short-lived branch: git checkout -b feat/cursor-pagination
  3. Small commits: 3-5 per branch, each compiles and passes tests
  4. Open PR within 1-2 days — never leave a branch open >3 days
  5. Squash-merge to main after approval
  6. Delete branch

Branch naming:
  feat/[ticket]-[description]     feat/ORD-123-cursor-pagination
  fix/[ticket]-[description]      fix/PAY-456-timing-attack
  chore/[description]             chore/upgrade-drizzle
  hotfix/[ticket]-[description]   hotfix/CRIT-789-payment-failure

Feature flags for incomplete work:
  // Merge to main but gate with flag
  if (featureFlags.isEnabled('new-checkout-flow', userId)) {
    return newCheckoutFlow(cart);
  }
  return legacyCheckoutFlow(cart);
  // Ship daily without waiting for all 3 stories to be done
```

### PR Template

```markdown
<!-- .github/pull_request_template.md -->
## Summary
<!-- 1-3 sentences: what does this PR do and why? -->

## Type of change
- [ ] Bug fix (non-breaking, fixes an issue)
- [ ] New feature (non-breaking, adds functionality)
- [ ] Breaking change (existing functionality changes)
- [ ] Chore / dependency update

## How to test
<!-- Steps to verify this works -->
1.
2.

## Checklist
- [ ] Tests added/updated and passing
- [ ] No console.logs or debug code left in
- [ ] Database migration tested (can run and rollback)
- [ ] API changes documented (OpenAPI updated)
- [ ] Feature flag configured if needed
- [ ] Security: no hardcoded credentials, SQL injection safe, no XSS

## Related issues
Closes #
```

### Branch Protection Rules (GitHub)

```yaml
# .github/branch-protection.yml or configure via GitHub API/Terraform

# For: main branch
Settings:
  Require pull request before merging: true
    Required approving reviews: 1  (2 for critical services)
    Dismiss stale reviews on new commits: true
    Require review from code owners: true  (for critical paths)

  Require status checks:
    - ci/test
    - ci/build
    - security/snyk
    # All must pass before merge

  Require branches to be up to date: true
    # Cannot merge outdated branch — prevents "works on my machine"

  Require conversation resolution before merging: true

  Restrict who can push to matching branches: true
    # No direct push to main — ever

  Allow force pushes: false
  Allow deletions: false
```

### Commit History Cleanup (Interactive Rebase)

```bash
# Before opening PR: clean up "WIP" and "fix typo" commits
# Squash 5 messy commits into 2 clean commits

git rebase -i HEAD~5

# In the editor:
# pick abc1234 feat: add cursor pagination foundation
# squash def5678 wip: fix types
# squash ghi9012 fix: address PR comments
# pick jkl3456 test: add pagination edge case tests
# squash mno7890 fix: test typo

# Result: 2 clean commits:
# feat: add cursor pagination to order listing (abc1234)
# test: add pagination edge case tests (jkl3456)

# After rebase, force-push the feature branch (safe — not main)
git push --force-with-lease origin feat/cursor-pagination
# --force-with-lease: safer than --force; fails if remote was updated since last fetch
```

### Git Bisect for Regression Hunting

```bash
# Binary search through commit history to find which commit introduced a bug

git bisect start
git bisect bad                    # Current commit is broken
git bisect good v1.4.0            # This tagged version was working

# Git checks out midpoint automatically
# Test the current commit:
# If broken:
git bisect bad
# If working:
git bisect good

# Git narrows down with each round (binary search)
# After 7-8 rounds on 100 commits: found the culprit commit

# Automate with a test script:
git bisect run npm test -- --testNamePattern "checkout flow"
# Git runs the test on each candidate commit automatically

git bisect reset  # Return to HEAD when done
```

---

## Anti-Patterns ❌

### Long-Lived Feature Branches (GitFlow Hell)
**What it is**: `feature/new-checkout` branch open for 3 weeks with 200 commits.
**What breaks**: Merge conflict hell when rebasing on main after 3 weeks of divergence. "Integration" takes 2 days. Bugs from interactions with other features discovered only at merge time.
**Fix**: Trunk-based. Merge to main within 1-2 days. Use feature flags for incomplete features.

### Force-Push to Main
**What it is**: `git push --force origin main` to fix a mistake.
**What breaks**: Rewrites shared history. Other engineers' local branches are now diverged from remote. CI history is corrupted.
**Fix**: Branch protection blocks it. Never force-push to shared branches. Create a revert commit instead.

### Commit Messages as Notes to Self
```
# Bad — these go in the PR description, not commits
"WIP"
"fix stuff"
"asdf"
"trying this approach"
"final fix (for real this time)"

# Good — descriptive, conventional
feat(cart): add quantity validation before checkout
fix(auth): use constant-time comparison in token validation
```

---

## Quick Reference

```
Conventional Commits: feat/fix/chore/docs/style/refactor/test/perf/ci/build
Breaking change: feat! or BREAKING CHANGE footer → major version bump
Squash merge: one clean commit per feature on main
Trunk-based: branches live <3 days; use feature flags for incomplete features
force-push: only on personal feature branches; never on main/develop
Interactive rebase: clean up before PR; squash WIP commits
git bisect: binary search 100 commits in 7 rounds
Branch protection: require 1+ review, CI passing, no direct push to main
Commit message: present tense, imperative ("add" not "added")
```
