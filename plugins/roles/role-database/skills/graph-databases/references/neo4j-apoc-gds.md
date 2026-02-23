# Neo4j — APOC Library and Graph Data Science (GDS)

## When to load
Load when using APOC for data import/export, batch processing, node merging, or running GDS algorithms (centrality, community detection, similarity, pathfinding, node embeddings, link prediction).

## APOC — Data Import / Export

```cypher
-- Load JSON from URL or file
CALL apoc.load.json('https://api.example.com/users') YIELD value
CREATE (u:User {id: value.id, name: value.name});

-- Load CSV
CALL apoc.load.csv('file:///data.csv', {header: true, sep: ','}) YIELD map
CREATE (p:Person {name: map.name, age: toInteger(map.age)});

-- Export subgraph to Cypher statements
CALL apoc.export.cypher.query(
  'MATCH (p:Person)-[r:KNOWS]->(f) RETURN p, r, f', 'output.cypher', {});
```

## APOC — Batch Processing

```cypher
-- Periodic iterate (batch with parallelism)
CALL apoc.periodic.iterate(
  'MATCH (p:Person) WHERE p.needsUpdate = true RETURN p',
  'SET p.status = "processed", p.needsUpdate = false',
  {batchSize: 1000, parallel: true, concurrency: 4}
);

-- Periodic commit (auto-commit every N ops)
CALL apoc.periodic.commit(
  'MATCH (p:Person) WHERE p.migrated IS NULL WITH p LIMIT $limit
   SET p.migrated = true RETURN count(*)', {limit: 10000}
);
```

## APOC — Utilities

```cypher
RETURN apoc.create.uuid() AS uuid;
RETURN apoc.text.levenshteinDistance('graph', 'grahp') AS distance;
CALL apoc.meta.schema() YIELD value RETURN value;
CALL apoc.meta.stats() YIELD nodeCount, relCount, labelCount;

-- Triggers
CALL apoc.trigger.add('update-timestamp',
  'UNWIND $createdNodes AS n SET n.created = timestamp()', {phase: 'after'});
```

## GDS — Graph Projection

```cypher
CALL gds.graph.project('social', 'Person', 'KNOWS',
  { nodeProperties: ['age', 'score'], relationshipProperties: ['weight'] });

-- Cypher projection for filtered graphs
CALL gds.graph.project.cypher('social_filtered',
  'MATCH (p:Person) WHERE p.active = true RETURN id(p) AS id, p.age AS age',
  'MATCH (a:Person)-[r:KNOWS]->(b:Person) WHERE r.since > date("2020-01-01")
   RETURN id(a) AS source, id(b) AS target, r.weight AS weight');

CALL gds.graph.list() YIELD graphName, nodeCount, relationshipCount;
CALL gds.graph.drop('social');
```

## GDS — Centrality

```cypher
CALL gds.pageRank.stream('social', {maxIterations: 20, dampingFactor: 0.85})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score ORDER BY score DESC LIMIT 10;

CALL gds.betweennessCentrality.stream('social')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name, score ORDER BY score DESC LIMIT 10;

CALL gds.degree.stream('social') YIELD nodeId, score RETURN gds.util.asNode(nodeId).name, score;
```

## GDS — Community Detection

```cypher
CALL gds.louvain.stream('social') YIELD nodeId, communityId
RETURN communityId, collect(gds.util.asNode(nodeId).name) AS members ORDER BY size(members) DESC;

CALL gds.labelPropagation.stream('social') YIELD nodeId, communityId
RETURN communityId, count(*) AS size ORDER BY size DESC;

CALL gds.wcc.stream('social') YIELD nodeId, componentId
RETURN componentId, count(*) AS size ORDER BY size DESC;

CALL gds.triangleCount.stream('social') YIELD nodeId, triangleCount
RETURN gds.util.asNode(nodeId).name, triangleCount;
```

## GDS — Similarity and Pathfinding

```cypher
CALL gds.nodeSimilarity.stream('social', {topK: 5})
YIELD node1, node2, similarity
RETURN gds.util.asNode(node1).name, gds.util.asNode(node2).name, similarity ORDER BY similarity DESC;

CALL gds.shortestPath.dijkstra.stream('social', {
  sourceNode: startNodeId, targetNode: endNodeId, relationshipWeightProperty: 'weight'
}) YIELD path, totalCost
RETURN [n IN nodes(path) | n.name] AS route, totalCost;

CALL gds.shortestPath.astar.stream('roads', {
  sourceNode: startId, targetNode: endId,
  latitudeProperty: 'latitude', longitudeProperty: 'longitude',
  relationshipWeightProperty: 'distance'
});
```

## GDS — Node Embeddings

```cypher
CALL gds.fastRP.stream('social', {embeddingDimension: 128, iterationWeights: [0.0, 1.0, 1.0, 1.0]})
YIELD nodeId, embedding RETURN gds.util.asNode(nodeId).name, embedding;

CALL gds.node2vec.stream('social', {embeddingDimension: 64, walkLength: 80, walksPerNode: 10})
YIELD nodeId, embedding;
```
