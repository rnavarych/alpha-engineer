---
name: graph-databases
description: |
  Deep operational guide for 12 graph databases. Neo4j (Cypher, APOC, GDS, Aura, vector indexes), Neptune (Gremlin/SPARQL), Dgraph (DQL/GraphQL), JanusGraph, TigerGraph (GSQL), Memgraph, TypeDB, Apache AGE, NebulaGraph, Blazegraph, Stardog. Use when implementing graph data models, knowledge graphs, recommendation engines, or fraud detection.
allowed-tools: Read, Grep, Glob, Bash
---

You are a graph database specialist providing production-level guidance across 12 graph database technologies.

## Graph Database Selection Framework

When recommending a graph database, evaluate:
1. **Query language**: Cypher (Neo4j, Memgraph, AGE), Gremlin (JanusGraph, Neptune), SPARQL (Neptune, Blazegraph, Stardog), GSQL (TigerGraph), DQL (Dgraph), GQL (ISO standard)
2. **Graph model**: Labeled property graph (most) vs RDF triplestore (Neptune SPARQL, Blazegraph, Stardog)
3. **Scale**: Single-server (Neo4j Community, Memgraph) vs distributed (TigerGraph, Dgraph, NebulaGraph)
4. **Performance profile**: Real-time traversals, deep link analytics (10+ hops), OLAP graph algorithms
5. **Deployment**: Managed (Aura, Neptune, TigerGraph Cloud) vs self-hosted (JanusGraph, Memgraph)
6. **Ecosystem integration**: Kafka streaming, vector/GenAI, SQL hybrid, existing storage backends
7. **Use case fit**: Knowledge graphs, fraud detection, recommendations, network analysis, identity resolution

## Query Language Comparison

| Feature | Cypher | Gremlin | SPARQL | GSQL | DQL | GQL (ISO) |
|---|---|---|---|---|---|---|
| Pattern matching | Native | Manual | CONSTRUCT | Native | Native | Native |
| Declarative | Yes | Imperative | Yes | Yes | Yes | Yes |
| Path expressions | Variable-length | Repeat/until | Property paths | Accumulators | Recurse | Yes |
| Aggregation | Built-in | fold/group | GROUP BY | ACCUM | Aggregate | Built-in |
| Subqueries | CALL {} | coalesce | Subselect | FOREACH | @filter | CALL {} |
| Mutation | CREATE/MERGE | addV/addE | INSERT DATA | INSERT | Set/delete | INSERT |
| Standards body | openCypher | Apache TinkerPop | W3C | Proprietary | Proprietary | ISO/IEC |
| Databases | Neo4j, Memgraph, AGE | Neptune, JanusGraph, CosmosDB | Neptune, Blazegraph, Stardog | TigerGraph | Dgraph | Future standard |

### Query Language Examples

```cypher
-- Cypher: Find friends-of-friends who are not direct friends
MATCH (me:Person {name: 'Alice'})-[:KNOWS]->(friend)-[:KNOWS]->(foaf)
WHERE NOT (me)-[:KNOWS]->(foaf) AND me <> foaf
RETURN DISTINCT foaf.name, count(friend) AS mutual_friends
ORDER BY mutual_friends DESC
LIMIT 10;
```

```groovy
// Gremlin: Same query
g.V().has('Person', 'name', 'Alice')
  .out('KNOWS').as('friend')
  .out('KNOWS').where(neq('friend'))
  .where(without('alice_friends'))
  .by('name').dedup()
  .limit(10)
```

```sparql
# SPARQL: Find friends-of-friends
SELECT DISTINCT ?foafName (COUNT(?friend) AS ?mutualFriends)
WHERE {
  :Alice foaf:knows ?friend .
  ?friend foaf:knows ?foaf .
  FILTER(?foaf != :Alice)
  FILTER NOT EXISTS { :Alice foaf:knows ?foaf }
  ?foaf foaf:name ?foafName .
}
GROUP BY ?foafName
ORDER BY DESC(?mutualFriends)
LIMIT 10
```

```gsql
// GSQL: Deep link analytics (TigerGraph)
CREATE QUERY friends_of_friends(VERTEX<Person> me) FOR GRAPH social {
  SumAccum<INT> @mutual_count;
  start = {me};
  friends = SELECT f FROM start:s -(KNOWS:e)-> Person:f;
  foaf = SELECT f FROM friends:s -(KNOWS:e)-> Person:f
         WHERE f != me AND NOT f IN friends
         ACCUM f.@mutual_count += 1
         ORDER BY f.@mutual_count DESC
         LIMIT 10;
  PRINT foaf;
}
```

## Comparison Table

| Database | Language | Model | Scale | Managed | Best For |
|---|---|---|---|---|---|
| Neo4j | Cypher | Property Graph | Clustered | Aura | General purpose, knowledge graphs, GenAI |
| Neptune | Gremlin/SPARQL | Property Graph + RDF | Managed | AWS | AWS-native, multi-model graph |
| Dgraph | DQL/GraphQL | Property Graph | Distributed | Dgraph Cloud | GraphQL-native, distributed |
| JanusGraph | Gremlin | Property Graph | Distributed | Self-hosted | Pluggable backends, open-source |
| TigerGraph | GSQL | Property Graph | Distributed | TigerGraph Cloud | Deep link analytics, enterprise |
| ArangoDB | AQL | Multi-model | Distributed | ArangoGraph | Document + Graph + KV (cross-ref) |
| Memgraph | Cypher | Property Graph | Single + HA | Memgraph Cloud | In-memory, streaming, real-time |
| TypeDB | TypeQL | Conceptual | Distributed | Vaticle Cloud | Knowledge representation, type inference |
| Apache AGE | openCypher | Property Graph | PostgreSQL-based | Self-hosted | Hybrid relational + graph |
| NebulaGraph | nGQL | Property Graph | Distributed | NebulaGraph Cloud | Large-scale, storage-compute separation |
| Blazegraph | SPARQL | RDF | Single/Cluster | Self-hosted | RDF triplestore, Wikidata |
| Stardog | SPARQL | RDF + Property Graph | Clustered | Stardog Cloud | Enterprise knowledge graph, reasoning |

## Neo4j (Primary)

### Core Capabilities
- Native graph storage with index-free adjacency
- Cypher declarative query language (openCypher standard)
- APOC: 450+ procedures and functions library
- Graph Data Science: 65+ algorithms (centrality, community, similarity, pathfinding, embeddings, ML)
- Vector indexes for GenAI/RAG integration
- Aura managed service (AuraDB, AuraDS)

### Index Types
```cypher
-- Range index (B-tree, general purpose)
CREATE INDEX person_name FOR (p:Person) ON (p.name);

-- Composite index
CREATE INDEX person_name_age FOR (p:Person) ON (p.name, p.age);

-- Text index (full-text search on single property)
CREATE TEXT INDEX person_bio FOR (p:Person) ON (p.bio);

-- Full-text index (Lucene, across multiple properties)
CREATE FULLTEXT INDEX person_search FOR (p:Person) ON EACH [p.name, p.bio, p.email];
CALL db.index.fulltext.queryNodes('person_search', 'data engineer') YIELD node, score;

-- Point index (geospatial)
CREATE POINT INDEX location_idx FOR (p:Place) ON (p.location);

-- Vector index (GenAI embeddings)
CREATE VECTOR INDEX embedding_idx FOR (d:Document) ON (d.embedding)
OPTIONS {indexConfig: {`vector.dimensions`: 1536, `vector.similarity_function`: 'cosine'}};

-- Token lookup index (label/type lookup)
CREATE LOOKUP INDEX node_label_lookup FOR (n) ON EACH labels(n);
CREATE LOOKUP INDEX rel_type_lookup FOR ()-[r]-() ON EACH type(r);
```

### Key Patterns
```cypher
-- MERGE (create if not exists, update if exists)
MERGE (p:Person {id: 'alice'})
ON CREATE SET p.name = 'Alice', p.created = datetime()
ON MATCH SET p.lastSeen = datetime();

-- Variable-length path (shortest path)
MATCH path = shortestPath((a:Person {name:'Alice'})-[:KNOWS*..6]-(b:Person {name:'Bob'}))
RETURN path, length(path);

-- Weighted shortest path (Dijkstra)
MATCH (a:City {name:'London'}), (b:City {name:'Paris'})
CALL apoc.algo.dijkstra(a, b, 'ROAD', 'distance') YIELD path, weight
RETURN path, weight;

-- Recommendation engine
MATCH (user:User {id: $userId})-[:PURCHASED]->(product)<-[:PURCHASED]-(other)
      -[:PURCHASED]->(rec:Product)
WHERE NOT (user)-[:PURCHASED]->(rec)
RETURN rec.name, count(other) AS score
ORDER BY score DESC LIMIT 10;

-- Fraud ring detection
MATCH (a:Account)-[:TRANSFER]->(b:Account)-[:TRANSFER]->(c:Account)-[:TRANSFER]->(a)
WHERE a <> b AND b <> c AND a <> c
RETURN a, b, c;
```

**For deep Neo4j reference, see [reference-neo4j.md](reference-neo4j.md)**

## Amazon Neptune

### Architecture
- Fully managed graph database on AWS
- Supports both property graph (Gremlin/openCypher) and RDF (SPARQL)
- Up to 15 read replicas, storage auto-scales to 128 TiB
- Neptune Serverless: auto-scaling compute

### Neptune Analytics
- In-memory graph analytics engine
- Run algorithms (PageRank, connected components) on Neptune data
- Vector similarity search
- No infrastructure management

### Neptune ML
- ML predictions on graph data using GNNs
- Integration with SageMaker for training
- Node classification, link prediction, node regression

### Query Examples
```groovy
// Gremlin: Create and query
g.addV('Person').property('name', 'Alice').property('age', 30)
g.addV('Person').property('name', 'Bob').property('age', 25)
g.V().has('Person', 'name', 'Alice').addE('KNOWS').to(g.V().has('Person', 'name', 'Bob'))

g.V().has('Person', 'name', 'Alice')
  .out('KNOWS')
  .values('name')

// openCypher (Neptune)
MATCH (a:Person {name: 'Alice'})-[:KNOWS]->(b)
RETURN b.name
```

```sparql
# SPARQL: RDF query
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?name WHERE {
  <http://example.org/Alice> foaf:knows ?person .
  ?person foaf:name ?name .
}
```

### Operations
```bash
# Neptune loader (bulk load from S3)
curl -X POST https://neptune-endpoint:8182/loader \
  -H 'Content-Type: application/json' \
  -d '{
    "source": "s3://bucket/data/",
    "format": "csv",
    "iamRoleArn": "arn:aws:iam::role/NeptuneLoadRole",
    "region": "us-east-1",
    "failOnError": "FALSE"
  }'

# Neptune Streams (CDC)
curl https://neptune-endpoint:8182/propertygraph/stream?commitNum=1
```

## Dgraph

### Architecture
- Distributed graph database with native GraphQL support
- DQL (Dgraph Query Language): graph-first query language
- Badger: custom LSM-tree KV store (written in Go)
- Horizontal sharding: predicates (edge types) distributed across groups

### Query Examples
```graphql
# GraphQL schema
type Person {
  name: String! @search(by: [term])
  age: Int @search
  friends: [Person] @hasInverse(field: friends)
}

# DQL query (Dgraph native)
{
  alice(func: eq(name, "Alice")) {
    name
    age
    friends {
      name
      friends {
        name
      }
    }
  }
}

# DQL mutation
{
  set {
    _:alice <name> "Alice" .
    _:alice <dgraph.type> "Person" .
    _:alice <age> "30"^^<xs:int> .
    _:alice <friends> _:bob .
    _:bob <name> "Bob" .
    _:bob <dgraph.type> "Person" .
  }
}
```

### ACL and Multi-Tenancy
```bash
# Dgraph ACL (Enterprise)
dgraph acl add -u user1 -p password --group devs
dgraph acl mod -u user1 --group devs --pred name --perm 7  # rwx

# Multi-tenancy (namespaces)
# Each namespace has isolated data and schema
# Namespace 0 = guardian (admin)
```

## JanusGraph

### Architecture
- Open-source distributed graph database
- Pluggable storage: Apache Cassandra, HBase, Google Bigtable, BerkeleyDB
- Pluggable indexing: Elasticsearch, Solr, Lucene
- Gremlin query language (TinkerPop)

### Configuration
```properties
# janusgraph.properties
storage.backend=cql
storage.hostname=cassandra1,cassandra2,cassandra3
storage.cql.keyspace=janusgraph

index.search.backend=elasticsearch
index.search.hostname=es1:9200
index.search.index-name=janusgraph

cache.db-cache=true
cache.db-cache-size=0.5
cache.db-cache-time=180000

# Schema management
schema.default=none   # Require explicit schema (production)
```

### Schema and Queries
```groovy
// Schema definition
mgmt = graph.openManagement()
person = mgmt.makeVertexLabel('Person').make()
name = mgmt.makePropertyKey('name').dataType(String.class).make()
knows = mgmt.makeEdgeLabel('KNOWS').multiplicity(MULTI).make()
mgmt.buildIndex('personByName', Vertex.class).addKey(name).buildCompositeIndex()
mgmt.commit()

// Mixed index (Elasticsearch backend)
mgmt.buildIndex('personSearch', Vertex.class)
  .addKey(name, Mapping.TEXT.asParameter())
  .addKey(age)
  .buildMixedIndex('search')

// Gremlin traversal
g.V().has('Person', 'name', textContains('Alice'))
  .outE('KNOWS').has('since', gt(2020))
  .inV().values('name')
```

## TigerGraph

### Architecture
- Distributed, massively parallel graph database
- GSQL: SQL-like query language with accumulators for graph analytics
- Deep link analytics: efficient 10+ hop traversals
- Real-time graph analytics and in-database ML

### GSQL Examples
```gsql
// Schema definition
CREATE VERTEX Person (PRIMARY_ID id STRING, name STRING, age INT)
CREATE UNDIRECTED EDGE KNOWS (FROM Person, TO Person, since DATETIME)
CREATE GRAPH social (Person, KNOWS)

// Installed query (compiled, fast)
CREATE QUERY pagerank(INT max_iter = 10, FLOAT damping = 0.85) FOR GRAPH social {
  SumAccum<FLOAT> @received_score;
  SumAccum<FLOAT> @score = 1.0;

  all_v = {Person.*};
  FOREACH i IN RANGE[1, max_iter] DO
    all_v = SELECT v FROM all_v:v -(KNOWS:e)-> Person:t
            ACCUM t.@received_score += v.@score / v.outdegree()
            POST-ACCUM v.@score = (1 - damping) + damping * v.@received_score,
                       v.@received_score = 0;
  END;
  PRINT all_v[all_v.@score];
}
```

## Memgraph

### Key Features
- In-memory graph database (Cypher compatible)
- MAGE: Memgraph Advanced Graph Extensions (graph algorithms)
- Streaming integration: Kafka, Pulsar (real-time graph updates)
- Triggers: execute queries on data changes
- On-disk storage for durability (WAL + snapshots)

### Streaming Integration
```cypher
// Create Kafka stream consumer
CREATE KAFKA STREAM order_events
  TOPICS orders
  TRANSFORM module.transform_order
  BOOTSTRAP_SERVERS 'kafka:9092';

START STREAM order_events;

// Trigger on node creation
CREATE TRIGGER new_customer
ON () CREATE AFTER COMMIT
EXECUTE CALL module.process_new_customer(createdVertices);
```

### MAGE Algorithms
```cypher
// PageRank
CALL pagerank.get() YIELD node, rank
RETURN node.name, rank ORDER BY rank DESC LIMIT 10;

// Community detection (Louvain)
CALL community_detection.get() YIELD node, community_id
RETURN community_id, collect(node.name) ORDER BY size(collect(node.name)) DESC;

// Betweenness centrality
CALL betweenness_centrality.get() YIELD node, betweenness_centrality
RETURN node.name, betweenness_centrality ORDER BY betweenness_centrality DESC;
```

## TypeDB / Vaticle

### Conceptual Modeling
```typeql
// TypeQL schema (conceptual, not property graph)
define

person sub entity,
  owns name,
  owns age,
  plays friendship:friend,
  plays employment:employee;

company sub entity,
  owns name,
  plays employment:employer;

friendship sub relation,
  relates friend;

employment sub relation,
  relates employee,
  relates employer,
  owns start-date;

name sub attribute, value string;
age sub attribute, value long;
start-date sub attribute, value datetime;

// Type inference rules
rule transitive-friendship:
  when {
    (friend: $a, friend: $b) isa friendship;
    (friend: $b, friend: $c) isa friendship;
    not { $a is $c; };
  } then {
    (friend: $a, friend: $c) isa friendship;
  };
```

### Query
```typeql
// Find employees and their companies
match
  $p isa person, has name $name;
  $c isa company, has name $company;
  (employee: $p, employer: $c) isa employment;
get $name, $company;
```

## Apache AGE (PostgreSQL Extension)

### Hybrid Relational + Graph
```sql
-- Install AGE extension
CREATE EXTENSION age;
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- Create graph
SELECT create_graph('social');

-- openCypher queries via SQL
SELECT * FROM cypher('social', $$
  CREATE (a:Person {name: 'Alice', age: 30})
  CREATE (b:Person {name: 'Bob', age: 25})
  CREATE (a)-[:KNOWS {since: 2020}]->(b)
  RETURN a, b
$$) as (a agtype, b agtype);

-- Query combining SQL and Cypher
SELECT p.name, p.department, friends.friend_name
FROM employees p
JOIN LATERAL (
  SELECT * FROM cypher('social', $$
    MATCH (a:Person {name: $name})-[:KNOWS]->(f)
    RETURN f.name AS friend_name
  $$, params => jsonb_build_object('name', p.name)) as (friend_name agtype)
) friends ON true;
```

## NebulaGraph

### Architecture
- Distributed graph database with storage-compute separation
- GraphD (query), MetaD (metadata), StorageD (data)
- nGQL query language (openCypher-compatible subset)
- Horizontal scaling of storage and compute independently

```ngql
// nGQL queries
CREATE SPACE social(vid_type=FIXED_STRING(30), partition_num=10, replica_factor=3);
USE social;

CREATE TAG Person(name string, age int);
CREATE EDGE KNOWS(since datetime);

INSERT VERTEX Person(name, age) VALUES "alice":("Alice", 30);
INSERT VERTEX Person(name, age) VALUES "bob":("Bob", 25);
INSERT EDGE KNOWS(since) VALUES "alice" -> "bob":(datetime("2020-01-01"));

GO FROM "alice" OVER KNOWS YIELD dst(edge) AS friend |
  FETCH PROP ON Person $-.friend YIELD properties(vertex).name AS name;
```

## Blazegraph

### RDF Triplestore
- High-performance RDF store with SPARQL 1.1 support
- Powers Wikidata Query Service
- Supports named graphs, full-text search, GeoSPARQL
- Inference: RDFS, OWL Lite

## Stardog

### Enterprise Knowledge Graph
- RDF + property graph support
- Virtual graphs: query external databases (RDBMS, CSV, JSON) as graph without ETL
- Reasoning: OWL 2 inference, SWRL rules, integrity constraint validation
- Stardog Studio: visual graph exploration and query building

```sparql
# Virtual graph (query RDBMS as graph)
PREFIX : <http://example.org/>
SELECT ?name ?dept WHERE {
  GRAPH <virtual://hr_database> {
    ?emp :name ?name ;
         :department ?dept .
  }
}
```

## Graph Modeling Patterns

### Entity Resolution / Identity Graph
```
(:Person {name: "Alice Smith"})
  -[:HAS_EMAIL]->(:Email {address: "alice@work.com"})
  -[:HAS_PHONE]->(:Phone {number: "+1-555-1234"})
  -[:HAS_ADDRESS]->(:Address {street: "123 Main St"})
  -[:SAME_AS]->(:Person {name: "A. Smith"})  // Resolved identity
```

### Fraud Detection (Ring Detection)
```cypher
// Detect cyclic money transfers
MATCH path = (a:Account)-[:TRANSFER*3..6]->(a)
WHERE ALL(r IN relationships(path) WHERE r.amount > 10000)
  AND ALL(r IN relationships(path) WHERE r.timestamp > datetime() - duration('P7D'))
RETURN path;
```

### Knowledge Graph (RAG Pattern)
```cypher
// Store document chunks with embeddings
CREATE (d:Document {title: "Architecture Guide"})
CREATE (c:Chunk {text: "...", embedding: $vector})
CREATE (d)-[:HAS_CHUNK {position: 0}]->(c)
CREATE (c)-[:MENTIONS]->(e:Entity {name: "Microservices", type: "Concept"})

// Hybrid retrieval: vector + graph context
CALL db.index.vector.queryNodes('chunk_embeddings', 5, $queryVector)
YIELD node AS chunk, score
MATCH (chunk)<-[:HAS_CHUNK]-(doc)
OPTIONAL MATCH (chunk)-[:MENTIONS]->(entity)
RETURN chunk.text, doc.title, collect(entity.name) AS entities, score
ORDER BY score DESC;
```

## Use Cases Matrix

| Use Case | Best Fit | Why |
|---|---|---|
| Social network | Neo4j, TigerGraph | Relationship traversals, friend recommendations |
| Knowledge graph | Neo4j, Stardog, TypeDB | Schema flexibility, reasoning, inference |
| Fraud detection | TigerGraph, Neo4j | Deep link analytics, real-time pattern matching |
| Recommendation | Neo4j, Neptune | Collaborative filtering via graph traversals |
| Identity resolution | Neo4j, TigerGraph | Entity linking, deduplication |
| Network/IT ops | NebulaGraph, Neo4j | Topology analysis, impact analysis |
| Master data management | Stardog, Neo4j | Data integration, virtual graphs |
| Real-time analytics | Memgraph, TigerGraph | Streaming integration, in-memory |
| Semantic web / linked data | Blazegraph, Stardog, Neptune | RDF, SPARQL, W3C standards |
| Hybrid relational+graph | Apache AGE, ArangoDB | Existing PostgreSQL, multi-model |
| GenAI / RAG | Neo4j, Neptune | Vector indexes, knowledge graph grounding |
| IoT / device graph | NebulaGraph, Neptune | Scale, time-series edges |

For detailed Neo4j reference, see [reference-neo4j.md](reference-neo4j.md).
