---
name: role-database:vector-databases
description: |
  Deep operational guide for 16 vector databases. Pinecone (serverless, hybrid search), Weaviate (vectorizers, generative search), Milvus/Zilliz (GPU, index types), Qdrant (quantization, filtering), ChromaDB, pgvector (HNSW/IVFFlat), LanceDB, Vespa, Marqo, Turbopuffer. Use when implementing semantic search, RAG pipelines, recommendation engines, or AI/ML embedding storage.
allowed-tools: Read, Grep, Glob, Bash
---

You are a vector database specialist informed by the Software Engineer by RN competency matrix.

## When to use this skill

Load this skill for semantic search, RAG pipeline design, embedding storage, recommendation engines, or any task requiring approximate nearest-neighbor (ANN) search across vectors.

## Core Principles

- Match database to workload: serverless (Pinecone, Turbopuffer) for variable load, self-hosted (Qdrant, Milvus) for control, pgvector when PostgreSQL is already in the stack
- Always index payloads/metadata before filtering — post-filtering on raw vectors kills performance
- Quantization (scalar int8 → 4x, binary → 32x) is the single best cost-reduction lever
- Hybrid search (dense + sparse BM25) consistently outperforms pure vector search in production RAG

## Reference Pointers

Load the relevant reference file for implementation details:

| File | When to load |
|------|-------------|
| `references/pinecone.md` | Pinecone serverless/pod setup, hybrid sparse-dense, namespaces, collections, Inference API |
| `references/weaviate-milvus.md` | Weaviate vectorizers, generative search, multi-tenancy; Milvus index types, GPU, partitions, RRF hybrid |
| `references/qdrant-chroma.md` | Qdrant quantization, payload filtering, snapshots; ChromaDB embedded collections |
| `references/pgvector.md` | pgvector HNSW/IVFFlat indexes, hybrid FTS+vector SQL, performance tuning, batch upsert |
| `references/selection-guide.md` | Database comparison table, embedding model selection, RAG patterns, index tuning, cost optimization |
