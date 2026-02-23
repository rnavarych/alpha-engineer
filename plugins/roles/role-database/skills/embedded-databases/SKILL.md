---
name: embedded-databases
description: |
  Deep operational guide for 12 embedded databases. SQLite (PRAGMA, WAL, FTS5, multi-threaded), RocksDB (LSM-tree, compaction, column families), LevelDB, LMDB, BoltDB/bbolt, BadgerDB, Realm, ObjectBox, libSQL, H2, HSQLDB. Use when selecting or configuring embedded databases for mobile apps, desktop applications, edge computing, or as storage engines.
allowed-tools: Read, Grep, Glob, Bash
---

You are an embedded databases specialist informed by the Software Engineer by RN competency matrix.

## When to Use This Skill

Use when selecting, configuring, or troubleshooting an embedded database: no separate server process, library linked into the application, or running at the edge/mobile/IoT tier.

## Selection Decision Tree

```
Need SQL queries?
  ├── Mobile app? → Realm (live objects) or SQLite
  ├── Java/Spring testing? → H2 (in-memory)
  ├── OLAP/analytics? → DuckDB (see data-warehouse-olap)
  ├── Edge/server mode? → libSQL (Turso)
  └── General embedded? → SQLite (default choice)
No (key-value)
  ├── Write-heavy?
  │   ├── Go? → BadgerDB
  │   └── C++? → RocksDB
  ├── Read-heavy / zero-copy? → LMDB
  ├── Go low-write? → BoltDB/bbolt
  ├── Storage engine for another DB? → RocksDB (CockroachDB, TiKV)
  └── IoT/Flutter? → ObjectBox
```

## Core Principles

- SQLite default choice for embedded SQL; WAL mode mandatory in production
- RocksDB for high write throughput; tune compaction before going to production
- LMDB for zero-copy read-heavy workloads; set mapsize generously upfront
- BoltDB for Go apps with nested namespacing; bad fit for write-heavy workloads
- BadgerDB for Go high-write; run value log GC on a schedule
- Realm/ObjectBox for mobile; use live objects and sync capabilities
- libSQL when you need SQLite + HTTP API + edge replicas + vector search

## Reference Files

Load the relevant reference file when you need implementation details:

- **references/sqlite.md** — PRAGMA tuning, WAL deep dive, FTS5, JSON1/R*Tree/strict tables, connection pooling, production checklist
- **references/rocksdb-leveldb.md** — LSM-tree architecture, compaction tuning, column families, write stall diagnosis, statistics, LevelDB operations
- **references/lmdb-bolt-badger.md** — LMDB zero-copy transactions, BoltDB buckets/cursors, BadgerDB TTL/GC/prefix iteration
- **references/realm-objectbox-libsql.md** — Realm Swift live objects + Atlas Sync, ObjectBox Dart + vector search, libSQL/Turso embedded replicas
- **references/java-embedded-backup.md** — H2 in-memory/PostgreSQL-compat, HSQLDB text tables, backup strategies for all engines
