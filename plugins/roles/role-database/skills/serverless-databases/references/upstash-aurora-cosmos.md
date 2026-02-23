# Upstash, Aurora Serverless v2, and Cosmos DB Serverless

## When to load
Load when working with Upstash (serverless Redis, Kafka, QStash), Amazon Aurora Serverless v2 (auto-scaling ACUs), or Azure Cosmos DB Serverless (pay-per-request). Also covers Xata (PostgreSQL + search + AI).

## Upstash

### Serverless Redis and Rate Limiting
```typescript
import { Redis } from '@upstash/redis';
import { Ratelimit } from '@upstash/ratelimit';

const redis = Redis.fromEnv();

await redis.set('session:user-123', JSON.stringify(sessionData), { ex: 3600 });
const session = await redis.get<SessionData>('session:user-123');

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '10 s'),
  analytics: true,
});
const { success, limit, remaining } = await ratelimit.limit('user-123');
```

### QStash (Serverless Message Queue)
```typescript
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

const producer = kafka.producer();
await producer.produce('orders', JSON.stringify({ orderId: '123', amount: 99.99 }));

const consumer = kafka.consumer();
const messages = await consumer.consume({
  consumerGroupId: 'order-processor',
  instanceId: 'instance-1',
  topics: ['orders'],
  autoOffsetReset: 'earliest',
});
```

## Amazon Aurora Serverless v2

### Create and Monitor
```bash
aws rds create-db-cluster \
  --db-cluster-identifier my-cluster \
  --engine aurora-postgresql \
  --engine-version 15.4 \
  --serverless-v2-scaling-configuration MinCapacity=0.5,MaxCapacity=64 \
  --master-username admin \
  --manage-master-user-password

aws rds create-db-instance \
  --db-instance-identifier my-instance \
  --db-cluster-identifier my-cluster \
  --db-instance-class db.serverless \
  --engine aurora-postgresql
# MinCapacity: 0.5 ACU (1 ACU ≈ 2 GB RAM), MaxCapacity: up to 128 ACU
# Scales in 0.5 ACU increments, instant (no connection drop)
# Always use v2 for new projects — no cold start, mixed with provisioned
```

## Xata (PostgreSQL + Search + AI)

### Query, Search, and AI
```typescript
import { XataClient } from './xata';

const xata = new XataClient();

const orders = await xata.db.orders
  .filter({ status: 'pending', 'amount': { $gt: 50 } })
  .sort('created_at', 'desc')
  .getPaginated({ pagination: { size: 20 } });

const results = await xata.db.orders.search('urgent delivery', {
  fuzziness: 1,
  highlight: { enabled: true },
  filter: { status: 'pending' },
});

const answer = await xata.db.orders.ask('What are the top 5 customers by order value?', {
  rules: ['Only use data from the orders table'],
});
```

## Azure Cosmos DB Serverless

### Pay-per-Request Container
```javascript
const { CosmosClient } = require('@azure/cosmos');

const client = new CosmosClient({
  endpoint: process.env.COSMOS_ENDPOINT,
  key: process.env.COSMOS_KEY,
});

const { container } = await client
  .database('shop')
  .containers.createIfNotExists({
    id: 'orders',
    partitionKey: { paths: ['/customerId'] },
    // No throughput configuration = serverless
  });

const { resource, requestCharge } = await container.items.create({
  id: 'order-123',
  customerId: 'customer-1',
  amount: 99.99,
});
// Serverless: $0.25 per million RUs, max 5000 RU per request
// Use for: dev/test, sporadic workloads, < 5000 RU/s peak
```
