# Kubernetes Manifests

## When to load
Load when writing Kubernetes deployments, services, or configuring resource management.

## Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
    version: v1.2.0
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-server
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # 1 extra pod during update
      maxUnavailable: 0    # zero downtime
  template:
    metadata:
      labels:
        app: api-server
        version: v1.2.0
    spec:
      serviceAccountName: api-server
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
        - name: api-server
          image: registry.example.com/api-server:v1.2.0  # always pin version
          ports:
            - containerPort: 3000
              protocol: TCP
          resources:
            requests:
              cpu: 250m        # 0.25 CPU cores
              memory: 256Mi
            limits:
              cpu: 1000m       # 1 CPU core
              memory: 512Mi    # OOMKilled if exceeded
          env:
            - name: NODE_ENV
              value: production
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: api-secrets
                  key: database-url
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health/live
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
          startupProbe:
            httpGet:
              path: /health/live
              port: 3000
            failureThreshold: 30    # 30 * 10s = 5min to start
            periodSeconds: 10
```

## Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-server
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: api-server
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
---
# External access via Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts: [api.example.com]
      secretName: api-tls
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-server
                port:
                  number: 80
```

## HPA (Horizontal Pod Autoscaler)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70  # scale up at 70% CPU
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # wait 5min before scaling down
```

## ConfigMap & Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  LOG_LEVEL: info
  CACHE_TTL: "3600"
---
apiVersion: v1
kind: Secret
metadata:
  name: api-secrets
type: Opaque
stringData:
  database-url: postgresql://user:pass@db:5432/app
  # In production: use External Secrets Operator or Sealed Secrets
```

## Resource Sizing Guide

```
Sizing strategy:
  1. Set requests = actual steady-state usage (measured)
  2. Set limits = peak usage + 20% headroom
  3. CPU limits: optional (can cause throttling)
  4. Memory limits: required (OOM protection)

Typical starting points:
  Small API:     requests 100m/128Mi, limits 500m/256Mi
  Medium API:    requests 250m/256Mi, limits 1000m/512Mi
  Worker:        requests 500m/512Mi, limits 2000m/1Gi
  Data service:  requests 1000m/1Gi, limits 4000m/4Gi

QoS classes:
  Guaranteed: requests == limits (first to get resources, last to evict)
  Burstable:  requests < limits (most common)
  BestEffort: no requests/limits (first to evict, avoid in production)
```

## Anti-patterns
- No resource requests/limits → pod scheduling chaos, noisy neighbors
- Using `latest` tag → non-reproducible deployments
- No readinessProbe → traffic sent to unready pods
- Secrets in ConfigMap → not base64-encoded or encrypted
- No PodDisruptionBudget → voluntary evictions can take down all replicas
- CPU limits on latency-sensitive services → throttling causes latency spikes

## Quick reference
```
Deployment: replicas + rolling update + probes + resources
Service: ClusterIP (internal), LoadBalancer (external), NodePort (dev)
Ingress: external HTTP routing, TLS, rate limiting
HPA: autoscale on CPU/memory/custom metrics, min 3 replicas
Probes: startup (slow init), readiness (traffic), liveness (restart)
Resources: requests for scheduling, limits for protection
Secrets: External Secrets Operator in production, never plain YAML
Namespaces: isolate environments (staging, production)
```
