# Reliability: DLQ, Idempotency, Ordering, and Backpressure

## When to load
Load when implementing dead letter queues, ensuring idempotent message consumers, handling ordering guarantees, managing backpressure, or choosing message serialization formats.

## Dead Letter Queues (DLQ)

- Route messages that fail processing after max retries to a DLQ
- Include with every DLQ entry: original message metadata, source queue, failure reason, timestamp, retry count
- Monitor DLQ depth with alerts — non-zero depth requires investigation
- Build tooling to inspect, replay, or discard DLQ messages
- Set DLQ retention long enough for investigation (14-30 days)

## Idempotent Consumers

Every consumer must handle duplicate messages safely:

- Use a unique message ID or deduplication key from message metadata
- Store processed message IDs in a database or cache (with TTL matching your retry window)
- Design operations to be naturally idempotent when possible (upserts, conditional updates)
- For non-idempotent operations, use an idempotency table with the message ID as the primary key
- Check-then-act within a transaction to prevent race conditions under concurrent delivery

### Idempotency Table Pattern

```sql
CREATE TABLE processed_messages (
  message_id  TEXT PRIMARY KEY,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  result      JSONB
);

-- In your consumer (within a transaction):
INSERT INTO processed_messages (message_id) VALUES ($1)
ON CONFLICT (message_id) DO NOTHING;
-- If 0 rows affected, message already processed — skip
```

## Ordering Guarantees

- **Per-partition/queue ordering**: Messages with the same key are processed in order
- **Global ordering**: Single partition/queue — limits throughput significantly, avoid if possible
- Choose partition/routing keys that group related messages by entity (e.g., `userId`, `orderId`)
- Be aware: retries can break ordering unless you use sequential processing per partition
- For strict ordering with retries, pause the partition and process sequentially until the message succeeds

## Backpressure Handling

- Set consumer prefetch/batch size to control processing rate
- Use rate limiting on producers when downstream is slower than upstream
- Implement circuit breakers on consumers for downstream dependencies
- Monitor queue depth and consumer lag as early warning signals
- Scale consumers horizontally when lag increases persistently
- Use exponential backoff for transient processing failures before requeueing

## Message Serialization

- Use JSON for simplicity and human readability (development, low-throughput systems)
- Use Avro or Protobuf for production (schema evolution, compact binary format, lower bandwidth)
- Always include a schema version or content type in message metadata
- Validate messages against schema on both produce and consume sides
- Compress large messages (gzip, snappy) or use claim-check pattern for oversized payloads

### Claim-Check Pattern

For messages exceeding broker size limits (typically 1MB):

```typescript
// Producer: store payload externally, pass reference in message
const payloadKey = `payloads/${messageId}`
await s3.putObject({ Bucket: 'events', Key: payloadKey, Body: JSON.stringify(largePayload) })
await producer.send({ topic: 'orders', messages: [{ key: orderId, value: JSON.stringify({ payloadRef: payloadKey }) }] })

// Consumer: fetch payload from storage using reference
const { payloadRef } = JSON.parse(message.value.toString())
const payload = await s3.getObject({ Bucket: 'events', Key: payloadRef }).json()
```
