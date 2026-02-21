---
name: search-merchandising
description: |
  Search and merchandising for e-commerce: product search relevance tuning, faceted navigation,
  recommendation engine patterns (collaborative filtering, content-based), A/B testing for
  layouts, personalization, and SEO for product pages.
allowed-tools: Read, Grep, Glob, Bash
---

# Search and Merchandising

## Product Search

### Search Engine Selection
- Use a dedicated search engine: Elasticsearch, OpenSearch, Algolia, Typesense, or Meilisearch.
- Index product data (title, description, brand, category, attributes, tags) for full-text search.
- Keep the search index in sync with the database via events, CDC, or scheduled reindexing.

### Relevance Tuning
- Apply field boosting: title (highest), brand, category, description, attributes.
- Use function scoring to boost by popularity (sales count, view count), recency, or margin.
- Configure synonyms (e.g., "sneakers" = "trainers" = "running shoes").
- Add stemming and language-specific analyzers for morphological matching.
- Implement "did you mean?" suggestions using fuzzy matching or a spellcheck index.

### Autocomplete and Typeahead
- Provide search-as-you-type suggestions from a completion suggester or prefix index.
- Show product suggestions, category suggestions, and recent searches.
- Debounce client-side requests (200-300ms) to reduce load.

## Faceted Navigation

### Facet Types
- **Range facets**: price ranges, ratings (use histogram aggregations).
- **Term facets**: brand, color, size, material (use terms aggregations).
- **Hierarchical facets**: category breadcrumbs (e.g., Clothing > Men > Shirts).
- **Boolean facets**: in-stock, on-sale, free shipping.

### Implementation
- Return facet counts alongside search results so users see how many products match each filter.
- Apply selected facets as query filters; update remaining facet counts dynamically.
- Preserve facet selections across pagination and sorting changes.
- Use URL query parameters for facets so filtered views are bookmarkable and shareable.

## Recommendation Engine

### Collaborative Filtering
- "Customers who bought X also bought Y" -- based on co-purchase patterns.
- Use matrix factorization (ALS) or item-based nearest neighbors on purchase history.
- Suitable for cross-sell on product pages and cart pages.

### Content-Based Filtering
- "Similar products" -- based on shared attributes (category, brand, price range, features).
- Use TF-IDF or embeddings on product descriptions for semantic similarity.
- Suitable for related products and "you may also like" sections.

### Hybrid Approach
- Combine collaborative and content-based signals for better coverage and accuracy.
- Use collaborative filtering for users with purchase history; fall back to content-based for new users (cold start).
- Re-train models on a regular schedule (daily or weekly) with recent interaction data.

### Placement Strategy
- Product detail page: similar products, frequently bought together.
- Cart page: cross-sell complementary items.
- Homepage: personalized picks, trending, new arrivals.
- Post-purchase email: recommendations based on the purchased items.

## A/B Testing

### What to Test
- Search result ranking algorithms.
- Product listing layouts (grid vs. list, cards per row).
- Recommendation placements and algorithms.
- Category page sorting defaults (relevance, price, popularity).
- CTA button text and color on product pages.

### Implementation
- Assign users to variants consistently (hash user ID or session ID).
- Track conversion events (add-to-cart, purchase) per variant.
- Run tests until statistical significance (p < 0.05) with sufficient sample size.
- Use a feature flag system (LaunchDarkly, Unleash, or custom) to control variants.

## Personalization

- Track user behavior: views, searches, add-to-carts, purchases.
- Build user profiles with preferred categories, brands, price ranges.
- Personalize search result ranking, homepage content, and email recommendations.
- Respect privacy: allow opt-out, comply with GDPR/CCPA for behavioral data.

## SEO for Product Pages

### Structured Data
- Add JSON-LD `Product` schema with name, description, image, price, availability, rating, and review count.
- Include `BreadcrumbList` schema for category navigation.
- Add `Organization` or `LocalBusiness` schema for the seller.

### Technical SEO
- Use canonical URLs to prevent duplicate content from filters and sorting.
- Generate unique, keyword-rich meta titles and descriptions per product.
- Create clean URL slugs: `/category/product-name` rather than `/product?id=123`.
- Implement `hreflang` tags for multi-language catalogs.
- Generate an XML sitemap with all product URLs and last-modified dates; submit to search engines.
- Optimize page load speed: lazy-load images, minimize JavaScript, use server-side rendering or static generation.
