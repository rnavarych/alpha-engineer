# Qdrant and ChromaDB

## When to load
Load when working with Qdrant quantization, payload filtering, snapshots, or sharding; or ChromaDB embedded/persistent collections with metadata filtering.

## Qdrant: Collection Config and Quantization

```python
from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance, VectorParams, ScalarQuantization,
    ProductQuantization, BinaryQuantization, OptimizersConfigDiff,
    HnswConfigDiff, Filter, FieldCondition, MatchValue, Range
)

client = QdrantClient(url="http://qdrant:6333", api_key="your-key")

client.create_collection(
    collection_name="products",
    vectors_config=VectorParams(
        size=1536,
        distance=Distance.COSINE,
        on_disk=True,
        hnsw_config=HnswConfigDiff(
            m=16,
            ef_construct=128,
            full_scan_threshold=10000,
            on_disk=True
        )
    ),
    # Scalar quantization: 4x memory reduction, ~1% recall loss
    quantization_config=ScalarQuantization(
        scalar=ScalarQuantization(type="int8", quantile=0.99, always_ram=True)
    ),
    # Product quantization: 8-64x memory reduction
    # quantization_config=ProductQuantization(product=ProductQuantization(compression="x16", always_ram=True))
    # Binary quantization: 32x reduction, best for high-dim OpenAI models
    # quantization_config=BinaryQuantization(binary=BinaryQuantization(always_ram=True))
    optimizers_config=OptimizersConfigDiff(
        indexing_threshold=20000,
        memmap_threshold=50000
    )
)

# Payload indexes for efficient pre-filtering
client.create_payload_index(collection_name="products", field_name="category", field_schema="keyword")
client.create_payload_index(collection_name="products", field_name="price", field_schema="float")
```

## Qdrant: Filtering and Batch Search

```python
# Filters applied BEFORE ANN search for efficiency
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
    score_threshold=0.7
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

# Distributed: shard_number=6, replication_factor=2, write_consistency_factor=1
```

## ChromaDB: Embedded Vector Store

```python
import chromadb
from chromadb.utils.embedding_functions import OpenAIEmbeddingFunction

# Persistent client (data stored to disk)
client = chromadb.PersistentClient(path="/data/chromadb")
# Or in-memory: client = chromadb.Client()

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
