# Product Search, Faceted Navigation, and Recommendation Engine

## When to load
Load when implementing product search relevance tuning, faceted navigation, or recommendation engine patterns (collaborative filtering, content-based, hybrid).

## Product Search

### Search Engine Selection
- Dedicated search engine: Elasticsearch, OpenSearch, Algolia, Typesense, or Meilisearch.
- Index product data: title, description, brand, category, attributes, tags.
- Keep index in sync via events, CDC pipeline, or scheduled reindexing.

### Relevance Tuning
- Field boosting: title (highest) > brand > category > description > attributes.
- Function scoring: boost by popularity (sales/views), recency, or margin.
- Synonyms: "sneakers" = "trainers" = "running shoes".
- Stemming and language-specific analyzers for morphological matching.
- "Did you mean?" suggestions via fuzzy matching or a spellcheck index.

### Autocomplete and Typeahead
- Search-as-you-type suggestions from a completion suggester or prefix index.
- Show product suggestions, category suggestions, and recent searches.
- Debounce client-side requests (200-300ms) to reduce load.

## Faceted Navigation

### Facet Types
- **Range facets**: price ranges, ratings — use histogram aggregations.
- **Term facets**: brand, color, size, material — use terms aggregations.
- **Hierarchical facets**: category breadcrumbs (Clothing > Men > Shirts).
- **Boolean facets**: in-stock, on-sale, free shipping.

### Implementation
- Return facet counts alongside search results so users see match counts per filter.
- Apply selected facets as query filters; update remaining facet counts dynamically.
- Preserve facet selections across pagination and sorting changes.
- Use URL query parameters for facets — filtered views must be bookmarkable and shareable.

## Recommendation Engine

### Collaborative Filtering
- "Customers who bought X also bought Y" — based on co-purchase patterns.
- Matrix factorization (ALS) or item-based nearest neighbors on purchase history.
- Best for cross-sell on product pages and cart pages.

### Content-Based Filtering
- "Similar products" — based on shared attributes (category, brand, price range, features).
- TF-IDF or embeddings on product descriptions for semantic similarity.
- Best for related products and "you may also like" sections.

### Hybrid Approach
- Combine collaborative + content-based for better coverage and accuracy.
- Use collaborative for users with purchase history; content-based for cold-start (new users).
- Retrain models on a regular schedule (daily or weekly) with recent interaction data.

### Placement Strategy
- **Product detail page**: similar products, frequently bought together.
- **Cart page**: cross-sell complementary items.
- **Homepage**: personalized picks, trending, new arrivals.
- **Post-purchase email**: recommendations based on purchased items.
