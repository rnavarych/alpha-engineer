# Neo4j — Operations, Performance, Backup, Security, Clustering, Visualization

## When to load
Load when configuring Neo4j memory/JVM settings, running neo4j-admin import/backup, setting up RBAC, configuring causal clustering or Fabric federated queries, or choosing visualization tools (Bloom, NeoDash).

## Memory Configuration

```
# neo4j.conf
server.memory.heap.initial_size=8g
server.memory.heap.max_size=8g
# Rule of thumb: heap = 1/4 of RAM (max 31g for compressed oops)

server.memory.pagecache.size=16g
# Rule of thumb: fit entire graph + indexes in page cache

db.memory.transaction.max=1g
db.memory.transaction.global_max_size=4g
```

## JVM Tuning

```
server.jvm.additional=-XX:+UseG1GC
server.jvm.additional=-XX:MaxGCPauseMillis=200
server.jvm.additional=-XX:+ParallelRefProcEnabled
server.jvm.additional=-XX:+AlwaysPreTouch
```

## Query Performance Monitoring

```cypher
CALL dbms.listQueries() YIELD queryId, username, query, elapsedTimeMillis
WHERE elapsedTimeMillis > 5000
RETURN queryId, username, query, elapsedTimeMillis;

CALL dbms.killQuery('query-id-here');

CALL db.stats.retrieve('GRAPH COUNTS');
CALL db.stats.collect('GRAPH COUNTS');
```

## Data Import

```cypher
-- LOAD CSV (built-in)
:auto LOAD CSV WITH HEADERS FROM 'file:///large_data.csv' AS row
CALL { WITH row MERGE (u:User {id: row.id}) SET u.name = row.name }
IN TRANSACTIONS OF 10000 ROWS;
```

```bash
# neo4j-admin import (bulk, fastest, offline)
neo4j-admin database import full \
  --nodes=Person=persons_header.csv,persons.csv \
  --nodes=Movie=movies_header.csv,movies.csv \
  --relationships=ACTED_IN=acted_in_header.csv,acted_in.csv \
  --overwrite-destination neo4j
# Header format: personId:ID(Person),name,:LABEL
# Relationship header: :START_ID(Person),role,:END_ID(Movie),:TYPE
```

## Backup and Restore

```bash
# Online backup (Enterprise)
neo4j-admin database backup neo4j --to-path=/backups/ --include-metadata=all

# Offline dump (Community/Enterprise)
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

## RBAC Security

```cypher
-- Built-in roles: admin, editor, publisher, reader, PUBLIC
CREATE ROLE analyst;
GRANT MATCH {*} ON GRAPH * NODE * TO analyst;
GRANT MATCH {*} ON GRAPH * RELATIONSHIP * TO analyst;
DENY WRITE ON GRAPH * TO analyst;

-- Property-level access
GRANT READ {name, email} ON GRAPH social NODE Person TO analyst;
DENY READ {ssn, salary} ON GRAPH social NODE Person TO analyst;

CREATE USER analyst1 SET PASSWORD 'secure123' CHANGE REQUIRED;
GRANT ROLE analyst TO analyst1;
SHOW USERS;
SHOW ROLES WITH USERS;
```

## Auth Providers

```
# LDAP
dbms.security.auth_providers=ldap
dbms.security.ldap.host=ldap://ldap.example.com
dbms.security.ldap.authorization.group_to_role_mapping=\
  "cn=admins,ou=groups,dc=example,dc=com" = admin

# OIDC (Enterprise)
dbms.security.auth_providers=oidc-okta
dbms.security.oidc.okta.issuer=https://dev-123456.okta.com/oauth2/default
```

## Causal Clustering

```
# Core server (minimum 3 for Raft consensus)
dbms.mode=CORE
causal_clustering.initial_discovery_members=core1:5000,core2:5000,core3:5000
causal_clustering.minimum_core_cluster_size_at_formation=3

# Read replica (async from cores, scale-out reads)
dbms.mode=READ_REPLICA
causal_clustering.initial_discovery_members=core1:5000,core2:5000,core3:5000
```

## Aura Managed Service

| Tier | Notes |
|------|-------|
| AuraDB Free | 200K nodes, 400K relationships, 1 database |
| AuraDB Professional | Auto-scaling, daily backups, 99.95% SLA |
| AuraDB Enterprise | Dedicated infra, private endpoints, SSO |
| AuraDS | Data science tier with GDS pre-installed |

## Visualization Tools

- **Neo4j Browser** — built-in at `http://localhost:7474`, Cypher editor, plan visualization
- **Neo4j Bloom** — business-friendly exploration, natural language search, scene sharing
- **NeoDash** — open-source dashboard builder; chart types: graph, table, bar, line, pie, map
- **Gephi / D3.js / vis.js** — custom desktop or web visualizations
