# OWASP Top 10 and Scanning Tools

## When to load
Load when reviewing code for vulnerabilities, setting up SAST/DAST/SCA pipelines, or assessing overall security posture against OWASP categories.

## OWASP Top 10 Checklist

1. **Broken Access Control**: Enforce least privilege, deny by default, validate on server side, IDOR prevention, path traversal protection
2. **Cryptographic Failures**: TLS 1.2+ (prefer 1.3), AES-256-GCM at rest, Argon2id for passwords, no weak algorithms
3. **Injection**: Parameterized queries, ORM usage, input validation, output encoding, NoSQL injection, LDAP injection, template injection
4. **Insecure Design**: Threat modeling (STRIDE, PASTA, LINDDUN), secure design patterns, defense in depth, abuse case analysis
5. **Security Misconfiguration**: Harden defaults, disable unused features, security headers, disable directory listing, error message suppression
6. **Vulnerable Components**: SAST/DAST/SCA scanning, Snyk, Dependabot, Renovate, SBOM generation, patch management automation
7. **Authentication Failures**: MFA, rate limiting, credential stuffing protection, passkeys, account lockout, secure session management
8. **Data Integrity Failures**: CI/CD pipeline integrity (Sigstore, SLSA), code signing, dependency verification, SBOM
9. **Logging Failures**: Log security events (SIEM: Splunk, Sentinel, Elastic SIEM), protect logs, centralized monitoring, tamper-evident logs
10. **SSRF**: Validate/sanitize URLs, allowlist destinations, network segmentation, IMDSv2 enforcement on cloud

## Static Analysis (SAST)
- **Semgrep**: Fast, custom rules, multi-language, CI-friendly, OWASP rulesets
- **SonarQube / SonarCloud**: Code quality + security, quality gates, 30+ languages
- **CodeQL**: GitHub-native, deep semantic analysis, CVE detection, custom queries in QL
- **Snyk Code**: AI-powered SAST, IDE integration, fix suggestions
- **Bandit**: Python-specific SAST; **Brakeman**: Ruby on Rails SAST; **gosec**: Go security checker
- **Trivy FS**: Filesystem scanning for secrets, misconfigurations, vulnerabilities
- **Checkov**: IaC scanning (Terraform, CloudFormation, Kubernetes, Helm, ARM templates)
- **tfsec**: Terraform-specific; **kube-linter**: Kubernetes manifest checks; **Hadolint**: Dockerfile linting

## Dynamic Analysis (DAST)
- **OWASP ZAP**: Open-source, active/passive scanning, CI integration, API scanning
- **Burp Suite Pro**: Industry standard, intercepting proxy, scanner, intruder, extensible
- **Nuclei**: Fast, template-based, community-driven vulnerability scanner
- **Nikto**: Web server scanner; **SQLMap**: SQL injection testing; **ffuf / dirsearch**: Endpoint fuzzing

## Software Composition Analysis (SCA)
- **Snyk Open Source**: License compliance, fix PRs, container scanning
- **Dependabot**: GitHub-native, auto-PRs for vulnerable dependencies
- **Renovate**: Broader support, monorepo, configurable update strategies
- **Socket.dev**: Supply chain risk analysis, behavior analysis of npm packages
- **OWASP Dependency-Check**: Java, .NET, JavaScript, Ruby
- **Grype**: Fast vulnerability scanner for container images and filesystems
- **Syft**: SBOM generation (SPDX, CycloneDX formats)

## Secrets Scanning
- **GitLeaks**: Git history scanning, pre-commit hooks, CI integration
- **TruffleHog**: Deep entropy-based secret detection, verified secrets
- **detect-secrets**: Yelp's tool, baseline management
- **GitHub Secret Scanning**: Native, push protection, partner patterns
