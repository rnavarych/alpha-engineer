# GitLab CI and Jenkins

## When to load
Load when configuring GitLab CI pipelines, working with Jenkins Jenkinsfiles, or comparing CI platform capabilities.

## GitLab CI Configuration
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

## GitLab CI Key Features
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

## CircleCI
- `.circleci/config.yml` configuration
- Orbs for reusable configuration (pre-packaged pipeline blocks)
- Docker layer caching for faster builds
- Insights for pipeline optimization (bottleneck detection, flaky test detection)
- Dynamic configuration with setup workflows
- Resource classes for different compute sizes (small to 2xlarge+)

## Quality Gate Tool Configuration

### SonarQube
```yaml
# sonar-project.properties
sonar.projectKey=my-app
sonar.sources=src
sonar.tests=test
sonar.typescript.lcov.reportPaths=coverage/lcov.info
sonar.coverage.exclusions=**/*.test.ts,**/*.spec.ts
sonar.qualitygate.wait=true
```

### CodeClimate
```yaml
# .codeclimate.yml
version: "2"
checks:
  argument-count: { config: { threshold: 4 } }
  complex-logic: { config: { threshold: 4 } }
  file-lines: { config: { threshold: 300 } }
  method-complexity: { config: { threshold: 10 } }
  method-lines: { config: { threshold: 30 } }
plugins:
  eslint: { enabled: true, channel: eslint-8 }
exclude_patterns:
  - "test/"
  - "**/*.test.ts"
  - "dist/"
  - "node_modules/"
```
