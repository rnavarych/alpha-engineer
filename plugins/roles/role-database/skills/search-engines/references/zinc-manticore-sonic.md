# Zinc, Manticore Search, and Sonic

## When to load
Load when working with lightweight or resource-constrained search: Zinc (single binary, ES-compatible), Manticore Search (MySQL protocol, percolation, columnar storage), or Sonic (minimal-resource text search backend).

## Zinc: Lightweight Elasticsearch Alternative

```bash
# Single binary, ~50MB RAM idle, no JVM, built-in web UI at :4080
ZINC_FIRST_ADMIN_USER=admin ZINC_FIRST_ADMIN_PASSWORD=secret \
  zinc server --data /data

# Create index
curl -X PUT "http://localhost:4080/api/index" \
  -H "Content-Type: application/json" -u admin:secret \
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
  -H "Content-Type: application/json" -u admin:secret \
  -d '{"name": "Wireless Headphones", "category": "Electronics", "price": 99.99}'

# Search (ES-compatible query DSL)
curl -X POST "http://localhost:4080/api/products/_search" \
  -H "Content-Type: application/json" -u admin:secret \
  -d '{
    "search_type": "match",
    "query": { "term": "headphones", "field": "name" },
    "sort_fields": ["-price"], "from": 0, "max_results": 20,
    "aggs": { "categories": { "terms": { "field": "category", "size": 10 } } }
}'
```

## Manticore Search: MySQL Protocol

```sql
-- Connect: mysql -h 127.0.0.1 -P 9306

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

INSERT INTO products (id, name, description, category, price)
VALUES (1, 'Wireless Headphones', 'Premium noise canceling', 'Electronics', 99.99);

-- Full-text search with facets
SELECT *, WEIGHT() as relevance
FROM products
WHERE MATCH('wireless headphone') AND price < 200
ORDER BY relevance DESC LIMIT 20
FACET category ORDER BY count(*) DESC
FACET brand ORDER BY count(*) DESC;

-- Percolation queries (reverse search: find stored queries that match a document)
CREATE TABLE alerts (query text, filters string) type='percolate';
INSERT INTO alerts (query, filters) VALUES ('price drop headphones', 'category=Electronics');
CALL PQ('alerts', '{"name": "Headphones on sale", "category": "Electronics"}');
```

```bash
# Start / import from MySQL
searchd --config /etc/manticore/manticore.conf
indexer --config /etc/manticore/manticore.conf --all --rotate
# Supports: real-time indexes, plain indexes, distributed indexes, columnar storage, Galera replication
```

## Sonic: Minimal Search Backend

```bash
# ~30MB RAM for millions of records; returns only IDs (fetch docs from primary DB)
sonic -c /etc/sonic.cfg

# sonic.cfg
[server]
  log_level = "info"
[channel]
  [channel.search]
    query_limit_default = 10
    query_limit_maximum = 100
    suggest_limit_default = 5
```

```javascript
const Sonic = require('sonic-channel');

// Ingest channel (write)
const ingest = new Sonic.Ingest({ host: 'localhost', port: 1491, auth: 'secret' });
await ingest.connect();
await ingest.push('products', 'default', 'product:1', 'Wireless Bluetooth Headphones Premium');
await ingest.push('products', 'default', 'product:2', 'Wired Studio Monitor Headphones');

// Search channel (read)
const search = new Sonic.Search({ host: 'localhost', port: 1491, auth: 'secret' });
await search.connect();

// Returns object IDs only — fetch full docs from your primary database
const results = await search.query('products', 'default', 'wireless headphones');
// -> ['product:1']

// Autocomplete suggestions
const suggestions = await search.suggest('products', 'default', 'wire');
// -> ['wireless', 'wired']
```
