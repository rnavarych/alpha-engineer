# Job Design, Retry Strategies, and Dead Letter Handling

## When to load
Load when designing job payloads, configuring retry policies, implementing dead letter queues, or setting up job prioritization and scheduled cron tasks.

## Technology Selection

| Technology | Language | Backend | Best For |
|------------|----------|---------|----------|
| BullMQ | Node.js/TS | Redis | Job queues, rate limiting, job dependencies, flows |
| Bull | Node.js/TS | Redis | Simpler job queues (predecessor to BullMQ) |
| Celery | Python | Redis/RabbitMQ | Distributed task queues, periodic tasks, chaining |
| Sidekiq | Ruby | Redis | High-performance Ruby background processing |
| Hangfire | C#/.NET | SQL Server/Redis | .NET background processing, dashboard |
| Quartz | Java | JDBC | Enterprise scheduling, cron-like triggers |

## Job Design Principles

### Idempotency
- Every job must be safe to execute multiple times with the same input
- Use unique job IDs to detect and skip duplicate processing
- Design database operations as upserts or conditional updates
- Store processing state externally, not in the job payload

### Atomicity
- Each job should do one logical unit of work
- Break complex workflows into multiple chained/dependent jobs
- If a job partially completes, the retry must not create duplicates or inconsistencies

### Serialization
- Job payloads must be JSON-safe (no class instances, no circular refs)
- Pass IDs and references, not large objects or database records
- Fetch fresh data inside the job (data may change between enqueue and execution)
- Keep payloads small — queue storage has limits

## Retry Strategies

### Exponential Backoff with Jitter
```
delay = min(base_delay * 2^attempt + random_jitter, max_delay)
```
- Base delay: 1-5 seconds
- Max delay: 5-30 minutes (prevents excessive delays)
- Max retries: 3-10 depending on operation criticality
- Jitter: random 0-30% of delay to prevent thundering herd

### Retry Configuration by Job Type
- **Email sending**: 3 retries, 30s / 2m / 10m
- **Payment processing**: 5 retries, 1m / 5m / 15m / 30m / 60m
- **Webhook delivery**: 8 retries, 1m / 5m / 15m / 30m / 1h / 2h / 4h / 8h
- **Data sync**: 3 retries, 1m / 5m / 15m

### Non-Retryable Errors
- Distinguish between transient and permanent failures
- Do not retry: validation errors, 4xx responses, business rule violations
- Do retry: network timeouts, 5xx responses, database connection errors
- Throw specific error types/classes to signal retry vs no-retry

## Dead Letter Handling

- Move jobs to a dead letter queue after exhausting all retries
- Store with every DLQ entry: original payload, error message, stack trace, attempt count, timestamps
- Alert on DLQ depth — non-zero requires investigation
- Build admin tooling to inspect, retry, or discard dead-lettered jobs
- Set retention policy on DLQ entries (30-90 days)

## Job Prioritization

- Use separate queues for different priority levels (critical, high, normal, low)
- Process higher-priority queues first (weighted or strict ordering)
- Example: payment confirmations (critical) > order notifications (high) > analytics sync (low)
- Monitor queue depths per priority to detect starvation of lower-priority jobs
- Consider rate-limited queues for external API calls (respect third-party rate limits)

## Cron / Scheduled Jobs

- Use cron expressions for periodic tasks: `0 */6 * * *` (every 6 hours)
- Implement distributed locking to prevent duplicate execution in multi-instance deployments
- Use leader election or a single scheduler instance with a worker fleet
- Log every scheduled execution with start time, duration, and outcome
- Implement overlapping protection — skip if the previous run is still active
- Tools: BullMQ repeatable jobs, Celery Beat, cron with Redis distributed lock
