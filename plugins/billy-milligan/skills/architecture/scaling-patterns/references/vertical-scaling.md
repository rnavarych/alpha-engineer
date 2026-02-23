# Vertical Scaling

## When to load
Load when discussing single-instance optimization, when vertical scaling is sufficient, instance sizing, or connection pool configuration for a single machine.

## Patterns

### When vertical is enough
```
Vertical scaling works well when:
- Traffic < 10,000 RPM on a single instance
- Database fits on one machine (<500GB, <10k TPS)
- Application is CPU or memory bound, not I/O bound
- Team is small, operational complexity matters
- Predictable traffic without sudden spikes

Modern single machines handle more than you think:
- 96 vCPU, 384GB RAM instances available on all clouds
- PostgreSQL on r6g.4xlarge: ~50k TPS
- Node.js on c6g.2xlarge: ~10k RPM for typical API
- Single Redis instance: ~100k ops/sec
```

### CPU optimization
```typescript
// Node.js: use cluster module for multi-core utilization
import cluster from 'cluster';
import os from 'os';

if (cluster.isPrimary) {
  const numWorkers = os.cpus().length;  // use all cores
  for (let i = 0; i < numWorkers; i++) {
    cluster.fork();
  }
  cluster.on('exit', (worker) => {
    console.log(`Worker ${worker.process.pid} died, respawning`);
    cluster.fork();
  });
} else {
  startServer();
}

// Or use PM2 (production process manager)
// pm2 start app.js -i max  # auto-detect CPU count
```

```typescript
// Move heavy computation to worker threads
import { Worker } from 'worker_threads';

async function heavyComputation(data: unknown): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./compute-worker.js', { workerData: data });
    worker.on('message', resolve);
    worker.on('error', reject);
  });
}
```

### Connection pool tuning
```typescript
// PostgreSQL connection pool formula:
// pool_size = CPU_cores * 2 + 1
// For a 4-core machine: pool_size = 9

// Why: each core handles ~2 concurrent queries + 1 for OS overhead
// More connections = more context switching = worse performance

import { Pool } from 'pg';
const pool = new Pool({
  max: 9,                    // CPU_cores * 2 + 1
  min: 2,                    // keep warm connections
  idleTimeoutMillis: 30000,  // close idle after 30s
  connectionTimeoutMillis: 5000, // fail fast if can't connect
  statement_timeout: 30000,  // kill queries >30s
});

// PgBouncer for connection multiplexing (100s of app instances -> fewer DB connections)
// pgbouncer.ini:
// pool_mode = transaction     # release connection after each transaction
// default_pool_size = 20      # connections per database-user pair
// max_client_conn = 1000      # total client connections
```

### Instance sizing guide
```
Workload type -> Instance family -> Starting size

API server (CPU bound):
  AWS: c6g.xlarge (4 vCPU, 8GB) -> c6g.4xlarge (16 vCPU, 32GB)
  GCP: c2-standard-4 -> c2-standard-16

Database (memory bound):
  AWS: r6g.xlarge (4 vCPU, 32GB) -> r6g.4xlarge (16 vCPU, 128GB)
  GCP: n2-highmem-4 -> n2-highmem-16

General purpose:
  AWS: m6g.xlarge (4 vCPU, 16GB) -> m6g.4xlarge (16 vCPU, 64GB)
  GCP: e2-standard-4 -> e2-standard-16

Rule: start small, monitor, upgrade. Vertical is faster than horizontal redesign.
```

## Anti-patterns
- Vertical scaling without profiling -> throwing money at unknown bottleneck
- Pool size = 100 on 4-core machine -> connection overhead kills performance
- No memory limits on containers -> OOM kills surprise you in production

## Decision criteria
- **Scale vertically first** when: <10k RPM, single-region, small team, predictable load
- **Switch to horizontal** when: hitting single-machine limits, need redundancy, traffic spikes unpredictable
- **Connection pool**: always CPU_cores * 2 + 1, use PgBouncer at >10 app instances

## Quick reference
```
Vertical first: simpler ops, works up to ~10k RPM
CPU: cluster mode (all cores), worker threads for heavy compute
Pool size: CPU_cores * 2 + 1 (e.g., 4 cores = 9 connections)
PgBouncer: transaction mode, 20 pool size, 1000 max clients
Profile before scaling: --prof, EXPLAIN ANALYZE, heap snapshots
Instance sizing: start c/r/m6g.xlarge, upgrade as needed
```
