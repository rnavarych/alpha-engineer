# Weaviate and Milvus / Zilliz

## When to load
Load when working with Weaviate schema/vectorizers/generative search/multi-tenancy, or Milvus/Zilliz index types, GPU acceleration, partitions, and hybrid search with RRF.

## Weaviate: Schema and Vectorizer Modules

```python
import weaviate
from weaviate.classes.config import Configure, Property, DataType, VectorDistances

client = weaviate.connect_to_weaviate_cloud(
    cluster_url="https://your-cluster.weaviate.network",
    auth_credentials=weaviate.auth.AuthApiKey("YOUR_KEY")
)

client.collections.create(
    name="Article",
    description="News articles for semantic search",
    vectorizer_config=Configure.Vectorizer.text2vec_openai(
        model="text-embedding-3-small",
        dimensions=1536
    ),
    # Configure.Vectorizer.text2vec_cohere(model="embed-english-v3.0")
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
        Property(name="category", data_type=DataType.TEXT, skip_vectorization=True),
        Property(name="published_at", data_type=DataType.DATE),
    ],
    multi_tenancy_config=Configure.multi_tenancy(enabled=True)
)
```

## Weaviate: Hybrid Search and Generative RAG

```python
articles = client.collections.get("Article")

# Hybrid: BM25 keyword + vector similarity
response = articles.query.hybrid(
    query="climate change renewable energy",
    alpha=0.75,        # 0=pure BM25, 1=pure vector
    limit=10,
    filters=weaviate.classes.query.Filter.by_property("category").equal("science"),
    return_metadata=weaviate.classes.query.MetadataQuery(score=True, explain_score=True),
    query_properties=["title", "content"]
)

# Near-text with concept steering
response = articles.query.near_text(
    query="impact of rising sea levels on coastal cities",
    limit=5,
    distance=0.3,
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
```

## Weaviate: Multi-Tenancy

```python
articles.tenants.create([
    weaviate.classes.tenants.Tenant(name="tenant-a",
        activity_status=weaviate.classes.tenants.TenantActivityStatus.ACTIVE),
    weaviate.classes.tenants.Tenant(name="tenant-b"),
])
tenant_articles = articles.with_tenant("tenant-a")
tenant_articles.data.insert(properties={"title": "Tenant A article", "content": "..."})
response = tenant_articles.query.near_text(query="search query", limit=5)
# Replication: set replication_config=Configure.replication(factor=3) on collection creation
```

## Milvus / Zilliz: Index Types and GPU Acceleration

```python
from pymilvus import MilvusClient, CollectionSchema, FieldSchema, DataType

client = MilvusClient(uri="http://milvus:19530")

schema = CollectionSchema(fields=[
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="category", dtype=DataType.VARCHAR, max_length=128),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="sparse_embedding", dtype=DataType.SPARSE_FLOAT_VECTOR),
])
client.create_collection(collection_name="documents", schema=schema)

# Index types:
# IVF_FLAT: inverted file (good recall, moderate speed)
# HNSW: best recall, high memory
# DiskANN: disk-based ANN for datasets larger than RAM
# GPU_IVF_FLAT / GPU_IVF_PQ: GPU-accelerated

index_params = client.prepare_index_params()
index_params.add_index(
    field_name="embedding",
    index_type="HNSW",
    metric_type="COSINE",
    params={"M": 16, "efConstruction": 256}
)
client.create_index(collection_name="documents", index_params=index_params)
```

## Milvus: Partition Strategy and Hybrid Search

```python
client.create_partition(collection_name="documents", partition_name="electronics")
client.insert(collection_name="documents", partition_name="electronics", data=records)

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

# Hybrid search with Reciprocal Rank Fusion
from pymilvus import AnnSearchRequest, RRFRanker

dense_req = AnnSearchRequest(data=[dense_vector], anns_field="embedding",
    param={"metric_type": "COSINE", "params": {"ef": 64}}, limit=20)
sparse_req = AnnSearchRequest(data=[sparse_vector], anns_field="sparse_embedding",
    param={"metric_type": "IP"}, limit=20)

results = client.hybrid_search(
    collection_name="documents",
    reqs=[dense_req, sparse_req],
    ranker=RRFRanker(k=60),
    limit=10,
    output_fields=["text", "category"]
)
```
