---
name: ci-cd-patterns
description: |
  Designs CI/CD pipelines: build, test, deploy stages, blue-green/canary/rolling deployments,
  feature flags, artifact management, and environment promotion strategies.
  Use when setting up or improving CI/CD pipelines or deployment workflows.
allowed-tools: Read, Grep, Glob, Bash
---

You are a CI/CD specialist. Design pipelines that are fast, reliable, secure, and enable confident deployments.

## Pipeline Stages

### Standard Pipeline
```
Code Push → Lint → Build → Unit Test → Integration Test → Security Scan → Deploy Staging → E2E Test → Deploy Production
```

### Pipeline Principles
- **Fail fast**: Run fastest checks first (lint 30s, unit tests 2m) before slow checks (integration 5m, E2E 10m)
- **Parallelize independent stages**: Lint, type-check, and unit tests can run simultaneously
- **Artifact-based promotion**: Build once, deploy the same artifact to every environment
- **Immutable artifacts**: Never modify after build -- tag with git SHA, sign for verification
- **Environment parity**: Staging mirrors production in infrastructure, data volume, and configuration
- **Deterministic builds**: Pin dependency versions, use lockfiles, reproducible container builds

### Pipeline Design Patterns

#### Sequential (Simple)
```
Lint → Build → Test → Deploy
```
Best for: Small projects, single service, fast test suites.

#### Fan-Out / Fan-In
```
         ┌─ Lint ──────┐
Build ───┼─ Unit Test ──┼─── Integration Test → Deploy
         └─ Type Check ─┘
```
Best for: Multiple independent validation steps that can run in parallel.

#### Diamond
```
         ┌─ Build Frontend ─┐
Checkout ┤                  ├─ Integration Test → Deploy
         └─ Build Backend  ─┘
```
Best for: Multi-component applications (frontend + backend).

#### Matrix Builds
```
Build × [Node 18, 20, 22] × [ubuntu, macos, windows]
```
Best for: Libraries and SDKs that must work across multiple platforms/versions.

### Per-Stage Best Practices

| Stage | Duration Target | What to Check | Failure Action |
|-------|----------------|---------------|----------------|
| **Lint/Format** | < 30s | Code style, import order, formatting | Block merge |
| **Type Check** | < 1m | Type errors, unused exports | Block merge |
| **Unit Test** | < 3m | Logic correctness, edge cases | Block merge |
| **Build** | < 5m | Compilation, bundling, asset generation | Block merge |
| **Integration Test** | < 10m | DB queries, API contracts, service boundaries | Block merge |
| **Security Scan** | < 5m | SAST, SCA, secret detection | Block merge (critical), warn (medium) |
| **E2E Test** | < 15m | Critical user flows, smoke tests | Block deploy (not merge) |
| **Deploy Staging** | < 5m | Infrastructure provisioning, health checks | Block production deploy |
| **Deploy Production** | < 10m | Rolling update, health checks, smoke tests | Auto-rollback |

## Deployment Strategies

### Blue-Green
Two identical environments -- blue (current) and green (new). Switch traffic atomically.

```yaml
# AWS ALB target group switching
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$GREEN_TG_ARN

# Rollback -- switch back to blue
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$BLUE_TG_ARN
```

- Instant rollback (switch back to previous target group)
- Requires 2x infrastructure during deployment window
- Database migrations must be backward-compatible (both versions run simultaneously)
- Smoke test the green environment before switching
- Drain connections from blue before decommissioning

### Canary
Route small percentage of traffic to the new version, monitor, gradually increase.

```yaml
# Kubernetes Ingress -- nginx canary annotations
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"  # 10% traffic
spec:
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-canary
                port: { number: 80 }
```

- **Rollout schedule**: 5% -> 10% -> 25% -> 50% -> 100% with monitoring between each step
- **Automated analysis**: Compare error rate, latency p99, and success rate between canary and baseline
- **Automatic rollback**: If error rate > 1% or latency p99 > 2x baseline, rollback immediately
- Best for high-traffic services where issues must be caught before full rollout

### Rolling
Update instances sequentially. Kubernetes default strategy.

```yaml
# Kubernetes Deployment rolling update
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1    # At most 1 pod down during update
      maxSurge: 2           # At most 2 extra pods during update
  template:
    spec:
      containers:
        - name: app
          readinessProbe:
            httpGet: { path: /healthz, port: 8080 }
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet: { path: /healthz, port: 8080 }
            initialDelaySeconds: 15
            periodSeconds: 20
```

- No extra infrastructure needed (just temporary surge capacity)
- Brief period with mixed versions -- APIs must be backward-compatible
- `maxUnavailable` controls how many pods can be down simultaneously
- `maxSurge` controls how many extra pods can be created during update
- Use readiness probes to prevent routing traffic to unready pods

### Recreate
Take down all instances, deploy new version. Simplest but causes downtime.

```yaml
strategy:
  type: Recreate
```

- Use only for: development environments, stateful apps that can't run mixed versions, batch jobs
- Never use for production services that require availability

## Feature Flags Architecture

### Evaluation Engine
```typescript
// Feature flag evaluation with targeting rules
interface FeatureFlag {
  key: string;
  defaultValue: boolean;
  rules: TargetingRule[];
  percentageRollout?: { percentage: number; attribute: string };  // sticky by user ID
  killSwitch: boolean;  // override -- always off when true
}

// Evaluation order:
// 1. Kill switch (if true, always return false)
// 2. User targeting rules (specific users/segments)
// 3. Percentage rollout (gradual rollout by user attribute hash)
// 4. Default value
```

### Flag Lifecycle
1. **Created**: Flag defined with `defaultValue: false`, no targeting rules
2. **Development**: Enabled for developers and QA via targeting rules
3. **Staging**: Enabled in staging environment for validation
4. **Gradual rollout**: 5% -> 25% -> 50% -> 100% in production
5. **Fully launched**: Flag permanently `true`, code path is the default
6. **Cleanup**: Remove flag checks from code, delete flag definition

### Feature Flag Tools

| Tool | Hosting | Pricing Model | Key Features |
|------|---------|---------------|-------------|
| **LaunchDarkly** | SaaS | Per-seat + MAU | Enterprise, SDKs for 25+ languages, experimentation, workflows |
| **Unleash** | Self-hosted or SaaS | Open-source core | Strategy types, constraints, variants, Kubernetes operator |
| **Flagsmith** | Self-hosted or SaaS | Open-source core | Remote config, A/B testing, audit logs |
| **ConfigCat** | SaaS | Per-config reads | Simple, percentage rollout, targeting, webhooks |
| **OpenFeature** | Standard | N/A (spec only) | Vendor-neutral SDK spec, provider pattern, hooks |
| **Statsig** | SaaS | Per-event | Feature gates, experiments, metrics, warehouse-native |
| **Custom** | Self-hosted | Engineering cost | Database/Redis-backed, simple but limited |

### Kill Switch Pattern
- Every feature flag should have a kill switch capability
- Kill switch must be evaluable without network call (cached locally)
- Test kill switch behavior in staging before production launch
- Document kill switch procedures in runbooks

## GitOps

### Principles
- Git is the single source of truth for declarative infrastructure and applications
- All changes go through pull requests -- auditable, reviewable, reversible
- Automated reconciliation: system state converges to desired state in git
- No manual `kubectl apply` or SSH to production servers

### ArgoCD Setup
```yaml
# ArgoCD Application definition
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-configs.git
    targetRevision: main
    path: environments/production/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true           # Delete resources not in git
      selfHeal: true         # Revert manual changes
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### Repository Structure (App Repo vs Config Repo)
```
# App repo (source code + CI)
my-app/
  src/
  Dockerfile
  .github/workflows/ci.yml    # Build, test, push image

# Config repo (Kubernetes manifests + CD)
k8s-configs/
  environments/
    dev/
      my-app/
        deployment.yaml
        service.yaml
        kustomization.yaml
    staging/
      my-app/
        kustomization.yaml     # Patches on top of base
    production/
      my-app/
        kustomization.yaml     # Production-specific patches
  base/
    my-app/
      deployment.yaml
      service.yaml
      kustomization.yaml
```

### Flux CD
```yaml
# Flux GitRepository + Kustomization
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: k8s-configs
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/org/k8s-configs.git
  ref: { branch: main }
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 5m
  path: ./environments/production/my-app
  sourceRef: { kind: GitRepository, name: k8s-configs }
  prune: true
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: my-app
      namespace: my-app
```

### Drift Detection
- ArgoCD: Compares live state vs desired state, shows diff in UI, auto-heals if configured
- Flux: Reconciliation loop every N minutes, reverts manual changes
- Alert on drift: Slack/PagerDuty notification when live state diverges from git

## Progressive Delivery

### Argo Rollouts
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
        - setWeight: 5
        - pause: { duration: 5m }
        - analysis:
            templates: [{ templateName: success-rate }]
        - setWeight: 25
        - pause: { duration: 10m }
        - analysis:
            templates: [{ templateName: success-rate }]
        - setWeight: 50
        - pause: { duration: 10m }
        - setWeight: 100
      canaryService: my-app-canary
      stableService: my-app-stable
---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  metrics:
    - name: success-rate
      interval: 1m
      successCondition: result[0] >= 0.99
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(http_requests_total{status=~"2.*",app="my-app",version="canary"}[5m]))
            /
            sum(rate(http_requests_total{app="my-app",version="canary"}[5m]))
```

### Flagger
- Works with Istio, Linkerd, NGINX, Contour, Gloo, Traefik
- Automated canary analysis with custom metrics
- A/B testing with HTTP header matching
- Blue/green with traffic mirroring

## Artifact Management

### Container Image Best Practices
- Tag images with git SHA: `app:abc123def` -- never use `latest` in production
- Multi-stage builds to minimize image size
- Scan images with Trivy, Grype, or Snyk before pushing
- Sign images with Cosign/Sigstore for supply chain security
- Use distroless or Alpine base images for smaller attack surface
- Store in private registries: ECR, GCR, ACR, Harbor, GitHub Container Registry

### Container Registry Comparison

| Registry | Provider | Key Features |
|----------|----------|-------------|
| **ECR** | AWS | IAM auth, lifecycle policies, image scanning, cross-region replication |
| **GCR / Artifact Registry** | GCP | IAM auth, vulnerability scanning, multi-format (Docker, Maven, npm) |
| **ACR** | Azure | AD auth, geo-replication, tasks (in-registry builds), Helm charts |
| **Harbor** | CNCF (self-hosted) | RBAC, vulnerability scanning, replication, Notary signing |
| **GitHub Container Registry** | GitHub | GitHub Actions integration, free for public, GHCR tokens |
| **Docker Hub** | Docker | Largest public registry, automated builds, Scout scanning |

### SBOM Generation
```bash
# Generate SBOM with Syft
syft packages my-app:latest -o spdx-json > sbom.spdx.json
syft packages my-app:latest -o cyclonedx-json > sbom.cdx.json

# Scan SBOM for vulnerabilities with Grype
grype sbom:sbom.spdx.json

# Attach SBOM to container image with Cosign
cosign attach sbom --sbom sbom.cdx.json my-registry/my-app:abc123
```

## Environment Strategy

```
Local → Dev → Staging → Preview (per-PR) → Production
```

- **Local**: Developer machines, docker-compose, hot reload, mock external services
- **Dev**: Shared development environment, frequent deploys, relaxed stability
- **Staging**: Production mirror, same infrastructure, same data volume (anonymized), pre-release validation
- **Preview (per-PR)**: Ephemeral environments spun up per pull request for review and testing
- **Production**: Live traffic, monitored, alerting, SLO-bound, change management

### Preview Environments per PR
```yaml
# GitHub Actions -- deploy preview per PR
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          PREVIEW_URL="https://pr-${{ github.event.number }}.preview.example.com"
          # Deploy to preview namespace
          kubectl create namespace preview-${{ github.event.number }} --dry-run=client -o yaml | kubectl apply -f -
          helm upgrade --install pr-${{ github.event.number }} ./chart \
            --namespace preview-${{ github.event.number }} \
            --set image.tag=${{ github.sha }} \
            --set ingress.host=pr-${{ github.event.number }}.preview.example.com
      - uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              owner: context.repo.owner, repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `Preview deployed: https://pr-${context.issue.number}.preview.example.com`
            });
```

## Security in CI/CD

### Scanning Pipeline
```
Source Code → SAST (Semgrep/CodeQL) → Build → SCA (Snyk/Trivy) → Image Scan (Trivy) → DAST (ZAP) → Deploy
```

### SAST (Static Application Security Testing)
- **Semgrep**: Fast, custom rules, multi-language, OWASP rulesets, CI-friendly
- **CodeQL**: GitHub-native, deep semantic analysis, CVE detection
- **SonarQube**: Code quality + security, quality gates, 30+ languages

### SCA (Software Composition Analysis)
- **Snyk**: Dependency scanning, fix PRs, license compliance, container scanning
- **Trivy**: All-in-one scanner -- images, IaC, SBOM, secrets, licenses (free, open-source)
- **Dependabot**: GitHub-native, auto-PRs for vulnerable dependencies
- **Renovate**: Broader support, monorepo, configurable update strategies, grouping

### Secret Scanning
- **GitLeaks**: Git history scanning, pre-commit hooks, CI integration
- **TruffleHog**: Deep entropy-based secret detection, verified secrets
- **GitHub Secret Scanning**: Push protection, partner patterns, alerts

### Signed Commits and Artifacts
```bash
# Sign container image with Cosign (keyless via OIDC)
cosign sign --yes my-registry/my-app:abc123

# Verify signature
cosign verify my-registry/my-app:abc123 --certificate-identity=ci@example.com \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

## Quality Gates

| Gate | Tool | Threshold | Enforcement |
|------|------|-----------|-------------|
| **Code coverage** | Codecov, Coveralls, SonarQube | > 80% lines, > 75% branches | Block merge if below |
| **Static analysis** | SonarQube, CodeClimate | 0 critical/blocker issues | Block merge |
| **Security scan** | Snyk, Trivy, Semgrep | 0 critical/high CVEs | Block merge |
| **Performance budget** | Lighthouse CI, Web Vitals | LCP < 2.5s, CLS < 0.1 | Warn on regression |
| **License compliance** | FOSSA, Snyk | No GPL in proprietary code | Block merge |
| **Bundle size** | Bundlewatch, Size Limit | < 250KB gzipped JS | Warn on increase > 5% |

## Monorepo CI/CD

### Tool Comparison

| Tool | Language | Affected Detection | Remote Cache | Task Orchestration |
|------|----------|-------------------|--------------|-------------------|
| **Turborepo** | JS/TS | Hash-based, git diff | Vercel Remote Cache, self-hosted | Topological, parallel |
| **Nx** | JS/TS (+ plugins for others) | Dependency graph, git diff | Nx Cloud, self-hosted | Distributed task execution |
| **Bazel** | Multi-language | Hermetic, content-addressable | Remote execution, remote cache | Fine-grained, parallel |
| **Pants** | Python, Go, Java, Scala | Dependency graph | Remote cache | Fine-grained, parallel |
| **Moon** | JS/TS, Rust | Hash-based | moonbase | Topological, parallel |

### Affected Detection
```bash
# Turborepo -- only build/test changed packages
npx turbo run build test --filter=...[HEAD~1]

# Nx -- only affected projects
npx nx affected --target=build --base=origin/main --head=HEAD

# Bazel -- query affected targets
bazel query 'rdeps(//..., set($(git diff --name-only origin/main...HEAD)))'
```

## Pipeline Optimization

### Caching Strategies
```yaml
# GitHub Actions -- dependency caching
- uses: actions/cache@v4
  with:
    path: |
      node_modules
      ~/.cache/pip
      ~/.gradle/caches
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json', '**/requirements.txt') }}
    restore-keys: ${{ runner.os }}-deps-

# Docker layer caching
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Build Skip Conditions
```yaml
# Skip CI for docs-only changes
on:
  push:
    paths-ignore:
      - '**.md'
      - 'docs/**'
      - '.github/ISSUE_TEMPLATE/**'

# Or use commit message convention
if: "!contains(github.event.head_commit.message, '[skip ci]')"
```

### Incremental Builds
- **TypeScript**: `tsc --incremental`, `tsconfig.tsBuildInfoFile`
- **Gradle**: Build cache, incremental compilation, configuration cache
- **Rust**: `cargo build` with sccache for distributed caching
- **Docker**: Multi-stage builds with layer caching, `--cache-from`

## Rollback Strategies

### Automated Rollback Triggers
- Error rate exceeds threshold (> 1% 5xx responses for 5 minutes)
- Latency p99 exceeds 2x baseline for 5 minutes
- Health check failures on new pods/instances
- Deployment timeout (new version doesn't become healthy within deadline)

### Database Rollback Coordination
- Schema changes must be backward-compatible (expand-contract pattern)
- Deploy new code that works with both old and new schema
- Run migration (expand phase)
- Remove old code paths after migration is verified (contract phase)
- Never deploy code and schema changes atomically

### Feature Flag Fallback
- If deployment fails, disable feature flag rather than rolling back code
- Faster than code rollback (seconds vs minutes)
- No infrastructure changes needed
- Works as a first response while investigating issues

## Release Management

### Semantic Versioning
- `MAJOR.MINOR.PATCH` -- `2.1.0`
- **MAJOR**: Breaking changes (API incompatibility)
- **MINOR**: New features (backward-compatible)
- **PATCH**: Bug fixes (backward-compatible)
- Pre-release: `2.1.0-beta.1`, `2.1.0-rc.1`

### Release Automation Tools

| Tool | Ecosystem | Versioning | Changelog |
|------|-----------|-----------|-----------|
| **semantic-release** | npm (any language via plugins) | Conventional Commits | Auto-generated from commits |
| **changesets** | npm monorepos | Manual version bumps via changeset files | Aggregated from changeset descriptions |
| **release-please** | GitHub-native | Conventional Commits | Auto-generated PR with changelog |
| **goreleaser** | Go | Git tags | Auto-generated |
| **cargo-release** | Rust | Cargo.toml version | Changelog updates |

### Conventional Commits
```
feat: add user registration endpoint
fix: prevent duplicate email registration
perf: optimize user search query with index
docs: update API documentation for v2
refactor!: rename UserService to AccountService

BREAKING CHANGE: UserService has been renamed to AccountService
```

- Commit types: `feat`, `fix`, `perf`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`
- `!` after type indicates breaking change
- Automated version bumping: `feat` -> minor, `fix` -> patch, `BREAKING CHANGE` -> major
- Enforced with commitlint in pre-commit hook or CI

For platform-specific references, see [reference-tools.md](reference-tools.md).
