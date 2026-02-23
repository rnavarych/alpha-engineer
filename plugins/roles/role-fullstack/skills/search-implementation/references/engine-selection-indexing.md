# Engine Selection and Indexing

## When to load
Load when choosing a search engine, planning the indexing strategy, or setting up incremental sync from a database.

## Search Engine Selection

| Engine        | Hosting     | Latency | Best For                               |
|---------------|-------------|---------|----------------------------------------|
| ElasticSearch | Self/Cloud  | ~50ms   | Large-scale, complex queries, analytics|
| OpenSearch    | Self/AWS    | ~50ms   | AWS-native, ElasticSearch alternative  |
| Typesense     | Self/Cloud  | ~5ms    | Typo-tolerant, easy setup, fast        |
| Meilisearch   | Self/Cloud  | ~5ms    | Developer-friendly, instant search     |
| Algolia       | Managed     | ~5ms    | Managed SaaS, rich UI components       |
| pg_trgm / FTS | PostgreSQL  | ~20ms   | Small datasets, no extra infra         |

## Indexing Strategy

1. **Define the schema** — choose searchable fields, filterable attributes, sortable attributes, and ranking rules.
2. **Initial sync** — bulk-index existing data using batch operations (1000-5000 documents per batch).
3. **Incremental sync** — update the index on data changes via:
   - Database triggers or Change Data Capture (Debezium).
   - Application-level hooks (Prisma middleware, Sequelize hooks).
   - Background job queue (process changes asynchronously).
4. **Denormalize for search** — flatten related data into the search document to avoid joins at query time.

## Implementation Pattern (Meilisearch)

```typescript
// Server: indexing
import { MeiliSearch } from 'meilisearch';
const client = new MeiliSearch({ host: process.env.MEILI_HOST, apiKey: process.env.MEILI_KEY });

await client.index('products').updateSettings({
  searchableAttributes: ['name', 'description', 'category'],
  filterableAttributes: ['category', 'price', 'inStock'],
  sortableAttributes: ['price', 'createdAt'],
  rankingRules: ['words', 'typo', 'proximity', 'attribute', 'sort', 'exactness'],
});

// Client: search with filters
const results = await client.index('products').search(query, {
  filter: ['category = "electronics"', 'price >= 10 AND price <= 500'],
  sort: ['price:asc'],
  limit: 20,
  offset: 0,
});
```
