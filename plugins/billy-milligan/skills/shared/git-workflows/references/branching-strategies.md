# Git Branching Strategies

## When to load
Load when choosing a branching model, setting up branch protection, or designing release workflows.

## Strategy Comparison

| Strategy | Best For | Complexity | Release Speed |
|----------|---------|------------|---------------|
| GitHub Flow | SaaS, continuous deploy | Low | Fast (daily) |
| GitFlow | Packaged software, versioned releases | High | Slow (weeks) |
| Trunk-Based | High-velocity teams, CI/CD mature | Low | Fastest |
| Release Branches | Mobile apps, multiple versions | Medium | Medium |

## GitHub Flow (Recommended for Most Teams)

```
main (always deployable)
  │
  ├─ feat/user-auth ──→ PR ──→ merge ──→ deploy
  │
  ├─ fix/login-bug ──→ PR ──→ merge ──→ deploy
  │
  └─ chore/update-deps ──→ PR ──→ merge ──→ deploy

Rules:
  1. main is always deployable
  2. Branch from main for all work
  3. Open PR when ready for review
  4. Merge to main after approval + CI pass
  5. Deploy immediately after merge (CD)
```

## Trunk-Based Development

```
main (trunk)
  │
  ├─ short-lived branch (< 1 day) ──→ merge
  │
  ├─ short-lived branch (< 1 day) ──→ merge
  │
  └─ Feature flags for incomplete work

Requirements:
  - Strong CI (fast test suite, < 10 min)
  - Feature flags for WIP
  - Small, frequent commits (multiple per day)
  - No long-lived branches

Feature flag pattern:
  if (featureFlags.isEnabled('new-checkout', userId)) {
    return newCheckoutFlow();
  }
  return legacyCheckoutFlow();
```

## GitFlow (When You Need It)

```
main ────────────────────────────────────── (production)
  │                                    ▲
  │                                    │
  └──→ develop ──→ release/1.2 ──→ merge to main + tag
         │              │
         ├─ feat/x      └─ bugfix only
         ├─ feat/y
         └─ feat/z

         hotfix/critical ──→ merge to main + develop

When to use GitFlow:
  ✅ Packaged software with version numbers
  ✅ Multiple release tracks (v1.x, v2.x)
  ✅ Regulatory requirements for release control
  ❌ SaaS with continuous deployment
  ❌ Small teams (< 5 devs)
```

## Branch Protection Rules

```bash
# GitHub CLI: protect main branch
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["ci/test","ci/lint"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null

Key rules for main:
  ✅ Require PR (no direct push)
  ✅ Require 1+ approving review
  ✅ Require CI status checks to pass
  ✅ Dismiss stale reviews on new commits
  ✅ Require branches to be up to date
  ✅ Require linear history (squash or rebase)
```

## Branch Naming Convention

```
Feature:    feat/TICKET-123-user-authentication
Bug fix:    fix/TICKET-456-login-redirect
Test:       test/TICKET-789-auth-unit-tests
Chore:      chore/update-dependencies
Docs:       docs/api-documentation
Release:    release/1.2.0
Hotfix:     hotfix/critical-security-patch

Pattern: <type>/<ticket>-<short-description>
  - Lowercase, kebab-case
  - Include ticket number for traceability
  - Keep description under 5 words
```

## Merge Strategies

```
Squash merge (recommended for feature branches):
  ✅ Clean history — one commit per feature
  ✅ Easy to revert entire features
  ❌ Loses individual commit history

Merge commit:
  ✅ Preserves full branch history
  ❌ Cluttered main branch history

Rebase merge:
  ✅ Linear history without merge commits
  ❌ Rewrites commit hashes
  ❌ Can cause issues with shared branches

Recommendation:
  Feature branches → squash merge
  Release branches → merge commit (preserve context)
  Hotfixes → merge commit
```

## Anti-patterns
- Long-lived feature branches (>3 days) → merge conflicts, integration hell
- Direct commits to main → no review, no CI gate
- No branch protection → accidental force push, policy bypass
- Mixing merge strategies → inconsistent history, hard to bisect
- Branch per developer instead of per feature → unclear ownership

## Quick reference
```
Default: GitHub Flow (branch → PR → merge → deploy)
High-velocity: Trunk-based (short branches, feature flags)
Versioned: GitFlow (develop → release → main)
Branch naming: type/ticket-description (kebab-case)
Protection: require PR, 1 review, CI pass, linear history
Merge: squash for features, merge commit for releases
Branch lifetime: < 3 days ideal, < 1 week maximum
Cleanup: delete branches after merge (auto-delete setting)
```
