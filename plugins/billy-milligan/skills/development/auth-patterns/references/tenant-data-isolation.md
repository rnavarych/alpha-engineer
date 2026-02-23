# Tenant Data Isolation

## Isolation Strategy Comparison

```
Three approaches — pick based on tenant count and data sensitivity:

1. Shared schema (row-level):
   - All tenants in same tables, filtered by tenant_id column
   - Best for: SaaS with 100s–100,000s of tenants
   - Pros: simple migrations, low infra cost, easy cross-tenant reporting
   - Cons: one bug leaks everything, noisy neighbor problem

2. Schema-per-tenant (same DB, separate schemas):
   - Each tenant gets their own Postgres schema (namespace)
   - Best for: 10–1000 tenants with compliance requirements
   - Pros: strong isolation, easy schema migrations per tenant
   - Cons: connection pool complexity, schema proliferation

3. Database-per-tenant:
   - Each tenant gets their own database instance
   - Best for: enterprise/regulated industries, < 100 tenants
   - Pros: maximum isolation, independent backups, tenant-level scaling
   - Cons: expensive, complex provisioning, hard to aggregate
```

## Schema-Per-Tenant (PostgreSQL)

```sql
-- Provision new tenant schema
CREATE SCHEMA tenant_acme;

-- Create tables in tenant schema
CREATE TABLE tenant_acme.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  total NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Set search path to target tenant
SET search_path = tenant_acme, public;

-- Now all queries hit tenant_acme schema
SELECT * FROM orders;  -- tenant_acme.orders
```

```typescript
// Dynamic schema routing per request
async function getTenantDb(tenantSlug: string) {
  const schema = `tenant_${tenantSlug.replace(/[^a-z0-9_]/g, '')}`;
  const client = await pool.connect();
  await client.query(`SET search_path = ${schema}, public`);
  return client;
}

// Middleware
app.use(async (req, res, next) => {
  req.db = await getTenantDb(req.tenant.slug);
  res.on('finish', () => req.db.release());
  next();
});
```

## Database-Per-Tenant

```typescript
// Connection registry — one pool per tenant DB
const tenantPools = new Map<string, Pool>();

async function getTenantPool(tenantId: string): Promise<Pool> {
  if (tenantPools.has(tenantId)) {
    return tenantPools.get(tenantId)!;
  }

  const config = await db.tenantConfigs.findUnique({ where: { tenantId } });
  const pool = new Pool({
    connectionString: config.databaseUrl,
    max: 10,
    idleTimeoutMillis: 30_000,
  });

  tenantPools.set(tenantId, pool);
  return pool;
}

// Tenant provisioning — create DB on signup
async function provisionTenantDatabase(tenantSlug: string) {
  // Connect to admin DB
  const adminClient = await adminPool.connect();
  try {
    const dbName = `tenant_${tenantSlug}`;
    await adminClient.query(`CREATE DATABASE ${dbName}`);

    // Run migrations against new DB
    await runMigrations(dbName);

    // Store connection config
    await db.tenantConfigs.create({
      data: {
        tenantSlug,
        databaseUrl: buildConnectionString(dbName),
      },
    });
  } finally {
    adminClient.release();
  }
}
```

## Hybrid Approach

```
Hybrid: shared schema for small tenants, dedicated DB for enterprise

Routing logic:
  - tenants.tier = 'free'       -> shared DB, filtered by tenant_id
  - tenants.tier = 'pro'        -> schema-per-tenant in shared server
  - tenants.tier = 'enterprise' -> dedicated database instance

Benefits:
  - Cost-efficient at scale (free tier shares infra)
  - Enterprise SLA with full isolation
  - Can migrate tenants between tiers without app changes
```

```typescript
async function getDbForTenant(tenant: Tenant) {
  switch (tenant.tier) {
    case 'enterprise':
      return getTenantPool(tenant.id);         // Dedicated DB
    case 'pro':
      return getSchemaConnection(tenant.slug); // Schema-per-tenant
    default:
      return sharedPool;                       // Row-level isolation
  }
}
```

## ABAC (Attribute-Based Access Control)

```typescript
// More granular than RBAC — rules based on resource attributes
interface AccessContext {
  user: { id: string; role: string; department: string };
  resource: { type: string; ownerId: string; status: string; tenantId: string };
  action: string;
}

type PolicyRule = (ctx: AccessContext) => boolean;

const policies: Record<string, PolicyRule[]> = {
  'orders:delete': [
    (ctx) => ctx.user.role === 'admin',
    // Owner can delete only if still pending
    (ctx) => ctx.resource.ownerId === ctx.user.id && ctx.resource.status === 'pending',
  ],
  'orders:write': [
    (ctx) => ctx.user.role === 'admin',
    // Managers write orders in their department
    (ctx) => ctx.user.role === 'manager' && ctx.resource.department === ctx.user.department,
    (ctx) => ctx.user.role === 'member' && ctx.resource.ownerId === ctx.user.id,
  ],
};

function evaluatePolicy(action: string, ctx: AccessContext): boolean {
  const rules = policies[action];
  if (!rules) return false;
  return rules.some((rule) => rule(ctx)); // Any matching rule grants access
}
```

## Org-Level Permissions

```typescript
// User can have different roles in different organizations
async function checkOrgPermission(
  userId: string,
  orgId: string,
  permission: string,
): Promise<boolean> {
  const membership = await db.orgMemberships.findUnique({
    where: { userId_orgId: { userId, orgId } },
  });

  if (!membership) return false;

  // Explicit overrides take priority
  if (membership.permissions.includes(permission)) return true;

  return hasPermission(membership.role, permission);
}
```

## Anti-Patterns
- Shared schema without RLS and application-level filters — double exposure
- Schema names built from raw user input — SQL injection via schema name
- Single connection pool for all tenant DBs — pool exhaustion
- No tenant provisioning tests — schema drift between tenants
- Migrating only new tenants — old tenants run stale schema

## Quick Reference
```
Shared schema: simple, cheap, needs RLS + app filter
Schema-per-tenant: search_path routing, good isolation, migration complexity
Database-per-tenant: max isolation, expensive, enterprise tier
Hybrid: route by tenant tier — pragmatic at scale
ABAC: attribute-based rules when RBAC isn't granular enough
Org-level: user has different roles per org, explicit overrides first
```

## When to load
Load when choosing a multi-tenancy isolation strategy, provisioning tenant schemas or databases, implementing hybrid tier routing, or modeling org-level permissions with ABAC.
