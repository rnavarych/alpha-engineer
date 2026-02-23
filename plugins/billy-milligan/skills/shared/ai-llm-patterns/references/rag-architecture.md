# RAG Architecture

## When to load
Load when building retrieval-augmented generation, vector search, or knowledge base systems.

## RAG Pipeline

```
User Query
    │
    ▼
┌─────────────┐
│  Embedding   │  → Convert query to vector
└──────┬───────┘
       │
       ▼
┌─────────────┐
│  Retrieval   │  → Find relevant documents (vector DB)
└──────┬───────┘
       │
       ▼
┌─────────────┐
│  Reranking   │  → Score and filter results (optional)
└──────┬───────┘
       │
       ▼
┌─────────────┐
│  Generation  │  → LLM answers using retrieved context
└─────────────┘
```

## Embedding & Storage

```typescript
import { OpenAI } from 'openai';

const openai = new OpenAI();

// Generate embeddings
async function embed(texts: string[]): Promise<number[][]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small', // 1536 dimensions, $0.02/1M tokens
    input: texts,
  });
  return response.data.map(d => d.embedding);
}

// Chunking strategy
function chunkDocument(text: string, options = {
  chunkSize: 512,       // tokens per chunk
  overlap: 50,          // overlap between chunks
  separator: '\n\n',    // prefer splitting at paragraphs
}): string[] {
  // Split by separator first, then by size
  const paragraphs = text.split(options.separator);
  const chunks: string[] = [];
  let current = '';

  for (const para of paragraphs) {
    if ((current + para).length > options.chunkSize * 4) { // ~4 chars per token
      if (current) chunks.push(current.trim());
      current = para;
    } else {
      current += options.separator + para;
    }
  }
  if (current) chunks.push(current.trim());

  return chunks;
}
```

## Vector Database Options

```
| Database | Type | Hosting | Best For |
|----------|------|---------|----------|
| Pinecone | Managed | Cloud | Production, serverless |
| Weaviate | Open source | Self/Cloud | Hybrid search (vector + keyword) |
| Qdrant | Open source | Self/Cloud | Performance, filtering |
| pgvector | Extension | Postgres | Small-medium (< 1M vectors) |
| Chroma | Open source | Self | Prototyping, local dev |
```

## pgvector (PostgreSQL)

```sql
-- Enable extension
CREATE EXTENSION vector;

-- Create table with vector column
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  embedding vector(1536),  -- match your model dimensions
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index (IVFFlat for < 1M rows, HNSW for larger)
CREATE INDEX ON documents
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- Similarity search
SELECT id, content, metadata,
       1 - (embedding <=> $1::vector) AS similarity
FROM documents
WHERE metadata->>'source' = 'docs'  -- filter first, then vector search
ORDER BY embedding <=> $1::vector
LIMIT 10;
```

## Retrieval + Generation

```typescript
async function ragQuery(userQuestion: string) {
  // 1. Embed the question
  const [queryEmbedding] = await embed([userQuestion]);

  // 2. Retrieve relevant chunks
  const results = await db.query(`
    SELECT content, metadata,
           1 - (embedding <=> $1::vector) AS similarity
    FROM documents
    WHERE 1 - (embedding <=> $1::vector) > 0.7  -- similarity threshold
    ORDER BY embedding <=> $1::vector
    LIMIT 5
  `, [JSON.stringify(queryEmbedding)]);

  // 3. Build context
  const context = results.rows
    .map(r => `[Source: ${r.metadata.source}]\n${r.content}`)
    .join('\n\n---\n\n');

  // 4. Generate answer with context
  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    system: `Answer questions based on the provided context.
If the context doesn't contain the answer, say "I don't have information about that."
Always cite which source you used.`,
    messages: [{
      role: 'user',
      content: `Context:\n${context}\n\nQuestion: ${userQuestion}`,
    }],
  });

  return {
    answer: response.content[0].text,
    sources: results.rows.map(r => r.metadata),
  };
}
```

## Chunking Strategies

```
Fixed-size:     Split every N tokens (simple, can break sentences)
Paragraph:      Split at \n\n boundaries (preserves context)
Semantic:       Split when topic changes (best quality, expensive)
Recursive:      Try \n\n → \n → sentence → word (LangChain default)
Document-aware: Split at headers/sections (best for docs/code)

Guidelines:
  Chunk size: 256-1024 tokens (512 is a good default)
  Overlap: 10-20% of chunk size (prevents losing context at boundaries)
  Metadata: always store source, page, section with each chunk
```

## Advanced: Hybrid Search

```sql
-- Combine vector similarity with full-text search (pgvector + tsvector)

-- Add full-text search column
ALTER TABLE documents ADD COLUMN tsv tsvector
  GENERATED ALWAYS AS (to_tsvector('english', content)) STORED;
CREATE INDEX ON documents USING gin(tsv);

-- Hybrid query: RRF (Reciprocal Rank Fusion)
WITH vector_results AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) AS vrank
  FROM documents ORDER BY embedding <=> $1::vector LIMIT 20
),
text_results AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank(tsv, query) DESC) AS trank
  FROM documents, plainto_tsquery('english', $2) query
  WHERE tsv @@ query LIMIT 20
)
SELECT d.id, d.content,
  COALESCE(1.0/(60 + v.vrank), 0) + COALESCE(1.0/(60 + t.trank), 0) AS rrf_score
FROM documents d
LEFT JOIN vector_results v ON d.id = v.id
LEFT JOIN text_results t ON d.id = t.id
WHERE v.id IS NOT NULL OR t.id IS NOT NULL
ORDER BY rrf_score DESC
LIMIT 10;
```

## Anti-patterns
- No chunking (embed entire documents) → exceeds token limits, poor retrieval
- No similarity threshold → returning irrelevant results
- Embedding queries and documents differently → mismatched vector space
- No metadata filtering → searching entire corpus when subset is relevant
- Stuffing too many chunks into context → dilutes relevant information

## Quick reference
```
Pipeline: embed → retrieve → (rerank) → generate
Embeddings: text-embedding-3-small (cheap) or 3-large (better)
Chunk size: 512 tokens default, 10-20% overlap
Vector DB: pgvector for <1M, Pinecone/Qdrant for larger
Similarity: cosine distance, threshold 0.7+
Top-k: retrieve 5-10 chunks, rerank to top 3-5
Hybrid: vector + full-text search with RRF fusion
Context: include source metadata, cite in responses
Evaluation: precision@k, recall, answer correctness
```
