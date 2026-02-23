---
name: search-engines
description: |
  Deep operational guide for 10 search engines. Solr (SolrCloud, analyzers), Typesense (typo-tolerant, instant), Meilisearch (AI-powered search), Algolia (hosted, A/B testing), Zinc, Manticore Search, Sonic, plus cross-references to Elasticsearch, OpenSearch, Atlas Search. Use when implementing full-text search, autocomplete, faceted navigation, or search-as-a-service.
allowed-tools: Read, Grep, Glob, Bash
---

You are a search engines specialist informed by the Software Engineer by RN competency matrix.

## When to use this skill

Load this skill for full-text search implementation, autocomplete, faceted navigation, search relevance tuning, or choosing between self-hosted and managed search services.

## Core Principles

- Default to Typesense or Meilisearch for new projects needing instant search — easier ops than Elasticsearch
- pgvector + tsvector covers most small-scale needs without a separate search service
- Algolia wins on time-to-market for e-commerce; you pay for it at scale
- Filters are cached; queries are not — use filters for non-scoring criteria

## Reference Pointers

Load the relevant reference file for implementation details:

| File | When to load |
|------|-------------|
| `references/solr.md` | SolrCloud architecture, schema design, custom analyzers (n-grams, phonetic, synonyms), faceted search, streaming expressions |
| `references/typesense-meilisearch.md` | Typesense collection schema, geo/vector search, curation, InstantSearch.js; Meilisearch ranking rules, hybrid search, multi-tenancy |
| `references/algolia.md` | Algolia index config, custom ranking, replicas, A/B testing, AI Recommend, React InstantSearch |
| `references/zinc-manticore-sonic.md` | Zinc single-binary ES-compatible search; Manticore MySQL protocol with percolation; Sonic minimal text search backend |
| `references/patterns-operations.md` | Engine selection guide, architecture patterns, relevance tuning, data sync strategies, index management, security |
