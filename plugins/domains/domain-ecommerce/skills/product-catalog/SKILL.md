---
name: domain-ecommerce:product-catalog
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

## When to use
- Designing product and variant data models (EAV, JSON attributes, option combinations)
- Integrating or evaluating headless commerce catalog APIs (Shopify, Saleor, commercetools, Vendure, Medusa)
- Connecting a PIM system (Akeneo, Pimcore, Salsify) as master product data source
- Building a pricing engine with dynamic rules, customer groups, or B2B contract pricing
- Implementing or replacing product reviews and ratings (Bazaarvoice, Yotpo, or custom)
- Generating and maintaining product feeds for Google Shopping, Meta Catalog, or Amazon
- Adding schema.org markup, localizing catalog content, or optimizing product image delivery

## Core principles
1. **Product and variant are separate entities** — shared data on product, purchasable specifics (SKU, price, stock) on variant
2. **PIM is master, commerce platform is transactional** — sync PIM → platform; never let the platform own the canonical product record
3. **Dynamic pricing needs floors and ceilings** — algorithmic rules without bounds will eventually misprice at 3 AM on a holiday
4. **Feed freshness directly impacts ad spend ROI** — stale price or stock in Google Shopping burns budget on unavailable products
5. **Schema.org data must match visible page content** — mismatches trigger manual Google reviews and rich result loss

## Reference Files
- `references/data-modeling-platforms.md` — product/variant/attribute/category modeling, GS1/GTIN standards, Shopify/Medusa/Saleor/commercetools/Vendure catalog capabilities
- `references/pim-pricing-reviews.md` — Akeneo, Pimcore, Salsify integration patterns; pricing engine types and dynamic pricing rules; Bazaarvoice, Yotpo, and custom reviews implementation
- `references/feeds-seo-localization-media.md` — Google Shopping, Meta Catalog, Amazon feed specs and architecture; schema.org Product markup; multi-language localization; search indexing; image/media management
