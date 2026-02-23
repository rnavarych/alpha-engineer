# Message Broker Selection and Core Patterns

## When to load
Load when choosing a message broker, configuring RabbitMQ exchanges, designing Kafka topics and consumer groups, or setting up schema management.

## Technology Selection

| Technology | Best For | Ordering | Delivery |
|------------|----------|----------|----------|
| RabbitMQ | Task queues, routing, RPC patterns | Per-queue (single consumer) | At-least-once |
| Apache Kafka | Event streaming, log aggregation, high throughput | Per-partition | At-least-once / Exactly-once (transactions) |
| Redis Streams | Lightweight streaming, low-latency, existing Redis infra | Per-stream | At-least-once |
| AWS SQS | Managed queue, serverless integration | FIFO queues (with dedup) | At-least-once / Exactly-once (FIFO) |
| AWS SNS + SQS | Fan-out pub/sub with reliable consumption | Per-subscription | At-least-once |
| Google Pub/Sub | Managed pub/sub, global, exactly-once processing | Per-subscription with ordering keys | At-least-once |

## RabbitMQ Patterns

### Exchange Types
- **Direct**: Route by exact routing key match — use for task queues
- **Topic**: Route by pattern matching (`order.*`, `payment.#`) — use for domain events
- **Fanout**: Broadcast to all bound queues — use for notifications
- **Headers**: Route by message header attributes — use when routing key is insufficient

### Configuration
- Enable publisher confirms for reliable publishing
- Set message TTL and queue max length to prevent unbounded growth
- Use quorum queues for data safety (replicated across nodes)
- Configure prefetch count to control consumer throughput
- Implement dead letter exchanges for failed message handling

## Apache Kafka Patterns

### Topic Design
- One topic per event type or domain aggregate (`orders`, `payments`, `user-events`)
- Use partitions for parallelism — partition count equals max consumer parallelism
- Choose partition key carefully (`userId`, `orderId`) for ordering within entity
- Set retention based on replay requirements (7 days default, longer for event sourcing)

### Consumer Groups
- Each consumer group gets a full copy of the topic data
- Consumers within a group split partitions — max parallelism equals partition count
- Use unique group IDs per service or processing pipeline
- Handle rebalancing gracefully: commit offsets before shutdown
- Monitor consumer lag to detect slow consumers

### Schema Management
- Use a schema registry (Confluent Schema Registry, AWS Glue)
- Avro or Protobuf for schema evolution with backward/forward compatibility
- Validate schemas on both produce and consume sides
- Never make breaking schema changes without a new topic or version field
