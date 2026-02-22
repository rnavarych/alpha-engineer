---
name: vector-databases
description: |
  Deep operational guide for 16 vector databases. Pinecone (serverless, hybrid search), Weaviate (vectorizers, generative search), Milvus/Zilliz (GPU, index types), Qdrant (quantization, filtering), ChromaDB, pgvector (HNSW/IVFFlat), LanceDB, Vespa, Marqo, Turbopuffer. Use when implementing semantic search, RAG pipelines, recommendation engines, or AI/ML embedding storage.
allowed-tools: Read, Grep, Glob, Bash
---

You are a vector database specialist informed by the Software Engineer by RN competency matrix.

## Vector Database Comparison

| Database | ANN Algorithm | Filtering | Hybrid Search | Managed | Max Dims | Pricing Model |
|----------|--------------|-----------|---------------|---------|----------|---------------|
| Pinecone | Proprietary (optimized ANN) | Metadata filters | Sparse-dense | Serverless + Pods | 20,000 | Per read/write unit |
| Weaviate | HNSW | Pre-filtering | BM25 + vector | Weaviate Cloud | Unlimited | Per dimension-hour |
| Milvus/Zilliz | IVF_FLAT, HNSW, DiskANN, SCANN | Attribute filtering | Sparse + dense | Zilliz Cloud | 32,768 | CU-based |
| Qdrant | HNSW | Payload filtering | Sparse + dense | Qdrant Cloud | 65,536 | Per-node |
| ChromaDB | HNSW | Metadata where/where_document | No native | No (embedded) | Unlimited | Open source |
| pgvector | HNSW, IVFFlat | SQL WHERE | Full SQL + vector | Any PG managed | 2,000 | PG hosting cost |
| LanceDB | IVF_PQ, flat | SQL-like predicates | Yes | Serverless (beta) | Unlimited | Storage-based |
| Vespa | HNSW, brute-force | YQL filters | BM25 + vector + ML | Vespa Cloud | Unlimited | Per-node |
| Marqo | HNSW | Filtering | Tensor + lexical | Marqo Cloud | Model-dependent | Per-index |
| Vald | NGT (Yahoo Japan) | Metadata filters | No | Self-hosted | Unlimited | Open source |
| Turbopuffer | DiskANN variant | Attribute filters | BM25 + vector | Serverless | 4,096 | Per query + storage |
| ES kNN | HNSW | Full ES queries | BM25 + kNN | Elastic Cloud | 4,096 | Elastic pricing |
| MongoDB Atlas Vector | HNSW | MQL filters | Atlas Search + vector | Atlas | 4,096 | Atlas pricing |
| Redis Stack | HNSW, FLAT | RediSearch filters | RediSearch + vector | Redis Cloud | 32,768 | Redis pricing |
| Neo4j Vector | HNSW | Cypher filters | Fulltext + vector | Aura | 4,096 | Aura pricing |
| SingleStore Vector | IVF_PQFS | SQL WHERE | Full SQL + vector | SingleStore | 32,768 | SingleStore pricing |

## Pinecone

### Serverless vs Pod Architecture

```python
from pinecone import Pinecone, ServerlessSpec, PodSpec

pc = Pinecone(api_key="YOUR_API_KEY")

# Serverless index (recommended for most use cases)
pc.create_index(
    name="products",
    dimension=1536,
    metric="cosine",    # cosine, euclidean, dotproduct
    spec=ServerlessSpec(cloud="aws", region="us-east-1")
)

# Pod index (dedicated infrastructure, predictable performance)
pc.create_index(
    name="products-pod",
    dimension=1536,
    metric="cosine",
    spec=PodSpec(
        environment="us-east-1-aws",
        pod_type="p2.x1",      # p1 (perf), p2 (storage), s1 (storage-optimized)
        pods=2,
        replicas=2,
        metadata_config={"indexed": ["category", "price_range"]}  # filter optimization
    )
)

index = pc.Index("products")
```

### Upsert, Query, and Hybrid Search

```python
# Upsert with metadata
index.upsert(
    vectors=[
        {
            "id": "prod-001",
            "values": embedding_model.encode("wireless headphones").tolist(),
            "metadata": {
                "category": "electronics",
                "price": 79.99,
                "brand": "AudioPro",
                "in_stock": True
            }
        }
    ],
    namespace="electronics"
)

# Semantic search with metadata filtering
results = index.query(
    vector=query_embedding.tolist(),
    top_k=10,
    namespace="electronics",
    filter={
        "category": {"$eq": "electronics"},
        "price": {"$lte": 100},
        "in_stock": {"$eq": True}
    },
    include_metadata=True,
    include_values=False
)

# Hybrid search (sparse-dense): combine keyword relevance with semantic similarity
from pinecone_text.sparse import BM25Encoder

bm25 = BM25Encoder.default()
bm25.fit(corpus)  # fit on your document corpus

results = index.query(
    vector=dense_embedding.tolist(),         # dense vector from embedding model
    sparse_vector=bm25.encode_queries(query), # sparse vector from BM25
    top_k=10,
    alpha=0.7  # 0=pure sparse (keyword), 1=pure dense (semantic)
)

# Pinecone Inference API (embed without external model)
embeddings = pc.inference.embed(
    model="multilingual-e5-large",
    inputs=["wireless headphones", "bluetooth earbuds"],
    parameters={"input_type": "passage", "truncate": "END"}
)
```

### Namespace Isolation and Collection Lifecycle

```python
# Namespaces: logical partitions within an index (zero cost to create)
index.upsert(vectors=electronics_vectors, namespace="electronics")
index.upsert(vectors=clothing_vectors, namespace="clothing")

# Query only within a namespace
results = index.query(vector=query_vec, top_k=5, namespace="electronics")

# Delete by namespace
index.delete(delete_all=True, namespace="old_data")

# Collections: static snapshots for backup/migration
pc.create_collection(name="products-backup", source="products")
# Create new index from collection
pc.create_index(name="products-v2", dimension=1536, metric="cosine",
    spec=ServerlessSpec(cloud="aws", region="us-east-1"),
    source_collection="products-backup")
```

## Weaviate

### Schema Design and Vectorizer Modules

```python
import weaviate
from weaviate.classes.config import Configure, Property, DataType, VectorDistances

client = weaviate.connect_to_weaviate_cloud(
    cluster_url="https://your-cluster.weaviate.network",
    auth_credentials=weaviate.auth.AuthApiKey("YOUR_KEY")
)

# Create collection with vectorizer module
client.collections.create(
    name="Article",
    description="News articles for semantic search",
    vectorizer_config=Configure.Vectorizer.text2vec_openai(
        model="text-embedding-3-small",
        dimensions=1536
    ),
    # Alternative vectorizers:
    # Configure.Vectorizer.text2vec_cohere(model="embed-english-v3.0")
    # Configure.Vectorizer.text2vec_huggingface(model="sentence-transformers/all-MiniLM-L6-v2")
    # Configure.Vectorizer.text2vec_ollama(model="nomic-embed-text", api_endpoint="http://localhost:11434")
    generative_config=Configure.Generative.openai(model="gpt-4o"),
    vector_index_config=Configure.VectorIndex.hnsw(
        distance_metric=VectorDistances.COSINE,
        ef_construction=128,
        max_connections=16,
        ef=64
    ),
    properties=[
        Property(name="title", data_type=DataType.TEXT),
        Property(name="content", data_type=DataType.TEXT),
        Property(name="category", data_type=DataType.TEXT,
                 skip_vectorization=True),  # exclude from vectorization
        Property(name="published_at", data_type=DataType.DATE),
        Property(name="source", data_type=DataType.TEXT,
                 skip_vectorization=True,
                 tokenization=weaviate.classes.config.Tokenization.FIELD),
    ],
    multi_tenancy_config=Configure.multi_tenancy(enabled=True)
)
```

### Hybrid Search (BM25 + Vector)

```python
articles = client.collections.get("Article")

# Hybrid search: combines BM25 keyword matching with vector similarity
response = articles.query.hybrid(
    query="climate change renewable energy",
    alpha=0.75,        # 0=pure BM25, 1=pure vector
    limit=10,
    filters=weaviate.classes.query.Filter.by_property("category").equal("science"),
    return_metadata=weaviate.classes.query.MetadataQuery(score=True, explain_score=True),
    query_properties=["title", "content"]  # BM25 searches these fields
)

# Near-text search (pure vector, auto-vectorized query)
response = articles.query.near_text(
    query="impact of rising sea levels on coastal cities",
    limit=5,
    distance=0.3,      # max distance threshold
    move_to=weaviate.classes.query.Move(force=0.5, concepts=["flooding", "infrastructure"]),
    move_away=weaviate.classes.query.Move(force=0.3, concepts=["politics"]),
)

# Generative search (RAG in a single query)
response = articles.generate.near_text(
    query="renewable energy breakthroughs 2024",
    limit=5,
    single_prompt="Summarize this article in 2 sentences: {content}",
    grouped_task="Based on these articles, what are the top 3 renewable energy trends?"
)

# BM25 keyword search
response = articles.query.bm25(
    query="solar panel efficiency",
    query_properties=["title^2", "content"],  # boost title matches
    limit=10
)
```

### Multi-Tenancy and Replication

```python
# Multi-tenancy: isolate data per tenant (separate vector indexes)
articles = client.collections.get("Article")

# Add tenants
articles.tenants.create([
    weaviate.classes.tenants.Tenant(name="tenant-a", activity_status=weaviate.classes.tenants.TenantActivityStatus.ACTIVE),
    weaviate.classes.tenants.Tenant(name="tenant-b"),
])

# Insert data for specific tenant
tenant_articles = articles.with_tenant("tenant-a")
tenant_articles.data.insert(properties={"title": "Tenant A article", "content": "..."})

# Query within tenant
response = tenant_articles.query.near_text(query="search query", limit=5)

# Replication: configure replication factor for availability
# Set via collection config: replication_config=Configure.replication(factor=3)
```

## Milvus / Zilliz

### Index Types and GPU Acceleration

```python
from pymilvus import MilvusClient, CollectionSchema, FieldSchema, DataType

client = MilvusClient(uri="http://milvus:19530")

# Create collection with schema
schema = CollectionSchema(fields=[
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="category", dtype=DataType.VARCHAR, max_length=128),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="sparse_embedding", dtype=DataType.SPARSE_FLOAT_VECTOR),
])

client.create_collection(collection_name="documents", schema=schema)

# Index types comparison
# IVF_FLAT: inverted file with flat search (good recall, moderate speed)
# IVF_SQ8: quantized IVF (lower memory, slightly lower recall)
# HNSW: hierarchical navigable small world (best recall, high memory)
# DiskANN: disk-based ANN (large datasets that don't fit in memory)
# SCANN: Google's ScaNN algorithm (fast, good recall)
# GPU_IVF_FLAT / GPU_IVF_PQ: GPU-accelerated indexes

# Create HNSW index (best for recall-critical applications)
index_params = client.prepare_index_params()
index_params.add_index(
    field_name="embedding",
    index_type="HNSW",
    metric_type="COSINE",
    params={"M": 16, "efConstruction": 256}
)
client.create_index(collection_name="documents", index_params=index_params)

# DiskANN index (for billion-scale datasets)
index_params.add_index(
    field_name="embedding",
    index_type="DISKANN",
    metric_type="COSINE"
)

# GPU-accelerated index (requires GPU-enabled Milvus)
index_params.add_index(
    field_name="embedding",
    index_type="GPU_IVF_PQ",
    metric_type="L2",
    params={"nlist": 1024, "m": 16, "nbits": 8}
)
```

### Search with Partition Strategy

```python
# Partition by category for efficient filtered search
client.create_partition(collection_name="documents", partition_name="electronics")
client.create_partition(collection_name="documents", partition_name="clothing")

# Insert into specific partition
client.insert(collection_name="documents", partition_name="electronics", data=records)

# Search within partition (much faster than post-filtering)
results = client.search(
    collection_name="documents",
    data=[query_vector],
    anns_field="embedding",
    search_params={"metric_type": "COSINE", "params": {"ef": 128}},
    limit=10,
    partition_names=["electronics"],
    filter='category == "smartphones"',
    output_fields=["text", "category"]
)

# Hybrid search (dense + sparse vectors)
from pymilvus import AnnSearchRequest, RRFRanker

dense_req = AnnSearchRequest(data=[dense_vector], anns_field="embedding",
    param={"metric_type": "COSINE", "params": {"ef": 64}}, limit=20)
sparse_req = AnnSearchRequest(data=[sparse_vector], anns_field="sparse_embedding",
    param={"metric_type": "IP"}, limit=20)

results = client.hybrid_search(
    collection_name="documents",
    reqs=[dense_req, sparse_req],
    ranker=RRFRanker(k=60),  # Reciprocal Rank Fusion
    limit=10,
    output_fields=["text", "category"]
)
```

## Qdrant

### Collection Config and Quantization

```python
from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance, VectorParams, QuantizationConfig, ScalarQuantization,
    ProductQuantization, BinaryQuantization, OptimizersConfigDiff,
    HnswConfigDiff, Filter, FieldCondition, MatchValue, Range
)

client = QdrantClient(url="http://qdrant:6333", api_key="your-key")

# Create collection with quantization for memory efficiency
client.create_collection(
    collection_name="products",
    vectors_config=VectorParams(
        size=1536,
        distance=Distance.COSINE,
        on_disk=True,         # store vectors on disk (for large datasets)
        hnsw_config=HnswConfigDiff(
            m=16,
            ef_construct=128,
            full_scan_threshold=10000,
            on_disk=True      # HNSW index on disk
        )
    ),
    # Scalar quantization: 4x memory reduction, ~1% recall loss
    quantization_config=ScalarQuantization(
        scalar=ScalarQuantization(
            type="int8",
            quantile=0.99,
            always_ram=True   # keep quantized vectors in RAM for fast search
        )
    ),
    # Product quantization: 8-64x memory reduction
    # quantization_config=ProductQuantization(product=ProductQuantization(compression="x16", always_ram=True))
    # Binary quantization: 32x memory reduction (best for high-dim models like OpenAI)
    # quantization_config=BinaryQuantization(binary=BinaryQuantization(always_ram=True))
    optimizers_config=OptimizersConfigDiff(
        indexing_threshold=20000,
        memmap_threshold=50000
    )
)

# Create payload indexes for efficient filtering
client.create_payload_index(
    collection_name="products",
    field_name="category",
    field_schema="keyword"
)
client.create_payload_index(
    collection_name="products",
    field_name="price",
    field_schema="float"
)
```

### Filtering Strategies and Search

```python
# Search with complex filters (filters applied BEFORE ANN search for efficiency)
results = client.query_points(
    collection_name="products",
    query=query_vector,
    query_filter=Filter(
        must=[
            FieldCondition(key="category", match=MatchValue(value="electronics")),
            FieldCondition(key="price", range=Range(lte=200.0)),
        ],
        must_not=[
            FieldCondition(key="out_of_stock", match=MatchValue(value=True))
        ],
        should=[
            FieldCondition(key="brand", match=MatchValue(value="Sony")),
            FieldCondition(key="brand", match=MatchValue(value="Samsung")),
        ]
    ),
    limit=10,
    with_payload=True,
    score_threshold=0.7   # minimum similarity score
)

# Batch search (multiple queries in one request)
results = client.query_batch_points(
    collection_name="products",
    requests=[
        {"query": vec1, "limit": 5, "filter": filter1},
        {"query": vec2, "limit": 5, "filter": filter2},
    ]
)

# Snapshot for backup
client.create_snapshot(collection_name="products")

# Distributed mode: sharding and replication
# Configure via collection creation:
# shard_number=6, replication_factor=2, write_consistency_factor=1
```

## ChromaDB

### Embedded Vector Store

```python
import chromadb
from chromadb.utils.embedding_functions import OpenAIEmbeddingFunction

# Persistent client (data stored to disk)
client = chromadb.PersistentClient(path="/data/chromadb")

# Or in-memory client (for testing)
# client = chromadb.Client()

# Create collection with embedding function
embedding_fn = OpenAIEmbeddingFunction(
    api_key="sk-...",
    model_name="text-embedding-3-small"
)

collection = client.get_or_create_collection(
    name="documents",
    embedding_function=embedding_fn,
    metadata={"hnsw:space": "cosine", "hnsw:M": 16, "hnsw:construction_ef": 128}
)

# Add documents (auto-embedded by the embedding function)
collection.add(
    ids=["doc-1", "doc-2", "doc-3"],
    documents=["Machine learning fundamentals", "Deep learning architectures", "NLP transformers"],
    metadatas=[
        {"source": "textbook", "chapter": 1},
        {"source": "textbook", "chapter": 5},
        {"source": "paper", "year": 2017}
    ]
)

# Query with metadata filtering
results = collection.query(
    query_texts=["neural network training"],
    n_results=5,
    where={"source": "textbook"},
    where_document={"$contains": "learning"},
    include=["documents", "metadatas", "distances"]
)

# Update and delete
collection.update(ids=["doc-1"], metadatas=[{"source": "textbook", "chapter": 1, "reviewed": True}])
collection.delete(where={"year": {"$lt": 2015}})
```

## pgvector

### HNSW vs IVFFlat Indexes

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

-- Distance operators
-- <=> cosine distance
-- <-> L2 (Euclidean) distance
-- <#> negative inner product (for max inner product search)

-- Semantic search with SQL filtering
SELECT id, content, metadata,
       1 - (embedding <=> $1::vector) AS similarity
FROM documents
WHERE metadata->>'category' = 'technology'
  AND created_at > now() - INTERVAL '30 days'
ORDER BY embedding <=> $1::vector
LIMIT 10;

-- Hybrid search: combine full-text search rank with vector similarity
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

### Performance Tuning

```sql
-- Increase maintenance_work_mem for faster index builds
SET maintenance_work_mem = '2GB';

-- HNSW search parameter: higher ef = better recall, slower search
SET hnsw.ef_search = 100;  -- default 40, increase for better recall

-- IVFFlat search parameter: higher probes = better recall, slower search
SET ivfflat.probes = 10;   -- default 1, increase for better recall

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

## LanceDB

### Serverless Embedded Vector Database

```python
import lancedb
from lancedb.pydantic import LanceModel, Vector
from lancedb.embeddings import get_registry

# Embedded mode (zero infrastructure)
db = lancedb.connect("~/.lancedb")

# Or cloud mode
# db = lancedb.connect("db://your-project", api_key="sk-...")

# Define schema with Pydantic model
embedder = get_registry().get("openai").create(name="text-embedding-3-small")

class Document(LanceModel):
    text: str = embedder.SourceField()
    vector: Vector(1536) = embedder.VectorField()
    category: str
    source: str

# Create table and add data (auto-embeds text field)
table = db.create_table("documents", schema=Document)
table.add([
    {"text": "Machine learning basics", "category": "ml", "source": "textbook"},
    {"text": "Neural network architectures", "category": "dl", "source": "paper"},
])

# Search with SQL-like predicates
results = table.search("deep learning training techniques") \
    .where("category = 'ml'") \
    .limit(5) \
    .to_pandas()

# Multi-modal: store images, audio alongside vectors
# Lance format supports nested types, lists, binary data natively
```

## Vespa

### Hybrid Search with ML Model Serving

```yaml
# services.xml - Vespa application configuration
schema product {
  document product {
    field title type string {
      indexing: summary | index
      index: enable-bm25
    }
    field description type string {
      indexing: summary | index
      index: enable-bm25
    }
    field embedding type tensor<float>(x[1536]) {
      indexing: summary | attribute | index
      attribute { distance-metric: angular }
      index { hnsw { max-links-per-node: 16  neighbors-to-explore-at-insert: 200 } }
    }
    field category type string {
      indexing: summary | attribute
      attribute: fast-search
    }
  }

  rank-profile hybrid inherits default {
    inputs {
      query(q_embedding) tensor<float>(x[1536])
    }
    first-phase {
      expression: 0.7 * closeness(field, embedding) + 0.3 * bm25(title) + 0.1 * bm25(description)
    }
  }
}
```

## Marqo

### Tensor Search for Unstructured Data

```python
import marqo

mq = marqo.Client(url="http://localhost:8882")

# Create index with model configuration
mq.create_index("products", model="open_clip/ViT-B-32/laion2b_s34b_b79k",
    settings_dict={
        "treatUrlsAndPointersAsImages": True,  # multi-modal: text + images
        "numberOfShards": 2
    }
)

# Add documents (auto-vectorized by chosen model)
mq.index("products").add_documents([
    {"title": "Wireless Headphones", "description": "Noise-cancelling Bluetooth headphones",
     "image_url": "https://example.com/headphones.jpg", "price": 79.99},
], tensor_fields=["title", "description", "image_url"])

# Search (multi-modal: query can match text or images)
results = mq.index("products").search("comfortable headphones for commuting",
    filter_string="price:[0 TO 100]", limit=10)
```

## Turbopuffer

### Serverless Vector Search on Object Storage

```python
import turbopuffer as tpuf

# Connect (serverless, no infrastructure to manage)
ns = tpuf.Namespace("products")

# Upsert vectors with attributes
ns.upsert(
    ids=[1, 2, 3],
    vectors=[[0.1, 0.2, ...], [0.3, 0.4, ...], [0.5, 0.6, ...]],
    attributes={
        "category": ["electronics", "clothing", "electronics"],
        "price": [79.99, 29.99, 149.99],
    }
)

# Query with attribute filters
results = ns.query(
    vector=[0.15, 0.25, ...],
    top_k=10,
    filters={"category": ["Eq", "electronics"]},
    include_attributes=["category", "price"]
)
```

## Cross-Reference Databases

### Elasticsearch kNN (see document-databases skill)

```json
// Elasticsearch 8.x kNN search
POST products/_search
{
  "knn": {
    "field": "embedding",
    "query_vector": [0.1, 0.2, ...],
    "k": 10,
    "num_candidates": 100,
    "filter": { "term": { "category": "electronics" } }
  },
  "fields": ["title", "category", "price"]
}
```

### MongoDB Atlas Vector Search (see document-databases skill)

```javascript
// Atlas Vector Search aggregation pipeline
db.products.aggregate([
  {
    $vectorSearch: {
      index: "vector_index",
      path: "embedding",
      queryVector: queryEmbedding,
      numCandidates: 100,
      limit: 10,
      filter: { category: "electronics" }
    }
  },
  { $project: { title: 1, category: 1, score: { $meta: "vectorSearchScore" } } }
]);
```

### Redis Stack Vector (see key-value-stores skill)

```redis
FT.CREATE idx:products ON HASH PREFIX 1 product:
  SCHEMA
    title TEXT
    category TAG
    embedding VECTOR HNSW 6 TYPE FLOAT32 DIM 1536 DISTANCE_METRIC COSINE

FT.SEARCH idx:products "*=>[KNN 10 @embedding $query_vec AS score]"
  PARAMS 2 query_vec "\x00\x00..."
  RETURN 3 title category score
  SORTBY score
  DIALECT 2
```

## Embedding Pipeline Patterns

### Chunking Strategies

```python
# Fixed-size chunking with overlap
def chunk_text(text: str, chunk_size: int = 512, overlap: int = 50) -> list[str]:
    words = text.split()
    chunks = []
    for i in range(0, len(words), chunk_size - overlap):
        chunk = " ".join(words[i:i + chunk_size])
        if chunk:
            chunks.append(chunk)
    return chunks

# Semantic chunking (split by meaning boundaries)
# Use sentence-transformers to detect topic shifts
# Or use LLM-based chunking for complex documents

# Recursive character splitting (LangChain-style)
# Split by paragraphs -> sentences -> words, maintaining chunk size target
```

### Embedding Model Selection

| Model | Dimensions | Speed | Quality | Provider |
|-------|-----------|-------|---------|----------|
| text-embedding-3-small | 1536 | Fast | Good | OpenAI |
| text-embedding-3-large | 3072 | Medium | Best | OpenAI |
| embed-english-v3.0 | 1024 | Fast | Excellent | Cohere |
| voyage-3 | 1024 | Medium | Excellent | Voyage AI |
| all-MiniLM-L6-v2 | 384 | Very fast | Good | Open source |
| nomic-embed-text | 768 | Fast | Good | Open source (Ollama) |
| bge-large-en-v1.5 | 1024 | Medium | Excellent | Open source |
| mxbai-embed-large | 1024 | Medium | Excellent | Open source |

## RAG Architecture Patterns

### Basic RAG Pipeline

```
User Query
    |
    v
[1. Embed Query] --> embedding model
    |
    v
[2. Vector Search] --> vector DB (top-k similar chunks)
    |
    v
[3. Rerank] --> cross-encoder reranker (Cohere, ColBERT, bge-reranker)
    |
    v
[4. Prompt Assembly] --> system prompt + retrieved context + user query
    |
    v
[5. LLM Generation] --> answer with citations
```

### Advanced RAG Patterns

```
1. Hybrid Search RAG: BM25 + vector search with Reciprocal Rank Fusion (RRF)
2. Multi-Query RAG: generate multiple query variations, search each, merge results
3. HyDE (Hypothetical Document Embeddings): generate hypothetical answer, embed it, search
4. Parent Document Retrieval: embed small chunks, retrieve parent document for context
5. Contextual Compression: LLM extracts only relevant parts from retrieved chunks
6. Self-RAG: LLM decides when to retrieve and evaluates retrieval quality
7. Graph RAG: combine vector search with knowledge graph traversal
8. Agentic RAG: LLM-driven iterative retrieval with tool use
```

## Operational Best Practices

### Index Tuning Guidelines

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

### Monitoring Vector Databases

- Track: query latency (p50/p95/p99), recall rate, index size, ingestion throughput
- Alert on: latency spikes, recall degradation, disk/memory usage > 80%
- Regularly benchmark recall against ground truth (sample queries with known relevant docs)
- Monitor embedding model drift: periodically re-embed a sample and compare similarity distributions

### Cost Optimization

- Use quantization to reduce memory (and cost) by 4-32x
- Implement metadata filtering to reduce the search space before ANN
- Use namespaces/partitions to isolate data and speed up filtered queries
- Choose serverless options (Pinecone Serverless, Turbopuffer) for variable workloads
- Batch upserts and queries to reduce API call overhead
- Consider pgvector if you already run PostgreSQL (zero additional infrastructure)
- Use dimensionality reduction (PCA, Matryoshka embeddings) for cost-sensitive deployments
