# Neo4j Deep Reference

## Cypher Query Optimization

### PROFILE and EXPLAIN
```cypher
-- EXPLAIN: shows query plan without executing
EXPLAIN
MATCH (p:Person)-[:KNOWS]->(f:Person)
WHERE p.name = 'Alice'
RETURN f.name;

-- PROFILE: executes and shows actual row counts + db hits
PROFILE
MATCH (p:Person)-[:KNOWS]->(f:Person)
WHERE p.name = 'Alice'
RETURN f.name;

-- Key metrics in PROFILE output:
-- Rows: actual rows produced by each operator
-- DbHits: number of database operations (lower = faster)
-- EstimatedRows: planner's estimate (compare with actual)
-- PageCacheHits / PageCacheMisses: memory efficiency
```

### Query Tuning Techniques
```cypher
-- 1. Use parameterized queries (plan caching)
MATCH (p:Person {name: $name}) RETURN p;

-- 2. Avoid cartesian products
-- BAD: implicit cartesian product
MATCH (a:Person), (b:Movie) WHERE a.name = 'Alice' RETURN a, b;
-- GOOD: explicit relationship
MATCH (a:Person {name: 'Alice'})-[:ACTED_IN]->(b:Movie) RETURN a, b;

-- 3. Filter early (push predicates down)
-- BAD: filter after expanding
MATCH (p:Person)-[:KNOWS*1..3]->(f) WHERE p.age > 25 RETURN f;
-- GOOD: filter before expanding
MATCH (p:Person) WHERE p.age > 25
WITH p MATCH (p)-[:KNOWS*1..3]->(f) RETURN f;

-- 4. Use index hints when planner chooses wrong index
MATCH (p:Person)
USING INDEX p:Person(name)
WHERE p.name = 'Alice'
RETURN p;

-- 5. Avoid eager aggregation (forces full materialization)
-- The PROFILE output will show "Eager" operators
-- Refactor queries to avoid unnecessary ordering/aggregation

-- 6. LIMIT pushdown
MATCH (p:Person)-[:KNOWS]->(f)
RETURN f.name
ORDER BY f.name
LIMIT 10;   -- Planner can use index-backed order + limit

-- 7. Use UNWIND for batch operations instead of individual CREATE
UNWIND $batch AS row
CREATE (p:Person {name: row.name, age: row.age});

-- 8. Use pattern comprehensions instead of OPTIONAL MATCH + collect
MATCH (p:Person)
RETURN p.name, [(p)-[:KNOWS]->(f) | f.name] AS friends;
```

### Eager Operator Avoidance
```cypher
-- Eager operators force full result materialization
-- Common triggers: ORDER BY, DISTINCT, aggregation between write clauses

-- BAD: Eager between MATCH and CREATE
MATCH (p:Person)
CREATE (p)-[:TAGGED]->(:Tag {name: p.category});
-- The planner inserts Eager to prevent read-after-write conflicts

-- GOOD: Use CALL {} subquery (Neo4j 4.1+)
MATCH (p:Person)
CALL {
  WITH p
  CREATE (p)-[:TAGGED]->(:Tag {name: p.category})
} IN TRANSACTIONS OF 1000 ROWS;
```

## Index Types

### Range Index (Default)
```cypher
-- General-purpose B-tree-like index
CREATE INDEX person_name FOR (p:Person) ON (p.name);
CREATE INDEX person_age FOR (p:Person) ON (p.age);

-- Composite index (multiple properties)
CREATE INDEX person_name_age FOR (p:Person) ON (p.name, p.age);
-- Supports: equality, range, prefix, exists, IS NOT NULL
-- Composite indexes support leftmost prefix queries

-- Relationship index
CREATE INDEX knows_since FOR ()-[r:KNOWS]-() ON (r.since);
```

### Text Index
```cypher
-- Optimized for text predicates (CONTAINS, STARTS WITH, ENDS WITH)
CREATE TEXT INDEX person_name_text FOR (p:Person) ON (p.name);

-- Queries using text index
MATCH (p:Person) WHERE p.name CONTAINS 'ali' RETURN p;
MATCH (p:Person) WHERE p.name STARTS WITH 'Al' RETURN p;
MATCH (p:Person) WHERE p.name ENDS WITH 'ce' RETURN p;
```

### Full-Text Index (Lucene-backed)
```cypher
-- Multi-property full-text search
CREATE FULLTEXT INDEX article_search FOR (a:Article)
ON EACH [a.title, a.body, a.abstract];

-- Query with relevance scoring
CALL db.index.fulltext.queryNodes('article_search', 'graph database performance')
YIELD node, score
RETURN node.title, score
ORDER BY score DESC
LIMIT 20;

-- Lucene syntax: wildcards, fuzzy, boolean, phrase
CALL db.index.fulltext.queryNodes('article_search', 'graph AND (database OR "knowledge graph")~2')
YIELD node, score RETURN node.title, score;

-- Relationship full-text index
CREATE FULLTEXT INDEX review_search FOR ()-[r:REVIEWED]-()
ON EACH [r.text, r.summary];
```

### Point Index (Geospatial)
```cypher
CREATE POINT INDEX location_idx FOR (p:Place) ON (p.location);

-- Store geospatial data
CREATE (p:Place {name: 'London', location: point({latitude: 51.5074, longitude: -0.1278})});

-- Distance queries
MATCH (p:Place)
WHERE point.distance(p.location, point({latitude: 51.5, longitude: -0.1})) < 10000
RETURN p.name, point.distance(p.location, point({latitude: 51.5, longitude: -0.1})) AS distance_m
ORDER BY distance_m;

-- Bounding box
MATCH (p:Place)
WHERE point.withinBBox(p.location, point({latitude: 51.0, longitude: -0.5}), point({latitude: 52.0, longitude: 0.5}))
RETURN p.name;
```

### Vector Index (GenAI)
```cypher
-- Create vector index
CREATE VECTOR INDEX document_embeddings FOR (d:Document) ON (d.embedding)
OPTIONS {
  indexConfig: {
    `vector.dimensions`: 1536,
    `vector.similarity_function`: 'cosine'   -- cosine | euclidean
  }
};

-- Store embeddings
CREATE (d:Document {
  title: 'Architecture Patterns',
  text: 'Microservices enable...',
  embedding: $embedding_vector     -- float[] from embedding API
});

-- Similarity search
CALL db.index.vector.queryNodes('document_embeddings', 10, $queryVector)
YIELD node AS doc, score
RETURN doc.title, doc.text, score
ORDER BY score DESC;

-- Hybrid: vector + graph context (GraphRAG)
CALL db.index.vector.queryNodes('document_embeddings', 5, $queryVector)
YIELD node AS chunk, score
MATCH (chunk)-[:PART_OF]->(doc:Document)
MATCH (chunk)-[:MENTIONS]->(entity:Entity)
RETURN chunk.text, doc.title, collect(DISTINCT entity.name) AS entities, score
ORDER BY score DESC;
```

### Token Lookup Index
```cypher
-- Fast label/type lookups (automatically created)
CREATE LOOKUP INDEX node_label_lookup FOR (n) ON EACH labels(n);
CREATE LOOKUP INDEX rel_type_lookup FOR ()-[r]-() ON EACH type(r);

-- Used internally for: MATCH (n:Person), MATCH ()-[r:KNOWS]->()
```

### Index Management
```cypher
SHOW INDEXES;                              -- List all indexes
SHOW INDEXES YIELD name, type, labelsOrTypes, properties, state;
DROP INDEX person_name;                    -- Drop by name

-- Wait for index to come online
CREATE INDEX my_idx FOR (n:Node) ON (n.prop);
CALL db.awaitIndex('my_idx', 300);         -- Wait up to 300s
```

## APOC Library

### Data Import/Export
```cypher
-- Load JSON from URL/file
CALL apoc.load.json('https://api.example.com/users')
YIELD value
CREATE (u:User {id: value.id, name: value.name});

-- Load CSV with custom parsing
CALL apoc.load.csv('file:///data.csv', {header: true, sep: ','})
YIELD map
CREATE (p:Person {name: map.name, age: toInteger(map.age)});

-- Export to JSON
CALL apoc.export.json.all('export.json', {});

-- Export subgraph to Cypher statements
CALL apoc.export.cypher.query(
  'MATCH (p:Person)-[r:KNOWS]->(f) RETURN p, r, f',
  'output.cypher', {}
);
```

### Batch Processing
```cypher
-- Periodic iterate (batch processing large datasets)
CALL apoc.periodic.iterate(
  'MATCH (p:Person) WHERE p.needsUpdate = true RETURN p',
  'SET p.status = "processed", p.needsUpdate = false',
  {batchSize: 1000, parallel: true, concurrency: 4}
);

-- Periodic commit (auto-commit every N operations)
CALL apoc.periodic.commit(
  'MATCH (p:Person) WHERE p.migrated IS NULL
   WITH p LIMIT $limit
   SET p.migrated = true
   RETURN count(*)',
  {limit: 10000}
);
```

### Node/Relationship Operations
```cypher
-- Merge nodes (deduplicate)
CALL apoc.refactor.mergeNodes([node1, node2], {
  properties: 'combine',
  mergeRels: true
});

-- Create virtual nodes/relationships (for projection)
CALL apoc.create.vNode(['Summary'], {name: 'Overview', count: 42}) YIELD node;
CALL apoc.create.vRelationship(startNode, 'SUMMARIZES', {}, endNode) YIELD rel;

-- Clone subgraph
CALL apoc.refactor.cloneSubgraph(
  [node1, node2], [rel1, rel2],
  {standinNodes: [[oldNode, newNode]]}
);
```

### Utilities
```cypher
-- Generate UUIDs
RETURN apoc.create.uuid() AS uuid;

-- Date/time formatting
RETURN apoc.date.format(timestamp(), 'ms', 'yyyy-MM-dd HH:mm:ss') AS formatted;

-- Text functions
RETURN apoc.text.levenshteinDistance('graph', 'grahp') AS distance;
RETURN apoc.text.sorensenDiceSimilarity('graph database', 'graph db') AS similarity;

-- Schema info
CALL apoc.meta.schema() YIELD value RETURN value;
CALL apoc.meta.stats() YIELD nodeCount, relCount, labelCount;

-- Triggers (execute on data changes)
CALL apoc.trigger.add('update-timestamp',
  'UNWIND $createdNodes AS n SET n.created = timestamp()',
  {phase: 'after'}
);
```

## Graph Data Science (GDS) Library

### Project Graph
```cypher
-- Create in-memory graph projection
CALL gds.graph.project(
  'social',                          -- Graph name
  'Person',                          -- Node labels
  'KNOWS',                           -- Relationship types
  {
    nodeProperties: ['age', 'score'],
    relationshipProperties: ['weight']
  }
);

-- Or use Cypher projection for complex graphs
CALL gds.graph.project.cypher(
  'social_filtered',
  'MATCH (p:Person) WHERE p.active = true RETURN id(p) AS id, p.age AS age',
  'MATCH (a:Person)-[r:KNOWS]->(b:Person) WHERE r.since > date("2020-01-01")
   RETURN id(a) AS source, id(b) AS target, r.weight AS weight'
);

-- List and manage projections
CALL gds.graph.list() YIELD graphName, nodeCount, relationshipCount;
CALL gds.graph.drop('social');
```

### Centrality Algorithms
```cypher
-- PageRank
CALL gds.pageRank.stream('social', {maxIterations: 20, dampingFactor: 0.85})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC LIMIT 10;

-- Betweenness Centrality (bridge nodes)
CALL gds.betweennessCentrality.stream('social')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC LIMIT 10;

-- Degree Centrality
CALL gds.degree.stream('social')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC;

-- Article Rank (variant of PageRank)
CALL gds.articleRank.stream('social')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name, score;

-- Eigenvector Centrality
CALL gds.eigenvector.stream('social')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name, score;
```

### Community Detection
```cypher
-- Louvain (modularity optimization)
CALL gds.louvain.stream('social')
YIELD nodeId, communityId
RETURN communityId, collect(gds.util.asNode(nodeId).name) AS members
ORDER BY size(members) DESC;

-- Label Propagation (fast, scalable)
CALL gds.labelPropagation.stream('social')
YIELD nodeId, communityId
RETURN communityId, count(*) AS size
ORDER BY size DESC;

-- Weakly Connected Components
CALL gds.wcc.stream('social')
YIELD nodeId, componentId
RETURN componentId, count(*) AS size
ORDER BY size DESC;

-- Strongly Connected Components
CALL gds.scc.stream('social')
YIELD nodeId, componentId
RETURN componentId, count(*) AS size;

-- Triangle Count + Local Clustering Coefficient
CALL gds.triangleCount.stream('social')
YIELD nodeId, triangleCount
RETURN gds.util.asNode(nodeId).name, triangleCount;

CALL gds.localClusteringCoefficient.stream('social')
YIELD nodeId, localClusteringCoefficient;
```

### Similarity
```cypher
-- Node Similarity (Jaccard)
CALL gds.nodeSimilarity.stream('social', {topK: 5})
YIELD node1, node2, similarity
RETURN gds.util.asNode(node1).name, gds.util.asNode(node2).name, similarity
ORDER BY similarity DESC;

-- K-Nearest Neighbors
CALL gds.knn.stream('social', {
  topK: 5,
  nodeProperties: ['age', 'score'],
  sampleRate: 0.5,
  deltaThreshold: 0.001
})
YIELD node1, node2, similarity;
```

### Node Embeddings
```cypher
-- FastRP (Fast Random Projection)
CALL gds.fastRP.stream('social', {
  embeddingDimension: 128,
  iterationWeights: [0.0, 1.0, 1.0, 1.0]
})
YIELD nodeId, embedding
RETURN gds.util.asNode(nodeId).name, embedding;

-- Node2Vec
CALL gds.node2vec.stream('social', {
  embeddingDimension: 64,
  walkLength: 80,
  walksPerNode: 10,
  returnFactor: 1.0,
  inOutFactor: 1.0
})
YIELD nodeId, embedding;

-- GraphSAGE (inductive, uses node properties)
CALL gds.beta.graphSage.train('social', {
  modelName: 'social-model',
  featureProperties: ['age', 'score'],
  embeddingDimension: 64,
  epochs: 5
});

CALL gds.beta.graphSage.stream('social', {modelName: 'social-model'})
YIELD nodeId, embedding;
```

### Link Prediction
```cypher
-- Train link prediction pipeline
CALL gds.beta.pipeline.linkPrediction.create('lp-pipeline');
CALL gds.beta.pipeline.linkPrediction.addNodeProperty('lp-pipeline', 'fastRP', {
  embeddingDimension: 64
});
CALL gds.beta.pipeline.linkPrediction.addFeature('lp-pipeline', 'hadamard', {
  nodeProperties: ['fastRP']
});
CALL gds.beta.pipeline.linkPrediction.configureSplit('lp-pipeline', {
  testFraction: 0.1,
  trainFraction: 0.1,
  validationFolds: 5
});
CALL gds.beta.pipeline.linkPrediction.train('social', {
  pipeline: 'lp-pipeline',
  modelName: 'lp-model',
  targetRelationshipType: 'KNOWS'
});
```

### Pathfinding
```cypher
-- Dijkstra shortest path
CALL gds.shortestPath.dijkstra.stream('social', {
  sourceNode: startNodeId,
  targetNode: endNodeId,
  relationshipWeightProperty: 'weight'
})
YIELD path, totalCost
RETURN [n IN nodes(path) | n.name] AS route, totalCost;

-- A* (with heuristic)
CALL gds.shortestPath.astar.stream('roads', {
  sourceNode: startId,
  targetNode: endId,
  latitudeProperty: 'latitude',
  longitudeProperty: 'longitude',
  relationshipWeightProperty: 'distance'
});

-- All shortest paths
CALL gds.allShortestPaths.dijkstra.stream('social', {
  sourceNode: startNodeId,
  relationshipWeightProperty: 'weight'
});

-- Minimum Spanning Tree
CALL gds.spanningTree.stream('network', {
  sourceNode: rootId,
  relationshipWeightProperty: 'cost'
});
```

## Aura (Managed Service)

### Tiers
- **AuraDB Free**: 200K nodes, 400K relationships, 1 database
- **AuraDB Professional**: Auto-scaling, daily backups, 99.95% SLA
- **AuraDB Enterprise**: Dedicated infrastructure, private endpoints, SSO, advanced security
- **AuraDS**: Data science tier with GDS library pre-installed

### Operations
```bash
# Aura CLI
aura-cli database list
aura-cli database create --name production --region us-east-1 --type enterprise
aura-cli database pause --id <db-id>
aura-cli database resume --id <db-id>
aura-cli snapshot create --database-id <db-id>
aura-cli snapshot restore --snapshot-id <snap-id>
```

## Causal Clustering

### Architecture (Neo4j 4.x)
```
Core Servers (minimum 3):
- Raft consensus for write leadership
- Accept both reads and writes
- Data replicated across all cores

Read Replicas:
- Asynchronous replication from cores
- Accept read-only queries
- Scale out read capacity

Routing:
- Bolt driver with routing: bolt+routing://
- Bookmarks for causal consistency (read-your-writes)
```

### Configuration
```
# neo4j.conf (core server)
dbms.mode=CORE
causal_clustering.initial_discovery_members=core1:5000,core2:5000,core3:5000
causal_clustering.minimum_core_cluster_size_at_formation=3
causal_clustering.minimum_core_cluster_size_at_runtime=3

# neo4j.conf (read replica)
dbms.mode=READ_REPLICA
causal_clustering.initial_discovery_members=core1:5000,core2:5000,core3:5000

# Bookmarks for causal consistency
# Driver sends bookmark after write, uses it for subsequent read
# Ensures read replica has caught up to the write
```

## Fabric (Federated Queries)

```cypher
-- Query across multiple databases
USE fabric.social
CALL {
  USE fabric.graph('us-social')
  MATCH (p:Person) WHERE p.country = 'US' RETURN p.name AS name, 'US' AS region
  UNION
  USE fabric.graph('eu-social')
  MATCH (p:Person) WHERE p.country IN ['UK','DE','FR'] RETURN p.name AS name, 'EU' AS region
}
RETURN name, region;
```

## Data Import

### LOAD CSV
```cypher
-- CSV import (built-in)
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
CREATE (u:User {id: row.id, name: row.name, email: row.email});

-- With periodic commit for large files
:auto LOAD CSV WITH HEADERS FROM 'file:///large_data.csv' AS row
CALL {
  WITH row
  MERGE (u:User {id: row.id})
  SET u.name = row.name
} IN TRANSACTIONS OF 10000 ROWS;
```

### neo4j-admin import (Bulk)
```bash
# Fastest import method (offline, requires database to be stopped)
neo4j-admin database import full \
  --nodes=Person=persons_header.csv,persons.csv \
  --nodes=Movie=movies_header.csv,movies.csv \
  --relationships=ACTED_IN=acted_in_header.csv,acted_in.csv \
  --overwrite-destination \
  neo4j

# Header format: personId:ID(Person),name,:LABEL
# Relationship header: :START_ID(Person),role,:END_ID(Movie),:TYPE
```

### Kafka Connector
```json
{
  "name": "neo4j-sink",
  "config": {
    "connector.class": "streams.kafka.connect.sink.Neo4jSinkConnector",
    "neo4j.server.uri": "bolt://neo4j:7687",
    "neo4j.authentication.basic.username": "neo4j",
    "neo4j.authentication.basic.password": "password",
    "topics": "users,orders",
    "neo4j.topic.cypher.users": "MERGE (u:User {id: event.id}) SET u.name = event.name",
    "neo4j.topic.cypher.orders": "MATCH (u:User {id: event.userId}) CREATE (u)-[:PLACED]->(:Order {id: event.orderId})"
  }
}
```

## Performance Tuning

### Memory Configuration
```
# neo4j.conf

# Heap (JVM)
server.memory.heap.initial_size=8g
server.memory.heap.max_size=8g
# Rule of thumb: heap = 1/4 of RAM (max 31g for compressed oops)

# Page cache (off-heap, caches graph data)
server.memory.pagecache.size=16g
# Rule of thumb: fit entire graph + indexes
# Check: CALL dbms.queryJmx('org.neo4j:instance=kernel#0,name=Page cache')

# Transaction memory
db.memory.transaction.max=1g
db.memory.transaction.global_max_size=4g
```

### JVM Tuning
```
# neo4j.conf (JVM additional)
server.jvm.additional=-XX:+UseG1GC
server.jvm.additional=-XX:MaxGCPauseMillis=200
server.jvm.additional=-XX:+ParallelRefProcEnabled
server.jvm.additional=-XX:+UnlockExperimentalVMOptions
server.jvm.additional=-XX:+UnlockDiagnosticVMOptions
server.jvm.additional=-XX:+AlwaysPreTouch
```

### Query Performance
```cypher
-- Monitor slow queries
CALL dbms.listQueries() YIELD queryId, username, query, elapsedTimeMillis
WHERE elapsedTimeMillis > 5000
RETURN queryId, username, query, elapsedTimeMillis;

-- Kill slow query
CALL dbms.killQuery('query-id-here');

-- Database statistics (for query planner)
CALL db.stats.retrieve('GRAPH COUNTS');
CALL db.stats.clear('GRAPH COUNTS');
CALL db.stats.collect('GRAPH COUNTS');
```

## Backup and Restore

```bash
# Online backup (Enterprise)
neo4j-admin database backup neo4j --to-path=/backups/ --include-metadata=all

# Offline backup (Community/Enterprise)
neo4j-admin database dump neo4j --to-path=/backups/neo4j.dump

# Restore from backup
neo4j-admin database restore --from-path=/backups/neo4j/ neo4j --overwrite-destination

# Restore from dump
neo4j-admin database load neo4j --from-path=/backups/neo4j.dump --overwrite-destination

# Incremental backup (Enterprise)
neo4j-admin database backup neo4j --to-path=/backups/ --type=incremental

# Consistency check
neo4j-admin database check neo4j
```

## Security

### RBAC
```cypher
-- Built-in roles: admin, editor, publisher, reader, PUBLIC

-- Create custom roles
CREATE ROLE analyst;
GRANT MATCH {*} ON GRAPH * NODE * TO analyst;          -- Read nodes
GRANT MATCH {*} ON GRAPH * RELATIONSHIP * TO analyst;  -- Read relationships
DENY WRITE ON GRAPH * TO analyst;                       -- No writes

-- Property-level access
GRANT READ {name, email} ON GRAPH social NODE Person TO analyst;
DENY READ {ssn, salary} ON GRAPH social NODE Person TO analyst;

-- Subgraph access control
GRANT TRAVERSE ON GRAPH social NODE Person TO analyst;
GRANT TRAVERSE ON GRAPH social RELATIONSHIP KNOWS TO analyst;
DENY TRAVERSE ON GRAPH social RELATIONSHIP MANAGES TO analyst;

-- User management
CREATE USER analyst1 SET PASSWORD 'secure123' CHANGE REQUIRED;
GRANT ROLE analyst TO analyst1;
SHOW USERS;
SHOW ROLES WITH USERS;
```

### Auth Providers
```
# neo4j.conf
# Native authentication (default)
dbms.security.auth_enabled=true

# LDAP
dbms.security.auth_providers=ldap
dbms.security.ldap.host=ldap://ldap.example.com
dbms.security.ldap.authentication.mechanism=simple
dbms.security.ldap.authorization.group_to_role_mapping=\
  "cn=admins,ou=groups,dc=example,dc=com" = admin; \
  "cn=analysts,ou=groups,dc=example,dc=com" = analyst

# OIDC / SSO (Enterprise)
dbms.security.auth_providers=oidc-okta
dbms.security.oidc.okta.issuer=https://dev-123456.okta.com/oauth2/default
dbms.security.oidc.okta.client_id=<client_id>
```

## Visualization

### Neo4j Browser
- Built-in web UI at `http://localhost:7474`
- Cypher query editor with syntax highlighting and auto-complete
- Graph visualization with interactive exploration
- Query plan visualization (EXPLAIN/PROFILE)
- Multi-statement editor, saved queries, favorites

### Neo4j Bloom
- Business-friendly graph exploration tool
- Natural language search (perspectives)
- Visualization rules (size, color, icons based on properties)
- Scene sharing, search phrases
- Available in Aura and Desktop

### NeoDash
- Open-source Neo4j dashboard builder
- Chart types: graph, table, bar, line, pie, map, markdown, iframe
- Parameterized dashboards with filters
- Shareable dashboard configurations stored in Neo4j

```cypher
-- NeoDash example: parameterized query for dashboard
MATCH (p:Person)-[r:PURCHASED]->(prod:Product)
WHERE p.segment = $neodash_segment
RETURN prod.category AS category, count(*) AS purchases, sum(r.amount) AS revenue
ORDER BY revenue DESC
LIMIT 10;
```

### Other Visualization Options
- **Graphlytic**: Advanced analytics and visualization platform
- **yFiles**: Commercial graph visualization library (Java, .NET, JS)
- **D3.js / vis.js / Sigma.js**: Custom web visualizations
- **Gephi**: Desktop graph analysis and visualization
- **Graph App Gallery**: Neo4j Desktop plugin marketplace
