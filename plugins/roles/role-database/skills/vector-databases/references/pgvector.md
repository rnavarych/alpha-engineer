# pgvector

## When to load
Load when adding vector search to PostgreSQL: HNSW vs IVFFlat index selection, hybrid FTS + vector queries, performance tuning, and batch upsert patterns.

## HNSW vs IVFFlat Indexes

```sql
-- Install pgvector extension
CREATE EXTENSION vector;

-- Create table with vector column
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding vector(1536),     -- full precision float4
    -- embedding halfvec(1536), -- half precision float2 (50% less storage)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- HNSW index (preferred: better recall, no training required)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 128);

-- IVFFlat index (faster build, requires training data)
-- Must have data in table before creating (needs cluster centers)
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);  -- sqrt(num_rows) is a good starting point

-- Distance operators:
-- <=> cosine distance
-- <-> L2 (Euclidean) distance
-- <#> negative inner product (max inner product search)

-- Semantic search with SQL filtering
SELECT id, content, metadata,
       1 - (embedding <=> $1::vector) AS similarity
FROM documents
WHERE metadata->>'category' = 'technology'
  AND created_at > now() - INTERVAL '30 days'
ORDER BY embedding <=> $1::vector
LIMIT 10;
```

## Hybrid Search (FTS + Vector)

```sql
-- Combine full-text search rank with vector similarity
SELECT id, content,
       ts_rank(to_tsvector('english', content), plainto_tsquery('english', $1)) AS text_rank,
       1 - (embedding <=> $2::vector) AS vector_similarity,
       -- Weighted combination
       0.3 * ts_rank(to_tsvector('english', content), plainto_tsquery('english', $1))
       + 0.7 * (1 - (embedding <=> $2::vector)) AS combined_score
FROM documents
WHERE to_tsvector('english', content) @@ plainto_tsquery('english', $1)
ORDER BY combined_score DESC
LIMIT 10;
```

## Performance Tuning

```sql
-- Increase maintenance_work_mem for faster index builds
SET maintenance_work_mem = '2GB';

-- HNSW search parameter: higher ef = better recall, slower search
SET hnsw.ef_search = 100;  -- default 40

-- IVFFlat search parameter: higher probes = better recall, slower search
SET ivfflat.probes = 10;   -- default 1

-- Parallel index build
SET max_parallel_maintenance_workers = 4;

-- Monitor index build progress
SELECT phase, blocks_done, blocks_total,
       round(100.0 * blocks_done / NULLIF(blocks_total, 0), 1) AS pct
FROM pg_stat_progress_create_index;

-- Check index size
SELECT pg_size_pretty(pg_relation_size('documents_embedding_idx'));

-- Batch upsert for ingestion performance
INSERT INTO documents (content, embedding, metadata)
SELECT unnest($1::text[]), unnest($2::vector[]), unnest($3::jsonb[])
ON CONFLICT (id) DO UPDATE SET embedding = EXCLUDED.embedding;
```
