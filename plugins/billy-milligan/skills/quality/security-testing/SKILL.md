---
name: security-testing
description: |
  Security testing: Snyk/Trivy in GitHub Actions for dependency scanning, Semgrep SAST,
  SQL injection test cases, XSS prevention testing, Gitleaks for secrets scanning,
  OWASP ZAP for DAST, security headers validation. Use when reviewing security posture,
  setting up security scanning in CI, writing security test cases.
allowed-tools: Read, Grep, Glob
---

# Security Testing

## When to use
- Setting up security scanning in CI/CD pipeline
- Writing security test cases for OWASP Top 10
- Reviewing code for common vulnerabilities
- Dependency vulnerability management
- Secrets scanning and prevention

## Core principles

1. **Shift security left** — scan in CI, not after breach
2. **Defense in depth** — scanner + code review + runtime WAF
3. **Test what you own** — focus on OWASP Top 10 for your attack surface
4. **Fail the pipeline on CRITICAL/HIGH** — non-negotiable for production
5. **No secrets in code** — ever. Not even in private repos.

## References available
- `references/dependency-scanning.md` — Snyk + Trivy GitHub Actions, severity thresholds, SARIF upload
- `references/semgrep-sast.md` — Semgrep CI config, p/owasp-top-ten ruleset, p/nodejs + p/typescript
- `references/secrets-scanning.md` — Gitleaks full-history scan, custom .gitleaks.toml allowlist rules
- `references/injection-test-cases.md` — SQL injection payloads, response assertions, no-500 rule
- `references/xss-test-cases.md` — XSS payload list, stored XSS verification, content escaping checks
- `references/security-headers.md` — required headers test, version exposure checks, CSP validation
