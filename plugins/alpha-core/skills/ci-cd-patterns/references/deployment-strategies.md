# Deployment Strategies

## When to load
Load when choosing or implementing blue-green, canary, rolling, or progressive delivery strategies, or designing rollback procedures.

## Blue-Green
Two identical environments — blue (current) and green (new). Switch traffic atomically.

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

## Canary
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
```

- **Rollout schedule**: 5% -> 10% -> 25% -> 50% -> 100% with monitoring between each step
- **Automated analysis**: Compare error rate, latency p99, and success rate between canary and baseline
- **Automatic rollback**: If error rate > 1% or latency p99 > 2x baseline, rollback immediately

## Rolling
Update instances sequentially. Kubernetes default strategy.

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 2
  template:
    spec:
      containers:
        - name: app
          readinessProbe:
            httpGet: { path: /healthz, port: 8080 }
            initialDelaySeconds: 5
            periodSeconds: 10
```

- No extra infrastructure needed (just temporary surge capacity)
- Brief period with mixed versions — APIs must be backward-compatible
- Use readiness probes to prevent routing traffic to unready pods

## Recreate
Take down all instances, deploy new version. Simplest but causes downtime.
- Use only for: development environments, stateful apps that can't run mixed versions, batch jobs
- Never use for production services that require availability

## Progressive Delivery with Argo Rollouts

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
        - setWeight: 50
        - pause: { duration: 10m }
        - setWeight: 100
```

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
- Works as a first response while investigating issues
