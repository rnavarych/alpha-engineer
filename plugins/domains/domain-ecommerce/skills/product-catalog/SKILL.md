---
name: product-catalog
description: |
  Product catalog design for e-commerce: headless platforms (Shopify, Medusa, Saleor, commercetools,
  Vendure), PIM integration (Akeneo, Pimcore, Salsify), data modeling (products, variants, attributes,
  categories, collections), GS1/GTIN barcodes, configurable/bundled products, dynamic pricing,
  reviews and ratings (Bazaarvoice, Yotpo), feed syndication (Google Shopping, Facebook Catalog),
  schema.org Product markup, tax calculation (Avalara, TaxJar), multi-language/localization,
  catalog search indexing, and image/media management.
allowed-tools: Read, Grep, Glob, Bash
---

# Product Catalog

## Data Modeling

### Products and Variants
- Separate the product (abstract item) from variants (purchasable SKUs with specific size, color, etc.).
- Use an EAV (entity-attribute-value) or JSON column for flexible custom attributes.
- Store variant-specific fields: SKU, price override, weight, dimensions, barcode (UPC/EAN/GTIN).
- Maintain a `products` table with shared data (title, description, brand) and a `variants` table keyed by product ID.
- Support product types/templates: define which attributes and options are available per product type (e.g., "Apparel" has Size/Color, "Electronics" has Storage/Color).
- Handle digital products alongside physical: license keys, downloadable files, streaming access, expiration dates.

### Configurable and Complex Products
- **Simple products**: single SKU, no options.
- **Configurable products**: parent product with child variants generated from option combinations (e.g., T-shirt with Size x Color = 12 variants).
- **Bundle products**: group of products sold together at a bundle price (fixed or dynamic pricing).
- **Grouped products**: related products displayed together but purchased individually.
- **Virtual/digital products**: no physical shipping, deliver via download link or license key.
- **Subscription products**: recurring delivery, linked to subscription engine for billing and fulfillment.
- **Made-to-order/custom products**: customer provides customization inputs (engraving, monogramming) at order time.

### Attributes and Options
- Define option types (e.g., "Size", "Color") at the product level.
- Each variant is a combination of option values (e.g., Size=M, Color=Red).
- Support attribute-based filtering: index attributes used in faceted search.
- Distinguish between customer-facing attributes (filterable, displayed) and internal attributes (weight, cost price, supplier ID).
- Swatch attributes: store hex colors or thumbnail images for visual option selectors.
- Attribute groups: organize attributes into sections for admin UX (General, Dimensions, SEO, Custom).

### Categories and Collections
- Use a hierarchical category tree (adjacency list or nested set model with `materialized_path` for efficient queries).
- Support multiple category assignments per product.
- Implement collections (curated groups) for merchandising (e.g., "Summer Sale", "Best Sellers").
- Differentiate between rule-based (automated) collections and manual collections.
- Rule-based collection examples: all products with tag "new-arrival" added in last 30 days, all products in category "Shoes" with price < $100.
- Category-specific attributes: define attribute sets per category (e.g., "Shoes" category requires "Sole Material", "Closure Type").
- Seasonal and rotating categories with publish/unpublish scheduling.

### GS1 / GTIN Standards
- **GTIN-12 (UPC-A)**: 12-digit barcode standard for North American retail.
- **GTIN-13 (EAN)**: 13-digit barcode standard for international retail.
- **GTIN-14**: 14-digit identifier for traded goods at various packaging levels (case, pallet).
- **GS1 Company Prefix**: unique identifier assigned to a company, prefix for all its GTINs.
- Store GTIN at the variant level (each SKU has a unique GTIN).
- Validate GTIN check digits on input to prevent data quality issues.
- Use GTINs for Google Shopping feed compliance (required for branded products).
- ISBN for books, ISSN for periodicals -- map to appropriate identifier fields.
- GS1 Digital Link: URL-based product identification linking physical barcode to digital content.

## Headless Commerce Platform Catalog Capabilities

### Shopify Catalog
- Products with up to 100 variants; 3 option types per product (e.g., Size, Color, Material).
- Metafields and metaobjects for extending product data schema (custom attributes, specifications, related content).
- Collections: manual and automated (rule-based on product tags, price, vendor, type).
- Storefront API (GraphQL) for headless catalog queries with cursor-based pagination.
- Bulk Operations API for large-scale catalog imports/updates (async GraphQL mutations).
- Product media: images, 3D models (GLB/USDZ), and videos.

### Medusa Catalog
- Products with unlimited variants and custom options.
- Product Types for grouping products with shared attributes.
- Sales Channels for controlling product visibility across storefronts.
- Price Lists for customer-group-specific and time-limited pricing.
- Product Categories with nested hierarchy.
- Tags and Collections for merchandising and filtering.
- Bulk import/export via CSV or API.

### Saleor Catalog
- Products with Product Types defining attribute schema.
- Attributes: dropdown, multiselect, numeric, date, boolean, file, reference, rich text, swatch.
- Multi-channel: product availability, pricing, and visibility per channel.
- Warehouses with per-warehouse stock tracking at the variant level.
- Collection and category management via GraphQL Admin API.
- Metadata system for arbitrary key-value data on any entity.

### commercetools Catalog
- Product Types define the attribute schema; Products are instances of a Product Type.
- Product Variants with prices, images, attributes, and availability per channel/customer group.
- Categories with localized names, descriptions, and external IDs for ERP mapping.
- Product Selections for controlling which products appear in which Store.
- Staged changes: work with a "staged" projection, then publish to the "current" projection.
- Custom Objects for schema-less supplementary data (FAQs, specifications, rich content).

### Vendure Catalog
- Products with Variants; each Variant has its own price, SKU, stock, and asset associations.
- Facets and Facet Values for filtering and categorization (Facet = "Color", FacetValue = "Red").
- Collections: automatic (filtered by Facet Values) or manual; hierarchical with parent/child.
- Custom Fields on Products, Variants, and other entities via plugin configuration.
- Channels for multi-store with separate catalog, pricing, and inventory per Channel.
- ProductVariantPrice supports multiple currencies and customer groups.

## PIM (Product Information Management) Integration

### Akeneo
- Open-source and enterprise PIM platform (PHP/Symfony, MySQL/Elasticsearch).
- Product families: define attribute sets per product type (e.g., "T-Shirt" family has Size, Color, Material).
- Attribute types: text, number, price, image, date, boolean, metric, reference entity, table.
- Channel and locale model: define which attributes are required/enriched per channel (web, print, marketplace) and locale (en_US, fr_FR).
- Completeness score: track product data enrichment percentage per channel/locale.
- REST API for product CRUD, media upload, category management, and export.
- Connectors: Shopify, Magento, Salesforce Commerce Cloud, and custom via API.
- Asset Manager: DAM-like asset management within Akeneo (images, videos, documents).
- Rules engine: automate attribute population (e.g., auto-set product title from brand + name + color).
- Tailored Exports: configure per-channel export profiles with attribute mapping and transformations.
- Data quality insights: identify missing, inconsistent, or duplicate product data.

### Pimcore
- Open-source data management platform combining PIM, DAM, MDM, and CMS (PHP/Symfony).
- Data objects: define custom data models with attributes, relations, and inheritance.
- Classification store: flexible attribute management for products with many optional attributes.
- Variants: inheritance-based variant management (child objects inherit parent attributes, override as needed).
- Asset management: built-in DAM for images, videos, documents with thumbnails and metadata.
- Data Hub: GraphQL API auto-generated from data model definitions.
- Import/export framework: CSV, XML, JSON, API-based import with mapping and transformation.
- Workflow management: approval workflows for product data (draft -> review -> approved -> published).
- Multi-site and multi-language with localized fields and fallback chains.
- eCommerce framework: built-in commerce capabilities or integration with external commerce engines.

### Salsify
- Cloud-based PIM and commerce experience management platform.
- Product content syndication to 500+ retailer and marketplace channels.
- Digital shelf analytics: monitor how products appear on retailer websites.
- Enhanced content: create rich product detail page content (A+ content, below-the-fold content).
- Workflow and collaboration: assign tasks, set due dates, track data enrichment progress.
- Schema management: define attribute schemas with validation rules and transformation formulas.
- API and bulk operations for programmatic product management.

### PIM Integration Patterns
- PIM as the master source of truth for product data; commerce platform as the transactional system.
- Sync flow: PIM -> commerce platform (product data, assets, categories); commerce platform -> PIM (inventory, pricing, if needed).
- Use event-driven sync (webhook or message queue) for near-real-time updates.
- Batch sync (scheduled jobs) for initial load and periodic reconciliation.
- Map PIM attributes to commerce platform fields; handle schema differences with transformation layers.
- Media pipeline: PIM exports high-res images; CDN/DAM generates responsive variants.

## Pricing Engine

### Price Types
- Base price (MSRP or list price).
- Sale price with start/end dates for time-limited promotions.
- Volume/tiered discounts (buy 10+ for 15% off).
- Customer-group pricing (wholesale, VIP, employee).
- Channel-specific pricing (web vs. marketplace vs. in-store).
- Contract pricing for B2B customers (negotiated per-SKU prices with effective dates).
- Subscription pricing (discounted price for subscribers, e.g., subscribe-and-save 15% off).
- Bundle pricing: fixed price for a set of products, or dynamic (sum of components minus bundle discount).

### Dynamic Pricing
- Competitor-based pricing: monitor competitor prices (Prisync, Competera, Intelligence Node) and adjust automatically.
- Demand-based pricing: increase price when demand is high, decrease when low (common in travel/events).
- Time-based pricing: happy hour, flash sale, early bird pricing with automatic schedule.
- Inventory-based pricing: reduce price as stock ages or when overstocked; increase when scarce.
- Algorithmic pricing rules: define pricing rules with conditions and actions (if stock < 10 and demand > threshold, increase by X%).
- Price floors and ceilings: set minimum and maximum price bounds to prevent algorithmic errors.
- A/B test pricing: test different price points to optimize for conversion or margin (ethical and legal considerations).

### Price Resolution
- Resolve the final price by evaluating rules in priority order: contract-specific > customer-group > sale > volume > channel > base.
- Store price history for analytics, audit, and price-change tracking.
- Support multi-currency pricing: per-currency price overrides or automatic conversion from a base currency.
- Price rounding rules: round to nearest 0.99, 0.95, or whole number per currency/market.
- Display original and sale price (strikethrough) with savings amount or percentage.

## Reviews and Ratings

### Bazaarvoice
- Hosted ratings and reviews platform with UGC collection (reviews, Q&A, photos, videos).
- Syndication network: share reviews across retailer partners and receive syndicated reviews.
- Conversations API for programmatic review submission and retrieval.
- Display API for embedding reviews, ratings, and Q&A on product pages.
- Moderation: automated and manual review moderation with profanity filtering and fraud detection.
- Sampling programs: send products to selected consumers for authentic review generation.
- Analytics: review volume, average rating, sentiment analysis, review influence on conversion.
- SEO impact: review schema markup (JSON-LD AggregateRating) for rich snippet stars in search results.

### Yotpo
- Reviews and ratings with photo/video UGC collection.
- Smart review request emails: timing, segmentation, and A/B testing for optimal review collection.
- On-site widgets: reviews carousel, product ratings, Q&A, visual UGC gallery.
- Loyalty and referral programs integrated with review collection.
- SMS marketing integration for review requests.
- API and webhooks for custom review display and workflow integration.
- Syndication to Google Shopping, Facebook, and retail partners.
- AI-powered review insights: topic clustering, sentiment analysis, product feedback.

### Custom Reviews Implementation
- Data model: `reviews` table with `product_id`, `customer_id`, `rating` (1-5), `title`, `body`, `status` (pending/approved/rejected), `verified_purchase` (boolean), `created_at`.
- Review media: associate images/videos with reviews; store in CDN with moderation workflow.
- Moderation queue: auto-approve based on rules (verified purchase, no profanity), manual review for flagged content.
- Aggregate ratings: maintain a materialized view or denormalized fields (`average_rating`, `review_count`) on the product.
- Helpful votes: "Was this review helpful?" with upvote/downvote counts for sorting.
- Review sorting: most recent, highest rated, lowest rated, most helpful.
- Incentivized reviews: offer discount codes or loyalty points for leaving a review (must disclose per FTC guidelines).
- Review reply: allow merchant to respond to reviews (shown publicly alongside the review).

## Feed Syndication

### Google Shopping (Merchant Center)
- Product feed specification: required fields (id, title, description, link, image_link, price, availability, brand, gtin, condition).
- Optional fields: sale_price, sale_price_effective_date, product_type, google_product_category, color, size, gender, age_group, item_group_id (for variants), shipping, tax.
- Feed formats: XML (RSS 2.0 / Atom), TSV/CSV, Content API for Shopping (REST API for real-time updates).
- Supplemental feeds for overriding or enriching primary feed data.
- Feed rules in Merchant Center for transforming data without changing source feed.
- Performance Max and Shopping campaigns consume Merchant Center product data.
- Free product listings: organic visibility in Google Shopping tab (no ad spend required).
- Feed diagnostics: monitor for disapproved products, warnings, and data quality issues.

### Facebook/Meta Catalog
- Catalog Manager for managing product feeds for Facebook/Instagram Shopping, Dynamic Ads.
- Feed format: CSV, TSV, or XML with fields: id, title, description, availability, condition, price, link, image_link, brand.
- Commerce Manager for checkout-enabled shops (Instagram Checkout, Facebook Shops).
- Catalog Batch API and individual item API for programmatic updates.
- Product sets: subsets of catalog for targeting in Dynamic Ads campaigns.
- Catalog diagnostics and feed health dashboard.

### Amazon Marketplace
- Amazon Seller Central flat file (CSV) feeds or Selling Partner API (SP-API).
- Product listing: match to existing Amazon ASINs or create new listings.
- Product data: item_name, brand, manufacturer, product_type, bullet_points, description, images, price, quantity.
- A+ Content (Enhanced Brand Content): rich product descriptions with images and comparison charts.
- Inventory feed: sync stock levels from your system to Amazon.
- Pricing feed: update prices dynamically (automate with repricing tools).
- Order feed: pull Amazon orders into your OMS for fulfillment.

### Feed Syndication Architecture
- Central product data source (PIM or commerce platform) feeds into a feed management system.
- Feed management tools: Feedonomics, DataFeedWatch, GoDataFeed, ChannelAdvisor, Channable.
- Transform and map product data to each channel's specification (field mapping, value transformation).
- Schedule feed generation: full feed daily, incremental updates every 1-4 hours for price/stock changes.
- Monitor feed health: track approval rates, error counts, and suppression reasons per channel.
- Multi-language and multi-currency feeds for international channels.

## Schema.org Product Markup

### Required Structured Data
- JSON-LD `Product` schema on product detail pages with: `name`, `description`, `image`, `sku`, `gtin`, `brand`, `offers`.
- `Offer` within Product: `price`, `priceCurrency`, `availability` (InStock, OutOfStock, PreOrder), `url`, `seller`.
- `AggregateRating`: `ratingValue`, `reviewCount`, `bestRating` for star ratings in search results.
- `Review`: individual review entries with `author`, `datePublished`, `reviewBody`, `reviewRating`.
- `BreadcrumbList`: category navigation path for breadcrumb rich results.

### Advanced Markup
- `AggregateOffer` for products with price ranges across variants (e.g., "From $29.99 to $49.99").
- `ItemList` for product listing pages (category pages, search results) with item position.
- `FAQPage` for product FAQ sections (rich result with expandable questions in search).
- `HowTo` for product usage guides or assembly instructions.
- `Organization` or `LocalBusiness` schema on the site for seller identity.
- `SaleEvent` or `SpecialAnnouncement` for sale periods.
- `shippingDetails`: `OfferShippingDetails` for shipping cost and delivery time in search results.
- `hasMerchantReturnPolicy`: `MerchantReturnPolicy` for return policy display in search results.

### Implementation Best Practices
- Use JSON-LD (not microdata or RDFa) as the recommended format by Google.
- Validate with Google's Rich Results Test and Schema Markup Validator.
- Ensure structured data matches visible page content (price, availability, ratings must match).
- Update structured data dynamically when product data changes (price, stock, reviews).
- Test with Google Search Console: monitor rich result performance, impressions, and click-through rates.
- Avoid markup spam: do not add structured data for products not visible on the page.

## Tax Calculation

### Tax Providers
- **Avalara (AvaTax)**: real-time tax calculation for US sales tax, VAT, GST across 190+ countries. REST API with product tax codes, exemption certificate management, and tax return filing.
- **TaxJar**: automated sales tax calculation, reporting, and filing for US and international. SmartCalcs API with nexus analysis and product categorization.
- **Vertex**: enterprise tax technology for complex multi-jurisdictional tax scenarios.
- **Stripe Tax**: automated tax calculation integrated with Stripe Payments (simple setup, limited customization).
- Fall back to static tax tables for simple scenarios (single jurisdiction, few product types).

### Tax Configuration
- Assign product tax codes (e.g., clothing, food, digital goods, SaaS) for correct categorization.
- Define nexus (tax obligation) per jurisdiction based on physical presence, economic nexus thresholds, or marketplace facilitator laws.
- Handle tax-exempt customers: store exemption certificates, validate expiration, apply exemptions at checkout.
- Marketplace tax collection: marketplace facilitator laws require the platform (not the seller) to collect and remit tax in many US states.

### Tax Display
- Display tax-inclusive or tax-exclusive prices based on locale (EU: inclusive; US: exclusive).
- Calculate tax at the line-item level and round per-line to avoid penny discrepancies.
- Store tax amounts separately on order line items for reporting and refund calculation.
- VAT invoicing: include VAT registration number, breakdown by VAT rate, net and gross amounts.
- Cross-border digital goods: EU MOSS/OSS for VAT on digital services sold to EU consumers.

## Multi-Language and Localization

- Store translatable fields (title, description, SEO metadata) in a separate translations table keyed by locale.
- Use a fallback chain: requested locale > default locale > original content.
- Localize units (weight, dimensions), date formats, and currency symbols.
- Generate locale-specific URL slugs for SEO (`/en/blue-sneakers`, `/de/blaue-turnschuhe`).
- Right-to-left (RTL) support for Arabic, Hebrew, and other RTL locales.
- Translation management: integrate with TMS platforms (Phrase, Lokalise, Crowdin) for workflow-based translation.
- Automatic translation fallback: machine translation (Google Translate, DeepL) as a bridge until human translation is ready.
- Locale-specific content: different product descriptions, images, or compliance text per market.

## Catalog Search Indexing

### Indexing Strategy
- Index products into a search engine (Elasticsearch, OpenSearch, Algolia, Typesense, Meilisearch) on create/update.
- Include searchable fields: title, description, brand, category names, attribute values, tags, SKU, GTIN.
- Use a change-data-capture (CDC) pipeline (Debezium) or application-level events to keep the index in sync.
- Batch reindex: full reindex on a schedule (nightly) with zero-downtime alias swapping.
- Incremental updates: process product change events within seconds for near-real-time search.

### Search Quality
- Configure field boosting (title > brand > category > description > attributes).
- Add synonyms and stemming rules for better recall (e.g., "sneakers" = "trainers" = "running shoes").
- Track search queries with zero results to identify catalog gaps or missing synonyms.
- Search analytics: track queries, clicks, conversions, and position metrics to improve relevance.
- Typo tolerance and fuzzy matching for resilient search against misspellings.
- Searchable custom attributes: allow merchants to configure which attributes are searchable.

## Image and Media Management

### Storage and Processing
- Upload original images to object storage (S3, GCS, Azure Blob).
- Generate responsive variants (thumbnail, medium, large, zoom) on upload or on-the-fly via an image CDN (Cloudinary, imgix, Fastly Image Optimizer).
- Store image metadata: alt text, sort order, variant association, primary flag, focal point for cropping.
- Support 3D models (GLB/USDZ) for AR product visualization (Apple AR Quick Look, Google Scene Viewer).
- Video assets: product videos stored in or linked from video CDN (Cloudinary, Mux, Vimeo).

### Optimization
- Serve images in modern formats (WebP, AVIF) with fallback to JPEG/PNG via content negotiation.
- Use lazy loading and responsive `srcset` with `sizes` attribute for frontend performance.
- Set cache headers for long-lived CDN caching with cache-busting via content hashes or versioned URLs.
- Image quality: adaptive quality based on connection speed (Save-Data header, Network Information API).
- Background removal and image enhancement: AI-powered image processing for consistent product photos (remove.bg, Cloudinary AI).
- Zoom and 360-degree views: high-resolution images with client-side zoom (Drift, Magic Zoom) and 360 spin sets.
