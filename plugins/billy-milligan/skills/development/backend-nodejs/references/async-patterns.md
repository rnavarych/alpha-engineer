# Async Patterns

## Promise.all — Parallel Independent Operations

```typescript
// BAD — sequential: 200ms + 300ms + 150ms = 650ms
const user = await getUser(userId);
const orders = await getOrders(userId);
const prefs = await getPreferences(userId);

// GOOD — parallel: max(200, 300, 150) = 300ms
const [user, orders, prefs] = await Promise.all([
  getUser(userId),
  getOrders(userId),
  getPreferences(userId),
]);

// Promise.allSettled — when partial failure is acceptable
const results = await Promise.allSettled([
  sendEmail(user),
  sendPush(user),
  sendSMS(user),
]);
// Check each: result.status === 'fulfilled' | 'rejected'
```

## BullMQ Job Queues

```typescript
import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis(process.env.REDIS_URL, { maxRetriesPerRequest: null });

// Producer — enqueue jobs
const emailQueue = new Queue('emails', { connection });

await emailQueue.add('welcome', { userId, email }, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 1000 }, // 1s, 2s, 4s
  removeOnComplete: 1000,
  removeOnFail: 5000,
});

// Scheduled job — run daily at 9am
await emailQueue.add('daily-digest', {}, {
  repeat: { pattern: '0 9 * * *' },
});

// Worker — process jobs
const worker = new Worker('emails', async (job) => {
  switch (job.name) {
    case 'welcome':
      await sendWelcomeEmail(job.data.email);
      break;
    case 'daily-digest':
      await sendDailyDigest();
      break;
  }
}, {
  connection,
  concurrency: 5,        // Process 5 jobs simultaneously
  limiter: {
    max: 100,
    duration: 60_000,     // Max 100 jobs per minute (rate limit)
  },
});

worker.on('failed', (job, err) => {
  logger.error({ jobId: job?.id, err }, 'Job failed');
});
```

## Worker Threads — CPU-Bound Work

```typescript
import { Worker, isMainThread, parentPort, workerData } from 'worker_threads';

// Main thread — offload heavy computation
async function processLargeCSV(filePath: string): Promise<ParseResult> {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./csv-worker.js', {
      workerData: { filePath },
    });
    worker.on('message', resolve);
    worker.on('error', reject);
    worker.on('exit', (code) => {
      if (code !== 0) reject(new Error(`Worker exited with code ${code}`));
    });
  });
}

// csv-worker.js — runs in separate thread
if (!isMainThread) {
  const { filePath } = workerData;
  const result = parseCSVSync(filePath); // CPU-intensive, won't block event loop
  parentPort.postMessage(result);
}
```

## Streams with Backpressure

```typescript
import { Transform, pipeline } from 'stream';
import { promisify } from 'util';

const pipelineAsync = promisify(pipeline);

// Process large file without loading into memory
await pipelineAsync(
  fs.createReadStream('large-file.csv'),
  new Transform({
    transform(chunk, encoding, callback) {
      try {
        const processed = processChunk(chunk.toString());
        callback(null, processed);
      } catch (err) {
        callback(err as Error);
      }
    },
    highWaterMark: 64 * 1024, // 64KB buffer — controls backpressure
  }),
  fs.createWriteStream('output.csv')
);

// Stream DB results to HTTP response
app.get('/export', async (req, res) => {
  res.setHeader('Content-Type', 'text/csv');
  const cursor = db.select().from(orders).cursor();
  for await (const row of cursor) {
    const ok = res.write(formatCSVRow(row));
    if (!ok) await new Promise((resolve) => res.once('drain', resolve)); // Backpressure
  }
  res.end();
});
```

## Concurrency Control

```typescript
// Limit concurrent operations — prevent overwhelming external services
import pLimit from 'p-limit';

const limit = pLimit(10); // Max 10 concurrent operations

const results = await Promise.all(
  urls.map((url) => limit(() => fetch(url))) // Only 10 run at a time
);
```

## Anti-Patterns
- `await` in a `for` loop for independent operations — use `Promise.all`
- No concurrency limit on `Promise.all` with 1000+ items — overwhelms target
- Heavy computation on main thread — use `worker_threads`
- Ignoring backpressure in streams — memory grows unbounded

## Quick Reference
```
Promise.all: independent I/O — parallel execution
Promise.allSettled: partial failure acceptable
BullMQ: retries, scheduling, rate limiting, persistence
Worker threads: CPU-bound (CSV parsing, crypto, image resize)
Streams: large data — pipeline() with backpressure
p-limit: control concurrency for external API calls
Concurrency: 5-10 for external APIs, CPU cores for workers
```
