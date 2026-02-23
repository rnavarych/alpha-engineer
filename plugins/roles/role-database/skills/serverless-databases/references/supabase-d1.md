# Supabase and Cloudflare D1

## When to load
Load when building with Supabase (PostgreSQL + Auth + Realtime + Edge Functions) or Cloudflare D1 (edge-native SQLite in Workers). Covers client setup, Row Level Security, realtime subscriptions, and D1 batch operations.

## Supabase

### Client Setup and CRUD
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
);

const { data: orders } = await supabase
  .from('orders')
  .select('*, customer:customers(name, email)')
  .eq('status', 'pending')
  .order('created_at', { ascending: false })
  .limit(20);

const { data: newOrder } = await supabase
  .from('orders')
  .insert({ customer_id: userId, amount: 99.99 })
  .select()
  .single();
```

### Row Level Security (RLS)
```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own orders"
    ON orders FOR SELECT
    USING (auth.uid() = customer_id);

CREATE POLICY "Admins see all"
    ON orders FOR SELECT
    USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Tenant isolation"
    ON orders FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
```

### Realtime Subscriptions
```typescript
const channel = supabase
  .channel('orders-changes')
  .on('postgres_changes',
    { event: '*', schema: 'public', table: 'orders', filter: `customer_id=eq.${userId}` },
    (payload) => console.log('Change:', payload.eventType, payload.new)
  )
  .subscribe();
```

### Edge Functions
```typescript
// supabase/functions/process-order/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  const { orderId } = await req.json();
  const { data: order } = await supabase
    .from('orders')
    .update({ status: 'confirmed', confirmed_at: new Date().toISOString() })
    .eq('id', orderId).select().single();
  return new Response(JSON.stringify(order), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

## Cloudflare D1

### Worker with D1 Binding
```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const db = env.DB;

    const { results } = await db
      .prepare('SELECT * FROM orders WHERE status = ? ORDER BY created_at DESC LIMIT ?')
      .bind('pending', 20)
      .all();

    const batch = await db.batch([
      db.prepare('UPDATE orders SET status = ? WHERE id = ?').bind('confirmed', orderId),
      db.prepare('INSERT INTO order_events (order_id, event) VALUES (?, ?)').bind(orderId, 'confirmed'),
    ]);

    return Response.json(results);
  }
};
```

### wrangler.toml and CLI
```toml
[[d1_databases]]
binding = "DB"
database_name = "my-app-db"
database_id = "xxxx-xxxx-xxxx"
```

```bash
wrangler d1 create my-app-db
wrangler d1 migrations create my-app-db create-orders-table
wrangler d1 migrations apply my-app-db
wrangler d1 time-travel my-app-db restore --timestamp "2024-06-15T10:00:00Z"
wrangler d1 export my-app-db --output ./backup.sql
```
