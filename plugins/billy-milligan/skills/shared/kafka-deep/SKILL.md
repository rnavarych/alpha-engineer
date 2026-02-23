---
name: kafka-deep
description: |
  Kafka deep-dive: topic design (partitions, replication factor), KafkaJS producer with
  idempotent writes, consumer groups with partition assignment, consumer lag monitoring,
  exactly-once semantics, schema registry, compacted topics, DLQ patterns.
  Use when designing Kafka topics, implementing producers/consumers, monitoring consumer lag.
allowed-tools: Read, Grep, Glob
---

# Kafka Deep Dive

## When to Use This Skill
- Designing topic structure (partitions, replication)
- Implementing reliable producers with idempotent writes
- Building consumer groups with proper error handling
- Monitoring consumer lag
- Choosing between Kafka, RabbitMQ, and SQS

## Core Principles

1. **Partition count determines parallelism ceiling** — 6 partitions = max 6 consumers in a group; you cannot scale beyond partition count
2. **Replication factor 3 for production** — 1 node lost: still operational; 2 nodes lost: read-only; RF=1 = data loss risk
3. **Consumer commits must happen after processing** — committing before processing = data loss on crash
4. **At-least-once is the default** — design consumers to be idempotent; dedup with Redis
5. **Consumer lag is the key operational metric** — lag >10k messages at current throughput = alert

## References available
- `references/topic-design.md` — naming conventions, partition count guidelines, replication factor, retention, partition key strategy
- `references/consumer-patterns.md` — KafkaJS producer with idempotent writes, consumer group with DLQ, lag monitoring, Kafka vs RabbitMQ vs SQS
- `references/exactly-once.md` — exactly-once semantics, transactions, schema registry, compacted topics
