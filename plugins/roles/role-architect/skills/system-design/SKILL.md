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

## When to use
- Designing a new system or major feature from scratch
- Evaluating trade-offs between architectural approaches
- Estimating capacity for a given load profile
- Choosing between consistency and availability models
- Architecting message-driven, event-driven, or stream processing systems
- Preparing for or conducting a system design review

## Core principles
1. **Requirements first** — no architecture without explicit functional and non-functional targets
2. **Diagrams as communication** — C4 model from context down to component; sequence diagrams for every critical flow
3. **Trade-offs are mandatory** — every decision needs at least two alternatives documented
4. **Capacity estimation gates the design** — estimate before you commit to a technology
5. **Distributed systems lie** — CAP/PACELC, consensus, and eventual consistency have real operational consequences

## Reference Files
- `references/requirements-and-diagrams.md` — functional/non-functional requirements, C4 model (all four levels), sequence diagrams, data flow diagrams, trade-off documentation, and capacity estimation formulas
- `references/distributed-systems-theory.md` — CAP theorem, PACELC theorem, Raft/Paxos/Zab consensus algorithms, vector clocks, Lamport timestamps, CRDTs, and eventual consistency patterns (read repair, anti-entropy, hinted handoff)
- `references/load-balancing-and-caching.md` — round-robin/least-connections/consistent hashing/Maglev/power-of-two-choices algorithms; cache-aside/write-through/write-behind/read-through/multi-layer caching; Redis Cluster patterns and hot key mitigation
- `references/messaging-streaming-and-patterns.md` — message queue patterns, event-driven architecture (event sourcing, outbox, saga), Kafka Streams, Apache Flink, Spark Structured Streaming, Lambda/Kappa architectures, search engines (Elasticsearch/Meilisearch/Algolia), and common system design problems (URL shortener, rate limiter, chat, news feed, notifications)
