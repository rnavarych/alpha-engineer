---
name: release-strategies
description: |
  Release strategies: blue-green (instant rollback <30s), canary with traffic splitting,
  feature flags (OpenFeature), graceful shutdown (SIGTERM handler), database migration
  coordination with deploys, rollback procedures. Use when planning production deployments.
allowed-tools: Read, Grep, Glob
---

# Release Strategies

## When to Use This Skill
- Planning a production deployment
- Choosing between blue-green, canary, or rolling deploy
- Implementing graceful shutdown to avoid request drops
- Coordinating database migrations with application deploys
- Designing feature flag rollout strategy

## Core Principles

1. **Graceful shutdown always** — SIGTERM handler before any deployment
2. **Database migrations before app deploy** — backward-compatible migrations, then rolling deploy
3. **Blue-green for instant rollback** — keep old version live until new is proven
4. **Canary for high-risk changes** — route 5% of traffic first, monitor, then roll forward
5. **Feature flags decouple deploy from release** — ship code dark, enable gradually

---

## Patterns ✅

### Graceful Shutdown

Without graceful shutdown: deployment terminates containers mid-request. Users see errors. Payment transactions interrupted.

```typescript
// Handle SIGTERM before server starts
const server = app.listen(3000);

async function shutdown(signal: string) {
  logger.info({ signal }, 'Shutdown signal received');

  // 1. Stop accepting new connections
  server.close(async () => {
    logger.info('HTTP server closed');

    // 2. Wait for in-flight requests to complete (timeout: 30s)
    // 3. Close database connections
    await db.$disconnect();
    logger.info('Database connections closed');

    // 4. Close Redis connections
    await redis.quit();
    logger.info('Redis connections closed');

    // 5. Flush metrics and traces
    await metricsServer.close();

    logger.info('Graceful shutdown complete');
    process.exit(0);
  });

  // Force shutdown after 30 seconds if graceful fails
  setTimeout(() => {
    logger.error('Graceful shutdown timeout — forcing exit');
    process.exit(1);
  }, 30_000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

```yaml
# Kubernetes: give container time to drain
spec:
  containers:
    - name: app
      lifecycle:
        preStop:
          exec:
            command: ['/bin/sh', '-c', 'sleep 5']  # Wait for LB to stop sending traffic
  terminationGracePeriodSeconds: 60  # 60s total (preStop + shutdown)
```

### Blue-Green Deployment

```
Blue environment: current production (v1.2.3)
Green environment: new version (v1.2.4)

Steps:
1. Deploy v1.2.4 to green environment (zero traffic)
2. Run smoke tests against green
3. Switch load balancer: 100% traffic → green
4. Monitor green for 15 minutes
5. Keep blue running for 30 minutes (instant rollback if needed)
6. Decommission blue

Rollback: switch load balancer back to blue (<30 seconds)
```

```yaml
# Kubernetes: blue-green with label switching
# Blue deployment (current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 3
  selector:
    matchLabels: { app: myapp, version: blue }
  template:
    metadata:
      labels: { app: myapp, version: blue }
    spec:
      containers:
        - name: app
          image: myapp:v1.2.3

---
# Service points to either blue or green
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: blue  # Change to 'green' to switch traffic
```

### Canary Deployment (Kubernetes + Istio)

```yaml
# Route 5% of traffic to canary
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts: [myapp]
  http:
    - route:
        - destination:
            host: myapp-stable
            port: { number: 80 }
          weight: 95
        - destination:
            host: myapp-canary
            port: { number: 80 }
          weight: 5  # 5% to canary

---
# Progressive rollout: 5% → 25% → 50% → 100%
# After each stage: monitor error rate, latency P99, business metrics
# If error rate > SLO: rollback (weight back to 0)
# If stable: increase weight
```

**Canary monitoring checklist**:
- [ ] Error rate stays within SLO
- [ ] P99 latency ≤ baseline P99
- [ ] No increase in business error events (failed payments, etc.)
- [ ] Memory and CPU within expected range
- [ ] All health checks passing

### Feature Flags (OpenFeature)

```typescript
// Feature flags: deploy code "dark," enable gradually without deploy
import { OpenFeature } from '@opentelemetry/openfeature-node';

const client = OpenFeature.getClient('order-service');

// Use feature flag for new checkout flow
async function checkout(request: CheckoutRequest, userId: string) {
  const useNewCheckout = await client.getBooleanValue(
    'new-checkout-flow',
    false,  // Default: off
    { targetingKey: userId }  // User-based targeting
  );

  if (useNewCheckout) {
    return newCheckoutService.process(request);
  }
  return legacyCheckoutService.process(request);
}

// Flag configuration in LaunchDarkly/Unleash/Flagsmith:
// - Enable for 1% of users
// - Monitor error rate on new flow
// - Ramp to 10%, 25%, 50%, 100%
// - If issues: set to 0% instantly (no deploy needed)
```

### Database Migration Coordination

```
Rule: Migrations must be backward-compatible with the running application version.

Sequence for adding a NOT NULL column:
  Step 1: Deploy migration (add column nullable) — old app still works
  Step 2: Deploy app (writes to new column) — old migration still compatible
  Step 3: Deploy migration (backfill + add constraint) — new app is writing, safe to constrain
  Step 4: Cleanup

Never:
  - Deploy migration and app simultaneously in one step
  - Add NOT NULL column without backfill in the same deploy
  - Drop a column that the current running app still reads
```

```typescript
// Kubernetes init container: run migrations before app starts
// This ensures migrations run exactly once before new pods start
spec:
  initContainers:
    - name: migrate
      image: myapp:v1.2.4
      command: ['node', 'dist/scripts/migrate.js']
      env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
  containers:
    - name: app
      image: myapp:v1.2.4
```

---

## Anti-Patterns ❌

### No Graceful Shutdown
**What it is**: Container receives SIGTERM, process exits immediately.
**What breaks**: Kubernetes sends SIGTERM 30 seconds before traffic stops. Without graceful shutdown, in-flight requests are dropped, database connections not closed cleanly, users see 502 errors during every deploy.
**Fix**: SIGTERM handler that closes HTTP server, drains connections, then exits.

### Database Migration in Same Commit as Application Change
**What it is**: One PR adds `NOT NULL column` + updates app to use it, deployed together.
**What breaks**: Old app pods still running during deploy → they read from table that has new constraint they don't know about. Locks, errors, rollback hell.
**Fix**: Two-step: first deploy migration (backward-compatible), then deploy app.

### Deploying on Friday Afternoon
**What it is**: The Friday Deploy (see team history).
**What breaks**: Issues discovered Friday 5PM → engineers debug Saturday morning. On-call has weekend plans. Support team is minimal. Customer impact over weekend.
**Rule**: No Friday deploys after 3PM. No deploys before major holidays.

### Big Bang Feature Releases
**What it is**: Entire new feature ships to 100% of users simultaneously.
**What breaks**: Hidden edge case affects 1% of users → 100% of users experience rollout risk. No gradual validation. Rollback requires redeploy.
**Fix**: Feature flags — ship dark, enable for 1% → 10% → 100%.

---

## Quick Reference

```
Graceful shutdown: close HTTP server → drain DB connections → exit
Kubernetes terminationGracePeriodSeconds: 60 (preStop 5s + shutdown 30s + buffer)
Blue-green rollback: <30 seconds (load balancer switch)
Canary traffic: 5% → 25% → 50% → 100% with monitoring at each stage
Migration timing: migration PR merged, deployed, verified → then app PR
Feature flag ramp: 1% → 5% → 25% → 50% → 100% over hours/days
Friday deploy: no deploys after 3PM Friday
```
