# Distributed Systems Theory

## When to load
Load when reasoning about CAP/PACELC trade-offs, selecting consensus algorithms, designing conflict resolution strategies, or choosing between consistency models in distributed architectures.

## CAP Theorem
- In the presence of a network partition, a distributed system must choose between Consistency (every read receives the most recent write) and Availability (every request receives a response, possibly stale).
- **CP systems** (Consistency + Partition tolerance): HBase, Zookeeper, etcd, Spanner. Choose when stale reads are unacceptable (financial balances, inventory counts).
- **AP systems** (Availability + Partition tolerance): Cassandra, CouchDB, DynamoDB (default), Riak. Choose when availability and latency are paramount and stale reads are acceptable (user profiles, social feeds).
- CA systems (Consistency + Availability without partition tolerance) are not realistic in distributed deployments. Traditional RDBMS on a single node is CA, but that is vertical scaling, not distributed.

## PACELC Theorem
- Extends CAP to account for behavior when no partition exists: even without partitions, you trade Latency for Consistency.
- **PA/EL** (Partition: Availability; Else: Low latency): Cassandra, DynamoDB, Riak. Best for high-throughput, globally distributed writes.
- **PC/EC** (Partition: Consistency; Else: Consistency): HBase, Zookeeper. Best for coordination and metadata storage.
- **PA/EC** (Partition: Availability; Else: Consistency): MongoDB. Prioritizes consistency when the network is stable.
- Use PACELC to make the latency-consistency trade-off explicit even in normal operating conditions.

## Consensus Algorithms
- **Raft**: Leader-based consensus. A leader is elected per term; all writes go through the leader and are replicated to a quorum (majority) before acknowledging. Simpler to understand than Paxos. Used by etcd, CockroachDB, TiKV. Key properties: leader election, log replication, safety (never returns an uncommitted value).
- **Paxos**: Classic consensus algorithm with two phases (Prepare/Promise, Accept/Accepted). More flexible than Raft but harder to implement correctly. Multi-Paxos adds leader optimization. Used by Google Spanner, Chubby.
- **Zab (ZooKeeper Atomic Broadcast)**: Consensus protocol for ZooKeeper. Separates leader election (fast path) from log replication. Optimized for crash-recovery with sequential consistency.
- **Practical consideration**: Do not implement consensus algorithms yourself. Use etcd, ZooKeeper, or Consul as coordination services.

## Vector Clocks and Lamport Timestamps
- **Lamport Timestamps**: Logical clock that captures "happened-before" relationships. Each event increments the clock. When sending a message, include the current timestamp. On receipt, set clock to max(local, received) + 1. Establishes a partial order of events but cannot detect concurrent events.
- **Vector Clocks**: Each node maintains a vector of counters, one per node. When an event occurs, increment your own counter. When sending, include the full vector. On receipt, take the element-wise maximum. Two events are concurrent if neither vector dominates the other. Used by Dynamo, Riak for conflict detection.
- **Hybrid Logical Clocks (HLC)**: Combine physical time with logical counters. Events are ordered by wall clock time when possible, falling back to logical counters for concurrent events. Used by CockroachDB and YugabyteDB for cross-node ordering.

## CRDTs and Conflict Resolution
- **CRDTs (Conflict-free Replicated Data Types)**: Data structures designed to merge concurrent updates automatically without coordination. Two categories:
  - **State-based CRDTs (CvRDTs)**: Merge full state. Examples: G-Counter (grow-only counter), PN-Counter (increment/decrement), G-Set (grow-only set), OR-Set (observed-remove set), LWW-Register (last-write-wins).
  - **Operation-based CRDTs (CmRDTs)**: Transmit operations; requires reliable delivery. More network-efficient but more complex.
- **Last-Write-Wins (LWW)**: Resolve conflicts by timestamp. Simple and widely used. Risk: concurrent writes lose data. Mitigate with vector clocks to detect true concurrency vs. causally ordered writes.
- **Multi-Value (MV) Register**: Keep all concurrent versions and expose them to the application for manual resolution. Used by Amazon S3, CouchDB. Requires application-layer merge logic.
- **Application-specific resolution**: For business logic conflicts (e.g., two users updating the same shopping cart item), define domain-specific merge rules (union of items, max quantity, etc.).

## Eventual Consistency Patterns
- **Read Repair**: On a read, compare responses from multiple replicas. If they differ, repair the out-of-date replica in the background. Used by Cassandra, Dynamo.
- **Anti-Entropy (Merkle Trees)**: Background process compares data between replicas using a hash tree. Only transmits differing subtrees. Used by DynamoDB, Cassandra for full sync.
- **Hinted Handoff**: When a replica is unavailable, the coordinator temporarily stores writes intended for it (hints). When the replica comes back, hints are replayed. Used by Cassandra, Dynamo.
- **Causal Consistency**: Guarantee that causally related reads and writes are seen in causal order, even if unrelated operations are eventually consistent. Implemented with vector clocks or dependency tracking.
