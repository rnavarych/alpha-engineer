# Supabase Realtime & CDC

## When to load
Load when using Supabase, or implementing Change Data Capture for real-time database sync.

## Supabase Realtime

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(url, anonKey);

// Listen to INSERT/UPDATE/DELETE on a table
const channel = supabase
  .channel('orders')
  .on('postgres_changes',
    { event: '*', schema: 'public', table: 'orders', filter: 'user_id=eq.123' },
    (payload) => {
      switch (payload.eventType) {
        case 'INSERT': addOrder(payload.new); break;
        case 'UPDATE': updateOrder(payload.new); break;
        case 'DELETE': removeOrder(payload.old); break;
      }
    }
  )
  .subscribe();

// Cleanup
channel.unsubscribe();
```

## Presence (who's online)

```typescript
const room = supabase.channel('room:lobby', {
  config: { presence: { key: userId } },
});

room.on('presence', { event: 'sync' }, () => {
  const state = room.presenceState();
  updateOnlineUsers(Object.keys(state));
});

room.subscribe(async (status) => {
  if (status === 'SUBSCRIBED') {
    await room.track({ user_id: userId, name: userName, online_at: new Date() });
  }
});
```

## Row Level Security for Realtime

```sql
-- Users only see their own orders in realtime
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);

-- Enable realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
```

## Generic CDC with Debezium

```yaml
# docker-compose for Debezium CDC
services:
  debezium:
    image: debezium/connect:2.4
    environment:
      BOOTSTRAP_SERVERS: kafka:9092
      CONFIG_STORAGE_TOPIC: debezium_configs
      OFFSET_STORAGE_TOPIC: debezium_offsets
```

```json
// Debezium connector config
{
  "name": "orders-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.dbname": "app",
    "table.include.list": "public.orders",
    "topic.prefix": "cdc",
    "slot.name": "debezium_orders"
  }
}
```

## Anti-patterns
- Subscribing to all rows without RLS → data leak to other users
- Not handling reconnection → stale UI after network blip
- CDC without monitoring replication lag → events arrive late
- Using realtime for analytics → polling/batch is more efficient

## Quick reference
```
Supabase: postgres_changes for INSERT/UPDATE/DELETE
Presence: track/untrack for who's online
RLS: required for secure realtime — filters at DB level
CDC: Debezium for non-Supabase Postgres
Filter: filter parameter limits events at server
Cleanup: always unsubscribe on unmount
```
