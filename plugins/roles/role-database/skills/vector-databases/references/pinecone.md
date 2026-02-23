# Pinecone

## When to load
Load when working with Pinecone serverless or pod indexes, hybrid sparse-dense search, namespaces, collections, or the Pinecone Inference API.

## Serverless vs Pod Architecture

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

## Upsert, Query, and Hybrid Search

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

## Namespace Isolation and Collection Lifecycle

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
