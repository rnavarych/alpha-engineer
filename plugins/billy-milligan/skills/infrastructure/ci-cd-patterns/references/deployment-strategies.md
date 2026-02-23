# Deployment Strategies

## Blue-Green Deployment

Two identical environments; switch traffic atomically.

### Kubernetes

```yaml
# Switch service selector from blue to green
apiVersion: v1
kind: Service
metadata:
  name: app
spec:
  selector:
    app: myapp
    version: green  # Flip to "blue" for rollback
```

### AWS ECS (CodeDeploy)

```json
{
  "deploymentController": { "type": "CODE_DEPLOY" },
  "loadBalancers": [{
    "targetGroupArn": "arn:aws:...:tg-green",
    "containerName": "app",
    "containerPort": 3000
  }]
}
```

Pros: instant rollback, zero downtime. Cons: 2x infrastructure cost during deploy.

## Canary Deployment

Route a percentage of traffic to the new version; expand on success.

### Kubernetes (Istio)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  http:
    - route:
        - destination:
            host: app
            subset: stable
          weight: 90
        - destination:
            host: app
            subset: canary
          weight: 10
```

Ramp schedule: **1% -> 5% -> 25% -> 50% -> 100%** over 2-4 hours.

### Vercel

```bash
# Promote preview to production (atomic)
vercel promote <deployment-url>
# Instant rollback
vercel rollback
```

## Rolling Update

Replace instances incrementally. Default for k8s Deployments.

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%        # Extra pods during update
      maxUnavailable: 0     # Zero downtime
  minReadySeconds: 30       # Wait before marking ready
```

## Decision Matrix

| Strategy | Zero Downtime | Rollback Speed | Cost | Complexity |
|---|---|---|---|---|
| Blue-Green | Yes | Instant | High (2x) | Low |
| Canary | Yes | Fast (shift traffic) | Low (+N%) | High |
| Rolling | Yes | Slow (re-roll) | None | Low |
| Recreate | No | Slow | None | Minimal |

## Platform-Specific Rollback Commands

```bash
# Kubernetes rollback
kubectl rollout undo deployment/app
kubectl rollout status deployment/app

# AWS ECS rollback (CodeDeploy)
aws deploy stop-deployment --deployment-id d-ABC123

# Vercel rollback
vercel rollback --yes

# Heroku rollback
heroku releases:rollback v42
```

## Anti-patterns

| Anti-pattern | Why it breaks |
|---|---|
| Deploying without health checks | Canary cannot detect failures |
| No readiness probe | Traffic hits unready pods |
| Missing `minReadySeconds` | Rolling update too aggressive |
| Canary without metrics | No data to decide promote vs rollback |
| Blue-green without smoke tests | Switch to broken environment |
