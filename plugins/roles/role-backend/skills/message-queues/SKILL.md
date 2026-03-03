---
name: role-backend:message-queues
description: |
  Implements message queue systems using RabbitMQ, Apache Kafka, Redis Streams, AWS SQS/SNS,
  and Google Pub/Sub. Covers topics, exchanges, dead letter queues, idempotency, ordering
  guarantees, consumer groups, backpressure handling, and message serialization.
  Use when setting up async communication, event-driven architectures, or decoupling services.
allowed-tools: Read, Grep, Glob, Bash
---

# Message Queues

## When to use
- Choosing between RabbitMQ, Kafka, Redis Streams, SQS, or Pub/Sub for a new integration
- Designing RabbitMQ exchange topology (direct, topic, fanout, headers)
- Designing Kafka topic partitioning and consumer group structure
- Implementing idempotent consumers that handle duplicate delivery safely
- Setting up dead letter queues and replay tooling for failed messages
- Enforcing ordering guarantees without sacrificing throughput
- Managing backpressure between fast producers and slow consumers
- Choosing message serialization format (JSON vs Avro vs Protobuf)

## Core principles
1. **At-least-once is the default** — every consumer must be idempotent; duplicates will arrive
2. **Partition key determines order** — group messages by entity ID, not randomly
3. **DLQ depth is never acceptable as a steady state** — it means something is broken
4. **Schema versioning from day one** — breaking changes without a registry are production incidents waiting to happen
5. **Consumer lag is the real SLA** — not throughput; lag tells you whether processing keeps pace with production

## Reference Files

- `references/brokers-patterns.md` — technology selection table with ordering and delivery guarantees, RabbitMQ exchange types and configuration, Kafka topic design and consumer group rules, and schema registry with Avro/Protobuf guidance
- `references/reliability-patterns.md` — DLQ setup and retention policy, idempotent consumer implementation with idempotency table SQL, ordering guarantees and retry trade-offs, backpressure techniques, message serialization format selection, and claim-check pattern for oversized payloads
