# Job Pipelines, Graceful Shutdown, and Monitoring

## When to load
Load when building multi-step job workflows, implementing graceful worker shutdown, or setting up job queue observability and alerting.

## Job Pipelines and Workflows

- Chain jobs for multi-step workflows: `fetchData → processData → sendReport`
- Use BullMQ Flows, Celery chains/chords, or custom orchestration
- Handle partial failures: each step must be independently retryable
- Store workflow state externally for visibility and recovery
- Implement a timeout for the entire workflow, not just individual steps

### BullMQ Flow Example

```typescript
import { FlowProducer } from 'bullmq'

const flow = new FlowProducer({ connection: redisConnection })

await flow.add({
  name: 'send-report',
  queueName: 'reports',
  children: [
    {
      name: 'process-data',
      queueName: 'processing',
      children: [
        { name: 'fetch-data', queueName: 'fetching', data: { sourceId } }
      ]
    }
  ]
})
// Children complete before parents; parent receives child results
```

### Celery Chain Example

```python
from celery import chain

pipeline = chain(
    fetch_data.s(source_id),
    process_data.s(),
    send_report.s(recipient_email)
)
pipeline.apply_async()
```

## Graceful Shutdown

- On SIGTERM, stop accepting new jobs immediately
- Wait for in-progress jobs to complete (with a maximum grace period)
- Return unfinished jobs to the queue for pickup by other workers
- Log shutdown progress: jobs in flight, drain status
- Set the grace period shorter than the orchestrator's kill timeout (e.g., 25s if kill timeout is 30s)

### Node.js Worker Shutdown

```typescript
const worker = new Worker('myQueue', processor, { connection: redisConnection })

process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, closing worker')
  await worker.close() // stops picking up new jobs, waits for current job
  logger.info('Worker closed cleanly')
  process.exit(0)
})
```

### Python Worker Shutdown

```python
import signal
from celery.signals import worker_shutdown

@worker_shutdown.connect
def on_shutdown(**kwargs):
    logger.info('Celery worker shutting down cleanly')

# Celery handles SIGTERM by finishing current task before stopping
```

## Monitoring and Observability

- Track metrics per queue: jobs processed, failed, retried; processing duration; queue depth
- Set up dashboards: BullMQ Board, Flower (Celery), Sidekiq Web UI
- Alert on:
  - Sustained queue growth (depth increasing without processing)
  - High failure rate (>5% of jobs failing)
  - DLQ depth becoming non-zero
  - Processing time spikes (p99 > threshold)
- Include job ID and correlation ID in all log entries
- Use structured logging with consistent fields: `jobId`, `queue`, `attempt`, `duration`, `status`

### Structured Log Example

```typescript
logger.info('Job completed', {
  jobId: job.id,
  queue: job.queueName,
  attempt: job.attemptsMade,
  duration: Date.now() - job.processedOn!,
  status: 'completed',
  correlationId: job.data.correlationId,
})
```
