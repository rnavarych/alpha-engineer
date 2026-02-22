---
name: search-implementation
description: |
  Implement search features using ElasticSearch, OpenSearch, Typesense,
  Meilisearch, or Algolia. Covers faceted search UI, autocomplete/typeahead,
  search relevance tuning, indexing strategies, and debounce patterns.
allowed-tools: Read, Grep, Glob, Bash
---

# Search Implementation

## When to Use

Activate when adding search functionality to an application -- product search, content discovery, autocomplete, faceted filtering, or full-text search across large datasets.

## Search Engine Selection

| Engine        | Hosting     | Latency | Best For                              |
|---------------|-------------|---------|---------------------------------------|
| ElasticSearch | Self/Cloud  | ~50ms   | Large-scale, complex queries, analytics|
| OpenSearch    | Self/AWS    | ~50ms   | AWS-native, ElasticSearch alternative  |
| Typesense     | Self/Cloud  | ~5ms    | Typo-tolerant, easy setup, fast        |
| Meilisearch   | Self/Cloud  | ~5ms    | Developer-friendly, instant search     |
| Algolia       | Managed     | ~5ms    | Managed SaaS, rich UI components       |
| pg_trgm / FTS | PostgreSQL  | ~20ms   | Small datasets, no extra infra         |

## Indexing Strategy

1. **Define the schema** -- choose searchable fields, filterable attributes, sortable attributes, and ranking rules.
2. **Initial sync** -- bulk-index existing data using batch operations (1000-5000 documents per batch).
3. **Incremental sync** -- update the index on data changes via:
   - Database triggers or Change Data Capture (Debezium).
   - Application-level hooks (Prisma middleware, Sequelize hooks).
   - Background job queue (process changes asynchronously).
4. **Denormalize for search** -- flatten related data into the search document to avoid joins at query time.

## Autocomplete / Typeahead

```typescript
// Debounced search with TanStack Query
function useSearch(query: string) {
  const [debouncedQuery] = useDebounce(query, 300);

  return useQuery({
    queryKey: ['search', debouncedQuery],
    queryFn: () => searchClient.search(debouncedQuery),
    enabled: debouncedQuery.length >= 2,
    staleTime: 60_000,
    placeholderData: keepPreviousData,
  });
}
```

- Debounce input by 200-300ms to reduce API calls.
- Show results after a minimum of 2 characters.
- Use `keepPreviousData` to avoid layout shift between queries.
- Highlight matching text in results using the search engine's highlight feature.

## Faceted Search UI

- Display facets (filters) as checkboxes, radio buttons, or range sliders in a sidebar.
- Show result counts per facet value (e.g., "Color: Red (42)").
- Update facet counts dynamically as filters are applied.
- Encode active filters in the URL query string for shareable and bookmarkable search states.
- Use `useSearchParams` (React Router / Next.js) to sync filter state with the URL.

## Search Relevance Tuning

- **Boost fields** -- assign higher weight to title/name vs description/body.
- **Typo tolerance** -- configure max typos per word length (1 for 4-7 chars, 2 for 8+).
- **Synonyms** -- define synonym groups (e.g., "laptop" = "notebook" = "portable computer").
- **Stop words** -- remove common words that add noise (language-specific lists).
- **Custom ranking** -- tie-break relevance with business metrics (popularity, recency, availability).

## Implementation Pattern (Meilisearch Example)

```typescript
// Server: indexing
import { MeiliSearch } from 'meilisearch';
const client = new MeiliSearch({ host: process.env.MEILI_HOST, apiKey: process.env.MEILI_KEY });

await client.index('products').updateSettings({
  searchableAttributes: ['name', 'description', 'category'],
  filterableAttributes: ['category', 'price', 'inStock'],
  sortableAttributes: ['price', 'createdAt'],
  rankingRules: ['words', 'typo', 'proximity', 'attribute', 'sort', 'exactness'],
});

// Client: search with filters
const results = await client.index('products').search(query, {
  filter: ['category = "electronics"', 'price >= 10 AND price <= 500'],
  sort: ['price:asc'],
  limit: 20,
  offset: 0,
});
```

## Common Pitfalls

- Indexing every field -- only index fields users actually search on to keep the index lean.
- Not handling empty search results -- always show suggestions, popular items, or a clear message.
- Re-indexing the entire dataset on every change instead of incremental updates.
- Skipping relevance testing -- test with real user queries and iterate on ranking rules.
- Missing debounce on the frontend causing excessive API calls and rate-limit hits.
