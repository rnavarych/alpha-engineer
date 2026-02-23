# Product Data Modeling and Headless Commerce Platforms

## When to load
Load when designing product/variant data models, working with headless commerce catalog APIs (Shopify, Medusa, Saleor, commercetools, Vendure), or structuring categories, attributes, and collections.

## Core Data Modeling

### Products and Variants
- Separate the product (abstract item) from variants (purchasable SKUs with specific size, color, etc.).
- EAV or JSON column for flexible custom attributes.
- Variant-specific fields: SKU, price override, weight, dimensions, barcode (UPC/EAN/GTIN).
- `products` table for shared data (title, description, brand); `variants` table keyed by product ID.
- Product types/templates: define available attributes per product type (Apparel: Size/Color, Electronics: Storage/Color).
- Digital products: license keys, downloadable files, streaming access, expiration dates.

### Product Types
- **Simple**: single SKU, no options.
- **Configurable**: parent + child variants from option combinations (T-shirt Size × Color = 12 variants).
- **Bundle**: group of products at bundle price (fixed or dynamic).
- **Grouped**: related products displayed together, purchased individually.
- **Virtual/digital**: no shipping; deliver via download link or license key.
- **Subscription**: recurring delivery linked to billing engine.
- **Made-to-order**: customer customization inputs at order time (engraving, monogramming).

### Attributes and Options
- Option types (Size, Color) at product level; each variant is a combination of option values.
- Attribute-based filtering: index attributes used in faceted search.
- Distinguish customer-facing (filterable, displayed) vs. internal (weight, cost, supplier ID).
- Swatch attributes: hex colors or thumbnail images for visual selectors.
- Attribute groups: General, Dimensions, SEO, Custom — for admin UX organization.

### Categories and Collections
- Hierarchical category tree: adjacency list or nested set with `materialized_path` for efficient queries.
- Multiple category assignments per product.
- Collections: curated groups for merchandising ("Summer Sale", "Best Sellers").
- Rule-based (automated) vs. manual collections.
- Rule examples: all products tagged "new-arrival" in last 30 days; all Shoes under $100.
- Seasonal categories with publish/unpublish scheduling.

### GS1 / GTIN Standards
- **GTIN-12 (UPC-A)**: 12-digit, North American retail.
- **GTIN-13 (EAN)**: 13-digit, international retail.
- **GTIN-14**: traded goods at case/pallet level.
- Store GTIN at variant level (each SKU has unique GTIN). Validate check digits on input.
- Required for Google Shopping feed compliance on branded products.
- GS1 Digital Link: URL-based identification linking physical barcode to digital content.

## Headless Commerce Platforms

### Shopify
- Products with up to 100 variants; 3 option types per product.
- Metafields and metaobjects for extending product schema.
- Manual and automated (rule-based) Collections.
- Storefront API (GraphQL) for headless queries with cursor-based pagination.
- Bulk Operations API for large-scale catalog imports/updates (async GraphQL mutations).

### Medusa
- Unlimited variants and custom options. Product Types for shared attributes.
- Sales Channels for product visibility per storefront.
- Price Lists for customer-group and time-limited pricing.
- Product Categories with nested hierarchy. Bulk import/export via CSV or API.

### Saleor
- Product Types define attribute schema. Attribute types: dropdown, multiselect, numeric, date, boolean, file, reference, rich text, swatch.
- Multi-channel: availability, pricing, visibility per channel.
- Warehouses with per-warehouse stock at variant level.
- Metadata system for arbitrary key-value data on any entity.

### commercetools
- Product Types define attribute schema; Products are instances.
- Product Variants with prices, images, attributes per channel/customer group.
- Staged changes: work with "staged" projection, publish to "current."
- Product Selections for controlling what appears per Store.

### Vendure
- Products + Variants; each Variant has its own price, SKU, stock, and assets.
- Facets + Facet Values for filtering and categorization.
- Automatic (filtered by Facet Values) or manual hierarchical Collections.
- Channels for multi-store with separate catalog, pricing, and inventory.
- Custom Fields on Products and Variants via plugin configuration.
