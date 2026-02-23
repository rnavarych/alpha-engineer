# Algolia

## When to load
Load when working with Algolia hosted search: index configuration, custom ranking, A/B testing, AI Recommend, React InstantSearch, or replica indexes for sorting.

## Index Configuration and Search

```typescript
import algoliasearch from 'algoliasearch';

const client = algoliasearch('APP_ID', 'ADMIN_API_KEY');
const index = client.initIndex('products');

await index.setSettings({
  searchableAttributes: [
    'name',                      // highest priority
    'unordered(description)',
    'tags',
  ],
  attributesForFaceting: [
    'searchable(category)',      // searchable facet
    'brand',
    'filterOnly(tenant_id)',     // filtering only, not displayed
    'price',
  ],
  customRanking: ['desc(popularity)', 'desc(rating)'],
  hitsPerPage: 20,
  typoTolerance: true,
  minWordSizefor1Typo: 4,
  minWordSizefor2Typos: 8,
  distinct: 1,                   // de-duplication
  attributeForDistinct: 'product_group',
  replicas: [
    'products_price_asc',        // replica index for price-asc sorting
    'products_price_desc',
  ],
});

// Index documents
await index.saveObjects(products, { autoGenerateObjectIDIfNotExist: true });

// Partial update (only specified attributes)
await index.partialUpdateObject({ objectID: 'product-123', price: 89.99, inventory: 42 });

// Search
const { hits, facets, nbHits } = await index.search('headphones', {
  filters: 'price < 300 AND category:Electronics',
  facets: ['category', 'brand'],
  hitsPerPage: 20,
  page: 0,
  attributesToHighlight: ['name', 'description'],
  attributesToSnippet: ['description:20'],
  analytics: true,
  clickAnalytics: true,
});
```

## A/B Testing

```typescript
const abTest = await client.initAnalytics().addABTest({
  name: 'relevance-test',
  variants: [
    { index: 'products', trafficPercentage: 50, description: 'Current ranking' },
    { index: 'products_v2', trafficPercentage: 50, description: 'New ranking' },
  ],
  endAt: '2024-12-31T00:00:00Z',
});
```

## AI Recommend

```typescript
const { results: recommendations } = await client.getRecommendations({
  requests: [{
    indexName: 'products',
    model: 'related-products',
    objectID: 'product-123',
    maxRecommendations: 5,
  }],
});
```

## React InstantSearch

```tsx
import {
  InstantSearch, SearchBox, Hits, RefinementList,
  RangeInput, Pagination, Stats, Configure
} from 'react-instantsearch';
import algoliasearch from 'algoliasearch/lite';

const searchClient = algoliasearch('APP_ID', 'SEARCH_ONLY_KEY');

function SearchPage() {
  return (
    <InstantSearch searchClient={searchClient} indexName="products">
      <Configure hitsPerPage={20} analytics={true} />
      <SearchBox placeholder="Search products..." />
      <Stats />
      <div className="search-layout">
        <aside>
          <RefinementList attribute="category" showMore={true} />
          <RefinementList attribute="brand" />
          <RangeInput attribute="price" />
        </aside>
        <main>
          <Hits hitComponent={ProductHit} />
          <Pagination />
        </main>
      </div>
    </InstantSearch>
  );
}
```
