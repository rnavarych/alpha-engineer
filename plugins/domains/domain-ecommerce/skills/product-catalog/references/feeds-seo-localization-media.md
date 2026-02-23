# Feed Syndication, SEO, Localization, Search Indexing, and Media

## When to load
Load when building product feed syndication (Google Shopping, Meta, Amazon), implementing schema.org markup, localizing catalog content, configuring search indexing, or managing product images and media.

## Feed Syndication

### Google Shopping (Merchant Center)
- Required fields: id, title, description, link, image_link, price, availability, brand, gtin, condition.
- Optional: sale_price, sale_price_effective_date, product_type, google_product_category, color, size, gender, age_group, item_group_id (variants), shipping, tax.
- Formats: XML (RSS 2.0/Atom), TSV/CSV, or Content API for Shopping (REST, real-time updates).
- Supplemental feeds for overriding/enriching primary feed. Feed rules in Merchant Center for transformation.
- Feed diagnostics: monitor disapproved products, warnings, data quality issues.

### Facebook/Meta Catalog
- Fields: id, title, description, availability, condition, price, link, image_link, brand.
- Catalog Manager for Facebook/Instagram Shopping and Dynamic Ads.
- Commerce Manager for checkout-enabled shops (Instagram Checkout, Facebook Shops).
- Catalog Batch API and item API for programmatic updates. Product sets for Dynamic Ads targeting.

### Amazon Marketplace
- Flat file (CSV) via Seller Central or SP-API.
- Data: item_name, brand, manufacturer, product_type, bullet_points, description, images, price, quantity.
- A+ Content for rich PDPs. Inventory and pricing feeds for dynamic sync.
- Order feed: pull Amazon orders into OMS for fulfillment.

### Feed Architecture
- Central PIM or commerce platform feeds into feed management system.
- Tools: Feedonomics, DataFeedWatch, ChannelAdvisor, Channable, GoDataFeed.
- Full feed daily; incremental updates every 1-4 hours for price/stock changes.
- Multi-language and multi-currency feeds for international channels.

## Schema.org Product Markup

### Required Structured Data
- JSON-LD `Product` on PDP with: `name`, `description`, `image`, `sku`, `gtin`, `brand`, `offers`.
- `Offer`: `price`, `priceCurrency`, `availability` (InStock/OutOfStock/PreOrder), `url`, `seller`.
- `AggregateRating`: `ratingValue`, `reviewCount`, `bestRating` for star ratings in search.
- `Review`: individual entries with `author`, `datePublished`, `reviewBody`, `reviewRating`.
- `BreadcrumbList`: category navigation path for breadcrumb rich results.

### Advanced Markup
- `AggregateOffer` for price ranges across variants ("From $29.99 to $49.99").
- `ItemList` for product listing pages with item position.
- `FAQPage` for product FAQ sections.
- `shippingDetails`: `OfferShippingDetails` for shipping cost and delivery time in search.
- `hasMerchantReturnPolicy`: `MerchantReturnPolicy` for return policy in search results.
- Use JSON-LD (not microdata or RDFa). Validate with Google Rich Results Test.
- Structured data must match visible page content — price/availability/ratings must be in sync.

## Multi-Language and Localization
- Translatable fields (title, description, SEO metadata) in separate translations table keyed by locale.
- Fallback chain: requested locale → default locale → original content.
- Localize units (weight, dimensions), date formats, and currency symbols.
- Locale-specific URL slugs for SEO (`/en/blue-sneakers`, `/de/blaue-turnschuhe`).
- RTL support for Arabic, Hebrew, and other RTL locales.
- TMS integration: Phrase, Lokalise, Crowdin for workflow-based translation.
- Machine translation (Google Translate, DeepL) as bridge until human translation is ready.

## Catalog Search Indexing
- Index products into Elasticsearch, OpenSearch, Algolia, Typesense, or Meilisearch on create/update.
- Searchable fields: title, description, brand, category names, attribute values, tags, SKU, GTIN.
- CDC pipeline (Debezium) or application-level events for index sync.
- Batch reindex: full nightly reindex with zero-downtime alias swapping.
- Field boosting: title > brand > category > description > attributes.
- Synonyms and stemming rules for recall (sneakers = trainers = running shoes).
- Track zero-result queries to identify catalog gaps or missing synonyms.

## Image and Media Management

### Storage and Processing
- Upload originals to S3/GCS/Azure Blob. Generate responsive variants (thumb, medium, large, zoom) via Cloudinary, imgix, or Fastly Image Optimizer.
- Store metadata: alt text, sort order, variant association, primary flag, focal point for cropping.
- 3D models (GLB/USDZ) for AR visualization (Apple AR Quick Look, Google Scene Viewer).
- Video assets via Cloudinary, Mux, or Vimeo CDN.

### Optimization
- Serve WebP/AVIF with JPEG/PNG fallback via content negotiation.
- Lazy loading + responsive `srcset` with `sizes` attribute.
- Long-lived CDN cache headers with content-hash or versioned URL cache-busting.
- Adaptive image quality based on connection speed (Save-Data header).
- AI background removal for consistent product photos (remove.bg, Cloudinary AI).
- Zoom and 360-degree views: high-res images with client-side zoom libraries and spin sets.
