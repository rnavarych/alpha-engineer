---
name: product-catalog
description: |
  Product catalog design for e-commerce: data modeling (products, variants, attributes,
  categories, collections), pricing engine, tax calculation, multi-language/localization,
  catalog search indexing, and image management.
allowed-tools: Read, Grep, Glob, Bash
---

# Product Catalog

## Data Modeling

### Products and Variants
- Separate the product (abstract item) from variants (purchasable SKUs with specific size, color, etc.).
- Use an EAV (entity-attribute-value) or JSON column for flexible custom attributes.
- Store variant-specific fields: SKU, price override, weight, dimensions, barcode (UPC/EAN).
- Maintain a `products` table with shared data (title, description, brand) and a `variants` table keyed by product ID.

### Attributes and Options
- Define option types (e.g., "Size", "Color") at the product level.
- Each variant is a combination of option values (e.g., Size=M, Color=Red).
- Support attribute-based filtering: index attributes used in faceted search.

### Categories and Collections
- Use a hierarchical category tree (adjacency list or nested set model).
- Support multiple category assignments per product.
- Implement collections (curated groups) for merchandising (e.g., "Summer Sale", "Best Sellers").
- Differentiate between rule-based (automated) and manual collections.

## Pricing Engine

### Price Types
- Base price (MSRP or list price).
- Sale price with start/end dates for time-limited promotions.
- Volume/tiered discounts (buy 10+ for 15% off).
- Customer-group pricing (wholesale, VIP, employee).

### Price Resolution
- Resolve the final price by evaluating rules in priority order: customer-specific > sale > volume > base.
- Store price history for analytics and audit.
- Support multi-currency pricing: per-currency price overrides or automatic conversion from a base currency.

## Tax Calculation

### Tax Providers
- Integrate with TaxJar or Avalara for real-time tax rate calculation.
- Fall back to static tax tables for simple scenarios (single jurisdiction).
- Pass product tax codes (e.g., clothing, food, digital goods) for correct categorization.

### Tax Display
- Display tax-inclusive or tax-exclusive prices based on locale (EU: inclusive; US: exclusive).
- Calculate tax at the line-item level and round per-line to avoid penny discrepancies.
- Store tax amounts separately on order line items for reporting.

## Multi-Language and Localization

- Store translatable fields (title, description, SEO metadata) in a separate translations table keyed by locale.
- Use a fallback chain: requested locale > default locale > original content.
- Localize units (weight, dimensions), date formats, and currency symbols.
- Generate locale-specific URL slugs for SEO.

## Catalog Search Indexing

### Indexing Strategy
- Index products into a search engine (Elasticsearch, OpenSearch, Algolia, Typesense) on create/update.
- Include searchable fields: title, description, brand, category names, attribute values.
- Use a change-data-capture (CDC) pipeline or application-level events to keep the index in sync.

### Search Quality
- Configure field boosting (title > description > attributes).
- Add synonyms and stemming rules for better recall.
- Track search queries with zero results to identify catalog gaps or missing synonyms.

## Image Management

### Storage and Processing
- Upload original images to object storage (S3, GCS, Azure Blob).
- Generate responsive variants (thumbnail, medium, large, zoom) on upload or on-the-fly via an image CDN (Cloudinary, imgix).
- Store image metadata: alt text, sort order, variant association, primary flag.

### Optimization
- Serve images in modern formats (WebP, AVIF) with fallback to JPEG/PNG.
- Use lazy loading and responsive `srcset` for frontend performance.
- Set cache headers for long-lived CDN caching with cache-busting via content hashes.
