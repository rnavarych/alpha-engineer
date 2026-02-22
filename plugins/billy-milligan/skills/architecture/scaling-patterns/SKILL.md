---
name: scaling-patterns
description: |
  Scaling patterns: stateless app servers, read replicas with read-your-writes caveat,
  horizontal vs vertical scaling thresholds, sharding strategies, token bucket rate limiting,
  backpressure and load shedding, connection pooling (PgBouncer), autoscaling triggers.
  Use when designing for scale, handling traffic spikes, scaling databases.
allowed-tools: Read, Grep, Glob
---

# Scaling Patterns

## When to Use This Skill
- Designing systems to handle 10x to 100x growth
- Scaling databases beyond single-instance limits
- Handling traffic spikes without overloading services
- Configuring connection pools and autoscaling
- Implementing rate limiting and load shedding

## Core Principles

1. **Stateless app servers first** — horizontal scaling requires no shared state in memory
2. **Scale reads before writes** — reads can use replicas; writes need more work
3. **Connection pools are mandatory** — PostgreSQL handles 100 connections, not 10,000
4. **Backpressure is safer than accepting unbounded load** — reject early rather than collapse
5. **Vertical scale first** — doubling CPU/RAM is fast and cheap; horizontal adds complexity

---

## Patterns ✅

### Stateless App Servers

```typescript
// State lives in Redis or DB, never in app memory
// Wrong: storing session in process memory
const sessions = new Map<string, Session>();  // Dies on deploy, breaks with 2+ instances

// Correct: session in Redis
async function getSession(sessionId: string): Promise<Session | null> {
  const raw = await redis.get(`session:${sessionId}`);
  return raw ? JSON.parse(raw) : null;
}

async function saveSession(sessionId: string, session: Session): Promise<void> {
  await redis.setex(`session:${sessionId}`, 86400, JSON.stringify(session));
}

// Correct: distributed lock in Redis (not in-memory mutex)
// Wrong: const lock = new Mutex();  // Only works within single process
```

**Checklist for stateless service**:
- [ ] No in-memory state that persists across requests (except LRU cache with short TTL)
- [ ] Session stored in Redis, not process memory
- [ ] File uploads go to S3, not local disk
- [ ] Background jobs handled by queue (BullMQ/Celery), not in-process workers
- [ ] Configuration from environment variables, not startup state

### Read Replicas

```
PostgreSQL Primary (writes + strong-consistency reads)
├── Read Replica 1 (reads)
├── Read Replica 2 (reads)
└── Read Replica 3 (reads — maybe analytics queries)

Typical replication lag: 1–100ms (usually <5ms on same region)
```

```typescript
// Route reads to replica, writes to primary
const primaryDb = drizzle(primaryPool);
const replicaDb = drizzle(replicaPool);

// Use replica for eventually-consistent reads
async function listProducts(filters: ProductFilters): Promise<Product[]> {
  return replicaDb.select().from(products).where(/* filters */);
}

// Use primary for write operations
async function createOrder(data: CreateOrderInput): Promise<Order> {
  return primaryDb.insert(orders).values(data).returning().then(r => r[0]);
}

// Read-your-writes: after writing, read from primary
async function updateAndFetch(id: string, data: Partial<Order>): Promise<Order> {
  await primaryDb.update(orders).set(data).where(eq(orders.id, id));
  // Must read from primary — replica may not have this write yet
  return primaryDb.query.orders.findFirst({ where: eq(orders.id, id) });
}
```

**Read-your-writes caveat**: If a user writes, then immediately reads, route that read to primary. Replica lag can be 1–100ms — enough for the user to see stale data.

### Connection Pooling (PgBouncer)

**Why it matters**: PostgreSQL handles ~100 connections before memory/CPU becomes a problem. With 20 app servers × 20 connections each = 400 connections. App servers autoscale to 50 → 1,000 connections → PostgreSQL OOM.

```ini
# pgbouncer.ini
[databases]
myapp = host=postgres-primary port=5432 dbname=myapp

[pgbouncer]
pool_mode = transaction           # Transaction-level pooling — recommended
max_client_conn = 10000           # Clients connecting to PgBouncer
default_pool_size = 25            # Connections to PostgreSQL per DB
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 3
max_db_connections = 100          # Total connections to PostgreSQL
server_idle_timeout = 600         # Close idle server connections after 10min
```

```typescript
// Application pool — connects to PgBouncer, not directly to PostgreSQL
const pool = new Pool({
  host: 'pgbouncer',
  port: 5432,
  database: 'myapp',
  user: 'app',
  password: process.env.DB_PASSWORD,
  max: 20,           // PgBouncer handles multiplexing to PostgreSQL
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});
```

**Effective connections**: 50 app servers × 20 pool connections = 1,000 client connections to PgBouncer. PgBouncer maintains only 25–100 connections to PostgreSQL.

### Token Bucket Rate Limiting

```typescript
// Token bucket: allows bursts, enforces sustained rate
// Refill rate: 100 tokens/second. Bucket capacity: 200 (allows 2s burst)

async function tokenBucketAllow(
  key: string,
  refillRate: number,   // tokens per second
  capacity: number      // max tokens (burst size)
): Promise<{ allowed: boolean; remaining: number }> {
  const now = Date.now() / 1000;
  const bucketKey = `tb:${key}`;

  // Lua script for atomic check-and-update
  const luaScript = `
    local tokens = tonumber(redis.call('HGET', KEYS[1], 'tokens') or ARGV[3])
    local lastRefill = tonumber(redis.call('HGET', KEYS[1], 'last') or ARGV[2])
    local now = tonumber(ARGV[2])
    local rate = tonumber(ARGV[1])
    local cap = tonumber(ARGV[3])
    local elapsed = math.max(0, now - lastRefill)
    tokens = math.min(cap, tokens + elapsed * rate)
    local allowed = tokens >= 1
    if allowed then tokens = tokens - 1 end
    redis.call('HSET', KEYS[1], 'tokens', tokens, 'last', now)
    redis.call('EXPIRE', KEYS[1], 3600)
    return { allowed and 1 or 0, math.floor(tokens) }
  `;

  const result = await redis.sendCommand(
    ['EVAL', luaScript, '1', bucketKey, now.toString(), refillRate.toString(), capacity.toString()]
  ) as [number, number];

  return { allowed: result[0] === 1, remaining: result[1] };
}
```

### Load Shedding and Backpressure

```typescript
// Load shedding: reject requests when system is overloaded
// Better to return 503 to 10% of users than to slow down 100% of users

import { Semaphore } from 'async-mutex';

const concurrencyLimit = new Semaphore(200);  // Max 200 concurrent requests

async function handleRequest(req: Request, res: Response) {
  const [acquired, release] = await concurrencyLimit.waitFor(0);  // Non-blocking check

  if (!acquired) {
    // System is at capacity — shed load
    res.status(503).set({
      'Retry-After': '5',
      'X-Load-Shed': 'true',
    }).json({ error: { code: 'SERVICE_OVERLOADED', message: 'Service temporarily overloaded' } });
    return;
  }

  try {
    await processRequest(req, res);
  } finally {
    release();
  }
}

// Queue-based backpressure for background jobs
const queue = new BullMQ.Queue('email-notifications', {
  defaultJobOptions: { attempts: 3, backoff: { type: 'exponential', delay: 1000 } }
});

// Don't enqueue if queue is already huge
async function enqueueEmailSafely(job: EmailJob) {
  const queueSize = await queue.getWaiting();
  if (queueSize > 10_000) {
    logger.warn({ queueSize }, 'Queue overloaded, dropping email job');
    metrics.increment('queue.dropped', { queue: 'email' });
    return;  // Drop job — don't cascade overload
  }
  await queue.add('send', job);
}
```

---

## Anti-Patterns ❌

### Connecting Directly to PostgreSQL Without PgBouncer
**What it is**: App connects directly to PostgreSQL with `max: 100` connections per pool.
**What breaks**: 50 app instances × 100 connections = 5,000 PostgreSQL connections → memory exhaustion → crash.
**When it breaks**: Autoscaling event under load — the worst possible time.

### Read-Your-Writes Violation
**What it is**: Write to primary, immediately read from replica expecting updated data.
**What breaks**: Replication lag (1–100ms) means replica doesn't have the write yet. User sees "update failed" when it actually succeeded.
**Fix**: Route the immediate post-write read to primary. Cache the user's own writes in Redis for 5 seconds.

### Vertical Scaling Until Instance Runs Out
**What it is**: Keep upgrading the database instance rather than adding read replicas or sharding.
**When it breaks**: AWS RDS db.r6g.16xlarge costs $8/hr. Beyond that, you must shard — but sharding a live system is extremely painful.
**Fix**: Add read replicas at 60–70% read utilization. Plan sharding strategy before hitting vertical limits.

### Accepting Unbounded Request Queue
**What it is**: No concurrency limit, no queue depth limit — always accept more work.
**What breaks**: Memory grows unboundedly during traffic spikes. Eventually OOM crash affects ALL in-flight requests. 100% of users affected.
**Fix**: Reject at 503 when over capacity. 10% affected is better than 100%.

---

## Quick Reference

```
Stateless checklist: no in-memory sessions, uploads to S3, jobs to queue
PgBouncer pool_mode: transaction (not session — enables true multiplexing)
PgBouncer default_pool_size: 25 per database, max_db_connections: 100
Read replica lag: 1–100ms (usually <5ms same region)
Read-your-writes: route to primary after write for consistency
Token bucket: allows bursts; sliding window: uniform rate
Load shed threshold: configure, tune, then enforce — 503 is correct
Autoscale trigger: CPU >70% for 3min or queue depth >1000
```
