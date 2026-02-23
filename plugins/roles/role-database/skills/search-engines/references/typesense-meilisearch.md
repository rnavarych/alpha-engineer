# Typesense and Meilisearch

## When to load
Load when implementing typo-tolerant instant search with Typesense (collection schema, geo, vector search, curation, InstantSearch.js) or AI-powered search with Meilisearch (ranking rules, hybrid search, multi-tenancy, multi-search).

## Typesense: Collection Setup

```bash
typesense-server --data-dir=/data --api-key=xyz --enable-cors

curl -X POST "http://localhost:8108/collections" \
  -H "X-TYPESENSE-API-KEY: xyz" \
  -d '{
    "name": "products",
    "fields": [
        {"name": "name", "type": "string"},
        {"name": "description", "type": "string"},
        {"name": "category", "type": "string", "facet": true},
        {"name": "brand", "type": "string", "facet": true},
        {"name": "price", "type": "float", "facet": true},
        {"name": "rating", "type": "float"},
        {"name": "tags", "type": "string[]", "facet": true},
        {"name": "location", "type": "geopoint"},
        {"name": "embedding", "type": "float[]", "num_dim": 384}
    ],
    "default_sorting_field": "rating",
    "token_separators": ["-", "/"],
    "enable_nested_fields": true
}'
```

## Typesense: Search, Geo, Vector, Curation

```typescript
import Typesense from 'typesense';
const client = new Typesense.Client({
  nodes: [{ host: 'localhost', port: 8108, protocol: 'http' }],
  apiKey: 'xyz', connectionTimeoutSeconds: 2,
});

await client.collections('products').documents().import(products, { action: 'upsert' });

// Search with typo tolerance, faceting, field weights
const results = await client.collections('products').documents().search({
  q: 'wireles headphnes',           // typos automatically corrected
  query_by: 'name,description,tags',
  query_by_weights: '3,1,2',
  filter_by: 'price:<300 && category:=Electronics && rating:>3.5',
  sort_by: '_text_match:desc,rating:desc',
  facet_by: 'category,brand,price',
  max_facet_values: 20,
  num_typos: 2,
});

// Geo search
const nearby = await client.collections('products').documents().search({
  q: '*',
  filter_by: 'location:(48.8566, 2.3522, 10 km)',
  sort_by: 'location(48.8566, 2.3522):asc',
});

// Vector/semantic search
const semantic = await client.collections('products').documents().search({
  q: 'comfortable noise canceling',
  query_by: 'name,description',
  vector_query: 'embedding:([], k:10)',  // auto-embed query text
});

// Synonyms
await client.collections('products').synonyms().upsert('headphone-synonyms', {
  synonyms: ['headphones', 'headsets', 'earphones', 'earbuds'],
});

// Curation (pin/hide results)
await client.collections('products').overrides().upsert('featured-headphones', {
  rule: { query: 'headphones', match: 'exact' },
  includes: [{ id: 'product-1', position: 1 }],
  excludes: [{ id: 'product-99' }],
});
```

## Typesense: InstantSearch.js Integration

```html
<script src="https://cdn.jsdelivr.net/npm/typesense-instantsearch-adapter@2/dist/typesense-instantsearch-adapter.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/instantsearch.js@4"></script>
<script>
const typesenseAdapter = new TypesenseInstantsearchAdapter({
  server: { apiKey: 'search-only-key', nodes: [{ host: 'search.example.com', port: 443, protocol: 'https' }] },
  additionalSearchParameters: { query_by: 'name,description,tags', query_by_weights: '3,1,2' },
});
const search = instantsearch({ indexName: 'products', searchClient: typesenseAdapter.searchClient });
search.addWidgets([
  instantsearch.widgets.searchBox({ container: '#search-box' }),
  instantsearch.widgets.hits({ container: '#hits', templates: { item: hitTemplate } }),
  instantsearch.widgets.refinementList({ container: '#category-filter', attribute: 'category' }),
  instantsearch.widgets.rangeSlider({ container: '#price-filter', attribute: 'price' }),
  instantsearch.widgets.pagination({ container: '#pagination' }),
]);
search.start();
</script>
```

## Meilisearch: Index Settings and Search

```bash
meilisearch --master-key=MASTER_KEY --env=production

curl -X POST 'http://localhost:7700/indexes/products/documents' \
  -H 'Authorization: Bearer MASTER_KEY' \
  -H 'Content-Type: application/json' --data-binary @products.json
```

```typescript
import { MeiliSearch } from 'meilisearch';
const client = new MeiliSearch({ host: 'http://localhost:7700', apiKey: 'MASTER_KEY' });

await client.index('products').updateSettings({
  searchableAttributes: ['name', 'description', 'tags'],
  filterableAttributes: ['category', 'brand', 'price', 'rating', 'location'],
  sortableAttributes: ['price', 'rating', 'created_at'],
  rankingRules: ['words', 'typo', 'proximity', 'attribute', 'sort', 'exactness'],
  typoTolerance: { enabled: true, minWordSizeForTypos: { oneTypo: 4, twoTypos: 8 }, disableOnAttributes: ['sku'] },
  synonyms: { 'headphones': ['headsets', 'earphones'], 'laptop': ['notebook', 'computer'] },
  pagination: { maxTotalHits: 10000 },
});

const results = await client.index('products').search('wireless headphones', {
  filter: ['price < 300', 'category = Electronics'],
  sort: ['price:asc'],
  facets: ['category', 'brand', 'price'],
  attributesToHighlight: ['name', 'description'],
  page: 1, hitsPerPage: 20,
});

// Multi-search across indexes
const multi = await client.multiSearch({ queries: [
  { indexUid: 'products', q: 'headphones', limit: 5 },
  { indexUid: 'articles', q: 'headphones review', limit: 3 },
]});

// Hybrid search (keyword + vector)
const hybrid = await client.index('products').search('comfortable earbuds', {
  hybrid: { semanticRatio: 0.5, embedder: 'default' },
});

// Multi-tenancy via tenant tokens
const tenantToken = client.generateTenantToken(
  'search-api-key-uid',
  { 'products': { filter: 'tenant_id = tenant-abc' } },
  { expiresAt: new Date('2025-01-01') }
);
```
