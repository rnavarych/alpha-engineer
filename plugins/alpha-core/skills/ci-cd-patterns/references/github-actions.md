# GitHub Actions

## When to load
Load when writing or debugging GitHub Actions workflows, matrix builds, reusable workflows, or OIDC-based cloud auth.

## Build, Test, and Deploy Workflow
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

  build-and-push:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      id-token: write  # OIDC for keyless cloud auth
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
          tags: ${{ env.ECR_REGISTRY }}/my-app:${{ github.sha }}
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

## Matrix Build
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
    - run: npm ci && npm test
```

## Reusable Workflows
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

# Caller:
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with: { environment: staging, image-tag: '${{ github.sha }}' }
    secrets: { KUBECONFIG: '${{ secrets.STAGING_KUBECONFIG }}' }
```

## Key Features
- YAML workflows in `.github/workflows/`
- Matrix builds for multi-platform/version testing
- Reusable workflows and composite actions for DRY pipelines
- GitHub-hosted and self-hosted runners (including ARM, GPU)
- Built-in secrets management, OIDC for keyless cloud auth (AWS, GCP, Azure)
- Marketplace for pre-built actions (20,000+ actions)
- Environment protection rules with required reviewers and wait timers
- Concurrency control: cancel in-progress runs, queue deployments
