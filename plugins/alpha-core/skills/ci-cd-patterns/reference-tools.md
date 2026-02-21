# CI/CD Tools Reference

## GitHub Actions
- YAML workflows in `.github/workflows/`
- Matrix builds for multi-platform/version testing
- Reusable workflows and composite actions
- GitHub-hosted and self-hosted runners
- Built-in secrets management, OIDC for cloud auth
- Marketplace for pre-built actions

## GitLab CI
- `.gitlab-ci.yml` configuration
- Stages, jobs, rules, artifacts
- Auto DevOps for automated pipeline generation
- Built-in container registry, security scanning
- Environments with review apps

## Jenkins
- Jenkinsfile (declarative or scripted pipeline)
- Plugin ecosystem (1800+ plugins)
- Distributed builds with agents
- Blue Ocean UI for pipeline visualization
- Best for complex, custom pipeline requirements

## ArgoCD / Flux
- GitOps-based continuous delivery
- Kubernetes-native deployment
- Declarative configuration in git
- Automatic sync and drift detection
- Progressive delivery with Argo Rollouts

## CircleCI
- `.circleci/config.yml`
- Orbs for reusable configuration
- Docker layer caching
- Insights for pipeline optimization

## Deployment Tools
- **Terraform**: Infrastructure provisioning
- **Ansible**: Configuration management
- **Helm**: Kubernetes package management
- **Kustomize**: Kubernetes configuration customization
- **Pulumi**: Infrastructure as code with real programming languages

## Quality Gates
- Code coverage thresholds (fail if below 80%)
- Static analysis (SonarQube, CodeClimate)
- Security scanning (Snyk, Trivy, OWASP Dependency-Check)
- License compliance checking
- Performance regression detection
