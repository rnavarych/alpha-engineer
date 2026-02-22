# Elasticsearch / OpenSearch Deep-Dive Reference

## Index Lifecycle Management (ILM)

### Phase Configuration

```json
PUT _ilm/policy/application_logs
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d",
            "max_docs": 100000000
          },
          "set_priority": { "priority": 100 },
          "readonly": {}
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 },
          "allocate": {
            "number_of_replicas": 1,
            "require": { "data": "warm" }
          },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "searchable_snapshot": {
            "snapshot_repository": "s3_repo",
            "force_merge_index": true
          },
          "allocate": {
            "require": { "data": "cold" }
          },
          "set_priority": { "priority": 0 }
        }
      },
      "frozen": {
        "min_age": "90d",
        "actions": {
          "searchable_snapshot": {
            "snapshot_repository": "s3_repo"
          }
        }
      },
      "delete": {
        "min_age": "365d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Data Streams (Time-Series)

```json
// Create index template for data stream
PUT _index_template/logs_template
{
  "index_patterns": ["logs-*"],
  "data_stream": {},
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "application_logs",
      "index.codec": "best_compression"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message":    { "type": "text" },
        "level":      { "type": "keyword" },
        "service":    { "type": "keyword" },
        "trace_id":   { "type": "keyword" },
        "host":       { "type": "keyword" }
      }
    }
  }
}

// Index into data stream (auto-rollover)
POST logs-application/_doc
{
  "@timestamp": "2024-03-15T10:30:00Z",
  "message": "Connection timeout to database",
  "level": "ERROR",
  "service": "api-gateway",
  "trace_id": "abc123",
  "host": "web-01"
}
```

---

## Shard Allocation

### Node Roles and Tier Awareness

```yaml
# elasticsearch.yml for hot node
node.roles: [data_hot, ingest]
node.attr.data: hot

# elasticsearch.yml for warm node
node.roles: [data_warm]
node.attr.data: warm

# elasticsearch.yml for cold node
node.roles: [data_cold]
node.attr.data: cold

# elasticsearch.yml for frozen node (searchable snapshots only)
node.roles: [data_frozen]
```

### Shard Allocation Settings

```json
// Cluster-level allocation settings
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.awareness.attributes": "zone",
    "cluster.routing.allocation.awareness.force.zone.values": ["us-east-1a", "us-east-1b", "us-east-1c"],

    "cluster.routing.allocation.disk.watermark.low": "85%",
    "cluster.routing.allocation.disk.watermark.high": "90%",
    "cluster.routing.allocation.disk.watermark.flood_stage": "95%",

    "cluster.routing.allocation.total_shards_per_node": 400,

    "cluster.routing.rebalance.enable": "all"
  }
}

// Index-level shard allocation filtering
PUT /hot_index/_settings
{
  "index.routing.allocation.require.data": "hot",
  "index.routing.allocation.total_shards_per_node": 2
}
```

### Shard Sizing Guidelines
- Target: 20-50 GB per shard (sweet spot for most workloads).
- Maximum: Do not exceed 50 GB per shard for search-heavy workloads.
- Minimum: Avoid very small shards (<1 GB); consolidate.
- Total shards: Keep below 20 shards per GB of heap per node.
- Time-series: 1 shard per ~50 GB of daily data, with rollover.

---

## Mapping Design

### Dynamic vs Explicit Mapping

```json
// Strict mapping (recommended for production)
PUT /orders
{
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "orderId":     { "type": "keyword" },
      "customerId":  { "type": "keyword" },
      "total":       { "type": "scaled_float", "scaling_factor": 100 },
      "status":      { "type": "keyword" },
      "createdAt":   { "type": "date", "format": "strict_date_optional_time||epoch_millis" },
      "items": {
        "type": "nested",
        "properties": {
          "productId":   { "type": "keyword" },
          "name":        { "type": "text", "fields": { "raw": { "type": "keyword" } } },
          "quantity":    { "type": "integer" },
          "price":       { "type": "scaled_float", "scaling_factor": 100 }
        }
      },
      "tags":        { "type": "keyword" },
      "notes":       { "type": "text", "analyzer": "english" }
    }
  }
}
```

### Field Type Selection

| Data | Type | When to Use |
|------|------|-------------|
| IDs, enums, status | `keyword` | Exact match, terms agg, sorting |
| Free text | `text` | Full-text search, relevance scoring |
| Both search + filter | `text` + `keyword` multi-field | Search on text, aggregate on keyword |
| Prices, scores | `scaled_float` | Decimal numbers with known precision |
| Counts, quantities | `integer` / `long` | Whole numbers |
| Dates | `date` | Time-based queries, date histograms |
| Coordinates | `geo_point` | Distance, bounding box queries |
| Embeddings | `dense_vector` | kNN / ANN similarity search |
| IP addresses | `ip` | IP range queries, CIDR |
| Structured objects | `object` | Flat object (fields indexed independently) |
| Array of objects | `nested` | Query object fields together (not cross-object) |
| High-cardinality JSON | `flattened` | Index dynamic keys without mapping explosion |

### Nested vs Object

```json
// Object type: fields cross-pollinate (incorrect for array of objects)
// If items: [{color: "red", size: "S"}, {color: "blue", size: "L"}]
// A query for color=red AND size=L would incorrectly match

// Nested type: maintains object boundaries
PUT /products
{
  "mappings": {
    "properties": {
      "variants": {
        "type": "nested",
        "properties": {
          "color": { "type": "keyword" },
          "size":  { "type": "keyword" },
          "stock": { "type": "integer" }
        }
      }
    }
  }
}

// Query nested objects correctly
GET /products/_search
{
  "query": {
    "nested": {
      "path": "variants",
      "query": {
        "bool": {
          "must": [
            { "term": { "variants.color": "red" } },
            { "term": { "variants.size": "S" } }
          ]
        }
      }
    }
  }
}
```

---

## Query DSL

### Bool Query Structure

```json
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "bluetooth speaker" } }
      ],
      "filter": [
        { "term": { "category": "electronics" } },
        { "range": { "price": { "gte": 20, "lte": 100 } } },
        { "terms": { "brand": ["sony", "bose", "jbl"] } }
      ],
      "should": [
        { "term": { "featured": true } },
        { "range": { "rating": { "gte": 4.5 } } }
      ],
      "must_not": [
        { "term": { "discontinued": true } }
      ],
      "minimum_should_match": 1
    }
  },
  "sort": [
    { "_score": "desc" },
    { "createdAt": "desc" }
  ],
  "from": 0,
  "size": 20
}
```

### Function Score (Custom Relevance)

```json
GET /products/_search
{
  "query": {
    "function_score": {
      "query": { "match": { "name": "headphones" } },
      "functions": [
        {
          "field_value_factor": {
            "field": "sales_count",
            "factor": 1.2,
            "modifier": "log1p",
            "missing": 1
          },
          "weight": 2
        },
        {
          "gauss": {
            "createdAt": {
              "origin": "now",
              "scale": "30d",
              "decay": 0.5
            }
          },
          "weight": 1
        },
        {
          "filter": { "term": { "featured": true } },
          "weight": 3
        }
      ],
      "score_mode": "sum",
      "boost_mode": "multiply"
    }
  }
}
```

### Parent-Child Queries

```json
// has_child: find parents with matching children
GET /forums/_search
{
  "query": {
    "has_child": {
      "type": "answer",
      "query": { "match": { "body": "elasticsearch performance" } },
      "score_mode": "max",
      "min_children": 1
    }
  }
}

// has_parent: find children with matching parents
GET /forums/_search
{
  "query": {
    "has_parent": {
      "parent_type": "question",
      "query": { "term": { "tags": "performance" } }
    }
  }
}
```

---

## ES|QL Query Language

ES|QL (Elasticsearch Query Language) is a pipe-based query language introduced in Elasticsearch 8.11.

```esql
// Basic filtering and aggregation
FROM logs-*
| WHERE @timestamp > NOW() - 24 HOURS
| WHERE log.level == "ERROR"
| STATS error_count = COUNT(*), unique_services = COUNT_DISTINCT(service.name) BY service.name
| SORT error_count DESC
| LIMIT 20

// Enrichment and calculation
FROM metrics-*
| WHERE @timestamp > NOW() - 1 HOUR
| EVAL latency_ms = response_time / 1000000
| EVAL latency_bucket = CASE(
    latency_ms < 100, "fast",
    latency_ms < 500, "normal",
    latency_ms < 2000, "slow",
    "critical"
  )
| STATS
    avg_latency = AVG(latency_ms),
    p99_latency = PERCENTILE(latency_ms, 99),
    request_count = COUNT(*)
  BY service.name, latency_bucket
| SORT avg_latency DESC

// Dissect and grok for log parsing
FROM logs-raw-*
| GROK message "%{IP:client_ip} - %{WORD:method} %{URIPATH:path} %{NUMBER:status:int} %{NUMBER:bytes:long}"
| WHERE status >= 500
| STATS error_count = COUNT(*) BY path, status
| SORT error_count DESC
| KEEP path, status, error_count
```

---

## Analyzers and Tokenizers

### Custom Analyzer

```json
PUT /articles
{
  "settings": {
    "analysis": {
      "char_filter": {
        "html_strip": { "type": "html_strip" },
        "emoji_map": {
          "type": "mapping",
          "mappings": [":)" => "happy", ":(" => "sad"]
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "standard",
          "max_token_length": 255
        }
      },
      "filter": {
        "my_stop": {
          "type": "stop",
          "stopwords": "_english_"
        },
        "my_synonym": {
          "type": "synonym",
          "synonyms": ["quick,fast,speedy", "big,large,huge"]
        },
        "my_stemmer": {
          "type": "stemmer",
          "language": "english"
        }
      },
      "analyzer": {
        "my_custom_analyzer": {
          "type": "custom",
          "char_filter": ["html_strip"],
          "tokenizer": "standard",
          "filter": ["lowercase", "my_stop", "my_synonym", "my_stemmer"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "my_custom_analyzer",
        "search_analyzer": "my_custom_analyzer"
      }
    }
  }
}

// Test analyzer
POST /articles/_analyze
{
  "analyzer": "my_custom_analyzer",
  "text": "The <b>quick</b> brown fox jumps over the lazy dog"
}
```

### Built-In Analyzers

| Analyzer | Behavior | Use Case |
|----------|----------|----------|
| `standard` | Unicode tokenization, lowercase | General-purpose (default) |
| `simple` | Split on non-letter, lowercase | Simple text matching |
| `whitespace` | Split on whitespace only | Preserve case, special chars |
| `keyword` | No tokenization (entire string as one token) | Exact match (use keyword type instead) |
| `language` (english, etc.) | Stemming, stop words, lowercase | Natural language text |
| `pattern` | Regex-based tokenization | Custom delimiters |

---

## Aggregations

### Bucket Aggregations

```json
GET /orders/_search
{
  "size": 0,
  "aggs": {
    "monthly_revenue": {
      "date_histogram": {
        "field": "createdAt",
        "calendar_interval": "month",
        "format": "yyyy-MM",
        "min_doc_count": 0,
        "extended_bounds": { "min": "2024-01", "max": "2024-12" }
      },
      "aggs": {
        "revenue": { "sum": { "field": "total" } },
        "avg_order": { "avg": { "field": "total" } },
        "order_count": { "value_count": { "field": "orderId" } }
      }
    }
  }
}
```

### Composite Aggregation (Pagination)

```json
GET /orders/_search
{
  "size": 0,
  "aggs": {
    "all_customers": {
      "composite": {
        "size": 100,
        "after": { "customer": "last_key_from_previous_page" },
        "sources": [
          { "customer": { "terms": { "field": "customerId" } } }
        ]
      },
      "aggs": {
        "total_spent": { "sum": { "field": "total" } }
      }
    }
  }
}
```

### Pipeline Aggregations

```json
GET /orders/_search
{
  "size": 0,
  "aggs": {
    "monthly": {
      "date_histogram": { "field": "createdAt", "calendar_interval": "month" },
      "aggs": {
        "revenue": { "sum": { "field": "total" } },
        "revenue_growth": {
          "derivative": { "buckets_path": "revenue" }
        },
        "cumulative_revenue": {
          "cumulative_sum": { "buckets_path": "revenue" }
        },
        "moving_avg_revenue": {
          "moving_avg": { "buckets_path": "revenue", "window": 3, "model": "simple" }
        }
      }
    }
  }
}
```

---

## Cross-Cluster Replication (CCR)

```json
// On follower cluster: follow a leader index
PUT /products-copy/_ccr/follow
{
  "remote_cluster": "leader-cluster",
  "leader_index": "products"
}

// Auto-follow pattern (replicate new indices automatically)
PUT /_ccr/auto_follow/logs_pattern
{
  "remote_cluster": "leader-cluster",
  "leader_index_patterns": ["logs-*"],
  "follow_index_pattern": "{{leader_index}}-replica",
  "settings": {
    "index.number_of_replicas": 0
  }
}

// Bi-directional replication (active-active)
// Set up CCR in both directions with index name prefixes to avoid conflicts
// Cluster A follows: "b-*" from Cluster B
// Cluster B follows: "a-*" from Cluster A
```

---

## Performance Tuning

### Bulk Indexing

```json
// Bulk API (always use for batch operations)
POST /_bulk
{"index": {"_index": "logs", "_id": "1"}}
{"@timestamp": "2024-03-15T10:00:00Z", "message": "Event 1", "level": "INFO"}
{"index": {"_index": "logs", "_id": "2"}}
{"@timestamp": "2024-03-15T10:00:01Z", "message": "Event 2", "level": "ERROR"}
```

### Indexing Optimization

```json
// Temporarily optimize for bulk loading
PUT /my_index/_settings
{
  "index.refresh_interval": "30s",
  "index.number_of_replicas": 0,
  "index.translog.durability": "async",
  "index.translog.flush_threshold_size": "1gb"
}

// After bulk loading, restore production settings
PUT /my_index/_settings
{
  "index.refresh_interval": "1s",
  "index.number_of_replicas": 1,
  "index.translog.durability": "request"
}

// Force merge for read-only indices
POST /my_index/_forcemerge?max_num_segments=1
```

### Circuit Breakers

```json
PUT _cluster/settings
{
  "persistent": {
    "indices.breaker.total.limit": "70%",
    "indices.breaker.fielddata.limit": "40%",
    "indices.breaker.request.limit": "60%",
    "network.breaker.inflight_requests.limit": "100%"
  }
}
```

### Search Performance

```json
// Use filter context (cacheable, no scoring) over query context when possible
// Use routing to target specific shards
GET /orders/_search?routing=customer123
{ "query": { "term": { "customerId": "customer123" } } }

// Profile slow queries
GET /products/_search
{
  "profile": true,
  "query": { "match": { "name": "headphones" } }
}
```

---

## Monitoring

### Cluster Health

```bash
# Quick health check
GET _cluster/health?wait_for_status=yellow&timeout=50s

# Detailed cluster stats
GET _cluster/stats

# Node-level stats
GET _nodes/stats/jvm,os,fs,indices

# Shard allocation explanation (debug unassigned shards)
GET _cluster/allocation/explain
{
  "index": "my_index",
  "shard": 0,
  "primary": true
}
```

### Key _cat APIs

```bash
# Shard distribution
GET _cat/shards?v&s=store:desc&h=index,shard,prirep,state,docs,store,node

# Index sizes
GET _cat/indices?v&s=store.size:desc&h=index,health,status,pri,rep,docs.count,store.size

# Node resources
GET _cat/nodes?v&h=name,ip,heap.percent,ram.percent,cpu,load_1m,disk.used_percent,node.role

# Thread pool (detect queue saturation)
GET _cat/thread_pool?v&h=node_name,name,active,queue,rejected,completed&s=rejected:desc

# Pending tasks
GET _cat/pending_tasks?v

# Recovery progress
GET _cat/recovery?v&active_only&h=index,shard,stage,bytes_percent,translog_ops_percent
```

### Alerting on Key Metrics
- Cluster status not green for >5 minutes.
- JVM heap usage >85% sustained.
- Thread pool rejections >0 on search/write.
- Disk usage >85% on any data node.
- Indexing latency p99 >500ms.
- Search latency p99 >1s.

---

## Security

### TLS Configuration

```yaml
# elasticsearch.yml
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12

xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: http-certificates.p12
```

### RBAC

```json
// Create role with index-level permissions
POST _security/role/logs_reader
{
  "indices": [
    {
      "names": ["logs-*"],
      "privileges": ["read", "view_index_metadata"],
      "field_security": {
        "grant": ["@timestamp", "message", "level", "service"]
      },
      "query": { "term": { "environment": "production" } }
    }
  ]
}

// Document-level security (DLS)
POST _security/role/tenant_data
{
  "indices": [{
    "names": ["orders-*"],
    "privileges": ["read"],
    "query": { "term": { "tenantId": "{{_user.metadata.tenant_id}}" } }
  }]
}

// API key creation
POST _security/api_key
{
  "name": "ingest-pipeline-key",
  "role_descriptors": {
    "ingest_role": {
      "indices": [{ "names": ["logs-*"], "privileges": ["write", "create_index"] }]
    }
  },
  "expiration": "30d"
}
```

---

## OpenSearch Specifics

### Security Plugin (vs X-Pack)

```yaml
# opensearch.yml
plugins.security.ssl.transport.enabled: true
plugins.security.ssl.transport.pemcert_filepath: node.pem
plugins.security.ssl.transport.pemkey_filepath: node-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.allow_default_init_securityindex: true
```

### SQL Plugin

```sql
-- Query OpenSearch with SQL
POST _plugins/_sql
{
  "query": "SELECT service, COUNT(*) as errors FROM logs-* WHERE level = 'ERROR' AND @timestamp > NOW() - INTERVAL 1 HOUR GROUP BY service ORDER BY errors DESC LIMIT 10"
}

-- Explain SQL to DSL
POST _plugins/_sql/_explain
{
  "query": "SELECT * FROM logs-* WHERE level = 'ERROR' LIMIT 5"
}
```

### k-NN Plugin (Vector Search)

```json
// Create k-NN index
PUT /embeddings
{
  "settings": {
    "index.knn": true,
    "index.knn.space_type": "cosinesimil"
  },
  "mappings": {
    "properties": {
      "embedding": {
        "type": "knn_vector",
        "dimension": 768,
        "method": {
          "name": "hnsw",
          "space_type": "cosinesimil",
          "engine": "faiss",
          "parameters": { "ef_construction": 256, "m": 16 }
        }
      }
    }
  }
}

// k-NN search
GET /embeddings/_search
{
  "query": {
    "knn": {
      "embedding": {
        "vector": [0.1, 0.2, ...],
        "k": 10
      }
    }
  }
}
```

### Trace Analytics (Observability)

```bash
# OpenSearch Observability plugin
# Ingest traces via Data Prepper (OpenTelemetry collector)
# Provides: Service map, trace analytics, log correlation
# Configured via Data Prepper pipeline YAML

# data-prepper-config.yaml
otel-trace-pipeline:
  source:
    otel_trace_source:
      ssl: false
  processor:
    - otel_trace_raw:
    - otel_trace_group:
        hosts: ["https://opensearch:9200"]
  sink:
    - opensearch:
        hosts: ["https://opensearch:9200"]
        index_type: trace-analytics-raw
```
