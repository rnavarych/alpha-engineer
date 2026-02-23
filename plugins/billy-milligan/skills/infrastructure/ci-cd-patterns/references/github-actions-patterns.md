# GitHub Actions Patterns

## Reusable Workflows

```yaml
# .github/workflows/reusable-test.yml
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'
    secrets:
      NPM_TOKEN:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
```

Caller workflow:

```yaml
jobs:
  call-tests:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '20'
    secrets: inherit
```

## Matrix Builds

```yaml
strategy:
  fail-fast: false
  matrix:
    os: [ubuntu-latest, macos-latest]
    node: [18, 20, 22]
    exclude:
      - os: macos-latest
        node: 18
```

## Caching (actions/cache)

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

Cache hit rate target: **>90%**. Average savings: **2-5 minutes** per run.

## Secrets via OIDC (No Static Keys)

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/GitHubActions
      aws-region: us-east-1
```

Why OIDC: no credentials to rotate, no credentials to leak, short-lived tokens (1h), per-repo and per-branch scoping.

## Composite Actions

```yaml
# .github/actions/setup-project/action.yml
name: Setup Project
runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    - run: npm ci
      shell: bash
    - run: npx playwright install --with-deps
      shell: bash
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Static AWS keys in secrets | Use OIDC federation |
| `actions/checkout@v2` | Pin to `@v4`, use Dependabot for updates |
| No `fail-fast: false` on matrix | Set it to avoid cascading cancellations |
| Caching `node_modules` only | Cache `~/.npm` too for cross-lock compatibility |
| `runs-on: self-hosted` without labels | Use labels to isolate workload types |

## Quick Reference

- Max workflow runtime: **6 hours** (GitHub-hosted)
- Max concurrent jobs (free): **20** (macOS: 5)
- Artifact retention: **90 days** default
- Cache size limit: **10 GB** per repo
- OIDC token lifetime: **1 hour**
