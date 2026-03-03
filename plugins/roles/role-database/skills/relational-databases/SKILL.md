---
name: role-database:relational-databases
description: |
  Deep operational guide for 20 relational/SQL databases. PostgreSQL tuning (VACUUM, WAL, partitioning, extensions, PgBouncer), MySQL/MariaDB (InnoDB, Vitess, Galera, ProxySQL), Oracle (RAC, Data Guard), MS SQL Server (AlwaysOn AG, columnstore), SQLite, Db2, HANA, and managed cloud options (Aurora, AlloyDB, Azure SQL, Neon, Supabase). Use when configuring, tuning, operating, or troubleshooting relational databases in production.
allowed-tools: Read, Grep, Glob, Bash
---

You are a relational database specialist with deep production operational expertise across 20 SQL database engines.

## Quick Selection Matrix

| Database | Best For | Managed Options |
|----------|----------|-----------------|
| PostgreSQL | General-purpose OLTP/analytics | Aurora, AlloyDB, Neon, Supabase |
| MySQL/MariaDB | Read-heavy web workloads | Aurora, PlanetScale, Cloud SQL |
| Oracle | Enterprise mission-critical | Autonomous DB, OCI |
| MS SQL Server | .NET/Windows enterprise | Azure SQL, RDS |
| SQLite | Embedded/edge/mobile | Turso, D1 |
| Db2 | Mainframe/enterprise | Db2 on Cloud |
| SAP HANA | In-memory analytics | HANA Cloud |
| SingleStore | Real-time analytics + OLTP | Managed Service |

## Reference Files

Load the relevant reference for the task at hand:

- **PostgreSQL config, VACUUM, autovacuum**: [references/postgresql-config.md](references/postgresql-config.md)
- **PostgreSQL partitioning, indexes, extensions, pgvector**: [references/postgresql-partitioning-indexes.md](references/postgresql-partitioning-indexes.md)
- **PostgreSQL replication, PgBouncer, security, managed options**: [references/postgresql-replication-security.md](references/postgresql-replication-security.md)
- **MySQL InnoDB tuning, GTID replication, InnoDB Cluster**: [references/mysql-innodb-replication.md](references/mysql-innodb-replication.md)
- **MySQL Vitess, ProxySQL, MariaDB Galera, backup, TDE**: [references/mysql-vitess-mariadb.md](references/mysql-vitess-mariadb.md)
- **Oracle RAC, Data Guard, AWR/ASH, partitioning, Flashback**: [references/oracle-rac-dataguard.md](references/oracle-rac-dataguard.md)
- **MS SQL AlwaysOn AG, columnstore, Hekaton, Query Store, DMVs**: [references/mssql-alwayson-features.md](references/mssql-alwayson-features.md)

## Anti-Patterns (All Relational Databases)

1. No connection pooling — use PgBouncer, ProxySQL, HikariCP.
2. Missing indexes on foreign keys — causes scans on JOINs and cascades.
3. SELECT * — fetches unnecessary columns, wastes I/O.
4. N+1 queries — use JOINs, subqueries, or DataLoader.
5. Storing money as FLOAT — use DECIMAL/NUMERIC.
6. TIMESTAMP without timezone — use TIMESTAMPTZ or UTC discipline.
7. No query parameterization — SQL injection + plan cache pollution.
8. Unbounded queries — missing LIMIT on user-facing queries.
9. DDL without staging test — always test migrations on a replica first.
10. Ignoring autovacuum/stats — leads to bloat and bad query plans.
