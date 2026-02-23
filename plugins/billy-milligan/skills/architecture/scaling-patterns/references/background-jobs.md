# Background Jobs

## When to load
Load when discussing job scheduling, cron jobs, worker retry logic, exponential backoff, Dead Letter Queue management, or BullMQ/Celery/Sidekiq patterns.

## Patterns

### Job scheduling with BullMQ
```typescript
import { Queue, Worker, QueueScheduler } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({ maxRetriesPerRequest: null });

// Define queue
const emailQueue = new Queue('email', { connection });

// Schedule a job
await emailQueue.add(
  'send-welcome',
  { userId: '123', template: 'welcome' },
  {
    attempts: 3,
    backoff: { type: 'exponential', delay: 1000 }, // 1s, 2s, 4s
    removeOnComplete: 100,   // keep last 100 completed jobs
    removeOnFail: 500,       // keep last 500 failed jobs for inspection
  }
);

// Schedule recurring job (cron)
await emailQueue.add(
  'weekly-digest',
  { type: 'weekly-digest' },
  { repeat: { cron: '0 9 * * 1' } } // every Monday 9 AM
);
```

### Worker with retry logic
```typescript
const emailWorker = new Worker(
  'email',
  async (job) => {
    const { userId, template } = job.data;

    // Log progress for long jobs
    await job.updateProgress(10);
    const user = await userService.findById(userId);

    await job.updateProgress(50);
    await emailService.send(user.email, template);

    await job.updateProgress(100);
    return { sentAt: new Date().toISOString() };
  },
  {
    connection,
    concurrency: 5,          // process 5 jobs in parallel
    limiter: {
      max: 100,              // max 100 jobs per period
      duration: 60_000,      // per minute
    },
  }
);

emailWorker.on('failed', (job, err) => {
  logger.error({ jobId: job?.id, attempt: job?.attemptsMade, err }, 'Job failed');
});

emailWorker.on('completed', (job) => {
  logger.info({ jobId: job.id, duration: Date.now() - job.timestamp }, 'Job completed');
});
```

### Dead Letter Queue management
```typescript
// SQS DLQ configuration
// Main queue -> after maxReceiveCount failures -> DLQ
// RedrivePolicy: { deadLetterTargetArn: dlqArn, maxReceiveCount: 3 }

// DLQ monitoring and reprocessing
async function reprocessDLQ() {
  const messages = await sqs.send(new ReceiveMessageCommand({
    QueueUrl: DLQ_URL,
    MaxNumberOfMessages: 10,
  }));

  for (const msg of messages.Messages || []) {
    try {
      await sqs.send(new SendMessageCommand({
        QueueUrl: MAIN_QUEUE_URL,
        MessageBody: msg.Body,
        MessageAttributes: {
          reprocessedAt: { DataType: 'String', StringValue: new Date().toISOString() },
          originalMessageId: { DataType: 'String', StringValue: msg.MessageId },
        },
      }));
      await sqs.send(new DeleteMessageCommand({
        QueueUrl: DLQ_URL,
        ReceiptHandle: msg.ReceiptHandle,
      }));
    } catch (err) {
      logger.error({ err, messageId: msg.MessageId }, 'DLQ reprocessing failed');
    }
  }
}

// Alert on DLQ depth
// CloudWatch alarm: ApproximateNumberOfMessagesVisible > 0 for 5 minutes
```

### Exponential backoff
```typescript
// Manual retry with exponential backoff + jitter
async function withRetry<T>(
  fn: () => Promise<T>,
  maxAttempts = 3,
  baseDelayMs = 1000
): Promise<T> {
  let lastError: Error;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err as Error;
      if (attempt === maxAttempts) break;

      // Exponential backoff with jitter: delay * 2^attempt * (0.5..1.5 random)
      const delay = baseDelayMs * Math.pow(2, attempt - 1) * (0.5 + Math.random());
      logger.warn({ attempt, delayMs: Math.round(delay), err: err.message }, 'Retrying');
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError!;
}
```

## Anti-patterns
- No DLQ -> failed jobs disappear silently, you never know
- Fixed delay retries -> thundering herd when many jobs fail simultaneously
- Unbounded worker concurrency -> overwhelm downstream services
- No job progress tracking for long-running jobs -> looks frozen, hard to debug
- Cron jobs without distributed lock -> multiple instances run the same job

## Quick reference
```
BullMQ: attempts=3, exponential backoff (1s, 2s, 4s)
Concurrency: tune by downstream capacity, not by CPU count
DLQ: alert if depth > 0 for 5 minutes
Exponential backoff: delay * 2^attempt + jitter
Cron: use distributed lock (Redis SET NX) to prevent duplicate runs
Progress: job.updateProgress() for jobs >10s
Cleanup: removeOnComplete=100, removeOnFail=500
```
