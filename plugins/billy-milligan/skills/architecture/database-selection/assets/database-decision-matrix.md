# Database Decision Matrix

## Project context
- **Project name**: _______________
- **Expected data volume**: _______________ (GB/TB at 1 year)
- **Expected throughput**: _______________ (reads/sec, writes/sec)
- **Team expertise**: _______________ (SQL, MongoDB, etc.)
- **Budget constraints**: _______________ (managed vs self-hosted)

## Data characteristics

| Characteristic | Score (1-5) | Notes |
|---------------|-------------|-------|
| Schema stability (fixed=5, evolving=1) | ___ | |
| Relationship complexity (none=1, deep=5) | ___ | |
| Write:read ratio (read-heavy=1, write-heavy=5) | ___ | |
| Consistency needs (eventual=1, strong=5) | ___ | |
| Query complexity (key lookup=1, aggregation=5) | ___ | |
| Time-series nature (no=1, primary=5) | ___ | |
| Geographic distribution (single=1, global=5) | ___ | |

## Scoring guide

**Schema stability 4-5 + Relationships 3-5** -> PostgreSQL
**Schema stability 1-2 + Relationships 1-2** -> MongoDB
**Write:read 4-5 + Time-series 4-5** -> TimescaleDB / Cassandra
**Relationships 5 + Traversal queries** -> Neo4j
**Consistency 1-2 + Throughput extreme** -> DynamoDB
**Sub-ms latency required** -> Redis (with persistence backup)

## Database comparison for THIS project

| Requirement | PostgreSQL | MongoDB | DynamoDB | Other: ___ |
|------------|-----------|---------|----------|------------|
| Data model fit | ___ /5 | ___ /5 | ___ /5 | ___ /5 |
| Query pattern support | ___ /5 | ___ /5 | ___ /5 | ___ /5 |
| Scale requirements | ___ /5 | ___ /5 | ___ /5 | ___ /5 |
| Operational complexity | ___ /5 | ___ /5 | ___ /5 | ___ /5 |
| Team expertise | ___ /5 | ___ /5 | ___ /5 | ___ /5 |
| Cost (managed) | ___ /5 | ___ /5 | ___ /5 | ___ /5 |
| Ecosystem/tooling | ___ /5 | ___ /5 | ___ /5 | ___ /5 |
| **Total** | ___ /35 | ___ /35 | ___ /35 | ___ /35 |

## Access patterns (list top 5)

| # | Pattern | Frequency | Latency SLA | Candidate DB |
|---|---------|-----------|-------------|--------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |

## Secondary databases needed

- [ ] Caching layer: Redis (sessions, hot data)
- [ ] Search engine: Elasticsearch (full-text, faceted search)
- [ ] Vector store: pgvector / Pinecone (embeddings, similarity)
- [ ] Analytics: TimescaleDB / ClickHouse (aggregations, dashboards)
- [ ] Message queue: not a DB but consider Kafka/SQS for async

## Opinionated defaults

If you scored and it is close, use these tiebreakers:

1. **When in doubt** -> PostgreSQL (most versatile, best ecosystem)
2. **Serverless on AWS** -> DynamoDB (native integration, pay-per-request)
3. **Rapid prototyping** -> MongoDB Atlas (flexible schema, fast iteration)
4. **Edge/embedded** -> SQLite (zero config, single file)
5. **Multi-region with strong consistency** -> CockroachDB (distributed SQL)

## Decision record

**Selected primary database**: _______________
**Rationale**: _______________
**Trade-offs accepted**: _______________
**Migration plan if wrong**: _______________
**Review date**: _______________ (revisit at 10x growth milestone)
