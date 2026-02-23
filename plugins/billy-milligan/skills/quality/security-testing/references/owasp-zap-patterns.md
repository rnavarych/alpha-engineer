# OWASP ZAP Patterns

## When to load
Load when setting up automated security scanning: ZAP baseline, API scan, CI integration.

## Baseline Scan (passive — non-intrusive)

```bash
# Docker-based baseline scan — safe for any environment
docker run --rm -t zaproxy/zap-stable zap-baseline.py \
  -t https://staging.example.com \
  -r report.html \
  -I  # Continue on warnings (fail only on errors)

# With custom rules file
docker run --rm -v $(pwd):/zap/wrk/:rw zaproxy/zap-stable zap-baseline.py \
  -t https://staging.example.com \
  -c zap-rules.conf \
  -r report.html
```

## API Scan (active — tests for vulnerabilities)

```bash
# Scan API defined by OpenAPI spec
docker run --rm -v $(pwd):/zap/wrk/:rw zaproxy/zap-stable zap-api-scan.py \
  -t https://staging.example.com/openapi.json \
  -f openapi \
  -r api-report.html \
  -c zap-api-rules.conf
```

## CI Integration (GitHub Actions)

```yaml
security-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: ZAP Baseline Scan
      uses: zaproxy/action-baseline@v0.10.0
      with:
        target: 'https://staging.example.com'
        rules_file_name: '.zap/rules.tsv'
        cmd_options: '-a'
    - name: Upload report
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: zap-report
        path: report_html.html
```

## Rule Configuration

```tsv
# .zap/rules.tsv — customize alerts
# ID	Action (IGNORE/WARN/FAIL)
10035	IGNORE	# Strict-Transport-Security (handled by CDN)
10038	IGNORE	# Content Security Policy (set per-page)
40012	FAIL	# Cross Site Scripting (Reflected)
40014	FAIL	# Cross Site Scripting (Persistent)
90033	FAIL	# Loosely Scoped Cookie
```

## Anti-patterns
- Running active scans against production → can modify data, cause outages
- Ignoring all warnings → defeats the purpose of scanning
- No rules configuration → too many false positives, team ignores results
- Only passive scans → misses injection vulnerabilities

## Quick reference
```
Baseline: passive, safe for any environment, finds config issues
API scan: active, uses OpenAPI spec, finds injection bugs
Full scan: active + spider, most thorough, staging only
Rules: .tsv file to IGNORE/WARN/FAIL specific alerts
CI: zaproxy/action-baseline for GitHub Actions
Frequency: baseline on every deploy, full scan weekly
```
