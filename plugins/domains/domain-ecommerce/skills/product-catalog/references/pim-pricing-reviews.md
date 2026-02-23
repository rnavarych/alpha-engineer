# PIM Integration, Pricing Engine, and Reviews

## When to load
Load when integrating PIM systems (Akeneo, Pimcore, Salsify), building a pricing engine with dynamic pricing rules, or implementing product reviews and ratings.

## PIM Integration

### Akeneo
- Open-source and enterprise PIM (PHP/Symfony, MySQL/Elasticsearch).
- Product families: attribute sets per product type. Attribute types: text, number, price, image, date, boolean, metric, reference entity, table.
- Channel and locale model: per-channel, per-locale attribute requirements and enrichment.
- Completeness score: track data enrichment % per channel/locale.
- REST API for product CRUD, media upload, categories, export.
- Connectors: Shopify, Magento, Salesforce CC, and custom via API.
- Rules engine: automate attribute population. Tailored Exports per channel.
- Data quality insights: missing, inconsistent, or duplicate product data.

### Pimcore
- Open-source data management platform: PIM + DAM + MDM + CMS (PHP/Symfony).
- Data objects with custom models, attributes, relations, inheritance.
- Classification store for products with many optional attributes.
- Inheritance-based variants: child objects inherit parent attributes, override as needed.
- Built-in DAM for images, videos, documents with thumbnails and metadata.
- Data Hub: GraphQL API auto-generated from model definitions.
- Workflow management: draft → review → approved → published.

### Salsify
- Cloud-based PIM + commerce experience management.
- Product content syndication to 500+ retailer and marketplace channels.
- Digital shelf analytics: monitor product presentation on retailer websites.
- Enhanced content: A+ content creation. Workflow + collaboration tooling.

### PIM Integration Patterns
- PIM = master source of truth for product data; commerce platform = transactional system.
- Sync: PIM → commerce (product data, assets, categories); commerce → PIM (inventory, pricing if needed).
- Event-driven sync (webhook or message queue) for near-real-time updates.
- Batch sync (scheduled jobs) for initial load and periodic reconciliation.
- Media pipeline: PIM exports high-res images; CDN/DAM generates responsive variants.

## Pricing Engine

### Price Types
- Base price (MSRP/list), sale price (with start/end dates), volume/tiered discounts.
- Customer-group pricing (wholesale, VIP, employee).
- Channel-specific pricing (web vs. marketplace vs. in-store).
- Contract pricing for B2B (negotiated per-SKU with effective dates).
- Subscription pricing (subscribe-and-save discount).
- Bundle pricing: fixed or dynamic (sum of components minus bundle discount).

### Dynamic Pricing
- Competitor-based: monitor via Prisync, Competera, Intelligence Node; auto-adjust.
- Demand-based: increase when demand high, decrease when low (travel/events model).
- Time-based: happy hour, flash sale, early bird with automatic schedule.
- Inventory-based: reduce price as stock ages or when overstocked; increase when scarce.
- Algorithmic rules: if stock < 10 and demand > threshold → increase by X%.
- Price floors and ceilings: bound algorithmic pricing to prevent errors.
- A/B test pricing: test price points for conversion vs. margin optimization.

### Price Resolution
- Evaluate rules in priority order: contract-specific > customer-group > sale > volume > channel > base.
- Store price history for analytics, audit, and change tracking.
- Multi-currency: per-currency price overrides preferred over auto-convert.
- Price rounding rules: nearest 0.99, 0.95, or whole number per currency.
- Display original + sale price (strikethrough) with savings amount or percentage.

## Reviews and Ratings

### Bazaarvoice
- Hosted UGC: reviews, Q&A, photos, videos. Syndication network across retailer partners.
- Conversations API for programmatic submission/retrieval. Display API for embedding.
- Automated + manual moderation with profanity filtering and fraud detection.
- Sampling programs for authentic review generation. Review schema markup for rich snippets.

### Yotpo
- Reviews + photo/video UGC. Smart review request emails with A/B testing.
- On-site widgets: carousel, ratings, Q&A, visual UGC gallery.
- Loyalty and referral programs integrated with review collection.
- AI-powered insights: topic clustering, sentiment analysis, product feedback.
- Syndication to Google Shopping, Facebook, and retail partners.

### Custom Reviews Implementation
- Schema: `reviews(product_id, customer_id, rating 1-5, title, body, status, verified_purchase, created_at)`.
- Moderation queue: auto-approve verified purchases with no profanity; manual for flagged.
- Maintain materialized `average_rating` and `review_count` on product (denormalized for performance).
- Helpful votes (upvote/downvote) for review sorting by helpfulness.
- Merchant reply field shown publicly alongside review.
- Incentivized reviews must be disclosed per FTC guidelines.
