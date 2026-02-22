---
name: system-design
description: |
  System design expertise including requirements analysis, C4 model diagrams,
  sequence diagrams, data flow diagrams, trade-off documentation,
  capacity estimation, distributed systems theory, load balancing algorithms,
  caching architectures, message-driven and stream processing architectures,
  data pipeline design, search architecture, and system design patterns for
  common internet-scale systems (URL shorteners, chat, news feed, rate limiters).
allowed-tools: Read, Grep, Glob, Bash
---

# System Design

## Requirements Analysis

### Functional Requirements
- Enumerate all user-facing capabilities the system must provide. Express each as a user story or use case with clear acceptance criteria.
- Identify core vs. ancillary features. Core features define the system's reason for existence; ancillary features can be deferred or simplified.
- Map requirements to system boundaries. Each requirement should trace to exactly one owning service or module.

### Non-Functional Requirements
- Define explicit targets for each quality attribute:
  - **Availability**: Target SLA (e.g., 99.9% = 8.76 hours downtime/year). Identify which components are on the critical path.
  - **Latency**: P50, P95, P99 targets per endpoint or user flow. Distinguish between interactive (< 200ms) and background (< 5s) operations.
  - **Throughput**: Expected QPS at launch, at 6 months, at 2 years. Identify peak multipliers (e.g., 3x during promotions).
  - **Durability**: Data loss tolerance. RPO and RTO for disaster recovery.
  - **Consistency**: Strong vs. eventual. Per-feature, not system-wide. Financial transactions need strong; activity feeds can be eventual.
  - **Security**: Authentication method, authorization model, encryption requirements, compliance constraints.
- Rank non-functional requirements by priority. When they conflict (e.g., consistency vs. latency), the ranking determines which wins.

## C4 Model Diagrams

### Level 1: System Context
- Show the system as a single box surrounded by its users (personas) and external systems it interacts with.
- Label every arrow with the interaction type and protocol (e.g., "Places orders via HTTPS/REST").
- Include both human actors and automated systems (payment gateways, email providers, third-party APIs).
- Use Mermaid C4 syntax for embedding in ADRs:
  ```
  C4Context
    Person(user, "User", "A customer of the system")
    System(system, "System Name", "Provides X capability")
    System_Ext(ext, "External System", "Sends events")
    Rel(user, system, "Uses", "HTTPS")
    Rel(system, ext, "Calls", "REST/JSON")
  ```

### Level 2: Container Diagram
- Decompose the system into containers: web apps, APIs, databases, message brokers, caches, file storage.
- Show technology choices on each container (e.g., "API Server — Node.js / Express").
- Draw communication paths with protocols and data formats (REST/JSON, gRPC/Protobuf, AMQP).
- Every container should have a clearly stated responsibility boundary. Containers that do too many things indicate a missing decomposition.

### Level 3: Component Diagram
- For each container that warrants deeper exploration, show its internal components (modules, services, controllers, repositories).
- Map responsibilities to components. Each component should have a single, clear purpose.
- Show dependencies between components and highlight interfaces/contracts.

### Level 4: Code Diagram
- Use sparingly. Only for critical or complex components where the internal class/function structure is non-obvious.
- Show key classes, interfaces, and their relationships. Align with the actual code structure.

## Sequence Diagrams

- Create sequence diagrams for every critical user flow and every flow that crosses more than two system boundaries.
- Show the happy path first, then add alt/opt frames for error cases and edge conditions.
- Include timing annotations for steps with SLA implications (database queries, external API calls).
- Label messages with both the logical action and the technical mechanism (e.g., "Create Order — POST /api/orders").

## Data Flow Diagrams

- Map how data enters, transforms, and exits the system. Identify every data source and sink.
- Mark trust boundaries explicitly. Data crossing a trust boundary must be validated, sanitized, or encrypted.
- Identify data at rest and data in transit. Annotate encryption requirements for each.
- Show data retention policies and archival flows for compliance-sensitive data.

## Trade-off Documentation

- For every significant design choice, document at least two alternatives side by side.
- Evaluate each alternative against explicit criteria: cost, complexity, latency, scalability, operational burden, team familiarity, and time-to-market.
- Use a decision matrix with weighted scores when multiple stakeholders are involved.
- Record which trade-off was accepted and why. Link to the corresponding ADR.

## Capacity Estimation

- Start with user-facing metrics: DAU, peak concurrent users, average session length, actions per session.
- Derive system-level metrics: QPS = DAU x actions_per_session / seconds_per_day. Apply peak multiplier (typically 2x-5x average).
- Estimate storage: record size x records_per_day x retention_period. Account for indexes, replicas, and backups.
- Estimate bandwidth: average_response_size x QPS. Include both ingress and egress.
- Size infrastructure: CPU cores, memory, disk IOPS. Add 30-50% headroom for unexpected spikes.

## Distributed Systems Theory

### CAP Theorem
- In the presence of a network partition, a distributed system must choose between Consistency (every read receives the most recent write) and Availability (every request receives a response, possibly stale).
- **CP systems** (Consistency + Partition tolerance): HBase, Zookeeper, etcd, Spanner. Choose when stale reads are unacceptable (financial balances, inventory counts).
- **AP systems** (Availability + Partition tolerance): Cassandra, CouchDB, DynamoDB (default), Riak. Choose when availability and latency are paramount and stale reads are acceptable (user profiles, social feeds).
- CA systems (Consistency + Availability without partition tolerance) are not realistic in distributed deployments. Traditional RDBMS on a single node is CA, but that is vertical scaling, not distributed.

### PACELC Theorem
- Extends CAP to account for behavior when no partition exists: even without partitions, you trade Latency for Consistency.
- **PA/EL** (Partition: Availability; Else: Low latency): Cassandra, DynamoDB, Riak. Best for high-throughput, globally distributed writes.
- **PC/EC** (Partition: Consistency; Else: Consistency): HBase, Zookeeper. Best for coordination and metadata storage.
- **PA/EC** (Partition: Availability; Else: Consistency): MongoDB. Prioritizes consistency when the network is stable.
- Use PACELC to make the latency-consistency trade-off explicit even in normal operating conditions.

### Consensus Algorithms
- **Raft**: Leader-based consensus. A leader is elected per term; all writes go through the leader and are replicated to a quorum (majority) before acknowledging. Simpler to understand than Paxos. Used by etcd, CockroachDB, TiKV. Key properties: leader election, log replication, safety (never returns an uncommitted value).
- **Paxos**: Classic consensus algorithm with two phases (Prepare/Promise, Accept/Accepted). More flexible than Raft but harder to implement correctly. Multi-Paxos adds leader optimization. Used by Google Spanner, Chubby.
- **Zab (ZooKeeper Atomic Broadcast)**: Consensus protocol for ZooKeeper. Separates leader election (fast path) from log replication. Optimized for crash-recovery with sequential consistency.
- **Practical consideration**: Do not implement consensus algorithms yourself. Use etcd, ZooKeeper, or Consul as coordination services.

### Vector Clocks and Lamport Timestamps
- **Lamport Timestamps**: Logical clock that captures "happened-before" relationships. Each event increments the clock. When sending a message, include the current timestamp. On receipt, set clock to max(local, received) + 1. Establishes a partial order of events but cannot detect concurrent events.
- **Vector Clocks**: Each node maintains a vector of counters, one per node. When an event occurs, increment your own counter. When sending, include the full vector. On receipt, take the element-wise maximum. Two events are concurrent if neither vector dominates the other. Used by Dynamo, Riak for conflict detection.
- **Hybrid Logical Clocks (HLC)**: Combine physical time with logical counters. Events are ordered by wall clock time when possible, falling back to logical counters for concurrent events. Used by CockroachDB and YugabyteDB for cross-node ordering.

### CRDTs and Conflict Resolution
- **CRDTs (Conflict-free Replicated Data Types)**: Data structures designed to merge concurrent updates automatically without coordination. Two categories:
  - **State-based CRDTs (CvRDTs)**: Merge full state. Examples: G-Counter (grow-only counter), PN-Counter (increment/decrement), G-Set (grow-only set), OR-Set (observed-remove set), LWW-Register (last-write-wins).
  - **Operation-based CRDTs (CmRDTs)**: Transmit operations; requires reliable delivery. More network-efficient but more complex.
- **Last-Write-Wins (LWW)**: Resolve conflicts by timestamp. Simple and widely used. Risk: concurrent writes lose data. Mitigate with vector clocks to detect true concurrency vs. causally ordered writes.
- **Multi-Value (MV) Register**: Keep all concurrent versions and expose them to the application for manual resolution. Used by Amazon S3, CouchDB. Requires application-layer merge logic.
- **Application-specific resolution**: For business logic conflicts (e.g., two users updating the same shopping cart item), define domain-specific merge rules (union of items, max quantity, etc.).

### Eventual Consistency Patterns
- **Read Repair**: On a read, compare responses from multiple replicas. If they differ, repair the out-of-date replica in the background. Used by Cassandra, Dynamo.
- **Anti-Entropy (Merkle Trees)**: Background process compares data between replicas using a hash tree. Only transmits differing subtrees. Used by DynamoDB, Cassandra for full sync.
- **Hinted Handoff**: When a replica is unavailable, the coordinator temporarily stores writes intended for it (hints). When the replica comes back, hints are replayed. Used by Cassandra, Dynamo.
- **Causal Consistency**: Guarantee that causally related reads and writes are seen in causal order, even if unrelated operations are eventually consistent. Implemented with vector clocks or dependency tracking.

## Load Balancing Algorithms

### Round-Robin
- Distribute requests sequentially across all healthy backends. Backend 1, 2, 3, 1, 2, 3...
- Best for: homogeneous backends with similar request costs and similar capacity.
- Limitation: does not account for request weight or backend load. A slow request can cause queue buildup on one backend while others are idle.
- **Weighted Round-Robin**: Assign weights to backends based on capacity. A backend with weight 3 receives 3x the traffic of a backend with weight 1. Use for heterogeneous instance types.

### Least Connections
- Route each new request to the backend with the fewest active connections.
- Best for: long-lived connections (WebSockets, gRPC streams, database connections) where request duration varies significantly.
- Limitation: does not account for request weight (a cheap request and an expensive request both count as 1 connection).
- **Least Response Time**: Combine least connections with lowest average response time. More accurate but requires tracking response times. Used by Nginx Plus, HAProxy.

### Consistent Hashing
- Map both requests and backends onto a ring (by hashing). Route each request to the first backend clockwise from the request's hash position.
- Key property: when a backend is added or removed, only K/n keys are remapped (K = number of keys, n = number of backends). Traditional hashing remaps almost all keys on topology changes.
- **Virtual nodes**: Each physical backend is represented by multiple positions on the ring (virtual nodes). Improves distribution uniformity. Cassandra uses 256 virtual nodes per physical node.
- Use for: distributed caches (Memcached, Redis Cluster), object storage routing, and any stateful routing where session affinity or data locality matters.

### Maglev Hashing
- Google's consistent hashing algorithm used in their load balancers (GFE). Produces a lookup table that maps connection 5-tuples to backends.
- Key property: minimal disruption on backend changes (near-minimal movement compared to Rendezvous hashing). Near-perfect load distribution.
- Faster than ring-based consistent hashing for lookup (O(1) table lookup vs. O(log n) ring traversal).
- Use for: high-throughput Layer 4 load balancers where lookup performance matters.

### Random with Power of Two Choices
- For each request, randomly select 2 backends, then route to the less loaded one.
- Achieves near-optimal load distribution with O(1) lookup. Significantly better than pure random.
- Reduces max load on any backend from O(log n / log log n) to O(log log n) compared to random.

## Caching Architectures

### Cache-Aside (Lazy Loading)
- Application checks cache first. On miss: read from database, populate cache, return result.
- Cache contains only requested data. Resilient to cache failure (falls back to database).
- Risk: cache stampede on cold start. Mitigate with mutex locks or probabilistic early expiration.

### Write-Through
- On every write, update both the cache and the database synchronously before returning success.
- Guarantees cache-database consistency. Cache is always warm.
- Adds write latency. Cache may hold data that is never read (write-heavy, read-light patterns waste cache space).

### Write-Behind (Write-Back)
- On write, update cache immediately and acknowledge. Persist to database asynchronously (in the background).
- Reduces write latency significantly. Excellent for write-heavy workloads.
- Risk: data loss if the cache fails before background write completes. Use only when occasional data loss is acceptable or with durable cache (Redis with AOF persistence).

### Read-Through
- Application always reads from cache. On miss, the cache itself fetches from database and populates.
- Transparent to the application — no cache logic in application code.
- Use with: Ehcache, Guava LoadingCache, or any cache library with loader support.

### Multi-Layer Caching
- Layer 1: In-process / L1 cache (Guava, Caffeine, node-lru-cache). Nanosecond latency. Size: MB. Per-instance, no sharing.
- Layer 2: Distributed cache (Redis, Memcached). Microsecond latency. Size: GB-TB. Shared across instances.
- Layer 3: CDN edge cache (CloudFront, Fastly, Cloudflare). Millisecond latency globally. Size: unlimited. Serves static and cacheable dynamic content.
- Layer 4: Database query cache / materialized views. Seconds to build. Amortized over many reads.
- Design cache key hierarchies that align with cache invalidation granularity. Fine-grained keys enable surgical invalidation; coarse-grained keys enable bulk invalidation.

### Distributed Cache Patterns
- **Redis Cluster**: Hash-slot-based sharding across 3-16383 hash slots. Use for shared session state, pub/sub, rate limiting, and distributed locks (Redlock).
- **Memcached**: Simpler, multi-threaded, no persistence. Use for pure caching where data loss on restart is acceptable. Slightly better raw throughput than Redis for simple get/set.
- **Cache Stampede Prevention**: Probabilistic early expiration (recalculate before expiry with probability proportional to time-to-expire). XFetch algorithm. Mutex/singleflight for concurrent cache misses.
- **Hot Key Problem**: A single highly popular key overwhelms a single cache node. Solutions: local in-process cache layer for hot keys, read replicas per hot key, key-level sharding (append a random suffix and merge on read).

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
- **Backpressure**: When downstream processing is slower than upstream production, apply backpressure to slow producers or buffer in bounded queues rather than dropping events. Reactive Streams specification defines backpressure contracts.
- **Partition strategy**: Partition streams by the key that determines processing co-location. All events for the same entity should go to the same partition for in-order processing without distributed coordination.
- **Schema evolution**: Use schema registries (Confluent Schema Registry, AWS Glue Schema Registry) with Avro or Protobuf. Define forward and backward compatibility rules before adding fields.

## Data Pipeline Architectures

### Batch Pipelines
- Process data in bulk on a schedule (hourly, daily). Highest throughput, simplest failure recovery (re-run the batch).
- Use for: nightly ETL to data warehouse, machine learning training jobs, report generation, and compliance data exports.
- Tools: Apache Spark, dbt (for SQL transformations), Apache Beam, AWS Glue, GCP Dataflow.

### Micro-Batch Pipelines
- Run batch jobs on very short intervals (seconds to minutes). Compromise between batch simplicity and streaming freshness.
- Tools: Spark Structured Streaming in trigger-once mode, AWS Glue incremental crawlers, Airflow DAGs with short schedules.
- Use for: near-real-time dashboards where true streaming is overkill, incremental data warehouse loads.

### Streaming Pipelines
- Continuous, event-by-event processing. Lowest latency (milliseconds). Highest complexity.
- Use for: fraud detection, real-time personalization, live dashboards, alerting systems.
- Tools: Kafka Streams, Apache Flink, Spark Structured Streaming, Google Dataflow, AWS Kinesis Data Analytics.

### Lambda Architecture
- Batch layer: reprocesses all historical data periodically for correctness. Backed by Hadoop/Spark on object storage.
- Speed layer: processes recent data in real time for freshness. Backed by Kafka Streams or Flink.
- Serving layer: merges batch views and speed layer views. Query hits both and combines results.
- Drawback: maintaining two code paths (batch and streaming) that must produce identical results is operationally expensive. Prefer Kappa unless you have a specific need for historical reprocessing.

### Kappa Architecture
- Single streaming pipeline handles all data. Reprocess historical data by replaying the message log (Kafka with extended retention).
- Simpler to operate and reason about than Lambda. Only one code path.
- Limitation: Kafka log replay is slower and more expensive than batch reprocessing with Spark. Use Lambda when reprocessing speed matters.

### Data Pipeline Orchestration
- **Apache Airflow**: DAG-based workflow orchestration. Rich operator ecosystem. Industry standard. Use for: complex dependency chains, mixed batch/streaming pipelines, cross-system workflows.
- **Prefect / Dagster**: Modern Python-native orchestration with better developer experience than Airflow. Dagster adds asset-based lineage. Use for data engineering teams preferring modern tooling.
- **dbt (data build tool)**: SQL-based transformation layer for data warehouses. Defines transformations as SELECT statements with dependency management. Built-in testing and documentation. Use for warehouse transformation layers.

## Search Architecture

### Elasticsearch
- Full-text search engine based on Apache Lucene. Distributed, horizontally scalable.
- **Inverted index**: Maps terms to document IDs. Enables O(1) term lookup.
- **Sharding**: Index split across N primary shards. Each shard has R replicas for fault tolerance and read scaling.
- **Relevance scoring**: BM25 algorithm by default. Combine with vector similarity (KNN with dense_vector) for semantic search.
- Use for: log search (ELK stack), e-commerce product search, full-text document search, and security event analysis.

### Meilisearch
- Typo-tolerant, fast full-text search. Single binary, easy to operate. Sub-50ms response times.
- Use for: user-facing search on smaller datasets (< 10M documents), developer tools, and teams prioritizing operator simplicity.

### Typesense
- Open-source alternative to Algolia. Strong typo tolerance, faceted search, geo-search.
- Simpler than Elasticsearch for pure search use cases. Use when Elasticsearch operational complexity is not justified.

### Algolia
- Hosted search-as-a-service. No infrastructure to manage. Globally distributed, < 1ms search latency from edge nodes.
- Use when: search is not a core differentiator, team wants to avoid search infrastructure, and budget allows.

### Search Architecture Patterns
- **Index synchronization**: Keep the search index in sync with the operational database. Options: synchronous writes (adds search latency to write path), CDC with Debezium, or periodic full reindexing.
- **Denormalized search documents**: Store all fields needed for search and display in the search document. Avoid joins at query time. Accept that search documents may be slightly stale.
- **Hybrid search**: Combine BM25 (keyword relevance) with vector similarity (semantic relevance) using Reciprocal Rank Fusion (RRF) or linear interpolation. Use for e-commerce and content search where both exact match and semantic similarity matter.

## System Design Patterns for Common Problems

### URL Shortener
- **Core design**: Map short codes (6-8 random base62 characters) to long URLs in a key-value store. Key: short code, Value: long URL + metadata.
- **ID generation**: Use a distributed counter (Redis INCR, database sequence) or UUID + base62 encoding. For truly unique codes at scale, use Snowflake IDs or hash the long URL and truncate.
- **Redirect**: HTTP 301 (permanent) for caching by browsers, 302 (temporary) to count clicks. Use 302 if analytics are needed.
- **Storage**: At 100M URLs with 500 bytes/URL = 50 GB. Fits in Redis. For durability, persist to PostgreSQL with Redis as cache.
- **Read scaling**: Read-heavy (1000:1 read/write ratio). Cache short-code-to-URL mapping aggressively in Redis (TTL = long, invalidate on deletion). CDN caching for redirect responses.
- **Custom aliases**: Allow users to choose their short code. Check uniqueness before creation. Reserve namespace for branded aliases.

### Rate Limiter
- **Token Bucket**: Bucket holds up to N tokens. Tokens refill at R tokens/second. Each request consumes 1 token. Request rejected if bucket is empty. Handles burst traffic up to bucket capacity. Smooth refill.
- **Sliding Window Log**: Track timestamps of all requests in a rolling window. Count entries in the window. If count < limit, allow; else reject. Accurate but memory-intensive (stores all request timestamps).
- **Sliding Window Counter**: Divide time into fixed windows. Approximate the sliding window by interpolating between the current window count and the previous window count. `count = curr_window_count + prev_window_count * ((window_size - elapsed_in_current_window) / window_size)`. Memory-efficient approximation.
- **Fixed Window Counter**: Simple. Counter per time window per user. Reset at window boundary. Vulnerable to boundary burst (2x limit possible at window edges). Use only when approximate limiting is acceptable.
- **Leaky Bucket**: Requests enter a queue (bucket) at any rate. Queue drains at a constant output rate. Smooths bursts into a constant stream. Good for rate-smoothing; bad when burst absorption is needed.
- **Distributed rate limiting**: Use Redis atomic operations (INCR + EXPIRE, or Lua scripts for atomic check-and-increment) to share rate limit state across application instances.

### Chat System
- **Real-time messaging**: WebSocket connections from clients to chat servers. Each server maintains active connections for a subset of users.
- **Message routing**: When user A sends to user B, the server for A must forward to the server for B. Use a presence/routing service backed by Redis to map user_id to server_id. Server-to-server communication via internal message bus (Kafka, Redis Pub/Sub).
- **Message storage**: Store messages in Cassandra (time-series access pattern: get last N messages for a conversation, ordered by timestamp). Use conversation_id as partition key, message_id (time-based) as clustering key.
- **Offline delivery**: When recipient is offline, store message in persistent store. Push notification via APNs/FCM. Deliver missed messages on reconnect.
- **Read receipts**: Client sends ACK event when message is displayed. Server updates read cursor per user per conversation.
- **Group chat**: Fan-out on write (send to all members' inboxes on message creation) vs. fan-out on read (query all members' messages on read). Fan-out on write is better for small groups; fan-out on read for large groups (thousands of members).

### News Feed
- **Pull model (fan-out on read)**: On feed request, fetch posts from all followed users, merge, sort, paginate. Simple writes, expensive reads. Does not scale for users with many followees.
- **Push model (fan-out on write)**: On post creation, write post to the feed inbox of all followers. Expensive writes for users with many followers (celebrities), cheap reads.
- **Hybrid**: Fan-out on write for regular users. Fan-out on read for celebrities (> 10K followers). On feed read, merge pre-computed fan-out results with freshly fetched celebrity posts.
- **Feed storage**: Redis sorted set per user. Score = timestamp. ZADD on write, ZREVRANGE on read. Evict old feed entries to bound memory.
- **Feed ranking**: ML-based ranking replaces chronological order. Compute ranking scores in the background, store pre-ranked feeds. Update when ranking model changes.

### Typeahead / Autocomplete
- **Trie data structure**: Tree where each node represents a character. Each path from root to a node represents a prefix. Store top-K suggestions at each node.
- **Scale**: Too large to fit in memory as a pure trie. Use inverted index on prefixes stored in Elasticsearch or a dedicated suggestion engine (Elasticsearch `completion` suggester).
- **Low latency**: Cache top suggestions for common prefixes in Redis. P99 target < 50ms.
- **Personalization**: Blend popular global completions with user's own search history. Weight user history higher for recent queries.
- **Real-time updates**: New trending queries should surface quickly. Use a streaming pipeline (Kafka) to update suggestion scores in near real time.

### Notification System
- **Channels**: Push notifications (APNs for iOS, FCM for Android, Web Push for browsers), Email (SendGrid, SES), SMS (Twilio, Vonage), In-app notification center.
- **Fanout service**: Receives notification events and fans out to all relevant channels for each recipient. Route to different downstream services per channel.
- **Deduplication**: Use idempotency keys to prevent sending duplicate notifications (at-least-once delivery in the queue means duplicates are possible). Redis SET with TTL to track recently sent notification IDs.
- **User preferences**: Store per-user, per-channel, per-notification-type preferences. Check preferences before sending. Respect opt-out and frequency caps.
- **Priority tiers**: Critical notifications (security alerts, transaction confirmations) should bypass batching. Non-critical (marketing, recommendations) can be batched and sent in off-peak hours.

## Design Workflow

### High-Level Design
1. Start with the system context diagram. Get agreement on scope and boundaries.
2. Identify the 3-5 most critical user flows and sketch sequence diagrams.
3. Produce the container diagram. Choose technologies based on requirements, team skills, and ecosystem maturity.
4. Perform capacity estimation. Validate that the proposed architecture can meet non-functional requirements.
5. Document top-level trade-offs in ADRs.

### Detailed Design
1. For each container, produce a component diagram. Define interfaces between components.
2. Design the data model. Normalize for consistency, denormalize for read performance where justified.
3. Define API contracts (OpenAPI, Protobuf schemas). Include error codes and pagination.
4. Specify failure modes and recovery strategies for each component.
5. Plan observability: what metrics, logs, and traces each component must emit.
6. Review the detailed design against the non-functional requirements checklist.

### System Design Interview Pattern
1. **Clarify requirements** (5 min): Scope, scale, non-functional requirements, constraints. Ask explicitly: read vs. write ratio, consistency requirements, latency targets.
2. **Capacity estimation** (5 min): QPS, storage, bandwidth. Show your math. State assumptions.
3. **High-level design** (10 min): Box diagram of major components. Do not optimize yet.
4. **Deep dives** (15 min): Pick 2-3 critical components and design them in detail. Address the interviewer's areas of interest.
5. **Trade-offs and bottlenecks** (5 min): Proactively identify weaknesses and how you would address them.
