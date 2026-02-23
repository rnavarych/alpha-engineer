# Scaling Strategies and Sharding

## When to load
Load when choosing between horizontal and vertical scaling, designing sharding strategies, implementing read/write splitting, or modeling eventual consistency and CQRS for high-scale systems.

## Horizontal vs. Vertical Scaling

### Vertical Scaling (Scale Up)
- Add more CPU, memory, or disk to a single machine.
- Simpler operationally: no distributed coordination, no data partitioning, no network hops.
- Hard ceiling: the largest available machine instance limits throughput. Cloud providers cap at 128-448 vCPUs and 6-24 TB RAM.
- Use vertical scaling first when: the workload is single-threaded, the data fits on one node, or the team lacks distributed systems experience.

### Horizontal Scaling (Scale Out)
- Add more machines and distribute the workload across them.
- Requires: load balancing, stateless services (or externalized state), data partitioning, and distributed coordination.
- No hard ceiling in theory, but operational complexity grows with each additional node.
- Prefer horizontal scaling when: you need fault tolerance (no single point of failure), the workload is parallelizable, or you anticipate growth beyond a single machine's capacity within 12 months.

### Hybrid Approach
- Scale vertically until you hit diminishing returns (cost per unit of capacity increases), then scale horizontally.
- Common pattern: one large primary database (vertical) with read replicas (horizontal) and horizontally scaled stateless application servers.

## Sharding Strategies

### Hash-Based Sharding
- Apply a hash function to the shard key (e.g., `hash(user_id) % num_shards`). Distributes data evenly.
- Pros: uniform distribution, simple implementation.
- Cons: range queries across shards require scatter-gather. Resharding (changing shard count) requires data migration.
- Mitigate resharding with consistent hashing (virtual nodes), which minimizes data movement when adding or removing shards.

### Range-Based Sharding
- Assign contiguous key ranges to shards (e.g., users A-M on shard 1, N-Z on shard 2).
- Pros: efficient range queries within a single shard. Natural for time-series data (shard by month/year).
- Cons: hot spots if key distribution is uneven. Monitor shard sizes and split proactively.

### Geo-Based Sharding
- Partition data by geographic region (e.g., EU data on EU shards, US data on US shards).
- Reduces latency for region-local requests. Simplifies data residency compliance (GDPR, data sovereignty).
- Cons: cross-region queries are expensive. Users who travel between regions need routing logic.

### Shard Key Selection
- Choose a key with high cardinality and even distribution. Avoid monotonically increasing keys (timestamps) for hash sharding.
- The shard key should appear in most queries to avoid cross-shard operations.
- Test shard key candidates against real query patterns before committing.

## Read/Write Splitting
- Route read queries to replicas, write queries to the primary. Reduces load on the primary database.
- Application-level routing: the application decides which connection to use. More control, more code.
- Proxy-level routing: a database proxy (ProxySQL, PgBouncer, Vitess) routes queries transparently.
- Replication lag: reads from replicas may return stale data. Acceptable for dashboards and feeds; unacceptable for "read-your-own-writes" flows.
- Read-your-own-writes pattern: after a write, route subsequent reads from the same session to the primary for a configurable window (e.g., 5 seconds).

## Eventual Consistency Patterns
- Accept that replicas, caches, and event consumers may be temporarily inconsistent with the source of truth.
- Design UIs to tolerate eventual consistency: show "processing" states, use optimistic updates with reconciliation.
- Use versioning or vector clocks to detect and resolve conflicts when concurrent writes occur.
- Compensating transactions: when a downstream system fails to process an event, issue a compensating action rather than rolling back the entire flow.
- Idempotency: make all write operations idempotent so that retries and duplicate event deliveries are safe.

## CQRS for Scale
- Separate the command (write) model from the query (read) model. Each can be optimized independently.
- Write model: normalized, consistent, optimized for transactional integrity. Backed by a relational database or event store.
- Read model: denormalized, eventually consistent, optimized for query patterns. Backed by search indexes, materialized views, or document stores.
- Event-driven synchronization: the write model publishes domain events. Projectors consume events and update the read model.
- Use CQRS only when read and write patterns diverge significantly. For simple CRUD applications, CQRS adds unjustified complexity.
