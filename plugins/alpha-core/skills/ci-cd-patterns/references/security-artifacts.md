# Security Scanning and Artifact Management

## When to load
Load when adding security scanning to pipelines, managing container images, generating SBOMs, or enforcing quality gates.

## Scanning Pipeline
```
Source Code → SAST (Semgrep/CodeQL) → Build → SCA (Snyk/Trivy) → Image Scan (Trivy) → DAST (ZAP) → Deploy
```

## SAST (Static Application Security Testing)
- **Semgrep**: Fast, custom rules, multi-language, OWASP rulesets, CI-friendly
- **CodeQL**: GitHub-native, deep semantic analysis, CVE detection
- **SonarQube**: Code quality + security, quality gates, 30+ languages

## SCA (Software Composition Analysis)
- **Snyk**: Dependency scanning, fix PRs, license compliance, container scanning
- **Trivy**: All-in-one scanner — images, IaC, SBOM, secrets, licenses (free, open-source)
- **Dependabot**: GitHub-native, auto-PRs for vulnerable dependencies
- **Renovate**: Broader support, monorepo, configurable update strategies, grouping

## Secret Scanning
- **GitLeaks**: Git history scanning, pre-commit hooks, CI integration
- **TruffleHog**: Deep entropy-based secret detection, verified secrets
- **GitHub Secret Scanning**: Push protection, partner patterns, alerts

## Signed Commits and Artifacts
```bash
# Sign container image with Cosign (keyless via OIDC)
cosign sign --yes my-registry/my-app:abc123

# Verify signature
cosign verify my-registry/my-app:abc123 \
  --certificate-identity=ci@example.com \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

## Container Image Best Practices
- Tag images with git SHA: `app:abc123def` — never use `latest` in production
- Multi-stage builds to minimize image size
- Scan images with Trivy, Grype, or Snyk before pushing
- Sign images with Cosign/Sigstore for supply chain security
- Use distroless or Alpine base images for smaller attack surface

## Container Registry Comparison

| Registry | Provider | Key Features |
|----------|----------|-------------|
| **ECR** | AWS | IAM auth, lifecycle policies, image scanning, cross-region replication |
| **Artifact Registry** | GCP | Multi-format (Docker, Maven, npm), IAM, vulnerability scanning |
| **ACR** | Azure | AD auth, geo-replication, ACR Tasks (in-registry builds), Helm charts |
| **Harbor** | CNCF (self-hosted) | RBAC, Trivy scanning, replication, Notary v2 signing |
| **GHCR** | GitHub | GitHub Actions integration, fine-grained permissions |
| **Docker Hub** | Docker | Largest public registry, Docker Scout scanning |

## SBOM Generation
```bash
syft packages my-app:latest -o spdx-json > sbom.spdx.json
grype sbom:sbom.spdx.json
cosign attach sbom --sbom sbom.cdx.json my-registry/my-app:abc123
```

## Quality Gates

| Gate | Tool | Threshold | Enforcement |
|------|------|-----------|-------------|
| **Code coverage** | Codecov, SonarQube | > 80% lines, > 75% branches | Block merge if below |
| **Static analysis** | SonarQube, CodeClimate | 0 critical/blocker issues | Block merge |
| **Security scan** | Snyk, Trivy, Semgrep | 0 critical/high CVEs | Block merge |
| **Performance budget** | Lighthouse CI | LCP < 2.5s, CLS < 0.1 | Warn on regression |
| **License compliance** | FOSSA, Snyk | No GPL in proprietary code | Block merge |
| **Bundle size** | Bundlewatch, Size Limit | < 250KB gzipped JS | Warn on increase > 5% |
