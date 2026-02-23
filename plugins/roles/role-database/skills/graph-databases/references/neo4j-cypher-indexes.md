# Neo4j — Cypher Optimization and Index Types

## When to load
Load when tuning Cypher queries, reading PROFILE/EXPLAIN plans, avoiding eager operators, creating range/text/full-text/point/vector indexes, or managing index lifecycle.

## PROFILE and EXPLAIN

```cypher
EXPLAIN
MATCH (p:Person)-[:KNOWS]->(f:Person) WHERE p.name = 'Alice' RETURN f.name;

PROFILE
MATCH (p:Person)-[:KNOWS]->(f:Person) WHERE p.name = 'Alice' RETURN f.name;
-- Key metrics: Rows, DbHits, EstimatedRows, PageCacheHits/Misses
```

## Query Tuning Techniques

```cypher
-- 1. Use parameterized queries (plan caching)
MATCH (p:Person {name: $name}) RETURN p;

-- 2. Filter early (push predicates down)
MATCH (p:Person) WHERE p.age > 25
WITH p MATCH (p)-[:KNOWS*1..3]->(f) RETURN f;

-- 3. Index hints when planner chooses wrong index
MATCH (p:Person) USING INDEX p:Person(name) WHERE p.name = 'Alice' RETURN p;

-- 4. LIMIT pushdown
MATCH (p:Person)-[:KNOWS]->(f) RETURN f.name ORDER BY f.name LIMIT 10;

-- 5. UNWIND for batch creates
UNWIND $batch AS row CREATE (p:Person {name: row.name, age: row.age});

-- 6. Pattern comprehensions instead of OPTIONAL MATCH + collect
MATCH (p:Person) RETURN p.name, [(p)-[:KNOWS]->(f) | f.name] AS friends;

-- 7. CALL {} subquery to avoid Eager between MATCH and write
MATCH (p:Person)
CALL { WITH p CREATE (p)-[:TAGGED]->(:Tag {name: p.category}) }
IN TRANSACTIONS OF 1000 ROWS;
```

## Range Index (Default B-tree)

```cypher
CREATE INDEX person_name FOR (p:Person) ON (p.name);
CREATE INDEX person_name_age FOR (p:Person) ON (p.name, p.age);
CREATE INDEX knows_since FOR ()-[r:KNOWS]-() ON (r.since);
-- Supports: equality, range, prefix, IS NOT NULL
-- Composite: leftmost prefix queries only
```

## Text Index

```cypher
CREATE TEXT INDEX person_name_text FOR (p:Person) ON (p.name);
MATCH (p:Person) WHERE p.name CONTAINS 'ali' RETURN p;
MATCH (p:Person) WHERE p.name STARTS WITH 'Al' RETURN p;
```

## Full-Text Index (Lucene-backed)

```cypher
CREATE FULLTEXT INDEX article_search FOR (a:Article) ON EACH [a.title, a.body, a.abstract];

CALL db.index.fulltext.queryNodes('article_search', 'graph database performance')
YIELD node, score RETURN node.title, score ORDER BY score DESC LIMIT 20;

-- Lucene syntax: wildcards, fuzzy, boolean, phrase
CALL db.index.fulltext.queryNodes('article_search',
  'graph AND (database OR "knowledge graph")~2') YIELD node, score;
```

## Point Index (Geospatial)

```cypher
CREATE POINT INDEX location_idx FOR (p:Place) ON (p.location);
CREATE (p:Place {name: 'London', location: point({latitude: 51.5074, longitude: -0.1278})});

MATCH (p:Place)
WHERE point.distance(p.location, point({latitude: 51.5, longitude: -0.1})) < 10000
RETURN p.name ORDER BY point.distance(p.location, point({latitude: 51.5, longitude: -0.1}));
```

## Vector Index (GenAI / GraphRAG)

```cypher
CREATE VECTOR INDEX document_embeddings FOR (d:Document) ON (d.embedding)
OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } };

-- Similarity search
CALL db.index.vector.queryNodes('document_embeddings', 10, $queryVector)
YIELD node AS doc, score RETURN doc.title, doc.text, score ORDER BY score DESC;

-- Hybrid: vector + graph context
CALL db.index.vector.queryNodes('document_embeddings', 5, $queryVector)
YIELD node AS chunk, score
MATCH (chunk)-[:PART_OF]->(doc:Document)
MATCH (chunk)-[:MENTIONS]->(entity:Entity)
RETURN chunk.text, doc.title, collect(DISTINCT entity.name) AS entities, score ORDER BY score DESC;
```

## Index Management

```cypher
SHOW INDEXES YIELD name, type, labelsOrTypes, properties, state;
DROP INDEX person_name;
CREATE INDEX my_idx FOR (n:Node) ON (n.prop);
CALL db.awaitIndex('my_idx', 300);   -- Wait up to 300s for online

-- Lookup indexes (auto-created, used for label/type scans)
CREATE LOOKUP INDEX node_label_lookup FOR (n) ON EACH labels(n);
CREATE LOOKUP INDEX rel_type_lookup FOR ()-[r]-() ON EACH type(r);
```
