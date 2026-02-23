# GitLab CI Patterns

## DAG Pipelines (Directed Acyclic Graph)

```yaml
stages:
  - build
  - test
  - deploy

build-app:
  stage: build
  script: npm run build
  artifacts:
    paths: [dist/]

unit-tests:
  stage: test
  needs: [build-app]  # DAG: runs as soon as build-app finishes
  script: npm test

e2e-tests:
  stage: test
  needs: [build-app]
  script: npx playwright test

deploy:
  stage: deploy
  needs: [unit-tests, e2e-tests]
  script: ./deploy.sh
```

DAG cuts pipeline time by **30-50%** vs sequential stages.

## Includes and Extends

```yaml
# .gitlab/ci/templates.yml
.node-base:
  image: node:20-alpine
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths: [node_modules/]
  before_script:
    - npm ci

# .gitlab-ci.yml
include:
  - local: '.gitlab/ci/templates.yml'
  - project: 'devops/ci-templates'
    ref: main
    file: '/security-scan.yml'

test:
  extends: .node-base
  script: npm test
```

## Environments and Review Apps

```yaml
deploy-review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.example.com
    on_stop: stop-review
    auto_stop_in: 1 week
  rules:
    - if: $CI_MERGE_REQUEST_IID

stop-review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

## Auto DevOps

Enable for convention-over-configuration:
- Auto-detects language (Dockerfile, package.json, Gemfile)
- Runs SAST, dependency scanning, container scanning
- Deploys to k8s with Helm

Override stages selectively:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

test:
  script: npm run test:custom  # Override just the test stage
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Sequential stages without `needs` | Use DAG for parallelism |
| Duplicated config across jobs | Use `extends` and `include` |
| No `cache:policy` set | Use `pull-push` for default, `pull` for consumers |
| Missing `artifacts:expire_in` | Set expiry to avoid storage bloat |
| `only/except` keywords | Migrate to `rules` syntax |

## Quick Reference

- Max pipeline duration: **1 hour** (configurable)
- Max jobs per pipeline: **200** (SaaS)
- Cache key separator: `${CI_COMMIT_REF_SLUG}` is branch-safe
- Artifact max size: **1 GB** (SaaS default)
- DAG speedup: **30-50%** over sequential stages
