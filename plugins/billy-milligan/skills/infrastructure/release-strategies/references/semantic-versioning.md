# Semantic Versioning

## Semver Format

```
MAJOR.MINOR.PATCH
  1.0.0 -> 1.0.1  (patch: bug fix, no API change)
  1.0.0 -> 1.1.0  (minor: new feature, backward compatible)
  1.0.0 -> 2.0.0  (major: breaking change)

Pre-release: 1.0.0-alpha.1, 1.0.0-beta.2, 1.0.0-rc.1
Build metadata: 1.0.0+build.123 (ignored in precedence)
```

## Conventional Commits

```
Format: <type>[optional scope]: <description>

Types:
  feat:     new feature                    -> bumps MINOR
  fix:      bug fix                        -> bumps PATCH
  docs:     documentation only
  style:    formatting, no code change
  refactor: code change, no feature/fix
  perf:     performance improvement
  test:     adding or fixing tests
  chore:    build, deps, tooling
  ci:       CI/CD changes

Breaking change (bumps MAJOR):
  feat!: remove legacy API endpoint
  -- or --
  feat: update auth flow

  BREAKING CHANGE: JWT token format changed from HS256 to RS256.
  All existing tokens will be invalidated.

Examples:
  feat(auth): add OAuth2 login flow
  fix(api): resolve null pointer in order validation
  test(checkout): add unit tests for discount calculation
  chore(deps): update express to v4.19
```

## semantic-release Setup

```json
{
  "release": {
    "branches": ["main"],
    "plugins": [
      "@semantic-release/commit-analyzer",
      "@semantic-release/release-notes-generator",
      "@semantic-release/changelog",
      "@semantic-release/npm",
      "@semantic-release/github",
      ["@semantic-release/git", {
        "assets": ["CHANGELOG.md", "package.json"],
        "message": "chore(release): ${nextRelease.version}"
      }]
    ]
  }
}
```

```yaml
# GitHub Actions: automated release
release:
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4
      with:
        persist-credentials: false
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm ci
    - run: npx semantic-release
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Changelog Generation

semantic-release generates CHANGELOG.md automatically from commits:

```markdown
# [2.1.0](https://github.com/org/repo/compare/v2.0.0...v2.1.0) (2024-02-15)

### Features

* **auth:** add OAuth2 login flow ([abc1234](commit-link))
* **api:** add pagination to list endpoints ([def5678](commit-link))

### Bug Fixes

* **checkout:** resolve race condition in cart update ([ghi9012](commit-link))
```

## Version Bump Decision Tree

```
Q: Does this change break existing API contracts?
  Yes -> MAJOR bump (2.0.0)
  No  -> Continue

Q: Does this add new functionality?
  Yes -> MINOR bump (1.1.0)
  No  -> Continue

Q: Is this a bug fix?
  Yes -> PATCH bump (1.0.1)
  No  -> No version bump (docs, chore, ci, style, test)
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Manual version bumps | Use semantic-release for automation |
| No conventional commits | Enforce with commitlint + husky |
| Breaking change without MAJOR bump | Use `feat!:` or `BREAKING CHANGE:` footer |
| Changelog written by hand | Generate from commits with semantic-release |
| Version in multiple files | Single source of truth (package.json) |

## Quick Reference

- MAJOR: breaking changes (incompatible API)
- MINOR: new features (backward compatible)
- PATCH: bug fixes (no new features)
- Conventional commit types: `feat`, `fix`, `docs`, `chore`, `test`, `ci`
- Breaking change marker: `feat!:` or `BREAKING CHANGE:` in footer
- Tool: semantic-release (analyzes commits, bumps version, publishes)
- Enforcement: commitlint + husky pre-commit hook
