---
name: role-database:graph-databases
description: |
  Deep operational guide for 12 graph databases. Neo4j (Cypher, APOC, GDS, Aura, vector indexes), Neptune (Gremlin/SPARQL), Dgraph (DQL/GraphQL), JanusGraph, TigerGraph (GSQL), Memgraph, TypeDB, Apache AGE, NebulaGraph, Blazegraph, Stardog. Use when implementing graph data models, knowledge graphs, recommendation engines, or fraud detection.
allowed-tools: Read, Grep, Glob, Bash
---

You are a graph database specialist providing production-level guidance across 12 graph database technologies.

## Selection Framework

1. **Query language**: Cypher (Neo4j, Memgraph, AGE), Gremlin (JanusGraph, Neptune), SPARQL (Neptune, Blazegraph, Stardog), GSQL (TigerGraph), DQL (Dgraph)
2. **Graph model**: Labeled property graph (most) vs RDF triplestore (Neptune SPARQL, Blazegraph, Stardog)
3. **Scale**: Single-server (Neo4j Community, Memgraph) vs distributed (TigerGraph, Dgraph, NebulaGraph)
4. **Deployment**: Managed (Aura, Neptune, TigerGraph Cloud) vs self-hosted (JanusGraph, Memgraph)

## Comparison Table

| Database | Language | Model | Scale | Best For |
|---|---|---|---|---|
| Neo4j | Cypher | Property Graph | Clustered | General purpose, knowledge graphs, GenAI |
| Neptune | Gremlin/SPARQL | Property Graph + RDF | Managed | AWS-native, multi-model graph |
| TigerGraph | GSQL | Property Graph | Distributed | Deep link analytics, enterprise |
| Memgraph | Cypher | Property Graph | Single + HA | In-memory, streaming, real-time |
| JanusGraph | Gremlin | Property Graph | Distributed | Pluggable backends, open-source |
| Dgraph | DQL/GraphQL | Property Graph | Distributed | GraphQL-native, distributed |
| Apache AGE | openCypher | Property Graph | PostgreSQL-based | Hybrid relational + graph |
| TypeDB | TypeQL | Conceptual | Distributed | Knowledge representation, type inference |
| Stardog | SPARQL | RDF + Property Graph | Clustered | Enterprise knowledge graph, reasoning |
| Blazegraph | SPARQL | RDF | Single/Cluster | RDF triplestore, Wikidata |

## Reference Files

Load the relevant reference for the task at hand:

- **Neo4j Cypher optimization, PROFILE/EXPLAIN, all index types (range/text/full-text/point/vector)**: [references/neo4j-cypher-indexes.md](references/neo4j-cypher-indexes.md)
- **Neo4j APOC library (import, batch, utilities) and GDS algorithms (centrality, community, pathfinding, embeddings)**: [references/neo4j-apoc-gds.md](references/neo4j-apoc-gds.md)
- **Neo4j operations: memory/JVM config, import, backup, RBAC, clustering, visualization**: [references/neo4j-operations.md](references/neo4j-operations.md)

## Graph Modeling Patterns

```cypher
-- Fraud ring detection (cyclic transfers)
MATCH path = (a:Account)-[:TRANSFER*3..6]->(a)
WHERE ALL(r IN relationships(path) WHERE r.amount > 10000)
RETURN path;

-- Recommendation engine (collaborative filtering)
MATCH (user:User {id: $userId})-[:PURCHASED]->(product)<-[:PURCHASED]-(other)
      -[:PURCHASED]->(rec:Product)
WHERE NOT (user)-[:PURCHASED]->(rec)
RETURN rec.name, count(other) AS score ORDER BY score DESC LIMIT 10;

-- Knowledge graph RAG
CALL db.index.vector.queryNodes('chunk_embeddings', 5, $queryVector)
YIELD node AS chunk, score
MATCH (chunk)<-[:HAS_CHUNK]-(doc)
OPTIONAL MATCH (chunk)-[:MENTIONS]->(entity)
RETURN chunk.text, doc.title, collect(entity.name) AS entities, score ORDER BY score DESC;
```

## Use Cases Matrix

| Use Case | Best Fit |
|---|---|
| Social network | Neo4j, TigerGraph |
| Knowledge graph | Neo4j, Stardog, TypeDB |
| Fraud detection | TigerGraph, Neo4j |
| Recommendation | Neo4j, Neptune |
| Real-time analytics | Memgraph, TigerGraph |
| Semantic web / RDF | Blazegraph, Stardog, Neptune |
| Hybrid relational+graph | Apache AGE, ArangoDB |
| GenAI / RAG | Neo4j, Neptune |
