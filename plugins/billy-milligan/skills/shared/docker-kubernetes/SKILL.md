---
name: docker-kubernetes
description: |
  Docker and Kubernetes production patterns: multi-stage Dockerfile, distroless images,
  Kubernetes Deployment with resource limits, HPA, liveness/readiness/startup probes,
  ConfigMaps and Secrets, PodDisruptionBudget, NetworkPolicy, RBAC. Production checklist.
  Use when containerizing apps, writing K8s manifests, scaling workloads, hardening clusters.
allowed-tools: Read, Grep, Glob
---

# Docker & Kubernetes Production Patterns

## When to Use This Skill
- Writing production-grade Dockerfiles
- Creating Kubernetes Deployment manifests
- Configuring autoscaling with HPA
- Setting up liveness/readiness probes
- Hardening cluster security with RBAC and NetworkPolicy

## Core Principles

1. **Multi-stage builds for small images** — builder stage installs dependencies; final stage is minimal; 180MB vs 1.2GB
2. **Resource limits are mandatory** — no limits = one pod can starve all others on the node
3. **Readiness ≠ Liveness** — readiness controls traffic; liveness triggers restart; startup handles slow init
4. **Pods are ephemeral** — never store state in a pod; PVCs for persistence, external services for state
5. **Least privilege RBAC** — service accounts with minimum permissions; separate SA per service

---

## Patterns ✅

### Production Dockerfile (Node.js)

```dockerfile
# Build stage — install all dependencies, compile TypeScript
FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies first (cache layer)
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# Copy source and build
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# Prune dev dependencies
RUN npm ci --omit=dev --ignore-scripts

# Production stage — minimal image
FROM node:20-alpine AS production
WORKDIR /app

# Non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs nodejs

# Copy only production artifacts
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

USER nodejs
EXPOSE 3000

# Use dumb-init for proper signal handling (PID 1 problem)
# Without it: SIGTERM not forwarded to Node.js; 30s graceful shutdown ignored
RUN apk add --no-cache dumb-init
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

```dockerfile
# Ultra-minimal Go distroless (~20MB vs 300MB with Alpine)
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server ./cmd/server

FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Kubernetes Deployment — Production Grade

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: production
  labels:
    app: order-service
    version: "1.5.2"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0      # Zero-downtime: no pod removed before new one is ready
      maxSurge: 1            # One extra pod during deployment
  template:
    metadata:
      labels:
        app: order-service
        version: "1.5.2"
    spec:
      serviceAccountName: order-service-sa  # Dedicated SA — not default
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
        - name: order-service
          image: gcr.io/myproject/order-service:1.5.2  # Pin exact tag — never :latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "100m"      # 0.1 CPU core guaranteed
              memory: "128Mi"
            limits:
              cpu: "500m"      # 0.5 CPU core max
              memory: "512Mi"  # OOMKilled if exceeded — choose carefully
          env:
            - name: NODE_ENV
              value: "production"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: order-service-secrets
                  key: database-url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: order-service-secrets
                  key: redis-url
          # Startup probe: for slow-starting apps (DB migrations)
          # K8s won't run liveness until startup succeeds
          startupProbe:
            httpGet:
              path: /health/startup
              port: 3000
            failureThreshold: 30   # 30 × 10s = 5 minutes max startup time
            periodSeconds: 10
          # Readiness probe: controls traffic routing
          # Failing = removed from Service endpoints (not restarted)
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 3    # 30s failing → removed from rotation
          # Liveness probe: controls restart
          # Failing = pod restarted
          livenessProbe:
            httpGet:
              path: /health/live
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 30
            failureThreshold: 3    # 90s failing → restart
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: order-service
      # Graceful shutdown: wait for requests to complete
      terminationGracePeriodSeconds: 60
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70    # Scale up when CPU avg >70%
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60    # Wait 60s before scaling up again
      policies:
        - type: Pods
          value: 3
          periodSeconds: 60             # Add max 3 pods per 60s
    scaleDown:
      stabilizationWindowSeconds: 300   # Wait 5 minutes before scaling down
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60             # Remove max 1 pod per 60s
```

### PodDisruptionBudget (Zero-Downtime During Node Maintenance)

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service-pdb
  namespace: production
spec:
  minAvailable: 2         # Always keep 2 pods running during voluntary disruptions
  selector:
    matchLabels:
      app: order-service
# During node drain: K8s waits for new pod to be ready before evicting old one
```

### Health Check Endpoints

```typescript
// Three probes, three endpoints
app.get('/health/startup', (req, res) => {
  // Called during startup — check DB connectivity
  try {
    await db.execute(sql`SELECT 1`);
    res.status(200).json({ status: 'starting' });
  } catch {
    res.status(503).json({ status: 'not ready' });
  }
});

app.get('/health/ready', (req, res) => {
  // Called continuously — check if pod can serve traffic
  // Fail if: DB pool exhausted, cache unreachable, degraded state
  const checks = {
    db: dbPool.totalCount < dbPool.options.max! * 0.9,  // Not >90% pool used
    cache: redisClient.isReady,
  };
  const healthy = Object.values(checks).every(Boolean);
  res.status(healthy ? 200 : 503).json({ status: healthy ? 'ready' : 'not ready', checks });
});

app.get('/health/live', (req, res) => {
  // Called continuously — check if process is alive (not deadlocked)
  // Should NOT check external dependencies — don't restart pod for DB outage
  res.status(200).json({ status: 'alive', uptime: process.uptime() });
});
```

---

## Anti-Patterns ❌

### Running as Root in Container
**What it is**: No `USER` directive in Dockerfile; container runs as root (UID 0).
**What breaks**: Container escape vulnerability gives attacker root on host node. Violates Pod Security Standards (restricted profile).
**Fix**: `RUN adduser --system --uid 1001 appuser && USER appuser`

### No Resource Limits
**What it is**: Deployment with no `resources.limits` defined.
**What breaks**: Memory leak in one pod = OOM killer evicts other pods on the node. CPU hog = latency spikes for neighbors.
**Fix**: Always set requests and limits. Start with 10× requests = limits, then tune based on actual usage.

### Using `:latest` Tag
**What it is**: `image: myapp:latest` in deployment manifest.
**What breaks**: Rollback is impossible — `:latest` is different between deploys. `kubectl rollout undo` may pull a different image than expected.
**Fix**: Always pin to immutable tags: `myapp:1.5.2` or `myapp:sha256-abc123def456`.

---

## Quick Reference

```
Multi-stage: builder installs deps + compiles; final stage copies artifacts only
Distroless: Go/Java images ~20MB; use gcr.io/distroless/static-debian12
Resource limits: always set; 10× requests = limits as starting point
Probes: startup (slow init), readiness (traffic), liveness (restart)
RollingUpdate: maxUnavailable=0 + maxSurge=1 for zero-downtime
PDB: minAvailable=2 prevents full disruption during node drain
HPA: scaleDown stabilization 300s prevents flapping
Image tags: never :latest; pin to semver or digest
Non-root: adduser + USER directive in all Dockerfiles
terminationGracePeriodSeconds: ≥30s (match app graceful shutdown timeout)
```
