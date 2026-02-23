# Elasticsearch / OpenSearch — ILM, Data Streams, Mapping, Shard Allocation

## When to load
Load when configuring Index Lifecycle Management policies, data streams for time-series logs, designing mappings (nested vs object, field types), or tuning shard allocation and node tier awareness.

## ILM Policy (Full Lifecycle)

```json
PUT _ilm/policy/application_logs
{
  "policy": { "phases": {
    "hot": { "min_age": "0ms", "actions": {
      "rollover": { "max_primary_shard_size": "50gb", "max_age": "1d", "max_docs": 100000000 },
      "set_priority": { "priority": 100 }
    }},
    "warm": { "min_age": "7d", "actions": {
      "shrink": { "number_of_shards": 1 },
      "forcemerge": { "max_num_segments": 1 },
      "allocate": { "number_of_replicas": 1, "require": { "data": "warm" } },
      "set_priority": { "priority": 50 }
    }},
    "cold": { "min_age": "30d", "actions": {
      "searchable_snapshot": { "snapshot_repository": "s3_repo", "force_merge_index": true },
      "set_priority": { "priority": 0 }
    }},
    "frozen": { "min_age": "90d", "actions": { "searchable_snapshot": { "snapshot_repository": "s3_repo" } } },
    "delete": { "min_age": "365d", "actions": { "delete": {} } }
  }}
}
```

## Data Streams

```json
PUT _index_template/logs_template
{
  "index_patterns": ["logs-*"], "data_stream": {},
  "template": {
    "settings": { "number_of_shards": 3, "number_of_replicas": 1, "index.lifecycle.name": "application_logs" },
    "mappings": { "properties": {
      "@timestamp": { "type": "date" }, "message": { "type": "text" },
      "level": { "type": "keyword" }, "service": { "type": "keyword" }
    }}
  }
}
```

## Mapping Design

```json
PUT /orders
{ "mappings": { "dynamic": "strict", "properties": {
  "orderId":    { "type": "keyword" },
  "total":      { "type": "scaled_float", "scaling_factor": 100 },
  "status":     { "type": "keyword" },
  "createdAt":  { "type": "date", "format": "strict_date_optional_time||epoch_millis" },
  "notes":      { "type": "text", "analyzer": "english" },
  "embedding":  { "type": "dense_vector", "dims": 768, "index": true, "similarity": "cosine" },
  "items": { "type": "nested", "properties": {
    "productId": { "type": "keyword" },
    "name":      { "type": "text", "fields": { "raw": { "type": "keyword" } } },
    "quantity":  { "type": "integer" },
    "price":     { "type": "scaled_float", "scaling_factor": 100 }
  }}
}}}
```

## Field Type Selection

| Data | Type | When to Use |
|------|------|-------------|
| IDs, enums, status | `keyword` | Exact match, terms agg, sorting |
| Free text | `text` | Full-text search, relevance scoring |
| Both search + filter | `text` + `keyword` multi-field | Search on text, aggregate on keyword |
| Prices, scores | `scaled_float` | Decimal with known precision |
| Dates | `date` | Time-based queries |
| Coordinates | `geo_point` | Distance, bounding box |
| Embeddings | `dense_vector` | kNN similarity search |
| Array of objects | `nested` | Query object fields together |
| High-cardinality JSON | `flattened` | Prevent mapping explosion |

## Shard Allocation

```yaml
# Hot node
node.roles: [data_hot, ingest]
node.attr.data: hot

# Warm node
node.roles: [data_warm]
node.attr.data: warm
```

```json
PUT _cluster/settings { "persistent": {
  "cluster.routing.allocation.awareness.attributes": "zone",
  "cluster.routing.allocation.disk.watermark.low": "85%",
  "cluster.routing.allocation.disk.watermark.high": "90%",
  "cluster.routing.allocation.disk.watermark.flood_stage": "95%"
}}
```

**Shard sizing:** target 20-50 GB per shard; keep below 20 shards per GB of heap per node; time-series: 1 shard per ~50 GB of daily data.
