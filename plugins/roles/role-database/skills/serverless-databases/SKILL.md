---
name: serverless-databases
description: |
  Deep operational guide for 10 serverless databases. Neon (branching, scale-to-zero), Turso (edge SQLite, embedded replicas), Supabase (PG + Auth + Realtime), Cloudflare D1 (edge SQLite), Xata, Upstash (serverless Redis/Kafka), Aurora Serverless v2, Cosmos DB Serverless. Use when implementing pay-per-use database architectures, edge computing, or development workflows with branching.
allowed-tools: Read, Grep, Glob, Bash
---

You are a serverless databases specialist informed by the Software Engineer by RN competency matrix.

## Serverless Database Comparison

| Database | Base Engine | Pricing Model | Cold Start | Edge Support | Branching | Best For |
|----------|-----------|---------------|------------|-------------|-----------|----------|
| Neon | PostgreSQL | Compute-time + storage | ~500ms | No | Yes (instant) | Dev workflows, scale-to-zero PG |
| Turso/libSQL | SQLite (libSQL) | Rows read/written | None (embedded) | Yes (global) | Yes (groups) | Edge apps, embedded replicas |
| Supabase | PostgreSQL | Compute + storage + bandwidth | ~2s (paused) | Edge Functions | Yes (preview) | Full-stack BaaS |
| PlanetScale | MySQL (Vitess) | Rows read/written | None | No | Yes (non-blocking) | MySQL at scale (see newsql) |
| Cloudflare D1 | SQLite | Rows read/written | None (Workers) | Yes (edge-native) | No | Workers ecosystem |
| Xata | PostgreSQL | Storage + AI + search | ~1s | No | Yes | PG + search + AI features |
| Upstash | Redis / Kafka | Per-request | ~5ms | Yes (global) | No | Serverless caching/messaging |
| CockroachDB Serverless | CockroachDB | Request Units | ~100ms | No | No | Distributed SQL (see newsql) |
| Aurora Serverless v2 | MySQL/PostgreSQL | ACU-hours | ~1s | No | No | AWS-native auto-scaling |
| Cosmos DB Serverless | Cosmos DB | Request Units | ~10ms | Global distrib | No | Azure-native, pay-per-request |

## Serverless Patterns

### Pattern 1: Scale-to-Zero Development

```
Production: Always-on with auto-scaling
Staging: Scale-to-zero (resume on request)
Preview: Branch per PR, auto-destroy on merge
Development: Local or scale-to-zero branch
```

### Pattern 2: Edge-First Architecture

```
User -> CDN/Edge -> Edge Database (Turso/D1) -> Origin Database
                         |
                    Embedded Replica (local SQLite)
                         |
                    Sync to Primary (async)
```

### Pattern 3: Serverless Full-Stack

```
Frontend (Vercel/Netlify) -> API (Edge Functions) -> Serverless DB (Neon/Turso)
                                |
                         Serverless Cache (Upstash Redis)
                                |
                         Serverless Queue (Upstash Kafka)
```

## Neon

### Serverless PostgreSQL with Branching

```bash
# Install Neon CLI
npm install -g neonctl

# Create project
neonctl projects create --name my-app --region aws-us-east-1

# Create branch (instant, copy-on-write)
neonctl branches create --name staging --parent main
neonctl branches create --name preview/pr-42 --parent main

# List branches
neonctl branches list

# Get connection string
neonctl connection-string --branch main
# postgres://user:pass@ep-xxx.us-east-1.aws.neon.tech/neondb?sslmode=require

# Delete branch (cleanup after PR merge)
neonctl branches delete preview/pr-42
```

### Scale-to-Zero and Compute Endpoints

```typescript
// Neon driver with serverless support (@neondatabase/serverless)
import { neon, neonConfig } from '@neondatabase/serverless';

// HTTP-based queries (no persistent connection, ideal for edge/serverless)
const sql = neon(process.env.DATABASE_URL);
const result = await sql`SELECT * FROM orders WHERE status = ${status}`;

// WebSocket pooling (for connection-heavy workloads)
neonConfig.webSocketConstructor = ws;
neonConfig.poolQueryViaFetch = true;

// With Drizzle ORM
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL);
const db = drizzle(sql);

const orders = await db
  .select()
  .from(ordersTable)
  .where(eq(ordersTable.status, 'pending'));
```

### Neon Auto-Scaling

```
Compute Endpoints:
- Scale-to-zero after configurable idle period (default 5 min)
- Auto-scale from 0.25 to 8 CU (Compute Units)
- Each CU = 1 vCPU + 4 GB RAM
- Cold start: ~500ms from zero to active

Configuration:
- Min compute size: 0.25 CU (scale-to-zero) or fixed minimum
- Max compute size: up to 8 CU
- Suspend timeout: 60s to 604800s (1 week)

Branch architecture:
- Branches share storage pages (copy-on-write)
- Zero additional storage cost until data diverges
- Instant creation (metadata-only operation)
- Parent branch is not affected by child branch writes
```

```bash
# Configure auto-scaling
neonctl endpoints update ep-xxx \
  --min-cu 0.25 \
  --max-cu 4 \
  --suspend-timeout 300

# Connection pooling (built-in PgBouncer)
# Append -pooler to endpoint hostname for pooled connections
# ep-xxx-pooler.us-east-1.aws.neon.tech (transaction mode)
```

### Neon for CI/CD and Preview Environments

```yaml
# GitHub Actions: create branch per PR
name: Preview Database
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  create-neon-branch:
    runs-on: ubuntu-latest
    steps:
      - uses: neondatabase/create-branch-action@v5
        id: create-branch
        with:
          project_id: ${{ secrets.NEON_PROJECT_ID }}
          branch_name: preview/pr-${{ github.event.pull_request.number }}
          api_key: ${{ secrets.NEON_API_KEY }}

      - name: Run Migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ steps.create-branch.outputs.db_url }}

      - name: Comment PR with connection string
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `Preview database created: \`${{ steps.create-branch.outputs.branch_id }}\``
            })
```

## Turso / libSQL

### Edge SQLite with Embedded Replicas

```bash
# Install Turso CLI
curl -sSfL https://get.tur.so/install.sh | bash

# Create database
turso db create my-app --group default

# Create database in specific region
turso db create my-app --group default --closest-location

# Add replicas in multiple regions
turso group locations add default lhr  # London
turso group locations add default nrt  # Tokyo
turso group locations add default syd  # Sydney

# Get connection info
turso db show my-app --url
turso db tokens create my-app

# Shell access
turso db shell my-app
```

### Embedded Replicas

```typescript
// Embedded replicas: local SQLite file synced from Turso primary
import { createClient } from '@libsql/client';

const client = createClient({
  url: 'file:local-replica.db',           // local SQLite file
  syncUrl: process.env.TURSO_DATABASE_URL, // remote primary
  authToken: process.env.TURSO_AUTH_TOKEN,
  syncInterval: 60,                         // sync every 60 seconds
});

// Initial sync
await client.sync();

// Reads are local (zero latency)
const result = await client.execute('SELECT * FROM orders WHERE status = ?', ['pending']);

// Writes go to primary, then sync back
await client.execute('INSERT INTO orders (customer, amount) VALUES (?, ?)', ['alice', 99.99]);

// Manual sync after critical writes
await client.sync();

// Benefits:
// - Zero read latency (local SQLite)
// - Works offline (reads from local copy)
// - Automatic background sync
// - Drastically reduced costs (local reads are free)
```

### Platform API

```bash
# Turso Platform API (manage databases programmatically)
# Create database per tenant
curl -X POST "https://api.turso.tech/v1/organizations/my-org/databases" \
  -H "Authorization: Bearer $TURSO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "tenant-abc", "group": "default"}'

# Database-per-tenant pattern
# Each tenant gets isolated database in same group
# All databases in group share infrastructure and replicas
```

## Supabase

### PostgreSQL + Auth + Realtime + Edge Functions + Storage

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
);

// Auth: sign up and sign in
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure-password',
});

// Database: auto-generated REST API (PostgREST)
const { data: orders } = await supabase
  .from('orders')
  .select('*, customer:customers(name, email)')
  .eq('status', 'pending')
  .order('created_at', { ascending: false })
  .limit(20);

// Insert with RLS (Row Level Security)
const { data: newOrder } = await supabase
  .from('orders')
  .insert({ customer_id: userId, amount: 99.99 })
  .select()
  .single();

// Realtime: subscribe to database changes
const channel = supabase
  .channel('orders-changes')
  .on('postgres_changes',
    { event: '*', schema: 'public', table: 'orders', filter: `customer_id=eq.${userId}` },
    (payload) => {
      console.log('Change:', payload.eventType, payload.new);
    }
  )
  .subscribe();

// Storage: file uploads
const { data: file } = await supabase.storage
  .from('order-attachments')
  .upload(`orders/${orderId}/receipt.pdf`, pdfBuffer, {
    contentType: 'application/pdf',
  });
```

### Row Level Security (RLS)

```sql
-- Enable RLS on table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their own orders
CREATE POLICY "Users see own orders"
    ON orders FOR SELECT
    USING (auth.uid() = customer_id);

-- Policy: users can insert their own orders
CREATE POLICY "Users create own orders"
    ON orders FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- Policy: admins can see all orders
CREATE POLICY "Admins see all"
    ON orders FOR SELECT
    USING (auth.jwt() ->> 'role' = 'admin');

-- Multi-tenant RLS
CREATE POLICY "Tenant isolation"
    ON orders FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
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
    .eq('id', orderId)
    .select()
    .single();

  return new Response(JSON.stringify(order), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

```bash
# Deploy edge function
supabase functions deploy process-order

# Database branching (preview environments)
supabase branches create preview-pr-42
supabase db push --branch preview-pr-42
```

## Cloudflare D1

### SQLite at the Edge

```typescript
// Cloudflare Worker with D1
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // D1 binding (configured in wrangler.toml)
    const db = env.DB;

    // Read query
    const { results } = await db
      .prepare('SELECT * FROM orders WHERE status = ? ORDER BY created_at DESC LIMIT ?')
      .bind('pending', 20)
      .all();

    // Write query
    const { meta } = await db
      .prepare('INSERT INTO orders (customer_id, amount, status) VALUES (?, ?, ?)')
      .bind(customerId, amount, 'pending')
      .run();

    // Batch operations (atomic)
    const batch = await db.batch([
      db.prepare('UPDATE orders SET status = ? WHERE id = ?').bind('confirmed', orderId),
      db.prepare('INSERT INTO order_events (order_id, event) VALUES (?, ?)').bind(orderId, 'confirmed'),
    ]);

    return Response.json(results);
  }
};
```

```toml
# wrangler.toml
[[d1_databases]]
binding = "DB"
database_name = "my-app-db"
database_id = "xxxx-xxxx-xxxx"

# Migrations
# wrangler d1 migrations create my-app-db create-orders-table
# wrangler d1 migrations apply my-app-db
```

```bash
# D1 CLI operations
wrangler d1 create my-app-db
wrangler d1 execute my-app-db --command "CREATE TABLE orders (id INTEGER PRIMARY KEY, ...)"

# Time travel (point-in-time recovery)
wrangler d1 time-travel my-app-db --timestamp "2024-06-15T10:00:00Z"
wrangler d1 time-travel my-app-db restore --timestamp "2024-06-15T10:00:00Z"

# Import data
wrangler d1 execute my-app-db --file ./seed.sql

# Export
wrangler d1 export my-app-db --output ./backup.sql
```

## Xata

### Serverless PostgreSQL + Search + File Storage + AI

```typescript
import { XataClient } from './xata'; // generated client

const xata = new XataClient();

// Full PostgreSQL access
const orders = await xata.db.orders
  .filter({ status: 'pending', 'amount': { $gt: 50 } })
  .sort('created_at', 'desc')
  .getPaginated({ pagination: { size: 20 } });

// Built-in full-text search (no Elasticsearch needed)
const results = await xata.db.orders.search('urgent delivery', {
  fuzziness: 1,
  prefix: 'phrase',
  highlight: { enabled: true },
  filter: { status: 'pending' },
  boosters: [{ numericBooster: { column: 'amount', factor: 2 } }],
});

// AI: ask questions about your data
const answer = await xata.db.orders.ask('What are the top 5 customers by order value?', {
  rules: ['Only use data from the orders table'],
  searchType: 'keyword',
});

// File attachments (built-in file storage)
await xata.db.orders.update('order-123', {
  receipt: {
    base64Content: base64EncodedPdf,
    mediaType: 'application/pdf',
    name: 'receipt.pdf',
  },
});

// Branching
// xata branch create preview-pr-42
// xata branch list
// xata branch delete preview-pr-42
```

## Upstash

### Serverless Redis

```typescript
import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv(); // uses UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN

// Basic operations (HTTP-based, works everywhere including edge)
await redis.set('session:user-123', JSON.stringify(sessionData), { ex: 3600 });
const session = await redis.get<SessionData>('session:user-123');

// Rate limiting
import { Ratelimit } from '@upstash/ratelimit';

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '10 s'), // 10 requests per 10 seconds
  analytics: true,
});

const { success, limit, remaining } = await ratelimit.limit('user-123');

// QStash: serverless message queue
import { Client } from '@upstash/qstash';

const qstash = new Client({ token: process.env.QSTASH_TOKEN });
await qstash.publishJSON({
  url: 'https://my-app.com/api/process-order',
  body: { orderId: '123' },
  retries: 3,
  delay: '10s',
});
```

### Serverless Kafka

```typescript
import { Kafka } from '@upstash/kafka';

const kafka = new Kafka({
  url: process.env.UPSTASH_KAFKA_REST_URL,
  username: process.env.UPSTASH_KAFKA_REST_USERNAME,
  password: process.env.UPSTASH_KAFKA_REST_PASSWORD,
});

// Produce (HTTP-based)
const producer = kafka.producer();
await producer.produce('orders', JSON.stringify({ orderId: '123', amount: 99.99 }));

// Consume
const consumer = kafka.consumer();
const messages = await consumer.consume({
  consumerGroupId: 'order-processor',
  instanceId: 'instance-1',
  topics: ['orders'],
  autoOffsetReset: 'earliest',
});
```

## Amazon Aurora Serverless v2

### Auto-Scaling ACUs

```bash
# Create Aurora Serverless v2 cluster
aws rds create-db-cluster \
  --db-cluster-identifier my-cluster \
  --engine aurora-postgresql \
  --engine-version 15.4 \
  --serverless-v2-scaling-configuration MinCapacity=0.5,MaxCapacity=64 \
  --master-username admin \
  --manage-master-user-password

# Add serverless v2 instance
aws rds create-db-instance \
  --db-instance-identifier my-instance \
  --db-cluster-identifier my-cluster \
  --db-instance-class db.serverless \
  --engine aurora-postgresql

# Scaling configuration:
# - MinCapacity: 0.5 ACU (1 ACU = ~2 GB RAM)
# - MaxCapacity: up to 128 ACU
# - Scales in 0.5 ACU increments
# - Instant scaling (no connection drop)
# - Mixed configuration: Serverless v2 readers + provisioned writer
```

```sql
-- Monitor ACU usage
SELECT
    server_id,
    metric_name,
    average AS avg_acu
FROM performance_insights.metrics
WHERE metric_name = 'db.load.avg'
ORDER BY timestamp DESC;

-- Aurora Serverless v2 vs v1:
-- v2: instant scaling, no cold start, mixed with provisioned
-- v1: 5-minute cold start, pause/resume, limited to specific versions
-- Always use v2 for new projects
```

## Azure Cosmos DB Serverless

```javascript
// Cosmos DB serverless: pay-per-request (no provisioned RU/s)
const { CosmosClient } = require('@azure/cosmos');

const client = new CosmosClient({
  endpoint: process.env.COSMOS_ENDPOINT,
  key: process.env.COSMOS_KEY,
});

// Create serverless container
const { container } = await client
  .database('shop')
  .containers.createIfNotExists({
    id: 'orders',
    partitionKey: { paths: ['/customerId'] },
    // No throughput configuration = serverless
  });

// Operations billed per RU consumed
const { resource, requestCharge } = await container.items.create({
  id: 'order-123',
  customerId: 'customer-1',
  amount: 99.99,
});
console.log(`Cost: ${requestCharge} RUs`);

// Serverless vs Provisioned:
// Serverless: $0.25 per million RUs, max 5000 RU per request
// Provisioned: $0.008 per RU/hour (manual or autoscale)
// Use serverless for: dev/test, sporadic workloads, < 5000 RU/s peak
// Use provisioned for: sustained high throughput, predictable cost
```

## Cost Optimization Strategies

### Neon
- Use scale-to-zero for non-production branches
- Set appropriate suspend timeouts (60s for dev, 300s for staging)
- Delete preview branches after PR merge (CI/CD automation)
- Use connection pooling to reduce compute endpoint wake-ups

### Turso
- Use embedded replicas for read-heavy workloads (free local reads)
- Group databases by region to share infrastructure
- Use groups for multi-tenant isolation with shared replicas

### Supabase
- Pause unused projects (free tier auto-pauses after 7 days)
- Use RLS instead of server-side filtering (reduces data transfer)
- Optimize Realtime subscriptions (filter at database level)

### Cloudflare D1
- Batch write operations (single transaction for multiple writes)
- Use D1 read replicas for global read performance
- Time travel instead of manual backups

### Upstash
- Use pipeline/multi for batch operations
- Set TTLs on all cache keys (prevent unbounded growth)
- Use Upstash rate limiting to protect downstream services

### General Serverless
- Monitor cold starts and set minimum compute where needed
- Use connection pooling (HTTP-based clients for edge)
- Implement caching layers to reduce database requests
- Automate branch cleanup in CI/CD pipelines
- Track per-request costs with observability tools

For cross-references, see:
- PlanetScale and CockroachDB Serverless in the newsql-distributed skill
- Turso/libSQL details in the embedded-databases skill
