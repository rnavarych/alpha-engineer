# CI/CD Tools Reference

## GitHub Actions

### Workflow Examples

#### Build, Test, and Deploy
```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-and-typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    needs: lint-and-typecheck
    services:
      postgres:
        image: postgres:16-alpine
        env: { POSTGRES_DB: testdb, POSTGRES_PASSWORD: test }
        ports: ['5432:5432']
        options: --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm test -- --coverage
        env: { DATABASE_URL: 'postgresql://postgres:test@localhost:5432/testdb' }
      - uses: actions/upload-artifact@v4
        with: { name: coverage, path: coverage/ }

  build-and-push:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      id-token: write  # OIDC for cloud auth
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/github-actions
          aws-region: us-east-1
      - uses: aws-actions/amazon-ecr-login@v2
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: |
            ${{ env.ECR_REGISTRY }}/my-app:${{ github.sha }}
            ${{ env.ECR_REGISTRY }}/my-app:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    runs-on: ubuntu-latest
    needs: build-and-push
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - run: |
          helm upgrade --install my-app ./chart \
            --namespace staging \
            --set image.tag=${{ github.sha }} \
            --wait --timeout 5m

  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment:
      name: production
      url: https://app.example.com
    steps:
      - uses: actions/checkout@v4
      - run: |
          helm upgrade --install my-app ./chart \
            --namespace production \
            --set image.tag=${{ github.sha }} \
            --wait --timeout 10m
```

#### Matrix Build
```yaml
test:
  runs-on: ${{ matrix.os }}
  strategy:
    fail-fast: false
    matrix:
      os: [ubuntu-latest, macos-latest, windows-latest]
      node-version: [18, 20, 22]
      exclude:
        - os: macos-latest
          node-version: 18
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with: { node-version: '${{ matrix.node-version }}' }
    - run: npm ci
    - run: npm test
```

#### Reusable Workflows
```yaml
# .github/workflows/reusable-deploy.yml
on:
  workflow_call:
    inputs:
      environment: { required: true, type: string }
      image-tag: { required: true, type: string }
    secrets:
      KUBECONFIG: { required: true }

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      - run: helm upgrade --install my-app ./chart --set image.tag=${{ inputs.image-tag }}
        env: { KUBECONFIG: '${{ secrets.KUBECONFIG }}' }

# Caller workflow
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with: { environment: staging, image-tag: '${{ github.sha }}' }
    secrets: { KUBECONFIG: '${{ secrets.STAGING_KUBECONFIG }}' }
```

### Key Features
- YAML workflows in `.github/workflows/`
- Matrix builds for multi-platform/version testing
- Reusable workflows and composite actions for DRY pipelines
- GitHub-hosted and self-hosted runners (including ARM, GPU)
- Built-in secrets management, OIDC for keyless cloud auth (AWS, GCP, Azure)
- Marketplace for pre-built actions (20,000+ actions)
- Environment protection rules with required reviewers and wait timers
- Concurrency control: cancel in-progress runs, queue deployments

## GitLab CI

### Configuration Example
```yaml
# .gitlab-ci.yml
stages:
  - validate
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

lint:
  stage: validate
  image: node:22-alpine
  script:
    - npm ci --cache .npm
    - npm run lint
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths: [.npm/]

build:
  stage: build
  image: docker:24
  services: [docker:24-dind]
  script:
    - docker build -t $DOCKER_IMAGE .
    - docker push $DOCKER_IMAGE

test:
  stage: test
  image: $DOCKER_IMAGE
  services:
    - postgres:16-alpine
  variables:
    POSTGRES_DB: testdb
    POSTGRES_PASSWORD: test
    DATABASE_URL: postgresql://postgres:test@postgres:5432/testdb
  script:
    - npm test -- --coverage
  coverage: '/Statements\s*:\s*(\d+\.?\d*)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

deploy_staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - helm upgrade --install my-app ./chart --set image.tag=$CI_COMMIT_SHA
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy_production:
  stage: deploy
  environment:
    name: production
    url: https://app.example.com
  script:
    - helm upgrade --install my-app ./chart --set image.tag=$CI_COMMIT_SHA
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual  # Require manual approval
```

### Key Features
- `.gitlab-ci.yml` configuration with stages, jobs, rules, artifacts
- Auto DevOps for automated pipeline generation
- Built-in container registry, security scanning (SAST, DAST, SCA, secret detection)
- Environments with review apps (ephemeral per-MR environments)
- DAG (directed acyclic graph) for complex job dependencies
- Parent-child pipelines for monorepo support
- Merge trains for serialized merges to protected branches

## Jenkins
- Jenkinsfile (declarative or scripted pipeline)
- Plugin ecosystem (1800+ plugins)
- Distributed builds with agents (static or dynamic Kubernetes pods)
- Blue Ocean UI for pipeline visualization
- Best for complex, custom pipeline requirements
- Shared libraries for reusable pipeline code
- Configuration as Code (JCasC) for reproducible Jenkins instances

## ArgoCD / Flux Setup

### ArgoCD Installation and Configuration
```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login via CLI
argocd login localhost:8080
argocd app create my-app \
  --repo https://github.com/org/k8s-configs.git \
  --path environments/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace my-app \
  --sync-policy automated \
  --self-heal \
  --auto-prune
```

### ArgoCD Application Sets
```yaml
# ApplicationSet for multi-cluster deployment
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-app
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - cluster: staging
            url: https://staging.k8s.example.com
          - cluster: production
            url: https://production.k8s.example.com
  template:
    metadata:
      name: 'my-app-{{cluster}}'
    spec:
      source:
        repoURL: https://github.com/org/k8s-configs.git
        path: 'environments/{{cluster}}/my-app'
        targetRevision: main
      destination:
        server: '{{url}}'
        namespace: my-app
```

### Flux CD Installation
```bash
# Install Flux
flux bootstrap github \
  --owner=my-org \
  --repository=fleet-infra \
  --branch=main \
  --path=./clusters/production \
  --personal

# Add application source
flux create source git my-app \
  --url=https://github.com/org/k8s-configs.git \
  --branch=main \
  --interval=1m

# Create Kustomization
flux create kustomization my-app \
  --source=GitRepository/my-app \
  --path="./environments/production" \
  --prune=true \
  --interval=5m \
  --health-check="Deployment/my-app.my-app"
```

## Argo Rollouts Canary Analysis

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: canary-analysis
spec:
  args:
    - name: service-name
    - name: canary-hash
  metrics:
    - name: error-rate
      interval: 2m
      count: 5
      successCondition: result[0] < 0.01  # < 1% error rate
      failureLimit: 2
      provider:
        prometheus:
          address: http://prometheus.monitoring:9090
          query: |
            sum(rate(http_requests_total{status=~"5.*",
              service="{{args.service-name}}",
              rollouts_pod_template_hash="{{args.canary-hash}}"}[5m]))
            /
            sum(rate(http_requests_total{
              service="{{args.service-name}}",
              rollouts_pod_template_hash="{{args.canary-hash}}"}[5m]))
    - name: latency-p99
      interval: 2m
      count: 5
      successCondition: result[0] < 500  # < 500ms p99
      failureLimit: 2
      provider:
        prometheus:
          address: http://prometheus.monitoring:9090
          query: |
            histogram_quantile(0.99,
              sum(rate(http_request_duration_seconds_bucket{
                service="{{args.service-name}}",
                rollouts_pod_template_hash="{{args.canary-hash}}"}[5m]))
              by (le))
```

## CircleCI
- `.circleci/config.yml` configuration
- Orbs for reusable configuration (pre-packaged pipeline blocks)
- Docker layer caching for faster builds
- Insights for pipeline optimization (bottleneck detection, flaky test detection)
- Dynamic configuration with setup workflows
- Resource classes for different compute sizes (small to 2xlarge+)

## Container Registry Comparison

| Registry | Provider | Pricing | Key Features |
|----------|----------|---------|-------------|
| **ECR** | AWS | $0.10/GB/month | IAM auth, lifecycle policies, image scanning, cross-region replication |
| **Artifact Registry** | GCP | $0.10/GB/month | Multi-format (Docker, Maven, npm, Python), IAM, vulnerability scanning |
| **ACR** | Azure | $0.003/day (Basic) | AD auth, geo-replication, ACR Tasks (in-registry builds), Helm charts |
| **Harbor** | Self-hosted | Free (OSS) | RBAC, Trivy scanning, replication, Notary v2 signing, quotas |
| **GHCR** | GitHub | Free (public) | GitHub Actions integration, fine-grained permissions, GHCR tokens |
| **Docker Hub** | Docker | Free (1 repo) | Largest public registry, automated builds, Docker Scout, Docker Official Images |
| **Quay.io** | Red Hat | Free (public) | Clair scanning, geo-replication, robot accounts, mirrors |

## Security Scanning Tool Comparison

| Tool | Type | Languages/Targets | Integration | License |
|------|------|-------------------|-------------|---------|
| **Semgrep** | SAST | 30+ languages | CLI, CI, IDE, GitHub App | OSS (Community rules) |
| **CodeQL** | SAST | C/C++, Java, JS/TS, Python, Go, Ruby, C#, Swift | GitHub native | Free for public repos |
| **SonarQube** | SAST + Quality | 30+ languages | CLI, CI, IDE, GitHub/GitLab | Community (free) + Enterprise |
| **Snyk** | SCA + SAST + Container | npm, pip, Maven, NuGet, Go, Docker | CLI, CI, IDE, Git integration | Free tier + paid |
| **Trivy** | SCA + Container + IaC + Secrets | Docker, OCI, Terraform, K8s | CLI, CI, Kubernetes operator | OSS (Apache 2.0) |
| **OWASP ZAP** | DAST | Web applications | CLI, CI, Docker, API scan | OSS (Apache 2.0) |
| **GitLeaks** | Secret scanning | Git history | Pre-commit, CI | OSS (MIT) |
| **Checkov** | IaC scanning | Terraform, CloudFormation, K8s, Helm, ARM | CLI, CI, IDE | OSS (Apache 2.0) |
| **Grype** | SCA | Container images, SBOMs, filesystems | CLI, CI | OSS (Apache 2.0) |

### Security Scanning Integration Example
```yaml
# GitHub Actions -- security scanning pipeline
security-scan:
  runs-on: ubuntu-latest
  steps:
    # SAST with Semgrep
    - uses: returntocorp/semgrep-action@v1
      with: { config: 'p/owasp-top-ten p/r2c-security-audit' }

    # SCA with Trivy
    - uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'

    # Container image scan
    - uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'my-app:${{ github.sha }}'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'

    # Secret scanning
    - uses: gitleaks/gitleaks-action@v2
      env: { GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}' }
```

## Monorepo Build Tool Comparison

| Feature | Turborepo | Nx | Bazel |
|---------|-----------|-----|-------|
| **Primary language** | JS/TS | JS/TS (extensible) | Multi-language |
| **Config format** | `turbo.json` | `nx.json` + `project.json` | `BUILD` files (Starlark) |
| **Task runner** | Topological, parallel | Topological, distributed | Hermetic, parallel |
| **Remote cache** | Vercel Remote Cache | Nx Cloud | Remote Execution + Cache |
| **Affected detection** | Hash-based | Dependency graph | Content-addressable |
| **Learning curve** | Low | Medium | High |
| **Incremental adoption** | Easy (add `turbo.json`) | Moderate | Difficult |
| **Best for** | JS/TS monorepos | JS/TS + growing polyglot | Large polyglot codebases |

### Turborepo Configuration
```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "test": {
      "dependsOn": ["build"],
      "inputs": ["src/**", "test/**"]
    },
    "lint": {},
    "deploy": {
      "dependsOn": ["build", "test", "lint"]
    }
  }
}
```

### Nx Configuration
```json
// nx.json
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "cache": true
    },
    "test": {
      "inputs": ["default", "^production"],
      "cache": true
    }
  },
  "namedInputs": {
    "production": ["default", "!{projectRoot}/**/*.spec.ts"]
  }
}
```

## Quality Gate Tool Configuration

### SonarQube Quality Gate
```yaml
# sonar-project.properties
sonar.projectKey=my-app
sonar.sources=src
sonar.tests=test
sonar.typescript.lcov.reportPaths=coverage/lcov.info
sonar.coverage.exclusions=**/*.test.ts,**/*.spec.ts
sonar.qualitygate.wait=true

# Quality gate conditions (configured in SonarQube UI or API):
# - Coverage on new code > 80%
# - Duplicated lines on new code < 3%
# - Maintainability rating on new code = A
# - Reliability rating on new code = A
# - Security rating on new code = A
# - Security hotspots reviewed on new code = 100%
```

### CodeClimate Configuration
```yaml
# .codeclimate.yml
version: "2"
checks:
  argument-count: { config: { threshold: 4 } }
  complex-logic: { config: { threshold: 4 } }
  file-lines: { config: { threshold: 300 } }
  method-complexity: { config: { threshold: 10 } }
  method-lines: { config: { threshold: 30 } }
  return-statements: { config: { threshold: 4 } }
plugins:
  eslint: { enabled: true, channel: eslint-8 }
  duplication: { enabled: true, config: { languages: { javascript: { mass_threshold: 50 } } } }
exclude_patterns:
  - "test/"
  - "**/*.test.ts"
  - "dist/"
  - "node_modules/"
```

## Release Automation Tools

### semantic-release
```json
// .releaserc.json
{
  "branches": ["main", { "name": "beta", "prerelease": true }],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    ["@semantic-release/git", { "assets": ["CHANGELOG.md", "package.json"] }]
  ]
}
```
```yaml
# GitHub Actions integration
release:
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4
      with: { fetch-depth: 0 }
    - uses: actions/setup-node@v4
      with: { node-version: '22' }
    - run: npm ci
    - run: npx semantic-release
      env: { GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}', NPM_TOKEN: '${{ secrets.NPM_TOKEN }}' }
```

### changesets
```bash
# Developer adds a changeset
npx changeset
# Prompts: Which packages? Major/minor/patch? Description?
# Creates .changeset/happy-fish-dance.md

# CI: changesets bot creates "Version Packages" PR
# When merged: bumps versions, updates CHANGELOGs, publishes to npm
```

```yaml
# GitHub Actions with changesets
version-or-publish:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
      with: { fetch-depth: 0 }
    - uses: changesets/action@v1
      with:
        publish: npm run release
      env: { GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}', NPM_TOKEN: '${{ secrets.NPM_TOKEN }}' }
```

### release-please
```yaml
# GitHub Actions with release-please
release:
  runs-on: ubuntu-latest
  steps:
    - uses: googleapis/release-please-action@v4
      id: release
      with:
        release-type: node
    # Build and publish only when release is created
    - uses: actions/checkout@v4
      if: ${{ steps.release.outputs.release_created }}
    - run: npm ci && npm publish
      if: ${{ steps.release.outputs.release_created }}
```

## Deployment Tools
- **Terraform**: Infrastructure provisioning (HCL), state management, plan/apply workflow, modules
- **OpenTofu**: Open-source Terraform fork, MPL 2.0 license, drop-in replacement
- **Ansible**: Configuration management, agentless (SSH), playbooks, roles, Galaxy
- **Helm**: Kubernetes package management, charts, values overrides, hooks, rollback
- **Kustomize**: Kubernetes configuration customization, overlays, patches, built into kubectl
- **Pulumi**: Infrastructure as code with real programming languages (TypeScript, Python, Go, C#, Java)
- **CDK (AWS)**: Infrastructure as code with TypeScript/Python/Java/Go/.NET, synthesizes CloudFormation
- **CDKTF**: Terraform CDK -- use programming languages to define Terraform configurations
- **Skaffold**: Local Kubernetes development, build/deploy/debug loop, file watching
- **Tilt**: Local Kubernetes development, live update, multi-service, dashboard

## Quality Gates
- **Code coverage thresholds**: Fail if below 80% lines / 75% branches on new code
- **Static analysis**: SonarQube quality gate, CodeClimate maintainability grade
- **Security scanning**: 0 critical/high CVEs (Snyk, Trivy), 0 secrets detected (GitLeaks)
- **License compliance**: FOSSA, Snyk license policy -- no GPL in proprietary code
- **Performance regression**: Lighthouse CI budgets (LCP < 2.5s), benchmark regression detection
- **Bundle size**: Size Limit, Bundlewatch -- alert on significant increase
- **API compatibility**: Contract test results (Pact can-i-deploy), OpenAPI diff (oasdiff)
- **Accessibility**: axe-core, Pa11y -- WCAG 2.1 AA compliance checks in CI
