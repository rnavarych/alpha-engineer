# Streaming Patterns and Operations

## When to load
Load when designing event-driven architecture patterns (event sourcing, CDC, saga, event mesh), comparing exactly-once semantics across platforms, planning capacity, or applying schema evolution strategy.

## Platform Comparison

| Platform | Architecture | Delivery Guarantee | Latency | Managed Option |
|----------|-------------|-------------------|---------|----------------|
| Apache Kafka | Distributed log, partitioned topics | Exactly-once (EOS) | Low (ms) | Confluent Cloud, MSK |
| Apache Pulsar | Segment-based, BookKeeper | Exactly-once (txn) | Low (ms) | StreamNative |
| Redpanda | Single-binary, Raft per partition | Exactly-once (EOS) | Sub-ms | Redpanda Cloud |
| NATS/JetStream | Subject-based, embedded Raft | At-least-once | Ultra-low | Synadia Cloud |
| Apache Flink | Stream processor, checkpointed | Exactly-once | Low (ms) | Confluent Cloud, KDA |
| Materialize | Differential dataflow | Exactly-once | Low (ms) | Materialize Cloud |
| RisingWave | Distributed streaming SQL | Exactly-once | Low (ms) | RisingWave Cloud |
| Amazon Kinesis | Sharded stream | At-least-once | Low (ms) | AWS-native |
| Azure Event Hubs | Partitioned log | At-least-once | Low (ms) | Azure-native |
| Google Pub/Sub | Global messaging | Exactly-once | Low (ms) | GCP-native |
| EventStoreDB | Append-only event log | Exactly-once (append) | Low (ms) | Event Store Cloud |

## Event-Driven Architecture Patterns

### Pattern 1: Event Sourcing + CQRS

```
Command -> Aggregate -> Event Store (EventStoreDB/Kafka)
                            |
                            v
                     Projection -> Read Model (PostgreSQL/Redis)
                            |
                            v
                     Query API -> Client
```

### Pattern 2: CDC Pipeline

```
PostgreSQL -> Debezium -> Kafka -> Flink/Materialize -> Analytics DB
                           |
                           +-> Elasticsearch (search index)
                           +-> Redis (cache invalidation)
```

### Pattern 3: Saga Pattern (Distributed Transactions)

```
Order Service -> [OrderCreated] -> Payment Service
                                       |
                                  [PaymentConfirmed]
                                       |
                                  Inventory Service -> [InventoryReserved]
                                       |
                                  Shipping Service -> [OrderShipped]
```

### Pattern 4: Event Mesh (Multi-Region)

```
Region A (Kafka) <-- MirrorMaker 2 / Pulsar Geo-Rep --> Region B (Kafka)
       |                                                        |
       v                                                        v
  Local Consumers                                        Local Consumers
```

## Exactly-Once Semantics Comparison

| Platform | Producer Idempotence | Consumer Exactly-Once | End-to-End EOS |
|----------|--------------------|-----------------------|----------------|
| Kafka | enable.idempotence=true | Transactional consumer | Read-process-write in transaction |
| Pulsar | Dedup by sequence ID | Transaction API | Pulsar transactions |
| Redpanda | Kafka-compatible EOS | Kafka-compatible EOS | Kafka-compatible EOS |
| Flink | Checkpointing | Checkpointed offsets | Two-phase commit sinks |
| Kinesis | No native | KCL checkpointing | At-least-once + dedup |
| Pub/Sub | No native | Exactly-once delivery | Dataflow exactly-once |

## Capacity Planning

```bash
# Kafka: estimate partition count
# target_throughput / per_partition_throughput = min_partitions
# 100 MB/s / 10 MB/s = 10 partitions (minimum)
# Account for consumer parallelism: max(throughput_partitions, consumer_count)

# Kafka: estimate disk
# daily_data = messages_per_second * avg_message_size * 86400
# total_disk = daily_data * retention_days * replication_factor * 1.1 (overhead)
```

## Schema Evolution Strategy

- Use Schema Registry with FULL_TRANSITIVE compatibility
- Add fields with defaults (backward compatible)
- Never remove required fields — use deprecation instead
- Use union types for optional fields (Avro) or optional keyword (Protobuf)
- Version topics when breaking changes are unavoidable: `orders.v2`
- Test schema compatibility in CI/CD pipeline

## Monitoring Metrics

- **Kafka**: consumer lag, under-replicated partitions, request latency, disk usage, ISR shrink rate
- **Pulsar**: backlog size, publish/dispatch rate, storage size, BookKeeper journal latency
- **Flink**: checkpoint duration, checkpoint size, back pressure, record throughput
- **General**: end-to-end latency, message throughput, error rate, dead-letter queue depth
