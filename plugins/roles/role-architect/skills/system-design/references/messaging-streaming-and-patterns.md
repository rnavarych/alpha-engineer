# Messaging, Streaming, and System Design Patterns

## When to load
Load when designing message-driven or event-driven systems, stream processing pipelines, search architectures, or working through common internet-scale system design problems (URL shorteners, chat, news feed, rate limiters).

## Message-Driven Architectures

### Message Queue Patterns
- **Point-to-Point (Queue)**: One producer, one consumer. Message delivered to exactly one consumer. Use for task distribution (work queues). Implementations: SQS, RabbitMQ queues, ActiveMQ queues.
- **Publish-Subscribe (Topic)**: One producer, many consumers. Each subscriber receives a copy. Use for event notification. Implementations: SNS, RabbitMQ exchanges (fanout), Kafka topics with consumer groups.
- **Request-Reply**: Async request-response using two queues. Producer sends to request queue with a correlation ID and reply-to queue. Consumer processes and sends response to reply-to queue. Use for async RPC.
- **Dead Letter Queue (DLQ)**: Route messages that fail processing (after N retries) to a DLQ for inspection. Every queue should have a DLQ. Monitor DLQ depth as an operational signal.

### Event-Driven Architecture Patterns
- **Event Notification**: Services emit events when their state changes. Other services listen and react. Services are decoupled but may develop implicit temporal coupling.
- **Event-Carried State Transfer**: Events carry the data needed for consumers to act without querying back. Increases payload size; eliminates inter-service reads during processing.
- **Event Sourcing**: The system's state is derived by replaying an immutable sequence of events. Current state is always computable from the event log. Enables temporal queries ("what was the state at time T?") and full audit trails. Use for financial systems, audit-critical workflows.
- **Outbox Pattern**: Write events to an outbox table in the same database transaction as the business state change. A separate process reads the outbox and publishes to the message broker. Guarantees exactly-once publication without distributed transactions.
- **Saga Pattern**: Coordinate long-running business transactions across services using a sequence of local transactions, each publishing events that trigger the next step. Define compensating transactions for rollback. Choreography (events trigger reactions) vs. orchestration (a central saga orchestrator sends commands).

## Stream Processing Architectures

### Kafka Streams
- Lightweight library for stream processing built on Kafka. Runs inside the application process — no separate cluster required.
- Provides stateful processing via local RocksDB state stores backed by Kafka topics (changelog topics). State is fault-tolerant and recoverable.
- Use for: enriching events with database lookups, aggregating metrics by time windows, joining streams, and maintaining materialized views.
- Windowing: tumbling (fixed, non-overlapping), hopping (fixed-size, overlapping), session (activity-based, gap-defined), and sliding windows.

### Apache Flink
- Distributed stream processing framework with first-class support for event time processing, watermarks, and exactly-once semantics.
- **Event Time vs. Processing Time**: Event time (when the event occurred) enables correct results despite out-of-order delivery. Use watermarks to declare that all events up to time T have arrived, triggering window computations.
- **Checkpointing**: Flink periodically snapshots state to distributed storage (S3, HDFS) using Chandy-Lamport algorithm. On failure, restart from the last checkpoint. Enables exactly-once processing with appropriate sources (Kafka with offset tracking).
- Use for: complex event processing, real-time ML feature computation, financial transaction monitoring, and anomaly detection.

### Spark Streaming / Structured Streaming
- Micro-batch processing (Structured Streaming) using Spark. Treats streaming data as unbounded tables.
- Lower complexity than Flink for teams familiar with Spark. Slightly higher latency (micro-batches, typically 100ms-10s) vs. true streaming.
- Use for: ETL pipelines that must scale from batch to streaming, ML pipelines (Spark MLlib integration), and teams with existing Spark investment.

### Stream Processing Design Principles
- **Idempotent consumers**: Design processors to handle duplicate deliveries safely. Use deduplication windows with unique event IDs.
- **Backpressure**: When downstream processing is slower than upstream production, apply backpressure to slow producers or buffer in bounded queues rather than dropping events.
- **Partition strategy**: Partition streams by the key that determines processing co-location. All events for the same entity should go to the same partition for in-order processing without distributed coordination.
- **Schema evolution**: Use schema registries (Confluent Schema Registry, AWS Glue Schema Registry) with Avro or Protobuf.

## Data Pipeline Architectures

### Pipeline Types
- **Batch**: Process data in bulk on a schedule. Highest throughput, simplest failure recovery. Tools: Apache Spark, dbt, Apache Beam, AWS Glue, GCP Dataflow.
- **Micro-Batch**: Very short intervals (seconds to minutes). Tools: Spark Structured Streaming trigger-once, Airflow DAGs with short schedules.
- **Streaming**: Continuous, event-by-event processing. Lowest latency (milliseconds). Tools: Kafka Streams, Apache Flink, Google Dataflow.
- **Lambda Architecture**: Batch layer (correctness) + Speed layer (freshness) + Serving layer (merged results). Drawback: two code paths that must produce identical results.
- **Kappa Architecture**: Single streaming pipeline handles all data. Reprocess historical data by replaying the Kafka log. Simpler than Lambda; slower for bulk reprocessing.

### Orchestration
- **Apache Airflow**: DAG-based workflow orchestration. Rich operator ecosystem. Industry standard for complex dependency chains.
- **Prefect / Dagster**: Modern Python-native orchestration. Dagster adds asset-based lineage.
- **dbt**: SQL-based transformation layer for data warehouses with built-in testing and documentation.

## Search Architecture
- **Elasticsearch**: Full-text search on Lucene. Inverted index for O(1) term lookup. BM25 scoring + dense_vector for hybrid search. Use for log search, e-commerce, full-text documents.
- **Meilisearch**: Typo-tolerant, fast, single binary. Sub-50ms response times. Use for smaller datasets (< 10M documents).
- **Typesense**: Open-source Algolia alternative. Strong typo tolerance, faceted search, geo-search.
- **Algolia**: Hosted SaaS, globally distributed, < 1ms from edge. Use when search is not a core differentiator.
- **Index synchronization**: Synchronous writes (adds latency), CDC with Debezium, or periodic full reindex.
- **Hybrid search**: Combine BM25 (keyword relevance) with vector similarity (semantic) using Reciprocal Rank Fusion (RRF).

## System Design Patterns for Common Problems

### URL Shortener
- Map short codes (6-8 base62 characters) to long URLs in a key-value store. Redis for speed, PostgreSQL for durability.
- ID generation: Redis INCR, database sequence, or Snowflake IDs. HTTP 302 for analytics; 301 for browser caching.
- Read-heavy (1000:1 ratio). Cache aggressively. CDN caching for redirect responses.

### Rate Limiter
- **Token Bucket**: N tokens max; refill at R/second. Handles burst up to bucket capacity.
- **Sliding Window Counter**: Approximate sliding window by interpolating current and previous window counts. Memory-efficient.
- **Fixed Window Counter**: Simple but vulnerable to boundary bursts (2x limit at window edges).
- **Leaky Bucket**: Constant output rate. Good for smoothing; bad when burst absorption is needed.
- Distributed: Redis atomic INCR + EXPIRE, or Lua scripts for atomic check-and-increment.

### Chat System
- WebSocket connections to chat servers. Redis maps user_id to server_id for routing. Kafka/Redis Pub/Sub for server-to-server communication.
- Message storage: Cassandra with conversation_id as partition key, time-based message_id as clustering key.
- Group chat fan-out: write for small groups; fan-out on read for large groups (thousands of members).

### News Feed
- **Hybrid model**: Fan-out on write for regular users. Fan-out on read for celebrities (> 10K followers).
- Feed storage: Redis sorted set per user. Score = timestamp. ZADD on write, ZREVRANGE on read.
- ML-based ranking replaces chronological order. Pre-ranked feeds stored in Redis.

### Notification System
- Channels: Push (APNs/FCM), Email (SendGrid/SES), SMS (Twilio), In-app.
- Deduplication: Redis SET with TTL tracks recently sent notification IDs.
- Priority tiers: critical notifications bypass batching; marketing can be batched for off-peak.

## Design Workflow

### High-Level Design
1. System context diagram — agree on scope and boundaries.
2. Critical user flows — 3-5 sequence diagrams.
3. Container diagram — choose technologies.
4. Capacity estimation — validate against non-functional requirements.
5. Top-level trade-offs — document in ADRs.

### System Design Interview Pattern
1. **Clarify requirements** (5 min): Scope, scale, NFRs, read/write ratio, consistency, latency targets.
2. **Capacity estimation** (5 min): QPS, storage, bandwidth. Show math, state assumptions.
3. **High-level design** (10 min): Box diagram. Do not optimize yet.
4. **Deep dives** (15 min): 2-3 critical components in detail.
5. **Trade-offs and bottlenecks** (5 min): Proactively identify weaknesses and mitigations.
