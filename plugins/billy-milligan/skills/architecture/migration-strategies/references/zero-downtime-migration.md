# Zero-Downtime Deployment & Migration

## When to load
Load when discussing blue-green deployments, canary rollouts, rolling updates, or rollback procedures.

## Patterns

### Blue-green deployment
```
Setup: two identical environments (blue = current, green = new)

1. Green environment deployed with new version
2. Run smoke tests against green
3. Switch load balancer/DNS to green
4. Monitor for 15-30 minutes
5. If issues: switch back to blue (instant rollback)
6. If stable: blue becomes next green

DNS switch: Route53 weighted routing 0/100 -> 100/0
ALB switch: update target group
```

```yaml
# AWS ALB target group switching
resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.front_end.arn
  action {
    type             = "forward"
    target_group_arn = var.active_color == "blue"
      ? aws_lb_target_group.blue.arn
      : aws_lb_target_group.green.arn
  }
}

# Kubernetes: use Argo Rollouts for blue-green
# apiVersion: argoproj.io/v1alpha1
# kind: Rollout
# spec:
#   strategy:
#     blueGreen:
#       activeService: app-active
#       previewService: app-preview
#       autoPromotionEnabled: false
```

Pros: instant rollback, full environment testing. Cons: 2x infrastructure cost during deployment.

### Canary rollout (1% -> 10% -> 50% -> 100%)
```yaml
# Kubernetes: Argo Rollouts canary
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app
spec:
  strategy:
    canary:
      steps:
        - setWeight: 1          # 1% traffic to canary
        - pause: { duration: 5m }
        - analysis:             # automated checks
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: web-app
        - setWeight: 10         # 10% if analysis passes
        - pause: { duration: 10m }
        - setWeight: 50
        - pause: { duration: 15m }
        - setWeight: 100        # full rollout

---
# Analysis template: auto-rollback if error rate > 1%
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  metrics:
    - name: success-rate
      interval: 60s
      successCondition: result[0] > 0.99
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(http_requests_total{service="{{args.service-name}}",status=~"2.."}[2m]))
            /
            sum(rate(http_requests_total{service="{{args.service-name}}"}[2m]))
```

```
Canary schedule:
1%  for  5 min -> check error rate, latency p99
10% for 10 min -> check business metrics (conversion, revenue)
50% for 15 min -> check resource utilization, no degradation
100% -> full rollout, keep old version for 1 hour rollback window
```

### Rolling update (Kubernetes default)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # add 1 extra pod during update
      maxUnavailable: 0    # never reduce below desired count
  template:
    spec:
      containers:
        - name: app
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 5
          lifecycle:
            preStop:
              exec:
                command: ["sh", "-c", "sleep 10"]  # drain connections
      terminationGracePeriodSeconds: 30
```

### Rollback procedures by platform

```bash
# Kubernetes: instant rollback to previous revision
kubectl rollout undo deployment/web-app
kubectl rollout undo deployment/web-app --to-revision=3

# Argo Rollouts: abort canary
kubectl argo rollouts abort web-app

# AWS ECS: update service to previous task definition
aws ecs update-service --cluster prod --service web-app \
  --task-definition web-app:42  # previous version

# Docker Compose: rollback to previous image tag
docker compose pull  # with previous tag in .env
docker compose up -d --remove-orphans

# Vercel: instant rollback to previous deployment
vercel rollback [deployment-url]
```

### Feature flags for risky changes
```typescript
// Decouple deployment from feature activation
import { LaunchDarkly } from 'launchdarkly-node-server-sdk';

const ldClient = LaunchDarkly.init(process.env.LD_SDK_KEY);

async function processPayment(order: Order) {
  const useNewProvider = await ldClient.variation(
    'new-payment-provider',
    { key: order.userId },
    false  // default: old provider
  );

  if (useNewProvider) {
    return newPaymentProvider.charge(order);
  }
  return legacyPaymentProvider.charge(order);
}

// Rollout plan:
// 1. Deploy code with flag OFF (no behavior change)
// 2. Enable for internal users (10 people)
// 3. Enable for 1% of users
// 4. Ramp to 10%, 50%, 100% over 2 weeks
// 5. Remove flag and old code path after 30 days
```

## Anti-patterns
- Deploying with no rollback plan -> stuck with broken production
- Rolling update with maxUnavailable > 0 and no readiness probe -> serves broken responses
- Canary without automated analysis -> nobody watches at 3 AM
- Feature flags that never get cleaned up -> code becomes unmaintainable

## Decision criteria
- **Rolling update**: default for Kubernetes, simple, good for low-risk changes
- **Canary**: high-risk changes, need gradual validation, have metrics/analysis
- **Blue-green**: need instant rollback, database-compatible changes, can afford 2x infra
- **Feature flags**: business logic changes, A/B testing, need instant kill switch

## Quick reference
```
Rolling update: default, maxSurge=1, maxUnavailable=0
Canary: 1% -> 10% -> 50% -> 100%, auto-analyze between steps
Blue-green: instant switch, 2x infra cost, instant rollback
Feature flags: deploy OFF, ramp gradually, clean up within 30 days
Rollback: kubectl rollout undo / vercel rollback / previous task def
Readiness probe: required for zero-downtime, check every 5s
Graceful shutdown: preStop sleep 10s + terminationGracePeriod 30s
Monitor after deploy: error rate, latency p99, business metrics
```
