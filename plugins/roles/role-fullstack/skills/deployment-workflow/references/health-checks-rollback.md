# Health Checks and Rollback Procedures

## When to load
Load when implementing health check endpoints, planning rollback strategies, or configuring load balancer routing.

## Health Checks

```typescript
// /api/health endpoint
export async function GET() {
  const checks = {
    database: await checkDatabase(),
    cache: await checkRedis(),
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  };
  const healthy = Object.values(checks).every((v) => v !== false);
  return Response.json(checks, { status: healthy ? 200 : 503 });
}
```

- Return HTTP 200 when healthy, 503 when degraded.
- Check all critical dependencies: database, cache, external APIs.
- Keep the health endpoint fast — set a short timeout per dependency check (1-2 seconds).
- Separate liveness (`/api/health/live`) from readiness (`/api/health/ready`) for Kubernetes deployments.

## Rollback Procedures

- **Vercel/Netlify** — instant rollback to any previous deployment from the dashboard.
- **Docker** — tag images with git SHA. Rollback by redeploying the previous image tag.
- **Database** — rollback migrations are risky. Prefer forward-only migrations with the expand-contract pattern.
- Document the rollback procedure in a runbook. Practice it before you need it.

## Runbook Checklist

1. Identify the failing deployment (metrics, logs, error rate spike).
2. Trigger rollback to the last known-good deployment SHA.
3. Verify health checks pass after rollback.
4. Notify the team via incident channel.
5. Post-mortem: identify root cause and add a regression test.
