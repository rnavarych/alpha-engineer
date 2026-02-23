---
name: search-implementation
description: Implement search features using Meilisearch, Typesense, Algolia, ElasticSearch, OpenSearch, or PostgreSQL full-text search. Covers indexing strategy with incremental sync via CDC or application hooks, autocomplete/typeahead with debounce, faceted search UI with URL-encoded filter state, relevance tuning (field boosts, typo tolerance, synonyms), and common pitfalls. Use when adding product search, content discovery, autocomplete, or faceted filtering to an application.
allowed-tools: Read, Grep, Glob, Bash
---

# Search Implementation

## When to use
- Adding full-text search to a product catalog or content site
- Building autocomplete or typeahead input
- Implementing faceted filtering with sidebar checkboxes and result counts
- Syncing a database with a search index (initial bulk load + incremental updates)
- Tuning relevance ranking after users complain results are wrong
- Choosing between self-hosted (Meilisearch, Typesense) and managed (Algolia)

## Core principles
1. **Engine matches scale and budget** — pg_trgm for small datasets with no extra infra; Meilisearch/Typesense for fast typo-tolerant search on a budget; Algolia when managed SaaS and rich UI components justify the cost
2. **Denormalize for search** — flatten related data into the search document at index time; joins at query time kill latency
3. **Incremental sync, not full re-index** — hook into Prisma middleware, DB triggers, or a CDC pipeline; bulk re-indexing on every change is the first thing that breaks under load
4. **Debounce is not optional** — 200-300ms debounce on autocomplete input; without it you hit rate limits and burn the user's battery
5. **Encode filters in the URL** — active facets belong in `useSearchParams`; shareable and bookmarkable search state is a product feature, not a nice-to-have

## Reference Files

- `references/engine-selection-indexing.md` — engine comparison table with latency and hosting characteristics, four-step indexing strategy, incremental sync options (CDC, hooks, job queue), Meilisearch settings and search code example
- `references/ui-patterns-relevance.md` — debounced useSearch hook with TanStack Query, keepPreviousData pattern, faceted search UI with URL sync, relevance tuning controls (field boosts, typo tolerance, synonyms, stop words, custom ranking), common pitfalls
