# GCP Data Patterns

## When to load
Load when choosing between Cloud SQL, Firestore, BigQuery, Cloud Storage, or Spanner.

## Data Service Decision Tree

```
What type of data?
  │
  ├─ Relational (SQL, joins, transactions)
  │   │
  │   ├─ Single region, < 10TB → Cloud SQL (Postgres/MySQL)
  │   │   ✅ Managed, automatic backups, read replicas
  │   │   ❌ Single region, vertical scaling limits
  │   │
  │   └─ Global, unlimited scale → Cloud Spanner
  │       ✅ Globally distributed, strongly consistent
  │       ❌ Expensive ($0.90/node-hr), requires careful schema
  │
  ├─ Document / NoSQL
  │   │
  │   ├─ Real-time sync, mobile/web → Firestore
  │   │   ✅ Real-time listeners, offline support, auto-scale
  │   │   ❌ Limited query capabilities, 1MB doc limit
  │   │
  │   └─ Wide-column, high throughput → Bigtable
  │       ✅ Petabyte-scale, single-digit ms latency
  │       ❌ No secondary indexes, row-key design critical
  │
  ├─ Analytics / Data Warehouse
  │   → BigQuery
  │     ✅ Serverless, petabyte-scale, SQL interface
  │     ❌ Not for OLTP, minimum 10MB per query billed
  │
  └─ Object Storage
      → Cloud Storage
        Standard / Nearline / Coldline / Archive
```

## Cloud SQL (PostgreSQL)

```bash
# Create instance
gcloud sql instances create my-db \
  --database-version POSTGRES_15 \
  --tier db-custom-4-16384 \
  --region us-central1 \
  --availability-type REGIONAL \
  --storage-type SSD \
  --storage-size 100 \
  --storage-auto-increase \
  --backup-start-time 03:00 \
  --enable-point-in-time-recovery

# Connection from Cloud Run (recommended: Unix socket via proxy)
# Set --add-cloudsql-instances in Cloud Run deploy
```

```typescript
// Cloud Run → Cloud SQL via Unix socket
import { Pool } from 'pg';

const pool = new Pool({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  host: `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME}`,
  // No IP needed — Cloud SQL Auth Proxy handles auth + encryption
});
```

## Firestore

```typescript
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();

// Create/update document
await db.collection('users').doc(userId).set({
  name: 'Alice',
  email: 'alice@example.com',
  createdAt: FieldValue.serverTimestamp(),
}, { merge: true });

// Query with composite index
const activeUsers = await db.collection('users')
  .where('status', '==', 'active')
  .where('plan', '==', 'pro')
  .orderBy('createdAt', 'desc')
  .limit(20)
  .get();

// Real-time listener
db.collection('messages')
  .where('roomId', '==', roomId)
  .orderBy('createdAt', 'desc')
  .limit(50)
  .onSnapshot((snapshot) => {
    snapshot.docChanges().forEach((change) => {
      if (change.type === 'added') handleNewMessage(change.doc.data());
    });
  });

// Transaction (atomic read-write)
await db.runTransaction(async (tx) => {
  const accountRef = db.collection('accounts').doc(accountId);
  const account = await tx.get(accountRef);
  const newBalance = account.data().balance - amount;
  if (newBalance < 0) throw new Error('Insufficient funds');
  tx.update(accountRef, { balance: newBalance });
});
```

## BigQuery

```sql
-- Partitioned table (cost optimization)
CREATE TABLE `project.dataset.events`
(
  event_id STRING,
  user_id STRING,
  event_type STRING,
  properties JSON,
  created_at TIMESTAMP
)
PARTITION BY DATE(created_at)
CLUSTER BY user_id, event_type;

-- Query scans only relevant partitions
SELECT event_type, COUNT(*) as count
FROM `project.dataset.events`
WHERE created_at BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY event_type
ORDER BY count DESC;
```

## Cost Optimization

```
Cloud SQL:  db-f1-micro free tier, then ~$50-200/mo typical
Firestore:  50K reads + 20K writes + 1GB/day free
BigQuery:   1TB/mo queries free, $5/TB after
Spanner:    ~$650/mo minimum (1 node), enterprise only
Cloud Storage: $0.020/GB/mo Standard, lifecycle rules

Tips:
  1. Cloud SQL: use db-custom for right-sizing (not predefined)
  2. Firestore: batch reads, denormalize to reduce document reads
  3. BigQuery: partition + cluster tables, use query preview
  4. Cloud Storage: lifecycle rules auto-transition to cheaper tiers
```

## Anti-patterns
- Firestore for analytics queries → use BigQuery
- Cloud SQL for global distribution → use Spanner
- BigQuery for real-time OLTP → use Cloud SQL or Firestore
- Bigtable for < 1TB data → overkill, use Firestore
- No partitioning in BigQuery → full table scans, expensive

## Quick reference
```
Cloud SQL: relational, managed Postgres/MySQL, single region
Firestore: document DB, real-time sync, mobile-first, serverless
BigQuery: analytics, serverless, SQL, partition for cost
Spanner: global SQL, strongly consistent, expensive
Bigtable: wide-column, petabyte-scale, IoT/time-series
Cloud Storage: objects, lifecycle rules, 4 storage classes
Connection: Cloud SQL Auth Proxy for Cloud Run/GKE
Free tiers: Firestore (generous), BigQuery (1TB/mo queries)
```
