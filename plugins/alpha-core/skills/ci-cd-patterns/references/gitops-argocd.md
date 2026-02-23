# GitOps: ArgoCD and Flux

## When to load
Load when setting up GitOps workflows, configuring ArgoCD or Flux, implementing canary analysis with Argo Rollouts, or managing multi-cluster deployments.

## GitOps Principles
- Git is the single source of truth for declarative infrastructure and applications
- All changes go through pull requests — auditable, reviewable, reversible
- Automated reconciliation: system state converges to desired state in git
- No manual `kubectl apply` or SSH to production servers

## ArgoCD Setup
```yaml
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
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff: { duration: 5s, factor: 2, maxDuration: 3m }
```

## ArgoCD CLI Setup
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
argocd login localhost:8080
argocd app create my-app \
  --repo https://github.com/org/k8s-configs.git \
  --path environments/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace my-app \
  --sync-policy automated --self-heal --auto-prune
```

## ArgoCD ApplicationSets (Multi-cluster)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
spec:
  generators:
    - list:
        elements:
          - cluster: staging
            url: https://staging.k8s.example.com
          - cluster: production
            url: https://production.k8s.example.com
  template:
    spec:
      source:
        path: 'environments/{{cluster}}/my-app'
      destination:
        server: '{{url}}'
```

## Flux CD Setup
```bash
flux bootstrap github \
  --owner=my-org --repository=fleet-infra \
  --branch=main --path=./clusters/production --personal

flux create source git my-app \
  --url=https://github.com/org/k8s-configs.git \
  --branch=main --interval=1m

flux create kustomization my-app \
  --source=GitRepository/my-app \
  --path="./environments/production" \
  --prune=true --interval=5m \
  --health-check="Deployment/my-app.my-app"
```

## Argo Rollouts Canary Analysis
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: canary-analysis
spec:
  metrics:
    - name: error-rate
      interval: 2m
      count: 5
      successCondition: result[0] < 0.01
      failureLimit: 2
      provider:
        prometheus:
          address: http://prometheus.monitoring:9090
          query: |
            sum(rate(http_requests_total{status=~"5.*",service="{{args.service-name}}"}[5m]))
            /
            sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
    - name: latency-p99
      interval: 2m
      successCondition: result[0] < 500
      provider:
        prometheus:
          query: |
            histogram_quantile(0.99,
              sum(rate(http_request_duration_seconds_bucket{service="{{args.service-name}}"}[5m]))
              by (le))
```

## Repository Structure (App Repo vs Config Repo)
```
# App repo (source code + CI)
my-app/
  src/
  Dockerfile
  .github/workflows/ci.yml

# Config repo (Kubernetes manifests + CD)
k8s-configs/
  environments/
    dev/my-app/
    staging/my-app/kustomization.yaml
    production/my-app/kustomization.yaml
  base/my-app/
```

## Drift Detection
- ArgoCD: Compares live state vs desired state, shows diff in UI, auto-heals if configured
- Flux: Reconciliation loop every N minutes, reverts manual changes
- Alert on drift: Slack/PagerDuty notification when live state diverges from git
