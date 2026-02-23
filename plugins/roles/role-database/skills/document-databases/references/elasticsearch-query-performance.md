# Elasticsearch / OpenSearch — Query DSL, ES|QL, Aggregations, Performance, Security

## When to load
Load when writing bool queries, function_score, ES|QL pipelines, bucket/pipeline aggregations, bulk indexing optimization, circuit breaker tuning, RBAC, or OpenSearch-specific SQL/k-NN/CCR.

## Bool Query DSL

```json
GET /products/_search
{ "query": { "bool": {
    "must": [{ "match": { "name": "bluetooth speaker" } }],
    "filter": [
      { "term": { "category": "electronics" } },
      { "range": { "price": { "gte": 20, "lte": 100 } } }
    ],
    "should": [{ "term": { "featured": true } }],
    "must_not": [{ "term": { "discontinued": true } }],
    "minimum_should_match": 1
}}, "sort": [{ "_score": "desc" }, { "createdAt": "desc" }], "from": 0, "size": 20 }
```

## Function Score (Custom Relevance)

```json
GET /products/_search
{ "query": { "function_score": {
    "query": { "match": { "name": "headphones" } },
    "functions": [
      { "field_value_factor": { "field": "sales_count", "factor": 1.2, "modifier": "log1p", "missing": 1 }, "weight": 2 },
      { "gauss": { "createdAt": { "origin": "now", "scale": "30d", "decay": 0.5 } }, "weight": 1 },
      { "filter": { "term": { "featured": true } }, "weight": 3 }
    ],
    "score_mode": "sum", "boost_mode": "multiply"
}}}
```

## ES|QL

```esql
FROM logs-*
| WHERE @timestamp > NOW() - 24 HOURS AND log.level == "ERROR"
| STATS error_count = COUNT(*), unique_services = COUNT_DISTINCT(service.name) BY service.name
| SORT error_count DESC | LIMIT 20

FROM metrics-*
| WHERE @timestamp > NOW() - 1 HOUR
| EVAL latency_ms = response_time / 1000000
| EVAL latency_bucket = CASE(latency_ms < 100, "fast", latency_ms < 500, "normal", "slow")
| STATS avg_latency = AVG(latency_ms), p99_latency = PERCENTILE(latency_ms, 99) BY service.name
```

## Aggregations

```json
GET /orders/_search
{ "size": 0, "aggs": { "monthly_revenue": {
    "date_histogram": { "field": "createdAt", "calendar_interval": "month",
      "min_doc_count": 0, "extended_bounds": { "min": "2024-01", "max": "2024-12" } },
    "aggs": {
      "revenue": { "sum": { "field": "total" } },
      "revenue_growth": { "derivative": { "buckets_path": "revenue" } },
      "cumulative_revenue": { "cumulative_sum": { "buckets_path": "revenue" } }
    }
}}}
```

## Bulk Indexing and Performance

```json
POST /_bulk
{"index": {"_index": "logs", "_id": "1"}}
{"@timestamp": "2024-03-15T10:00:00Z", "message": "Event 1", "level": "INFO"}

PUT /my_index/_settings
{ "index.refresh_interval": "30s", "index.number_of_replicas": 0,
  "index.translog.durability": "async", "index.translog.flush_threshold_size": "1gb" }

POST /my_index/_forcemerge?max_num_segments=1
```

```json
PUT _cluster/settings { "persistent": {
  "indices.breaker.total.limit": "70%",
  "indices.breaker.fielddata.limit": "40%"
}}
```

## Monitoring

```bash
GET _cluster/health?wait_for_status=yellow&timeout=50s
GET _cat/shards?v&s=store:desc&h=index,shard,prirep,state,docs,store,node
GET _cat/nodes?v&h=name,ip,heap.percent,ram.percent,cpu,load_1m,disk.used_percent
GET _cat/thread_pool?v&h=node_name,name,active,queue,rejected&s=rejected:desc
```

Alert thresholds: JVM heap >85%, thread pool rejections >0, disk >85%, search p99 >1s.

## RBAC and API Keys

```json
POST _security/role/logs_reader
{ "indices": [{ "names": ["logs-*"], "privileges": ["read", "view_index_metadata"],
    "field_security": { "grant": ["@timestamp", "message", "level", "service"] },
    "query": { "term": { "environment": "production" } }
}]}

POST _security/api_key
{ "name": "ingest-pipeline-key",
  "role_descriptors": { "ingest_role": {
    "indices": [{ "names": ["logs-*"], "privileges": ["write", "create_index"] }]
  }},
  "expiration": "30d"
}
```

## Cross-Cluster Replication and OpenSearch

```json
PUT /products-copy/_ccr/follow
{ "remote_cluster": "leader-cluster", "leader_index": "products" }
```

**OpenSearch specifics:** Security plugin (built-in RBAC, no X-Pack needed), SQL plugin, PPL, k-NN plugin with HNSW/Faiss engine, ISM (Index State Management = ILM equivalent), OpenSearch Serverless.
