# Search UI Patterns and Relevance Tuning

## When to load
Load when building autocomplete/typeahead, faceted search UI, or tuning search relevance rules.

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

- **Boost fields** — assign higher weight to title/name vs description/body.
- **Typo tolerance** — configure max typos per word length (1 for 4-7 chars, 2 for 8+).
- **Synonyms** — define synonym groups (e.g., "laptop" = "notebook" = "portable computer").
- **Stop words** — remove common words that add noise (language-specific lists).
- **Custom ranking** — tie-break relevance with business metrics (popularity, recency, availability).

## Common Pitfalls

- Indexing every field — only index fields users actually search on to keep the index lean.
- Not handling empty search results — always show suggestions, popular items, or a clear message.
- Re-indexing the entire dataset on every change instead of incremental updates.
- Skipping relevance testing — test with real user queries and iterate on ranking rules.
- Missing debounce on the frontend causing excessive API calls and rate-limit hits.
