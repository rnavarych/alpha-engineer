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

## When to Use This Skill
- Setting up security scanning in CI/CD pipeline
- Writing security test cases for OWASP Top 10
- Reviewing code for common vulnerabilities
- Dependency vulnerability management
- Secrets scanning and prevention

## Core Principles

1. **Shift security left** — scan in CI, not after breach
2. **Defense in depth** — scanner + code review + runtime WAF
3. **Test what you own** — focus on OWASP Top 10 for your attack surface
4. **Fail the pipeline on CRITICAL/HIGH** — non-negotiable for production
5. **No secrets in code** — ever. Not even in private repos.

---

## Patterns ✅

### Dependency Scanning in CI

```yaml
# .github/workflows/security.yml
name: Security Scanning

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 8 * * 1'  # Monday morning scan (new CVEs published over weekend)

jobs:
  snyk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high  # Fail on HIGH and CRITICAL
          # Creates Snyk projects and tracks vulnerabilities over time

  trivy:
    runs-on: ubuntu-latest
    needs: build  # Scan built Docker image
    steps:
      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # Fail on findings
          ignore-unfixed: true  # Don't fail for CVEs with no fix available

      - uses: github/codeql-action/upload-sarif@v3
        if: always()  # Upload even if previous step failed
        with:
          sarif_file: 'trivy-results.sarif'
```

### Semgrep SAST (Static Analysis)

```yaml
  semgrep:
    runs-on: ubuntu-latest
    container:
      image: semgrep/semgrep
    steps:
      - uses: actions/checkout@v4
      - run: |
          semgrep ci \
            --config auto \
            --config p/security-audit \
            --config p/nodejs \
            --config p/typescript \
            --config p/owasp-top-ten \
            --error  # Exit 1 on findings
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

### Gitleaks Secrets Scanning

```yaml
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history — scan all commits

      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}
        # Detects: AWS keys, GitHub tokens, Stripe keys, private keys, etc.
```

```toml
# .gitleaks.toml — custom rules
[allowlist]
  description = "Allow test fixtures"
  paths = ["test/fixtures/**", "**/*.test.ts"]
  regexes = ["EXAMPLE_.*_KEY", "test_.*_token"]

[[rules]]
  id = "custom-stripe-test-key"
  description = "Stripe test secret key"
  regex = '''sk_test_[0-9a-zA-Z]{24,}'''
  tags = ["payment", "stripe"]
```

### SQL Injection Test Cases

```typescript
// security.test.ts — test for injection vulnerabilities
describe('SQL Injection Prevention', () => {
  const injectionPayloads = [
    "'; DROP TABLE users; --",
    "1' OR '1'='1",
    "1; SELECT * FROM users",
    "UNION SELECT * FROM users--",
    "' OR 1=1--",
    "admin'--",
    "1' AND SLEEP(5)--",  // Time-based blind injection
  ];

  it.each(injectionPayloads)('should safely handle SQL injection: %s', async (payload) => {
    // Test that injection attempts return 400 or empty results, never DB error or data leak
    const response = await request(app)
      .get(`/api/users?search=${encodeURIComponent(payload)}`)
      .set('Authorization', `Bearer ${validToken}`);

    expect(response.status).toBeOneOf([200, 400]);
    // If 200: verify it didn't return actual user data
    if (response.status === 200) {
      expect(response.body.data).toHaveLength(0);
    }
    // Must NOT be 500 — internal server error often means injection succeeded
    expect(response.status).not.toBe(500);
  });

  it('should not expose DB error messages', async () => {
    const response = await request(app)
      .get("/api/users?search='")  // Intentional syntax error
      .set('Authorization', `Bearer ${validToken}`);

    // DB error messages reveal schema information
    expect(JSON.stringify(response.body)).not.toContain('syntax error');
    expect(JSON.stringify(response.body)).not.toContain('PostgreSQL');
    expect(JSON.stringify(response.body)).not.toContain('pg_');
  });
});
```

### XSS Prevention Testing

```typescript
describe('XSS Prevention', () => {
  const xssPayloads = [
    '<script>alert("xss")</script>',
    '"><script>alert(1)</script>',
    "javascript:alert('xss')",
    '<img src=x onerror=alert(1)>',
    '<svg onload=alert(1)>',
    '{{7*7}}',  // Template injection test
  ];

  it.each(xssPayloads)('should sanitize XSS payload in user input: %s', async (payload) => {
    // Create content with XSS payload
    const response = await request(app)
      .post('/api/comments')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ content: payload });

    if (response.status === 201) {
      // Stored XSS: verify stored content is escaped
      const getResponse = await request(app)
        .get(`/api/comments/${response.body.id}`)
        .set('Authorization', `Bearer ${validToken}`);

      // Content should be stored as escaped text, not as HTML
      expect(getResponse.body.content).not.toContain('<script>');
      expect(getResponse.body.content).not.toContain('onerror=');
    }
  });
});
```

### Security Headers Validation

```typescript
describe('Security Headers', () => {
  it('should include required security headers', async () => {
    const response = await request(app).get('/');

    expect(response.headers['x-content-type-options']).toBe('nosniff');
    expect(response.headers['x-frame-options']).toBe('DENY');
    expect(response.headers['strict-transport-security']).toContain('max-age=');
    expect(response.headers['content-security-policy']).toBeDefined();
    // Must not expose server info
    expect(response.headers['x-powered-by']).toBeUndefined();
    expect(response.headers['server']).toBeUndefined();
  });

  it('should not expose version information', async () => {
    const response = await request(app).get('/api/unknown-endpoint');
    const headers = JSON.stringify(response.headers);
    expect(headers).not.toMatch(/express/i);
    expect(headers).not.toMatch(/node/i);
    expect(headers).not.toMatch(/nginx\/\d/);
  });
});
```

---

## Anti-Patterns ❌

### Only Scanning on Merge
**What it is**: Security scan only runs when merging to main.
**What breaks**: PR introduces vulnerability, reviewed and merged with security scan still running. Or: PR approved before scan completes.
**Fix**: Security scan must be a required status check. Must pass before merge.

### Ignoring Non-Critical Vulnerabilities
**What it is**: `--severity-threshold=critical` — only fail on CRITICAL.
**What breaks**: HIGH severity accumulates. Eventually so many ignores that nobody reviews them. One HIGH leads to breach.
**Fix**: Fail on HIGH and CRITICAL. MEDIUM: create ticket automatically, fix within 30 days. LOW: backlog.

### Manual Security Review Only
**What it is**: Relying on code reviewers to catch security issues.
**What breaks**: Humans miss patterns. Under deadline pressure, reviews get rushed. Scanners are consistent and never tired.
**Fix**: Automated scanning + human review. Scanners catch patterns; humans catch logic flaws.

---

## Quick Reference

```
Dependency scanning: Snyk (JavaScript) + Trivy (Docker images)
SAST: Semgrep with p/owasp-top-ten + p/nodejs rules
Secrets: Gitleaks on full history (fetch-depth: 0)
Fail threshold: CRITICAL + HIGH = block merge
SQL injection: test all user inputs with injection payloads
XSS: verify stored content is escaped, not raw HTML
Headers: X-Content-Type-Options, X-Frame-Options, HSTS, CSP
Scan frequency: every PR + weekly scheduled scan (new CVEs)
```
