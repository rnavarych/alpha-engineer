# Vector Database Selection Guide

## When to load
Load when choosing a vector database, tuning index parameters, designing embedding pipelines, planning RAG architecture, or optimizing cost and operations.

## Comparison Table

| Database | ANN Algorithm | Hybrid Search | Managed | Max Dims | Pricing Model |
|----------|--------------|---------------|---------|----------|---------------|
| Pinecone | Proprietary ANN | Sparse-dense | Serverless + Pods | 20,000 | Per read/write unit |
| Weaviate | HNSW | BM25 + vector | Weaviate Cloud | Unlimited | Per dimension-hour |
| Milvus/Zilliz | IVF_FLAT, HNSW, DiskANN, SCANN | Sparse + dense | Zilliz Cloud | 32,768 | CU-based |
| Qdrant | HNSW | Sparse + dense | Qdrant Cloud | 65,536 | Per-node |
| ChromaDB | HNSW | No native | No (embedded) | Unlimited | Open source |
| pgvector | HNSW, IVFFlat | Full SQL + vector | Any PG managed | 2,000 | PG hosting cost |
| LanceDB | IVF_PQ, flat | Yes | Serverless (beta) | Unlimited | Storage-based |
| Vespa | HNSW, brute-force | BM25 + vector + ML | Vespa Cloud | Unlimited | Per-node |
| Turbopuffer | DiskANN variant | BM25 + vector | Serverless | 4,096 | Per query + storage |

## LanceDB

```python
import lancedb
from lancedb.pydantic import LanceModel, Vector
from lancedb.embeddings import get_registry

db = lancedb.connect("~/.lancedb")
embedder = get_registry().get("openai").create(name="text-embedding-3-small")

class Document(LanceModel):
    text: str = embedder.SourceField()
    vector: Vector(1536) = embedder.VectorField()
    category: str
    source: str

table = db.create_table("documents", schema=Document)
table.add([{"text": "Machine learning basics", "category": "ml", "source": "textbook"}])

results = table.search("deep learning training techniques") \
    .where("category = 'ml'") \
    .limit(5) \
    .to_pandas()
```

## Cross-Reference Databases (covered in other skills)

```json
// Elasticsearch kNN (document-databases skill)
// POST products/_search
{
  "knn": { "field": "embedding", "query_vector": [0.1, 0.2], "k": 10,
    "num_candidates": 100, "filter": { "term": { "category": "electronics" } } }
}
```

```javascript
// MongoDB Atlas Vector Search (document-databases skill)
db.products.aggregate([{
  $vectorSearch: { index: "vector_index", path: "embedding",
    queryVector: queryEmbedding, numCandidates: 100, limit: 10,
    filter: { category: "electronics" } }
}]);
```

```
// Redis Stack Vector (key-value-stores skill)
FT.CREATE idx:products ON HASH PREFIX 1 product:
  SCHEMA title TEXT category TAG
  embedding VECTOR HNSW 6 TYPE FLOAT32 DIM 1536 DISTANCE_METRIC COSINE
```

## Embedding Model Selection

| Model | Dimensions | Speed | Quality | Provider |
|-------|-----------|-------|---------|----------|
| text-embedding-3-small | 1536 | Fast | Good | OpenAI |
| text-embedding-3-large | 3072 | Medium | Best | OpenAI |
| embed-english-v3.0 | 1024 | Fast | Excellent | Cohere |
| voyage-3 | 1024 | Medium | Excellent | Voyage AI |
| all-MiniLM-L6-v2 | 384 | Very fast | Good | Open source |
| bge-large-en-v1.5 | 1024 | Medium | Excellent | Open source |

## Index Tuning Guidelines

```
HNSW Parameters:
  M (max connections): 16-64 (higher = better recall, more memory)
  ef_construction: 128-512 (higher = better index quality, slower build)
  ef_search: 64-256 (higher = better recall at query time, slower search)

IVF Parameters:
  nlist (clusters): sqrt(N) to 4*sqrt(N) where N = total vectors
  nprobe (clusters to search): 5-20% of nlist

Quantization Guidelines:
  Scalar (int8): 4x compression, ~1% recall loss -- good default
  Product (PQ): 8-64x compression, 2-5% recall loss -- large datasets
  Binary: 32x compression, best for high-dim (1536+) models
```

## RAG Architecture Patterns

```
Basic RAG Pipeline:
  [Embed Query] -> [Vector Search top-k] -> [Rerank (Cohere/ColBERT)]
    -> [Prompt Assembly] -> [LLM Generation with citations]

Advanced Patterns:
  1. Hybrid RAG: BM25 + vector search with Reciprocal Rank Fusion (RRF)
  2. Multi-Query RAG: generate query variations, merge results
  3. HyDE: embed hypothetical answer, search with it
  4. Parent Document Retrieval: embed small chunks, return parent docs
  5. Self-RAG: LLM decides when/if to retrieve
  6. Graph RAG: vector search + knowledge graph traversal
```

## Operational Monitoring

- Track: query latency (p50/p95/p99), recall rate, index size, ingestion throughput
- Alert on: latency spikes, recall degradation, disk/memory > 80%
- Benchmark recall against ground truth periodically
- Monitor embedding model drift: re-embed samples and compare distributions

## Cost Optimization

- Use quantization: 4-32x memory and cost reduction
- Implement metadata filtering to shrink ANN search space
- Use namespaces/partitions to isolate data
- Serverless (Pinecone Serverless, Turbopuffer) for variable workloads
- Consider pgvector if PostgreSQL already in stack (zero extra infra)
- Matryoshka embeddings or PCA for dimension reduction
