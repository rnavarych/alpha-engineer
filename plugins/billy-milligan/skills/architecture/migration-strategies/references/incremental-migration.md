# Incremental Migration Approach

## When to load
Load when planning a step-by-step incremental migration, rollback strategy, migration timelines, or the general rules for safely moving from one system to another.

## Patterns

### General incremental migration rules
```
1. Strangler fig: new system wraps old, routes traffic gradually
2. One direction only: never migrate back and forth
3. Shared nothing: migrated code should not depend on legacy internals
4. Feature parity: migrated route must pass all existing tests
5. Monitoring: compare latency/errors between old and new paths
6. Rollback: keep old path functional until new is proven (2+ weeks)
7. Clean up: remove old code within 30 days of full migration
```

### Migration timeline template
```
Week 1-2:   Set up new system alongside old, proxy/fallback in place
Week 3-4:   Migrate 2-3 lowest-risk pages/routes/endpoints
Week 5-8:   Migrate remaining pages; performance and parity validation
Week 9-12:  Direct dependencies from new system, remove proxies
Post-12:    Keep old system on standby for 2 weeks, then decommission

Do NOT:
- Replace external/B2B-facing contracts mid-migration
- Migrate everything in one release (page by page, route by route)
- Skip monitoring comparison between old and new paths
```

### Rollback plan template
```
Before any migration step:
1. Identify the rollback trigger (error rate, latency, failed tests)
2. Keep old code path deployable independently
3. Feature flag the new path (flip off = instant rollback)
4. Test rollback in staging before migrating production

Rollback execution:
1. Flip feature flag off (or revert router config)
2. Verify old path serves traffic (monitor 5 min)
3. Alert team, open incident ticket
4. Investigate before re-attempting migration
```

```typescript
// Feature flag for migration routing
// Controls which system handles requests during transition
const USE_NEW_SYSTEM = process.env.MIGRATION_FLAG === 'new';

export async function handleRequest(req: Request) {
  if (USE_NEW_SYSTEM) {
    return newSystemHandler(req);
  }
  return legacyHandler(req);
}

// Deploy with MIGRATION_FLAG=legacy first
// Gradually roll to MIGRATION_FLAG=new via canary or env config
// Rollback: set MIGRATION_FLAG=legacy, no redeploy needed if env-driven
```

### Monitoring during migration
```typescript
// Compare latency and error rates between old and new paths
// Emit consistent metrics from both paths so you can diff them

logger.info({
  event: 'request.handled',
  path: req.path,
  system: USE_NEW_SYSTEM ? 'new' : 'legacy',
  durationMs: Date.now() - startTime,
  statusCode: res.statusCode,
});

// Dashboard: overlay old vs new latency p50/p95/p99
// Alert if: new path error rate > old path error rate + 1%
// Alert if: new path p95 latency > old path p95 latency * 1.2
```

### Parallel run (shadow mode)
```typescript
// Send traffic to both systems, compare responses without serving new output
async function shadowMigration(req: Request): Promise<Response> {
  const [legacyResult, newResult] = await Promise.allSettled([
    legacyHandler(req),
    newSystemHandler(req),  // shadow: result discarded
  ]);

  // Log discrepancies for investigation
  if (legacyResult.status === 'fulfilled' && newResult.status === 'fulfilled') {
    const match = deepEqual(legacyResult.value, newResult.value);
    if (!match) {
      logger.warn({
        event: 'shadow.mismatch',
        path: req.path,
        legacy: legacyResult.value,
        newSystem: newResult.value,
      });
    }
  }

  // Always serve legacy response during shadow phase
  return legacyResult.status === 'fulfilled'
    ? legacyResult.value
    : Promise.reject(legacyResult.reason);
}
```

## Anti-patterns
- No rollback plan -> stuck when something breaks at 2 AM
- Skipping shadow mode for critical paths -> discover differences in production
- Removing legacy code before 2-week stability window -> no way back
- Migrating without feature flags -> rollback requires a full redeploy

## Quick reference
```
Shadow mode: run both, serve legacy, log diffs
Feature flag: MIGRATION_FLAG env var, flip = instant rollback
Stability window: 2 weeks before decommissioning old path
Monitoring: overlay old vs new p50/p95/p99, alert on divergence
Rollback trigger: define before starting, not during incident
Clean up: remove old code within 30 days or it becomes permanent
```
