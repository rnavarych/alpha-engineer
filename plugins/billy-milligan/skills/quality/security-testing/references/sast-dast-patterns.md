# SAST/DAST Patterns

## When to load
Load when setting up static analysis, dynamic testing, or secret scanning.

## SAST — Static Analysis

### Semgrep

```yaml
# .semgrep.yml — custom rules
rules:
  - id: no-dangerous-code-execution
    patterns:
      - pattern: $FUNC(...)
      - metavariable-regex:
          metavariable: $FUNC
          regex: ^(eval|Function)$
    message: "Dynamic code execution is dangerous — use safe alternatives"
    languages: [javascript, typescript]
    severity: ERROR

  - id: no-raw-sql
    patterns:
      - pattern: db.query($SQL)
      - pattern-not: db.query($SQL, $PARAMS)
    message: "Use parameterized queries to prevent SQL injection"
    languages: [javascript, typescript]
    severity: ERROR
```

```bash
# Run Semgrep
semgrep --config auto .                    # Auto-detect language rules
semgrep --config p/owasp-top-ten .         # OWASP-focused rules
semgrep --config .semgrep.yml .            # Custom rules
semgrep --config auto --json -o results.json .  # CI output
```

### ESLint Security

```json
{
  "extends": ["plugin:security/recommended"],
  "plugins": ["security"],
  "rules": {
    "security/detect-object-injection": "warn",
    "security/detect-non-literal-regexp": "error",
    "security/detect-unsafe-regex": "error"
  }
}
```

## Secret Scanning

```bash
# Gitleaks — scan for secrets in git history
gitleaks detect --source . --verbose
gitleaks detect --source . --report-format json --report-path leaks.json

# Pre-commit hook
gitleaks protect --staged
```

```yaml
# .gitleaks.toml — custom allowlist
[allowlist]
  paths = ["tests/fixtures/", ".env.example"]
  regexes = ["EXAMPLE_KEY_\\w+"]

# GitHub Actions
- uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## DAST — Dynamic Testing

```
DAST runs against a live application (staging):

Tools:
  OWASP ZAP: open source, API + web scanning
  Burp Suite: professional, manual + automated
  Nuclei: template-based, fast, community rules

CI pipeline position:
  SAST → Unit Tests → Build → Deploy Staging → DAST → Deploy Production

DAST frequency:
  Baseline scan: every deploy to staging
  Full scan: weekly scheduled
  Penetration test: quarterly (manual)
```

## CI Pipeline

```yaml
security:
  runs-on: ubuntu-latest
  steps:
    # SAST: Static analysis
    - uses: returntocorp/semgrep-action@v1
      with:
        config: p/owasp-top-ten

    # Secret scanning
    - uses: gitleaks/gitleaks-action@v2

    # Dependency scanning
    - run: npm audit --audit-level=high

    # Container scanning (if Docker)
    - uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'myapp:${{ github.sha }}'
        severity: 'CRITICAL,HIGH'
```

## Anti-patterns
- SAST only, no DAST → misses runtime vulnerabilities
- Scanning only main branch → vulnerabilities merge before detection
- No allowlisting for false positives → team ignores all findings
- Secret scanning without pre-commit → secrets already in git history

## Quick reference
```
SAST: Semgrep (auto + OWASP rules), runs on every PR
Secrets: Gitleaks pre-commit + CI, scan git history
DAST: ZAP baseline on deploy, full scan weekly
Deps: npm audit + Snyk/Trivy in CI
Pipeline: SAST → tests → build → deploy staging → DAST
Semgrep: p/owasp-top-ten for quick coverage
Gitleaks: protect --staged for pre-commit hook
```
