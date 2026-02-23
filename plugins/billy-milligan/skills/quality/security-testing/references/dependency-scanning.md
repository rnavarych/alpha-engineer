# Dependency Scanning

## When to load
Load when setting up vulnerability scanning for dependencies: npm audit, Snyk, Dependabot.

## npm audit

```bash
# Check for vulnerabilities
npm audit

# Fix automatically (safe — respects semver)
npm audit fix

# Fix with breaking changes (careful — review changes)
npm audit fix --force

# JSON output for CI parsing
npm audit --json | jq '.vulnerabilities | keys[]'

# CI: fail on high/critical only
npm audit --audit-level=high
```

## Snyk Integration

```yaml
# GitHub Actions
security-deps:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=high
```

```bash
# CLI usage
snyk test                        # Check for vulnerabilities
snyk test --severity-threshold=high  # Only high+critical
snyk monitor                     # Track in Snyk dashboard
snyk ignore --id=SNYK-JS-LODASH-12345 --expiry=2024-06-01 --reason="No exploit path"
```

## Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    groups:
      dev-dependencies:
        dependency-type: "development"
        update-types: ["minor", "patch"]
      production:
        dependency-type: "production"
        update-types: ["patch"]
    ignore:
      - dependency-name: "aws-sdk"
        update-types: ["version-update:semver-major"]
```

## Triage Process

```
1. Critical/High with known exploit → fix within 24 hours
2. Critical/High without exploit → fix within 1 week
3. Medium → fix within 1 month or accept risk with documentation
4. Low/Informational → batch with regular maintenance

Decision tree:
  Is the vulnerable code reachable? → No → Lower priority
  Is there a fix available? → No → Monitor, consider alternative
  Is it in production deps? → No (devDep only) → Lower priority
  Is there a known exploit? → Yes → Immediate fix
```

## Anti-patterns
- Running `npm audit fix --force` blindly → introduces breaking changes
- Ignoring vulnerabilities permanently → accumulates risk
- Only scanning at build time → misses new CVEs in existing deps
- Updating every dependency immediately → churn without prioritization

## Quick reference
```
npm audit: built-in, --audit-level=high for CI
Snyk: --severity-threshold=high, snyk ignore for accepted risks
Dependabot: weekly schedule, group minor/patch, limit 10 PRs
Triage: critical+exploit=24h, high=1w, medium=1mo
devDependencies: lower priority (not in production bundle)
Container: trivy image scan for Docker vulnerabilities
Lock file: always commit package-lock.json / pnpm-lock.yaml
```
