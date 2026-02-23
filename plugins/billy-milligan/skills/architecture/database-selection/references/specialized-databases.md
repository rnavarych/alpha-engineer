# Specialized Databases

## When to load
Load when discussing time-series, graph, vector, or search databases beyond standard relational/NoSQL options.

## Patterns

### TimescaleDB (time-series on PostgreSQL)
```sql
-- Extension on Postgres: keep SQL, add time-series superpowers
CREATE TABLE metrics (
  time TIMESTAMPTZ NOT NULL,
  device_id TEXT NOT NULL,
  cpu_usage DOUBLE PRECISION,
  memory_usage DOUBLE PRECISION
);
SELECT create_hypertable('metrics', 'time');

-- Automatic compression (10x-20x savings)
ALTER TABLE metrics SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'device_id',
  timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('metrics', INTERVAL '7 days');

-- Continuous aggregates (materialized rollups)
CREATE MATERIALIZED VIEW metrics_hourly
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS bucket,
       device_id,
       AVG(cpu_usage) AS avg_cpu,
       MAX(cpu_usage) AS max_cpu
FROM metrics
GROUP BY bucket, device_id;
```
Use when: time-series data AND you want to stay on PostgreSQL. Handles millions of rows/sec inserts. Alternative: InfluxDB (purpose-built, InfluxQL/Flux query language, better for pure metrics).

### Neo4j (graph database)
```cypher
// Social network: find friends-of-friends who like same genre
MATCH (me:User {id: $userId})-[:FRIENDS_WITH]->(friend)-[:FRIENDS_WITH]->(fof)
WHERE NOT (me)-[:FRIENDS_WITH]->(fof) AND me <> fof
MATCH (fof)-[:LIKES]->(genre:Genre)<-[:LIKES]-(me)
RETURN fof.name, COLLECT(genre.name) AS sharedGenres, COUNT(genre) AS score
ORDER BY score DESC LIMIT 10;

// Fraud detection: find circular money flows
MATCH path = (a:Account)-[:TRANSFERRED*3..6]->(a)
WHERE ALL(t IN relationships(path) WHERE t.amount > 10000)
RETURN path, REDUCE(total = 0, t IN relationships(path) | total + t.amount) AS totalFlow;
```
Use when: relationships ARE the data (social graphs, fraud detection, recommendation engines, knowledge graphs). Not for: simple CRUD, tabular data, full-text search.

### Pinecone / pgvector (vector databases)
```typescript
// pgvector: vector search inside PostgreSQL
// CREATE EXTENSION vector;
// ALTER TABLE products ADD COLUMN embedding vector(1536);
// CREATE INDEX ON products USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

// Semantic search with pgvector
const results = await db.query(`
  SELECT id, name, 1 - (embedding <=> $1::vector) AS similarity
  FROM products
  WHERE 1 - (embedding <=> $1::vector) > 0.7
  ORDER BY embedding <=> $1::vector
  LIMIT 20
`, [queryEmbedding]);

// Pinecone: managed vector DB (higher scale)
const pinecone = new Pinecone({ apiKey: process.env.PINECONE_API_KEY });
const index = pinecone.index('products');
const results = await index.query({
  vector: queryEmbedding,
  topK: 20,
  filter: { category: { $eq: 'electronics' } },
  includeMetadata: true,
});
```
Use pgvector when: <1M vectors AND already on Postgres. Use Pinecone/Weaviate when: >1M vectors, need managed infrastructure, high QPS vector search.

### Elasticsearch / OpenSearch (search engine)
```typescript
// Index with custom analyzer
await client.indices.create({
  index: 'products',
  body: {
    settings: {
      analysis: {
        analyzer: {
          product_analyzer: {
            type: 'custom',
            tokenizer: 'standard',
            filter: ['lowercase', 'synonym', 'stemmer']
          }
        }
      }
    },
    mappings: {
      properties: {
        name: { type: 'text', analyzer: 'product_analyzer' },
        description: { type: 'text' },
        price: { type: 'float' },
        tags: { type: 'keyword' },
        created_at: { type: 'date' }
      }
    }
  }
});

// Multi-field search with boosting
const results = await client.search({
  index: 'products',
  body: {
    query: {
      bool: {
        must: { multi_match: { query: 'wireless headphones', fields: ['name^3', 'description'] } },
        filter: [
          { range: { price: { lte: 200 } } },
          { term: { 'tags': 'electronics' } }
        ]
      }
    },
    highlight: { fields: { name: {}, description: {} } }
  }
});
```
Use when: full-text search with relevance scoring, faceted search, log analytics (ELK stack). Not a primary database. Always sync from source of truth (Postgres/Mongo -> Elasticsearch via CDC or queue).

## Anti-patterns
- Elasticsearch as primary data store -> no ACID, data loss risk; always sync from source DB
- Neo4j for tabular CRUD -> massive overhead for simple lookups
- pgvector without IVFFLAT/HNSW index -> linear scan on every query
- TimescaleDB without compression policy -> storage costs explode

## Decision criteria
| Need | Database | When to use instead |
|------|----------|-------------------|
| Time-series + SQL | TimescaleDB | InfluxDB if no Postgres dependency needed |
| Graph traversals | Neo4j | Postgres recursive CTEs if graph is simple |
| Vector similarity | pgvector (<1M) | Pinecone/Weaviate (>1M vectors, managed) |
| Full-text search | Elasticsearch | Postgres `tsvector` if search needs are basic |

## Quick reference
```
TimescaleDB: time-series on Postgres, 10-20x compression, continuous aggregates
Neo4j: graph traversals, 3+ hops, relationship-centric queries
pgvector: <1M vectors, add to existing Postgres, cosine/L2/inner product
Pinecone: >1M vectors, managed, metadata filtering, serverless
Elasticsearch: full-text search, log analytics, always secondary to source DB
Rule: start with Postgres extensions, graduate to specialized DB when scale demands
```
