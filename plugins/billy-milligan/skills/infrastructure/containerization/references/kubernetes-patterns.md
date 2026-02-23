# Kubernetes Patterns

## Deployment with Best Practices

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: app
          image: myapp:v1.2.3
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health/live
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 15
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 2
          env:
            - name: NODE_ENV
              value: production
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url
      terminationGracePeriodSeconds: 60
```

## HPA (Horizontal Pod Autoscaler)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Pods
          value: 4
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
```

## Resource Limits

```
Sizing guidelines:
  requests = what scheduler guarantees (set to average usage)
  limits   = hard cap (set to peak usage + buffer)

  requests too low  -> pod scheduled on overloaded node -> throttling
  requests too high -> wasted cluster capacity
  limits too low    -> OOMKilled under load
  no limits set     -> one pod starves the entire node

Recommended ratios:
  CPU:    limits = 2x requests
  Memory: limits = 1.5-2x requests

Start conservative, tune with VPA recommendations after 7 days.
```

## Health Checks

```
livenessProbe:  "Is the process alive?"
  Failure: kubelet kills the container and restarts it.
  Use for: deadlock detection, hung processes.
  DO NOT check dependencies (DB, Redis) here -- restart won't fix them.

readinessProbe: "Can the process handle traffic?"
  Failure: pod removed from Service endpoints (no traffic routed).
  Use for: dependency checks, warmup completion.

startupProbe:   "Has the process finished starting?"
  Failure: kubelet kills the container.
  Use for: slow-starting apps (JVM warmup, large model loading).
  While running: liveness and readiness probes are disabled.
```

## RBAC

```yaml
# Least-privilege ServiceAccount for app
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
    resourceNames: ["app-config"]  # Named access only
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-binding
subjects:
  - kind: ServiceAccount
    name: app-sa
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| No resource requests/limits | Always set both; use VPA for tuning |
| Liveness probe checks DB | Only check process health; use readiness for deps |
| Single replica in production | Minimum 3 replicas for HA |
| Default ServiceAccount | Create dedicated SA with least-privilege RBAC |
| No PodDisruptionBudget | Set `minAvailable: 2` for production workloads |

## Quick Reference

- Replicas minimum: **3** for production
- CPU request: set to **average** usage; limit at **2x**
- Memory request: set to **average** usage; limit at **1.5-2x**
- HPA target CPU: **70%** utilization
- Scale-down stabilization: **300s** (prevent flapping)
- terminationGracePeriodSeconds: **60** (match app shutdown time)
