---
name: pipeline-designer
description: |
  CI/CD pipeline design expertise covering GitHub Actions, GitLab CI, Jenkins,
  CircleCI, ArgoCD, and Flux. Includes pipeline stages, deployment strategies,
  caching, artifact management, secrets in CI, and environment promotion.
allowed-tools: Read, Grep, Glob, Bash
---

# Pipeline Designer

## Pipeline Architecture

- Design pipelines with clear stages: **lint** -> **test** -> **build** -> **security scan** -> **deploy staging** -> **integration test** -> **deploy production**.
- Each stage should be independently re-runnable. Avoid coupling between stages beyond artifact passing.
- Fail fast: run linting and unit tests before expensive build and integration steps.
- Use pipeline-as-code exclusively. Define pipelines in version-controlled YAML files alongside the application code.

## GitHub Actions

- Use reusable workflows (`workflow_call`) and composite actions to share pipeline logic across repositories.
- Pin action versions to commit SHAs, not tags, for supply-chain security: `uses: actions/checkout@abc123`.
- Leverage `concurrency` groups to cancel redundant runs on the same branch.
- Use `GITHUB_TOKEN` with minimal permissions via the `permissions` key. Avoid long-lived PATs.
- Cache dependencies with `actions/cache` keyed on lockfile hashes. Use `actions/setup-*` for language toolchains.

## GitLab CI

- Use `extends` and `include` to compose pipelines from shared templates. Store templates in a dedicated CI library project.
- Define `rules` instead of `only/except` for clearer, more maintainable pipeline conditions.
- Leverage `needs` for DAG-based execution to parallelize independent jobs without waiting for an entire stage.
- Use GitLab environments for deployment tracking and manual approval gates.

## Jenkins

- Prefer **Declarative Pipelines** in `Jenkinsfile` over scripted pipelines for readability and maintainability.
- Use shared libraries for common pipeline steps. Version them and load with `@Library('shared-lib@v1.0')`.
- Run agents as ephemeral containers (Kubernetes plugin) instead of persistent VMs to reduce drift and maintenance.
- Secure credentials with Jenkins Credentials Store and inject them only into the stages that need them.

## ArgoCD and Flux (GitOps)

- **ArgoCD**: define `Application` or `ApplicationSet` manifests pointing to Git repositories. Enable auto-sync with self-heal for production.
- **Flux**: use `GitRepository`, `Kustomization`, and `HelmRelease` CRDs for declarative delivery.
- Separate application code repositories from GitOps deployment repositories. CI pushes image tags; CD reconciles desired state.
- Implement progressive delivery with Argo Rollouts for canary and blue-green strategies integrated into GitOps.

## Deployment Strategies

- **Rolling Update**: default Kubernetes strategy. Gradually replaces old pods. Set `maxSurge` and `maxUnavailable` for control.
- **Blue-Green**: run two identical environments. Switch traffic via load balancer or DNS. Instant rollback by switching back.
- **Canary**: route a small percentage of traffic to the new version. Monitor error rates and latency. Promote or rollback based on metrics.
- **Feature Flags**: decouple deployment from release. Deploy code that is inactive until the flag is enabled. Allows per-user or percentage-based rollouts.

## Parallel Jobs and Matrix Builds

- Use matrix strategies to test across multiple language versions, OS platforms, or dependency sets in parallel.
- Split large test suites across parallel runners using test splitting tools (Jest sharding, pytest-xdist, CircleCI test splitting).
- Run independent stages concurrently: security scanning alongside unit tests, not after them.

## Caching and Artifacts

- Cache dependency directories (node_modules, .m2, pip cache) keyed on lockfile content for reproducible, fast builds.
- Store build artifacts (binaries, Docker images, test reports) and pass them between stages rather than rebuilding.
- Set artifact retention policies: short for PR builds (1-3 days), longer for release builds (30-90 days).

## Secrets in CI

- Never hardcode secrets in pipeline files. Use the platform's secret store (GitHub Secrets, GitLab CI Variables, Jenkins Credentials).
- Scope secrets to the minimum: repository-level, not organization-level, unless truly shared.
- Mask secrets in logs. Most CI platforms do this automatically for declared secrets; verify with a test run.
- Rotate CI secrets on a schedule and when team members leave.

## Quality Gates and Environment Promotion

- Define quality gates: minimum code coverage, zero critical vulnerabilities, all tests passing, performance budget met.
- Promotion flow: merge to `main` deploys to staging automatically. Production requires manual approval or automated canary validation.
- Use environment protection rules (GitHub) or manual gates (GitLab) to prevent unauthorized production deployments.
- Tag releases with semantic versions. Keep a changelog generated from conventional commits.

## Best Practices Checklist

1. Pipeline defined as code in the repository
2. Fail fast with lint and test stages first
3. Actions/images pinned to immutable references
4. Secrets injected from platform secret stores
5. Caching enabled for dependency installation
6. Deployment strategy appropriate for the service
7. Quality gates enforced before production
8. Pipeline runs are idempotent and re-runnable
