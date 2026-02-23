# Rollback Procedures

## Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/app

# Rollback to previous version
kubectl rollout undo deployment/app

# Rollback to specific revision
kubectl rollout undo deployment/app --to-revision=3

# Verify rollback status
kubectl rollout status deployment/app

# Check which image is running
kubectl get deployment app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Time to rollback: **30-60 seconds** (depends on readiness probe timing).

## Vercel Rollback

```bash
# List recent deployments
vercel ls

# Rollback to previous deployment
vercel rollback

# Rollback to specific deployment
vercel rollback <deployment-url>

# Promote a specific deployment to production
vercel promote <deployment-url>
```

Time to rollback: **instant** (DNS switch to previous immutable deployment).

## AWS ECS Rollback

```bash
# List recent task definitions
aws ecs list-task-definitions --family-prefix myapp --sort DESC --max-items 5

# Update service to previous task definition
aws ecs update-service \
  --cluster production \
  --service myapp \
  --task-definition myapp:42  # Previous revision number

# If using CodeDeploy: stop and rollback
aws deploy stop-deployment --deployment-id d-ABC123 --auto-rollback-enabled
```

Time to rollback: **2-5 minutes** (new tasks must start and pass health checks).

## Database Rollback

```bash
# Prisma: rollback last migration
npx prisma migrate resolve --rolled-back "20240215_add_column"

# Knex: rollback last batch
npx knex migrate:rollback

# Flyway: undo last migration (if undo scripts exist)
flyway undo

# Raw SQL: always write down migrations
```

### Safe Migration Rollback Pattern

```
Forward migration:
  ALTER TABLE orders ADD COLUMN discount_code VARCHAR(50);

Rollback migration:
  ALTER TABLE orders DROP COLUMN discount_code;

Rule: every migration MUST have a corresponding rollback script.
Rule: never drop columns/tables in the same deploy that stops writing to them.
```

### Two-Phase Migration for Breaking Changes

```
Phase 1 (deploy migration):
  - Add new column (nullable)
  - Old app continues to work (ignores new column)

Phase 2 (deploy app):
  - New app writes to both old and new columns
  - Background job backfills new column

Phase 3 (deploy cleanup):
  - Remove old column references from app
  - Add NOT NULL constraint
  - Drop old column

Rollback at any phase:
  Phase 1: drop new column
  Phase 2: rollback app (old app ignores new column)
  Phase 3: rollback app + migration
```

## Feature Flag Kill Switch

```typescript
// Fastest rollback: no deploy needed
// Set feature flag to false/0%

// LaunchDarkly
await ldClient.variation('new-checkout-flow', context, false);
// In LaunchDarkly dashboard: toggle off or set rollout to 0%

// Unleash
// In Unleash UI: disable the feature toggle

// Homegrown
await redis.set('flag:new-checkout-flow', 'false');
```

Time to rollback: **seconds** (propagation time of flag system).

## Rollback Decision Matrix

| Scenario | Rollback Method | Time | Risk |
|---|---|---|---|
| Bad deploy, no DB changes | k8s rollout undo / Vercel rollback | Seconds-minutes | Low |
| Bad deploy + DB migration | Rollback app, then migration | Minutes | Medium |
| Feature causing errors | Feature flag kill switch | Seconds | Low |
| Data corruption | Restore from backup + point-in-time recovery | Hours | High |
| Third-party dependency down | Feature flag off + fallback | Seconds | Low |

## Pre-Rollback Checklist

```
Before rolling back:
  [ ] Confirm the issue is caused by the new deploy (not upstream)
  [ ] Check if database migration is involved (separate rollback needed)
  [ ] Notify team in incident channel
  [ ] Capture current error logs and metrics for postmortem

After rolling back:
  [ ] Verify service health (health check endpoint, metrics)
  [ ] Confirm error rate returned to baseline
  [ ] Update incident channel with status
  [ ] Create ticket for root cause investigation
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| No rollback plan before deploy | Every deploy needs documented rollback steps |
| Rolling back DB + app simultaneously | Roll back app first, then DB if needed |
| Feature flag without kill switch | Every flag must be instantly disable-able |
| No deployment history retained | Keep last 5+ revisions (k8s: `revisionHistoryLimit`) |
| Rollback without verification | Always check health endpoint after rollback |
