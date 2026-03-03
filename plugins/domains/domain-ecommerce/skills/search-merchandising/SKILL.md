---
name: domain-ecommerce:search-merchandising
description: |
  Search and merchandising for e-commerce: product search relevance tuning, faceted navigation,
  recommendation engine patterns (collaborative filtering, content-based), A/B testing for
  layouts, personalization, and SEO for product pages.
allowed-tools: Read, Grep, Glob, Bash
---

# Search and Merchandising

## When to use
- Selecting or tuning a product search engine (Elasticsearch, Algolia, Typesense, Meilisearch)
- Implementing or improving search relevance (field boosting, synonyms, function scoring)
- Building faceted navigation with dynamic facet counts and URL-preserving filters
- Implementing a recommendation engine (collaborative filtering, content-based, or hybrid)
- Running A/B tests on search ranking, listing layouts, or recommendation placements
- Adding personalization to search results, homepage, or email recommendations
- Implementing technical SEO for product pages (schema.org, canonical URLs, hreflang, sitemaps)

## Core principles
1. **Boost by behavior, not just text match** — sales count and view count as function score signals outperform pure BM25 for commerce
2. **Facet counts must stay accurate under multi-select** — post-filter aggregations; users abandon nav when counts are wrong
3. **Cold start kills collaborative filtering** — always have a content-based fallback for new users and new products
4. **Canonical every filter combination** — faceted nav generates thousands of URL permutations; without canonicals, you split ranking signals
5. **Hash user ID for A/B assignment** — session-based assignment causes variant flicker on login; user ID gives consistent experience

## Reference Files
- `references/search-facets-recommendations.md` — search engine selection, relevance tuning, autocomplete, facet types and implementation, collaborative/content-based/hybrid recommendation patterns and placement strategy
- `references/abtesting-personalization-seo.md` — what to A/B test in search and merchandising, feature flag implementation, personalization pipeline, schema.org markup, technical SEO for product pages
