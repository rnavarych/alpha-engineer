---
name: search-engines
description: |
  Deep operational guide for 10 search engines. Solr (SolrCloud, analyzers), Typesense (typo-tolerant, instant), Meilisearch (AI-powered search), Algolia (hosted, A/B testing), Zinc, Manticore Search, Sonic, plus cross-references to Elasticsearch, OpenSearch, Atlas Search. Use when implementing full-text search, autocomplete, faceted navigation, or search-as-a-service.
allowed-tools: Read, Grep, Glob, Bash
---

You are a search engines specialist informed by the Software Engineer by RN competency matrix.

## Search Engine Comparison

| Engine | Hosting | Query Language | Typo Tolerance | Faceting | Vector Search | Pricing |
|--------|---------|---------------|----------------|----------|--------------|---------|
| Elasticsearch | Self-hosted / Elastic Cloud | Query DSL, ES|QL | Fuzzy queries | Yes | kNN, HNSW | Open-source + paid features |
| OpenSearch | Self-hosted / AWS | Query DSL | Fuzzy queries | Yes | kNN, HNSW | Open-source (Apache 2.0) |
| Apache Solr | Self-hosted | Lucene syntax, JSON | Fuzzy queries | Yes (advanced) | Dense vectors | Open-source (Apache 2.0) |
| Typesense | Self-hosted / Typesense Cloud | Simple API | Built-in (excellent) | Yes | Yes (built-in) | Open-source + cloud |
| Meilisearch | Self-hosted / Meilisearch Cloud | Simple API | Built-in (excellent) | Yes | Yes (hybrid) | Open-source + cloud |
| Algolia | Hosted only | Simple API | Built-in | Yes (InstantSearch) | Yes (NeuralSearch) | Per-search pricing |
| Zinc | Self-hosted | ES-compatible API | Fuzzy queries | Yes | No | Open-source (Apache 2.0) |
| Manticore Search | Self-hosted / Manticore Cloud | MySQL protocol + JSON | Fuzzy queries | Yes | No | Open-source (GPLv2) |
| Sonic | Self-hosted | Channel-based protocol | Fuzzy (limited) | No | No | Open-source (Mozilla 2.0) |
| Atlas Search | MongoDB Atlas | Aggregation pipeline | Fuzzy queries | Yes | kNN, HNSW | Atlas billing |

> Cross-references: Elasticsearch and OpenSearch have deep coverage in the document-databases skill. MongoDB Atlas Search is covered in the document-databases skill.

## Search Architecture Patterns

### Pattern 1: Dedicated Search Service

```
Application -> Primary Database (PostgreSQL)
                    |
              CDC/Sync Layer (Debezium, custom sync)
                    |
              Search Engine (Elasticsearch/Typesense)
                    |
              Search API -> Application
```

### Pattern 2: Search-as-a-Service

```
Application -> Algolia/Typesense Cloud
                    |
              Indexing API (push on write)
              Search API (direct from frontend)
```

### Pattern 3: Embedded Search

```
Application -> Database with Built-in Search
               (MongoDB Atlas Search, PostgreSQL FTS,
                Supabase + pg_trgm, SQLite FTS5)
```

### When to Use Which Pattern

```
Small dataset (<100K docs), simple search:
  -> PostgreSQL full-text search (pg_trgm, tsvector)
  -> SQLite FTS5

Medium dataset, instant search needed:
  -> Typesense or Meilisearch (easy setup, great UX)

Large dataset, complex queries, analytics:
  -> Elasticsearch or OpenSearch (mature, flexible)

E-commerce with merchandising:
  -> Algolia (InstantSearch, A/B testing, analytics)

Budget-conscious, ES-compatible:
  -> Zinc (lightweight, Go-based)

Lightweight text search only:
  -> Sonic (minimal resources)

MySQL ecosystem:
  -> Manticore Search (MySQL protocol)
```

## Apache Solr

### SolrCloud Architecture

```bash
# SolrCloud: distributed search with ZooKeeper coordination
# Components:
# - Collections: logical index (like ES index)
# - Shards: horizontal partitions of a collection
# - Replicas: copies of each shard (NRT, TLOG, PULL types)
# - ZooKeeper: coordination, config management

# Start SolrCloud
bin/solr start -c -z zk1:2181,zk2:2181,zk3:2181

# Create collection
bin/solr create_collection -c products \
  -shards 3 \
  -replicationFactor 2 \
  -p 8983

# Upload configset
bin/solr zk upconfig -z localhost:2181 \
  -n products_config \
  -d /path/to/configset

# Collection API
curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=products&numShards=3&replicationFactor=2&collection.configName=products_config"
```

### Schema Design and Analyzers

```xml
<!-- managed-schema (schemaless) or schema.xml (classic) -->
<schema name="products" version="1.6">
    <field name="id" type="string" indexed="true" stored="true" required="true"/>
    <field name="name" type="text_en" indexed="true" stored="true"/>
    <field name="description" type="text_en" indexed="true" stored="true"/>
    <field name="category" type="string" indexed="true" stored="true" docValues="true"/>
    <field name="price" type="pdouble" indexed="true" stored="true" docValues="true"/>
    <field name="tags" type="strings" indexed="true" stored="true" docValues="true"/>
    <field name="location" type="location" indexed="true" stored="true"/>
    <field name="_text_" type="text_general" indexed="true" stored="false" multiValued="true"/>

    <!-- Custom analyzer for product search -->
    <fieldType name="text_product" class="solr.TextField">
        <analyzer type="index">
            <tokenizer class="solr.StandardTokenizerFactory"/>
            <filter class="solr.LowerCaseFilterFactory"/>
            <filter class="solr.StopFilterFactory" words="stopwords.txt"/>
            <filter class="solr.SynonymGraphFilterFactory" synonyms="synonyms.txt" expand="true"/>
            <filter class="solr.FlattenGraphFilterFactory"/>
            <filter class="solr.EdgeNGramFilterFactory" minGramSize="2" maxGramSize="15"/>
        </analyzer>
        <analyzer type="query">
            <tokenizer class="solr.StandardTokenizerFactory"/>
            <filter class="solr.LowerCaseFilterFactory"/>
            <filter class="solr.StopFilterFactory" words="stopwords.txt"/>
            <filter class="solr.SynonymGraphFilterFactory" synonyms="synonyms.txt"/>
        </analyzer>
    </fieldType>

    <!-- Phonetic matching for names -->
    <fieldType name="phonetic" class="solr.TextField">
        <analyzer>
            <tokenizer class="solr.StandardTokenizerFactory"/>
            <filter class="solr.DoubleMetaphoneFilterFactory" inject="false"/>
        </analyzer>
    </fieldType>

    <!-- Copy fields for catch-all search -->
    <copyField source="name" dest="_text_"/>
    <copyField source="description" dest="_text_"/>
</schema>
```

### Faceted Search and Streaming

```bash
# Faceted search query
curl "http://localhost:8983/solr/products/select" -d '
{
    "query": "wireless headphones",
    "filter": ["price:[50 TO 300]", "in_stock:true"],
    "facet": {
        "categories": {
            "type": "terms",
            "field": "category",
            "limit": 10
        },
        "price_ranges": {
            "type": "range",
            "field": "price",
            "start": 0,
            "end": 1000,
            "gap": 100
        },
        "brands": {
            "type": "terms",
            "field": "brand",
            "limit": 20,
            "sort": "count desc"
        },
        "avg_rating": {
            "type": "func",
            "func": "avg(rating)"
        }
    },
    "sort": "score desc, popularity desc",
    "rows": 20
}'

# Streaming expressions (analytical queries)
curl "http://localhost:8983/solr/products/stream" -d '
    expr=rollup(
        search(products, q="*:*", fl="category,price", sort="category asc", qt="/export"),
        over="category",
        sum(price),
        count(*)
    )
'

# Data Import Handler (DIH) from SQL database
# solrconfig.xml:
# <requestHandler name="/dataimport" class="solr.DataImportHandler">
#   <lst name="defaults">
#     <str name="config">db-data-config.xml</str>
#   </lst>
# </requestHandler>
```

## Typesense

### Typo-Tolerant Instant Search

```bash
# Start Typesense
typesense-server --data-dir=/data --api-key=xyz --enable-cors

# Create collection with schema
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

```typescript
// TypeScript client
import Typesense from 'typesense';

const client = new Typesense.Client({
  nodes: [{ host: 'localhost', port: 8108, protocol: 'http' }],
  apiKey: 'xyz',
  connectionTimeoutSeconds: 2,
});

// Index documents (batch)
await client.collections('products').documents().import(products, { action: 'upsert' });

// Search with typo tolerance, faceting, and geo
const results = await client.collections('products').documents().search({
  q: 'wireles headphnes',           // typos automatically corrected
  query_by: 'name,description,tags',
  query_by_weights: '3,1,2',        // boost name matches
  filter_by: 'price:<300 && category:=Electronics && rating:>3.5',
  sort_by: '_text_match:desc,rating:desc',
  facet_by: 'category,brand,price',
  max_facet_values: 20,
  page: 1,
  per_page: 20,
  highlight_full_fields: 'name,description',
  typo_tokens_threshold: 1,         // min tokens before allowing typos
  num_typos: 2,                     // max typos per word
});

// Geo search
const nearbyResults = await client.collections('products').documents().search({
  q: '*',
  filter_by: 'location:(48.8566, 2.3522, 10 km)',  // within 10km of Paris
  sort_by: 'location(48.8566, 2.3522):asc',
});

// Vector search (semantic/hybrid)
const semanticResults = await client.collections('products').documents().search({
  q: 'comfortable noise canceling',
  query_by: 'name,description',
  vector_query: 'embedding:([], k:10)',  // auto-embed query text
  // or provide explicit vector:
  // vector_query: 'embedding:([0.1, 0.2, ...], k:10)',
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

### InstantSearch Integration

```html
<!-- Typesense with InstantSearch.js (Algolia-compatible) -->
<script src="https://cdn.jsdelivr.net/npm/typesense-instantsearch-adapter@2/dist/typesense-instantsearch-adapter.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/instantsearch.js@4"></script>

<script>
const typesenseAdapter = new TypesenseInstantsearchAdapter({
  server: {
    apiKey: 'search-only-key',
    nodes: [{ host: 'search.example.com', port: 443, protocol: 'https' }],
  },
  additionalSearchParameters: {
    query_by: 'name,description,tags',
    query_by_weights: '3,1,2',
  },
});

const search = instantsearch({
  indexName: 'products',
  searchClient: typesenseAdapter.searchClient,
});

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

## Meilisearch

### AI-Powered Instant Search

```bash
# Start Meilisearch
meilisearch --master-key=MASTER_KEY --env=production

# Create index and add documents
curl -X POST 'http://localhost:7700/indexes/products/documents' \
  -H 'Authorization: Bearer MASTER_KEY' \
  -H 'Content-Type: application/json' \
  --data-binary @products.json
```

```typescript
import { MeiliSearch } from 'meilisearch';

const client = new MeiliSearch({
  host: 'http://localhost:7700',
  apiKey: 'MASTER_KEY',
});

// Configure index settings
await client.index('products').updateSettings({
  searchableAttributes: ['name', 'description', 'tags'],
  filterableAttributes: ['category', 'brand', 'price', 'rating', 'location'],
  sortableAttributes: ['price', 'rating', 'created_at'],
  rankingRules: [
    'words',            // number of matching words
    'typo',             // fewer typos ranked higher
    'proximity',        // words closer together ranked higher
    'attribute',        // earlier attributes ranked higher
    'sort',             // custom sort
    'exactness',        // exact matches ranked higher
  ],
  typoTolerance: {
    enabled: true,
    minWordSizeForTypos: { oneTypo: 4, twoTypos: 8 },
    disableOnAttributes: ['sku'],
  },
  synonyms: {
    'headphones': ['headsets', 'earphones'],
    'laptop': ['notebook', 'computer'],
  },
  pagination: { maxTotalHits: 10000 },
  faceting: { maxValuesPerFacet: 100 },
});

// Search with faceting
const results = await client.index('products').search('wireless headphones', {
  filter: ['price < 300', 'category = Electronics'],
  sort: ['price:asc'],
  facets: ['category', 'brand', 'price'],
  attributesToHighlight: ['name', 'description'],
  attributesToCrop: ['description'],
  cropLength: 30,
  showMatchesPosition: true,
  page: 1,
  hitsPerPage: 20,
});

// Multi-search (search multiple indexes in one request)
const multiResults = await client.multiSearch({
  queries: [
    { indexUid: 'products', q: 'headphones', limit: 5 },
    { indexUid: 'articles', q: 'headphones review', limit: 3 },
  ],
});

// Geo search
const nearby = await client.index('stores').search('', {
  filter: ['_geoRadius(48.8566, 2.3522, 10000)'],  // 10km radius
  sort: ['_geoPoint(48.8566, 2.3522):asc'],
});

// Hybrid search (keyword + vector)
const hybridResults = await client.index('products').search('comfortable earbuds', {
  hybrid: {
    semanticRatio: 0.5,  // 50% keyword, 50% semantic
    embedder: 'default',
  },
});

// Multi-tenancy (tenant tokens)
const tenantToken = client.generateTenantToken(
  'search-api-key-uid',
  { 'products': { filter: 'tenant_id = tenant-abc' } },
  { expiresAt: new Date('2025-01-01') }
);
```

## Algolia

### Hosted Search with Analytics

```typescript
import algoliasearch from 'algoliasearch';

const client = algoliasearch('APP_ID', 'ADMIN_API_KEY');
const index = client.initIndex('products');

// Configure index
await index.setSettings({
  searchableAttributes: [
    'name',              // highest priority
    'unordered(description)',
    'tags',
  ],
  attributesForFaceting: [
    'searchable(category)',  // searchable facet
    'brand',
    'filterOnly(tenant_id)', // not displayed, only for filtering
    'price',
  ],
  customRanking: [
    'desc(popularity)',
    'desc(rating)',
  ],
  hitsPerPage: 20,
  typoTolerance: true,
  minWordSizefor1Typo: 4,
  minWordSizefor2Typos: 8,
  distinct: 1,                  // de-duplication
  attributeForDistinct: 'product_group',
  replicas: [
    'products_price_asc',     // replica for price sorting
    'products_price_desc',
  ],
});

// Index documents
await index.saveObjects(products, { autoGenerateObjectIDIfNotExist: true });

// Partial updates (only specified attributes)
await index.partialUpdateObject({
  objectID: 'product-123',
  price: 89.99,
  inventory: 42,
});

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

// A/B testing
const abTest = await client.initAnalytics().addABTest({
  name: 'relevance-test',
  variants: [
    { index: 'products', trafficPercentage: 50, description: 'Current ranking' },
    { index: 'products_v2', trafficPercentage: 50, description: 'New ranking' },
  ],
  endAt: '2024-12-31T00:00:00Z',
});

// Recommend (AI recommendations)
const { results: recommendations } = await client.getRecommendations({
  requests: [
    {
      indexName: 'products',
      model: 'related-products',
      objectID: 'product-123',
      maxRecommendations: 5,
    },
  ],
});
```

### InstantSearch (Frontend SDK)

```tsx
// React InstantSearch
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

## Zinc

### Lightweight Elasticsearch Alternative

```bash
# Start Zinc (single binary, Go-based)
ZINC_FIRST_ADMIN_USER=admin ZINC_FIRST_ADMIN_PASSWORD=secret \
  zinc server --data /data

# Create index
curl -X PUT "http://localhost:4080/api/index" \
  -H "Content-Type: application/json" \
  -u admin:secret \
  -d '{
    "name": "products",
    "storage_type": "disk",
    "mappings": {
        "properties": {
            "name": { "type": "text", "index": true, "highlightable": true },
            "description": { "type": "text", "index": true },
            "category": { "type": "keyword", "index": true, "aggregatable": true },
            "price": { "type": "float", "index": true, "aggregatable": true }
        }
    }
}'

# Index document
curl -X POST "http://localhost:4080/api/products/_doc" \
  -H "Content-Type: application/json" \
  -u admin:secret \
  -d '{"name": "Wireless Headphones", "category": "Electronics", "price": 99.99}'

# Search (ES-compatible query DSL)
curl -X POST "http://localhost:4080/api/products/_search" \
  -H "Content-Type: application/json" \
  -u admin:secret \
  -d '{
    "search_type": "match",
    "query": { "term": "headphones", "field": "name" },
    "sort_fields": ["-price"],
    "from": 0,
    "max_results": 20,
    "aggs": {
        "categories": { "terms": { "field": "category", "size": 10 } }
    }
}'

# Zinc advantages:
# - Single binary, ~50MB RAM idle
# - Built-in web UI at http://localhost:4080
# - Elasticsearch-compatible API subset
# - Go-based (no JVM dependency)
# - Good for: small-medium datasets, resource-constrained environments
```

## Manticore Search

### MySQL Protocol with Real-Time Indexes

```sql
-- Connect with any MySQL client
-- mysql -h 127.0.0.1 -P 9306

-- Create real-time index
CREATE TABLE products (
    name text,
    description text,
    category string attribute,
    brand string attribute,
    price float attribute,
    tags multi attribute,
    created_at timestamp attribute
) morphology='stem_en' min_word_len=2;

-- Insert data
INSERT INTO products (id, name, description, category, price)
VALUES (1, 'Wireless Headphones', 'Premium noise canceling', 'Electronics', 99.99);

-- Full-text search with ranking
SELECT *, WEIGHT() as relevance
FROM products
WHERE MATCH('wireless headphone')
AND price < 200
ORDER BY relevance DESC
LIMIT 20
FACET category ORDER BY count(*) DESC
FACET brand ORDER BY count(*) DESC;

-- Percolation queries (reverse search: find queries that match a document)
CREATE TABLE alerts (query text, filters string) type='percolate';
INSERT INTO alerts (query, filters) VALUES ('price drop headphones', 'category=Electronics');

-- Match incoming document against stored queries
CALL PQ('alerts', '{"name": "Headphones on sale", "category": "Electronics"}');
```

```bash
# Manticore Search configuration (manticore.conf)
# Supports: real-time indexes, plain indexes, distributed indexes
# Columnar storage for analytics workloads
# Built-in replication (Galera-based)

# Start
searchd --config /etc/manticore/manticore.conf

# Import from MySQL
indexer --config /etc/manticore/manticore.conf --all --rotate
```

## Sonic

### Lightweight Search Backend

```bash
# Sonic: fast text search backend (Rust, minimal resources)
# Not a full search engine - designed as search layer behind primary DB
# Uses: autocomplete, search suggestions, fast text matching
# Memory: ~30MB for millions of records

# Start Sonic
sonic -c /etc/sonic.cfg

# sonic.cfg
[server]
  log_level = "info"
[channel]
  [channel.search]
    query_limit_default = 10
    query_limit_maximum = 100
    suggest_limit_default = 5
  [channel.ingest]
    # no special config needed
```

```javascript
// Node.js client
const Sonic = require('sonic-channel');

// Ingest channel (write data)
const ingest = new Sonic.Ingest({ host: 'localhost', port: 1491, auth: 'secret' });
await ingest.connect();

// Push searchable text (collection, bucket, object_id, text)
await ingest.push('products', 'default', 'product:1', 'Wireless Bluetooth Headphones Premium');
await ingest.push('products', 'default', 'product:2', 'Wired Studio Monitor Headphones');

// Search channel (read data)
const search = new Sonic.Search({ host: 'localhost', port: 1491, auth: 'secret' });
await search.connect();

// Query returns object IDs (look up full documents in primary DB)
const results = await search.query('products', 'default', 'wireless headphones');
// Returns: ['product:1']

// Suggest (autocomplete)
const suggestions = await search.suggest('products', 'default', 'wire');
// Returns: ['wireless', 'wired']

// Sonic returns only IDs -> fetch full documents from your primary database
// This is by design: Sonic is a search index, not a document store
```

## Relevance Tuning Strategies

### Field Boosting

```
Boost fields by importance:
- Product name: 3x weight (most relevant)
- Tags/keywords: 2x weight
- Description: 1x weight (default)
- Category: 0.5x weight (contextual)
```

### Query-Time Tuning

```
1. Exact match bonus: boost exact phrase matches
2. Proximity bonus: boost when search terms are close together
3. Freshness: boost recent documents
4. Popularity: boost by view count, sales, or engagement
5. Personalization: boost by user preferences or history
```

### Index-Time Optimization

```
1. Synonyms: define at index time for consistent handling
2. Stop words: remove common words (the, is, at)
3. Stemming: normalize word forms (running -> run)
4. N-grams: enable partial matching (edge n-grams for autocomplete)
5. Phonetic analysis: match similar-sounding words
```

### A/B Testing Search Relevance

```
1. Define metrics: click-through rate, conversion rate, zero-result rate
2. Split traffic: 50/50 between variants
3. Measure: which ranking formula produces better outcomes
4. Tools: Algolia A/B testing, custom analytics with feature flags
5. Iterate: continuously refine ranking based on data
```

## Operational Best Practices

### Data Synchronization

```
Primary DB -> Search Engine sync strategies:

1. Real-time sync (lowest latency):
   - CDC via Debezium -> Kafka -> Search connector
   - Database triggers -> queue -> indexer

2. Near real-time (seconds):
   - Application-level dual writes (with retry)
   - Change streams (MongoDB) -> indexer

3. Batch sync (minutes-hours):
   - Scheduled full/incremental reindex
   - ETL pipeline

Best practice: use CDC for production, batch for recovery/rebuild
```

### Index Management

- Alias-based reindexing: create new index, reindex, swap alias
- Blue-green indexing for zero-downtime schema changes
- Monitor index size and query latency
- Set up alerts for zero-result queries (improve coverage)
- Track search analytics: popular queries, no-result queries, click position

### Performance Optimization

- Use filters (not queries) for non-scoring criteria (faster, cacheable)
- Limit returned fields to what the UI needs
- Use pagination wisely: prefer search-after over deep offset pagination
- Cache frequent queries at application level
- Shard by tenant for multi-tenant workloads
- Monitor query latency percentiles (p50, p95, p99)

### Security

- Separate admin and search-only API keys
- Use tenant-scoped API keys for multi-tenant search
- Never expose admin keys to frontend code
- Rate limit search API to prevent abuse
- Sanitize user input before constructing queries
- Use HTTPS for all search traffic

For cross-references, see:
- Elasticsearch and OpenSearch deep coverage in the document-databases skill
- MongoDB Atlas Search in the document-databases skill
- PostgreSQL full-text search (tsvector/tsquery) in the relational-databases skill
