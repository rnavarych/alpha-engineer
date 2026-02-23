# Async Processing

## When to load
Load when discussing message queues, event-driven architecture, worker patterns, backpressure, or offloading work from the synchronous request path.

## Patterns

### Queue comparison
| Feature | SQS | RabbitMQ | Kafka |
|---------|-----|----------|-------|
| Model | Pull-based queue | Push/pull queue | Distributed log |
| Ordering | FIFO (optional) | Per-queue | Per-partition |
| Throughput | ~3k msg/s (FIFO) | ~30k msg/s | ~100k+ msg/s |
| Retention | 14 days max | Until consumed | Configurable (forever) |
| Replay | No | No | Yes (offset reset) |
| Use case | Task queue, decoupling | Complex routing | Event streaming, CDC |
| Ops complexity | None (managed) | Medium | High |

### Producer pattern
```typescript
// SQS: fire-and-forget task queue
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

async function enqueueEmailJob(to: string, template: string, data: object) {
  await sqs.send(new SendMessageCommand({
    QueueUrl: process.env.EMAIL_QUEUE_URL,
    MessageBody: JSON.stringify({ to, template, data, enqueuedAt: Date.now() }),
    MessageGroupId: to,              // FIFO: group by recipient
    MessageDeduplicationId: `${to}:${template}:${Date.now()}`,
  }));
}

// Kafka: event streaming
import { Kafka } from 'kafkajs';

const producer = kafka.producer({ idempotent: true }); // exactly-once semantics
await producer.send({
  topic: 'order-events',
  messages: [{
    key: orderId,            // partition by order ID
    value: JSON.stringify({ type: 'order.created', data: order }),
    headers: { 'correlation-id': correlationId },
  }],
});
```

### Worker pattern
```typescript
// Reliable worker with visibility timeout
async function processMessages() {
  while (true) {
    const messages = await sqs.send(new ReceiveMessageCommand({
      QueueUrl: QUEUE_URL,
      MaxNumberOfMessages: 10,      // batch for efficiency
      WaitTimeSeconds: 20,          // long polling (reduce API calls)
      VisibilityTimeout: 300,       // 5min to process
    }));

    for (const msg of messages.Messages || []) {
      try {
        const job = JSON.parse(msg.Body);
        await processJob(job);
        await sqs.send(new DeleteMessageCommand({
          QueueUrl: QUEUE_URL,
          ReceiptHandle: msg.ReceiptHandle,
        }));
      } catch (err) {
        // Message becomes visible again after visibility timeout
        // After maxReceiveCount (3), moves to DLQ
        logger.error({ err, messageId: msg.MessageId }, 'Job processing failed');
      }
    }
  }
}

// Kafka consumer group
await consumer.run({
  partitionsConsumedConcurrently: 4,
  eachMessage: async ({ topic, partition, message }) => {
    try {
      await handleEvent(JSON.parse(message.value.toString()));
    } catch (err) {
      await dlqProducer.send({
        topic: `${topic}.dlq`,
        messages: [{ key: message.key, value: message.value,
          headers: { ...message.headers, error: err.message, originalTopic: topic }
        }],
      });
    }
  },
});
```

### Backpressure
```typescript
// Rate-limited consumer
import { RateLimiter } from 'limiter';
const limiter = new RateLimiter({ tokensPerInterval: 100, interval: 'second' });

async function processWithBackpressure(message: Message) {
  await limiter.removeTokens(1);  // wait if rate exceeded
  await processMessage(message);
}

// Circuit breaker on downstream dependency
import CircuitBreaker from 'opossum';

const breaker = new CircuitBreaker(callExternalService, {
  timeout: 5000,
  errorThresholdPercentage: 50,  // open at 50% error rate
  resetTimeout: 30000,           // try again after 30s
  volumeThreshold: 10,           // minimum 10 calls before tripping
});

breaker.on('open', () => logger.warn('Circuit breaker opened'));
```

## Anti-patterns
- Processing in the request path what could be async -> slow API responses
- No DLQ -> failed messages disappear silently
- Unbounded concurrency in workers -> overwhelm downstream services
- No idempotency in consumers -> duplicate processing on retry
- Visibility timeout shorter than processing time -> duplicate processing

## Decision criteria
- **SQS**: default for AWS, simple task queues, no replay needed, zero ops
- **RabbitMQ**: complex routing (topic exchange, headers), priority queues, self-hosted OK
- **Kafka**: event streaming, need replay, CDC, high throughput (>50k msg/s), event sourcing

## Quick reference
```
SQS: simple queue, FIFO optional, 14d retention, managed
RabbitMQ: routing flexibility, priorities, ~30k msg/s
Kafka: event log, replay, partitioned, ~100k+ msg/s
Visibility timeout: 2-3x expected processing time
Long polling: WaitTimeSeconds=20 (SQS), reduces API calls
Batch size: 10 messages (SQS), tune by processing time
Circuit breaker: open at 50% errors, reset after 30s
Idempotency: always, use message ID + dedup key
```
