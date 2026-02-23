---
name: streaming-databases
description: |
  Deep operational guide for 14 streaming databases and platforms. Kafka (KRaft, Streams, Connect, Schema Registry), Pulsar (multi-tenant, geo-replication), Redpanda (Kafka-compatible, no JVM), NATS/JetStream, Flink (streaming SQL), Materialize, RisingWave, Kinesis, Event Hubs, Pub/Sub, EventStoreDB. Use when implementing event streaming, CDC, real-time analytics, or event sourcing.
allowed-tools: Read, Grep, Glob, Bash
---

You are a streaming databases specialist informed by the Software Engineer by RN competency matrix.

## When to use this skill

Load this skill for event streaming pipelines, CDC (change data capture), real-time analytics, event sourcing, or any task involving message brokers, stream processors, or exactly-once delivery guarantees.

## Core Principles

- Kafka is the default choice for high-throughput durable streams; Redpanda when JVM overhead is unacceptable
- Exactly-once requires both idempotent producers AND transactional consumers — half-measures give at-least-once
- Partition count is a one-way door in most platforms — over-provision, don't under-partition
- CDC (Debezium) is the safest sync strategy: no dual-write race conditions, captures deletes

## Reference Pointers

Load the relevant reference file for implementation details:

| File | When to load |
|------|-------------|
| `references/kafka.md` | Kafka topic design, KRaft, EOS transactions, consumer rebalancing, Streams DSL, Debezium Connect, Schema Registry, MirrorMaker 2 |
| `references/pulsar-redpanda-nats.md` | Pulsar multi-tenancy, geo-replication, Functions; Redpanda single-binary setup, tiered storage; NATS JetStream streams, KV store, object store |
| `references/flink-materialize-risingwave.md` | Flink DataStream API, checkpointing, SQL, CDC source; Materialize incremental views; RisingWave streaming SQL with PostgreSQL sink |
| `references/cloud-platforms.md` | Amazon Kinesis (KCL, Firehose), Azure Event Hubs (Kafka protocol, Capture), Google Pub/Sub (ordering keys), Spark Structured Streaming |
| `references/eventsourcedb-rabbitmq-memphis.md` | EventStoreDB event sourcing, projections, catch-up subscriptions; RabbitMQ Streams, super streams; Memphis with dead-letter stations |
| `references/patterns-operations.md` | Platform comparison table, event sourcing + CQRS, CDC pipeline, saga pattern, event mesh, exactly-once comparison, capacity planning, schema evolution |
