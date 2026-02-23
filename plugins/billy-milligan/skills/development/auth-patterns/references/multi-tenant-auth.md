# Multi-Tenant Auth

## Tenant Isolation

```typescript
// Every request scoped to a tenant — data never leaks between tenants

// Tenant context middleware
function tenantContext(req: Request, res: Response, next: NextFunction) {
  // Tenant from subdomain: acme.myapp.com -> 'acme'
  const tenantSlug = req.hostname.split('.')[0];
  // Or from header: X-Tenant-ID
  // Or from JWT claim: token.tenantId

  const tenant = await db.tenants.findUnique({ where: { slug: tenantSlug } });
  if (!tenant) {
    return res.status(404).json({ error: 'Tenant not found' });
  }

  req.tenant = tenant;
  next();
}

// All queries scoped to tenant — defense in depth
class OrderRepository {
  constructor(private db: DB, private tenantId: string) {}

  async findMany(filters: OrderFilters) {
    return this.db.orders.findMany({
      where: {
        tenantId: this.tenantId,  // ALWAYS filter by tenant
        ...filters,
      },
    });
  }

  async findById(id: string) {
    const order = await this.db.orders.findUnique({ where: { id } });
    if (order?.tenantId !== this.tenantId) {
      throw new NotFoundError('Order not found');
      // Never reveal that the order exists in another tenant
    }
    return order;
  }
}
```

## Row-Level Security (PostgreSQL)

```sql
-- Enable RLS on table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their tenant's orders
CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Set tenant context per connection
SET app.tenant_id = 'tenant-uuid-here';

-- Now all queries automatically filtered:
SELECT * FROM orders;  -- Only returns current tenant's orders
-- Even SELECT * cannot access other tenants' data
```

```typescript
// Set RLS context per request
app.use(async (req, res, next) => {
  const client = await pool.connect();
  await client.query(`SET app.tenant_id = $1`, [req.tenant.id]);
  req.dbClient = client;
  res.on('finish', () => client.release());
  next();
});
```

## RBAC (Role-Based Access Control)

```typescript
// Permission matrix: role -> permissions
const PERMISSIONS = {
  owner: ['*'],  // All permissions
  admin: [
    'orders:read', 'orders:write', 'orders:delete',
    'users:read', 'users:write', 'users:invite',
    'settings:read', 'settings:write',
    'billing:read', 'billing:write',
  ],
  manager: [
    'orders:read', 'orders:write',
    'users:read', 'users:invite',
    'settings:read',
    'billing:read',
  ],
  member: [
    'orders:read', 'orders:write',
    'users:read',
  ],
  viewer: [
    'orders:read',
    'users:read',
  ],
} as const;

type Role = keyof typeof PERMISSIONS;
type Permission = string;

function hasPermission(role: Role, permission: Permission): boolean {
  const perms = PERMISSIONS[role];
  return perms.includes('*') || perms.includes(permission);
}

// Middleware
function requirePermission(permission: Permission) {
  return (req: Request, res: Response, next: NextFunction) => {
    const userRole = req.user?.role as Role;
    if (!userRole || !hasPermission(userRole, permission)) {
      return res.status(403).json({
        error: { code: 'FORBIDDEN', message: `Missing permission: ${permission}` },
      });
    }
    next();
  };
}

// Usage
app.get('/orders', requirePermission('orders:read'), listOrders);
app.post('/orders', requirePermission('orders:write'), createOrder);
app.delete('/orders/:id', requirePermission('orders:delete'), deleteOrder);
```

## Anti-Patterns
- Tenant ID from client without verification — users can access other tenants
- No RLS or application-level tenant filter — one missing WHERE clause = data leak
- Single global role — user is admin everywhere instead of per-org
- Permission checks in frontend only — backend must enforce independently
- Hardcoded roles in code — use database-backed role definitions for flexibility

## Quick Reference
```
Tenant isolation: ALWAYS filter by tenantId — defense in depth
RLS: PostgreSQL row-level security — automatic tenant filtering
RBAC: role -> permissions map, check in middleware
Tenant source: subdomain, header, or JWT claim — always verify
Data leak prevention: never reveal resources exist in other tenants
```

## When to load
Load when implementing multi-tenant authentication, row-level security, RBAC permission systems, or tenant context middleware.
