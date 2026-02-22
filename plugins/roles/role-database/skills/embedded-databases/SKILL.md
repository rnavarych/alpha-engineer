---
name: embedded-databases
description: |
  Deep operational guide for 12 embedded databases. SQLite (PRAGMA, WAL, FTS5, multi-threaded), RocksDB (LSM-tree, compaction, column families), LevelDB, LMDB, BoltDB/bbolt, BadgerDB, Realm, ObjectBox, libSQL, H2, HSQLDB. Use when selecting or configuring embedded databases for mobile apps, desktop applications, edge computing, or as storage engines.
allowed-tools: Read, Grep, Glob, Bash
---

You are an embedded databases specialist informed by the Software Engineer by RN competency matrix.

## Embedded Database Comparison

| Database | Language | Storage Engine | ACID | Best For |
|----------|---------|---------------|------|----------|
| SQLite | C | B-tree | Yes | General-purpose embedded SQL, mobile |
| RocksDB | C++ | LSM-tree | Yes | High write throughput, storage engine |
| LevelDB | C++ | LSM-tree | No (crash-safe) | Simple ordered KV, lightweight |
| LMDB | C | B+tree (mmap) | Yes | Read-heavy, zero-copy, low latency |
| BoltDB/bbolt | Go | B+tree (COW) | Yes | Go apps, etcd, low-write workloads |
| BadgerDB | Go | LSM + value log | Yes | Go apps, high write throughput |
| Realm | C++ (core) | MVCC object store | Yes | Mobile apps (iOS/Android), live objects |
| ObjectBox | C++ (core) | Custom B+tree | Yes | Mobile/edge, IoT, Dart/Flutter |
| libSQL | C | B-tree (SQLite fork) | Yes | Server-capable SQLite, edge replicas |
| DuckDB | C++ | Columnar | Yes | Analytics, OLAP (see data-warehouse-olap) |
| H2 | Java | B-tree / page store | Yes | Java testing, Spring Boot embedded |
| HSQLDB | Java | B-tree / cached | Yes | Java embedded SQL, standards compliance |

## When-to-Use Decision Framework

```
Need SQL queries?
  ├── Yes
  │   ├── Mobile app? → Realm (live objects) or SQLite
  │   ├── Java/Spring testing? → H2 (in-memory)
  │   ├── OLAP/analytics? → DuckDB (see data-warehouse-olap)
  │   ├── Edge/server mode? → libSQL (Turso)
  │   └── General embedded? → SQLite (default choice)
  └── No (key-value)
      ├── Write-heavy?
      │   ├── Go? → BadgerDB
      │   └── C++? → RocksDB
      ├── Read-heavy?
      │   ├── Zero-copy needed? → LMDB
      │   └── Go? → BoltDB/bbolt
      ├── Used as storage engine? → RocksDB (CockroachDB, TiKV, Pebble)
      └── IoT/Flutter? → ObjectBox
```

## SQLite

### PRAGMA Tuning

```sql
-- Essential PRAGMAs for production use
PRAGMA journal_mode = WAL;          -- Write-Ahead Log (concurrent reads + writes)
PRAGMA synchronous = NORMAL;        -- balance durability and performance
PRAGMA busy_timeout = 5000;         -- wait 5s for locks instead of failing
PRAGMA cache_size = -64000;         -- 64MB page cache (negative = KB)
PRAGMA foreign_keys = ON;           -- enforce FK constraints (off by default!)
PRAGMA auto_vacuum = INCREMENTAL;   -- reclaim space without full vacuum
PRAGMA temp_store = MEMORY;         -- temp tables in memory
PRAGMA mmap_size = 268435456;       -- memory-map 256MB of database file
PRAGMA page_size = 4096;            -- 4KB pages (must set before creating DB)

-- WAL mode tuning
PRAGMA wal_autocheckpoint = 1000;   -- checkpoint after 1000 pages
PRAGMA wal_checkpoint(TRUNCATE);    -- manual checkpoint and truncate WAL

-- Analysis for query optimizer
ANALYZE;                            -- update statistics for query planner
PRAGMA optimize;                    -- auto-analyze tables that need it (3.18+)
```

### WAL Mode Deep Dive

```
WAL (Write-Ahead Log) Mode:
- Writes go to WAL file, not directly to database
- Readers see consistent snapshot (MVCC-like)
- Multiple concurrent readers + single writer
- Checkpoints transfer WAL changes to database

Trade-offs:
+ Concurrent reads during writes
+ Faster writes (sequential WAL appends)
+ Crash recovery is faster
- WAL file can grow large under heavy writes
- Not suitable for network filesystems (NFS)
- Requires shared memory (-shm file)
```

```bash
# Check WAL file size
ls -la mydb.db mydb.db-wal mydb.db-shm

# Force checkpoint (shrink WAL)
sqlite3 mydb.db "PRAGMA wal_checkpoint(TRUNCATE);"
```

### FTS5 (Full-Text Search)

```sql
-- Create FTS5 virtual table
CREATE VIRTUAL TABLE articles_fts USING fts5(
    title,
    body,
    tags,
    content='articles',          -- external content table
    content_rowid='id',
    tokenize='porter unicode61'  -- Porter stemming + Unicode
);

-- Populate FTS index
INSERT INTO articles_fts(articles_fts) VALUES('rebuild');

-- Triggers to keep FTS in sync with content table
CREATE TRIGGER articles_ai AFTER INSERT ON articles BEGIN
    INSERT INTO articles_fts(rowid, title, body, tags)
    VALUES (new.id, new.title, new.body, new.tags);
END;
CREATE TRIGGER articles_ad AFTER DELETE ON articles BEGIN
    INSERT INTO articles_fts(articles_fts, rowid, title, body, tags)
    VALUES ('delete', old.id, old.title, old.body, old.tags);
END;
CREATE TRIGGER articles_au AFTER UPDATE ON articles BEGIN
    INSERT INTO articles_fts(articles_fts, rowid, title, body, tags)
    VALUES ('delete', old.id, old.title, old.body, old.tags);
    INSERT INTO articles_fts(rowid, title, body, tags)
    VALUES (new.id, new.title, new.body, new.tags);
END;

-- Search queries
SELECT * FROM articles_fts WHERE articles_fts MATCH 'database AND optimization';
SELECT * FROM articles_fts WHERE articles_fts MATCH 'title:sqlite OR body:embedded';
SELECT *, rank FROM articles_fts WHERE articles_fts MATCH 'streaming' ORDER BY rank;

-- Phrase search and NEAR queries
SELECT * FROM articles_fts WHERE articles_fts MATCH '"exact phrase"';
SELECT * FROM articles_fts WHERE articles_fts MATCH 'NEAR(kafka streaming, 5)';

-- Highlight and snippet
SELECT highlight(articles_fts, 1, '<b>', '</b>') FROM articles_fts WHERE articles_fts MATCH 'query';
SELECT snippet(articles_fts, 1, '<b>', '</b>', '...', 20) FROM articles_fts WHERE articles_fts MATCH 'query';
```

### JSON1, R*Tree, and Strict Tables

```sql
-- JSON1 extension (built-in since 3.38)
CREATE TABLE events (
    id INTEGER PRIMARY KEY,
    data TEXT NOT NULL  -- JSON stored as text
);

SELECT json_extract(data, '$.user.name') AS user_name,
       json_extract(data, '$.amount') AS amount
FROM events
WHERE json_extract(data, '$.type') = 'purchase';

-- JSON path operators (3.38+)
SELECT data->>'$.user.name' AS user_name FROM events;  -- text extraction
SELECT data->'$.items' AS items FROM events;             -- JSON extraction

-- Generated columns for JSON indexing
ALTER TABLE events ADD COLUMN event_type TEXT
    GENERATED ALWAYS AS (json_extract(data, '$.type')) STORED;
CREATE INDEX idx_event_type ON events(event_type);

-- R*Tree extension (spatial indexing)
CREATE VIRTUAL TABLE locations USING rtree(
    id,
    min_lat, max_lat,
    min_lon, max_lon
);

-- Find locations within bounding box
SELECT * FROM locations
WHERE min_lat >= 40.0 AND max_lat <= 41.0
  AND min_lon >= -74.5 AND max_lon <= -73.5;

-- Strict tables (3.37+): enforce column types
CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL
) STRICT;
-- Type affinity is strictly enforced (no silent type coercion)
```

### Multi-Threaded Modes

```c
// SQLite threading modes:
// 1. Single-thread: SQLITE_THREADSAFE=0 (fastest, no mutex)
// 2. Multi-thread: SQLITE_THREADSAFE=2 (no connection sharing between threads)
// 3. Serialized: SQLITE_THREADSAFE=1 (default, full mutex protection)

// Recommended pattern: WAL mode + connection per thread
sqlite3_config(SQLITE_CONFIG_MULTITHREAD);  // multi-thread mode

// Or per-connection
sqlite3_open_v2("mydb.db", &db,
    SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX, NULL);
```

```python
# Python: connection per thread with WAL
import sqlite3
import threading

def worker(db_path):
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    # ... use connection ...
    conn.close()

# Connection pool pattern
from queue import Queue

class SQLitePool:
    def __init__(self, db_path, pool_size=5):
        self.pool = Queue(maxsize=pool_size)
        for _ in range(pool_size):
            conn = sqlite3.connect(db_path, check_same_thread=False)
            conn.execute("PRAGMA journal_mode=WAL")
            conn.execute("PRAGMA synchronous=NORMAL")
            conn.execute("PRAGMA busy_timeout=5000")
            self.pool.put(conn)

    def get(self):
        return self.pool.get()

    def put(self, conn):
        self.pool.put(conn)
```

## RocksDB

### LSM-Tree Architecture and Compaction

```
Write Path:
  Write -> MemTable (in-memory sorted) -> Immutable MemTable -> SST files (L0)
           |
           v
  WAL (Write-Ahead Log) for crash recovery

Compaction (background merging of SST files):
  L0 (unsorted, overlapping) -> L1 (sorted, non-overlapping) -> L2 -> ... -> Ln

Compaction Styles:
  - Level (default): L0 -> L1 -> L2, size-ratio between levels
  - Universal: merge similar-sized files, lower write amplification
  - FIFO: time-based expiry, no merging (time-series/cache)
```

```cpp
#include <rocksdb/db.h>
#include <rocksdb/options.h>

// RocksDB configuration for write-heavy workload
rocksdb::Options options;
options.create_if_missing = true;
options.IncreaseParallelism(4);
options.OptimizeLevelStyleCompaction();

// Write buffer (MemTable) tuning
options.write_buffer_size = 128 * 1024 * 1024;      // 128MB per memtable
options.max_write_buffer_number = 4;                  // 4 memtables in memory
options.min_write_buffer_number_to_merge = 2;         // merge 2 before flush

// Compaction tuning
options.level0_file_num_compaction_trigger = 4;       // trigger L0->L1 at 4 files
options.level0_slowdown_writes_trigger = 20;          // slow down writes
options.level0_stop_writes_trigger = 36;              // stop writes (write stall!)
options.max_bytes_for_level_base = 512 * 1024 * 1024; // 512MB L1 size
options.target_file_size_base = 64 * 1024 * 1024;     // 64MB per SST file

// Block cache (read performance)
auto cache = rocksdb::NewLRUCache(1 * 1024 * 1024 * 1024); // 1GB
rocksdb::BlockBasedTableOptions table_options;
table_options.block_cache = cache;
table_options.block_size = 16 * 1024;                  // 16KB blocks
table_options.filter_policy.reset(rocksdb::NewBloomFilterPolicy(10)); // Bloom filter
options.table_factory.reset(rocksdb::NewBlockBasedTableFactory(table_options));

// Compression
options.compression = rocksdb::kLZ4Compression;
options.bottommost_compression = rocksdb::kZSTD;  // ZSTD for cold data

rocksdb::DB* db;
rocksdb::Status status = rocksdb::DB::Open(options, "/path/to/db", &db);
```

### Column Families and Write Stalls

```cpp
// Column families: logical partitions within one DB
// Each CF has its own MemTable, SST files, and compaction settings
std::vector<rocksdb::ColumnFamilyDescriptor> cf_descs;
cf_descs.push_back({"default", rocksdb::ColumnFamilyOptions()});
cf_descs.push_back({"metadata", metadata_options});    // small, read-heavy
cf_descs.push_back({"events", events_options});         // large, write-heavy

std::vector<rocksdb::ColumnFamilyHandle*> handles;
rocksdb::DB* db;
rocksdb::DB::Open(options, "/path/to/db", cf_descs, &handles, &db);

// Write to specific column family
db->Put(write_options, handles[1], "key", "value");  // metadata CF

// Write stall diagnostics
// Check LOG file for: "Stalling writes", "Stopping writes"
// Common causes:
// 1. L0 files exceed level0_slowdown_writes_trigger
// 2. Too many pending compaction bytes
// 3. MemTable count exceeds max_write_buffer_number
// Fix: increase compaction parallelism, increase L0 triggers, use faster storage
```

### Statistics and Monitoring

```cpp
// Enable statistics
options.statistics = rocksdb::CreateDBStatistics();

// After running workload, check stats
std::string stats;
db->GetProperty("rocksdb.stats", &stats);
std::cout << stats << std::endl;

// Key metrics to monitor:
// - rocksdb.compaction.times.micros: compaction duration
// - rocksdb.stall.micros: total write stall time
// - rocksdb.block.cache.hit/miss: cache hit rate
// - rocksdb.num-running-compactions: active compaction threads
// - rocksdb.estimate-pending-compaction-bytes: compaction backlog
```

## LevelDB

```go
// LevelDB: lightweight, ordered key-value store by Google
import "github.com/syndtr/goleveldb/leveldb"

db, err := leveldb.OpenFile("/path/to/db", nil)
defer db.Close()

// Basic operations
db.Put([]byte("key"), []byte("value"), nil)
data, _ := db.Get([]byte("key"), nil)
db.Delete([]byte("key"), nil)

// Ordered iteration (keys are sorted)
iter := db.NewIterator(nil, nil)
for iter.Next() {
    key := iter.Key()
    value := iter.Value()
    fmt.Printf("%s: %s\n", key, value)
}
iter.Release()

// Range scan
iter := db.NewIterator(&util.Range{Start: []byte("a"), Limit: []byte("z")}, nil)

// Batch writes (atomic)
batch := new(leveldb.Batch)
batch.Put([]byte("key1"), []byte("value1"))
batch.Put([]byte("key2"), []byte("value2"))
batch.Delete([]byte("old-key"))
db.Write(batch, nil)
```

## LMDB

### Memory-Mapped B+Tree

```c
// LMDB: Lightning Memory-Mapped Database
// - Zero-copy reads (direct pointer to mapped memory)
// - Copy-on-write B+tree (no write amplification)
// - Readers never block writers, writers never block readers
// - Single writer at a time (no write contention)

#include <lmdb.h>

MDB_env *env;
mdb_env_create(&env);
mdb_env_set_mapsize(env, 1024UL * 1024 * 1024 * 10); // 10GB max size
mdb_env_set_maxdbs(env, 10);  // named databases within environment
mdb_env_open(env, "/path/to/db", MDB_NORDAHEAD, 0664);

// Read transaction (zero-copy, no memory allocation)
MDB_txn *txn;
MDB_dbi dbi;
mdb_txn_begin(env, NULL, MDB_RDONLY, &txn);
mdb_dbi_open(txn, "mydb", 0, &dbi);

MDB_val key = {3, "foo"};
MDB_val data;
mdb_get(txn, dbi, &key, &data);
// data.mv_data points directly to mapped memory (zero-copy!)
printf("Value: %.*s\n", (int)data.mv_size, (char*)data.mv_data);
mdb_txn_abort(txn);  // read-only, just release

// Write transaction
mdb_txn_begin(env, NULL, 0, &txn);
MDB_val value = {5, "hello"};
mdb_put(txn, dbi, &key, &value, 0);
mdb_txn_commit(txn);

// Cursor iteration (ordered traversal)
MDB_cursor *cursor;
mdb_cursor_open(txn, dbi, &cursor);
while (mdb_cursor_get(cursor, &key, &data, MDB_NEXT) == 0) {
    // process key-value pair
}
mdb_cursor_close(cursor);
```

## BoltDB / bbolt

```go
// bbolt: pure Go B+tree key-value database
// Used by etcd for metadata storage
// Copy-on-write, ACID, single-writer

import "go.etcd.io/bbolt"

db, err := bbolt.Open("my.db", 0600, &bbolt.Options{Timeout: 1 * time.Second})
defer db.Close()

// Read-write transaction
db.Update(func(tx *bbolt.Tx) error {
    bucket, _ := tx.CreateBucketIfNotExists([]byte("users"))
    return bucket.Put([]byte("user:123"), []byte(`{"name":"Alice"}`))
})

// Read-only transaction
db.View(func(tx *bbolt.Tx) error {
    bucket := tx.Bucket([]byte("users"))
    v := bucket.Get([]byte("user:123"))
    fmt.Println(string(v))
    return nil
})

// Cursor for range scans
db.View(func(tx *bbolt.Tx) error {
    c := tx.Bucket([]byte("users")).Cursor()
    prefix := []byte("user:")
    for k, v := c.Seek(prefix); k != nil && bytes.HasPrefix(k, prefix); k, v = c.Next() {
        fmt.Printf("key=%s, value=%s\n", k, v)
    }
    return nil
})

// Nested buckets
db.Update(func(tx *bbolt.Tx) error {
    root, _ := tx.CreateBucketIfNotExists([]byte("tenants"))
    tenant, _ := root.CreateBucketIfNotExists([]byte("tenant-a"))
    return tenant.Put([]byte("setting:theme"), []byte("dark"))
})
```

## BadgerDB

```go
// BadgerDB: fast Go key-value store (used by Dgraph)
// LSM-tree with value log separation (SSD-optimized)
import "github.com/dgraph-io/badger/v4"

opts := badger.DefaultOptions("/path/to/db").
    WithValueLogFileSize(256 << 20).    // 256MB value log files
    WithNumCompactors(4).               // parallel compaction
    WithBlockCacheSize(256 << 20).      // 256MB block cache
    WithCompression(options.ZSTD)

db, err := badger.Open(opts)
defer db.Close()

// Write transaction
db.Update(func(txn *badger.Txn) error {
    entry := badger.NewEntry([]byte("key"), []byte("value")).WithTTL(24 * time.Hour)
    return txn.SetEntry(entry)
})

// Read transaction
db.View(func(txn *badger.Txn) error {
    item, err := txn.Get([]byte("key"))
    if err != nil { return err }
    return item.Value(func(val []byte) error {
        fmt.Println(string(val))
        return nil
    })
})

// Prefix iteration
db.View(func(txn *badger.Txn) error {
    opts := badger.DefaultIteratorOptions
    opts.Prefix = []byte("user:")
    it := txn.NewIterator(opts)
    defer it.Close()
    for it.Rewind(); it.Valid(); it.Next() {
        item := it.Item()
        fmt.Printf("key=%s\n", item.Key())
    }
    return nil
})

// Garbage collection (reclaim value log space)
ticker := time.NewTicker(5 * time.Minute)
for range ticker.C {
    for db.RunValueLogGC(0.5) == nil {} // compact until < 50% waste
}
```

## Realm

### Mobile-First Object Database

```swift
// Swift (iOS)
import RealmSwift

class Order: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var customerName: String
    @Persisted var amount: Double
    @Persisted var status: String = "pending"
    @Persisted var items: List<OrderItem>  // to-many relationship
    @Persisted var createdAt: Date = Date()
}

// Open Realm
let config = Realm.Configuration(schemaVersion: 2, migrationBlock: { migration, oldVersion in
    if oldVersion < 2 { /* migration logic */ }
})
let realm = try! Realm(configuration: config)

// Write transaction
try! realm.write {
    let order = Order()
    order.customerName = "Alice"
    order.amount = 99.99
    realm.add(order)
}

// Live objects: auto-update when data changes
let orders = realm.objects(Order.self).filter("status == 'pending'").sorted(byKeyPath: "createdAt")
let token = orders.observe { changes in
    switch changes {
    case .update(_, let deletions, let insertions, let modifications):
        // UI updates here (e.g., tableView.performBatchUpdates)
        break
    default: break
    }
}

// Atlas Device Sync (cloud sync)
let app = App(id: "myapp-xxxxx")
let user = try await app.login(credentials: .anonymous)
let config = user.flexibleSyncConfiguration { subs in
    subs.append(QuerySubscription<Order>(name: "my-orders") {
        $0.customerName == user.id
    })
}
let realm = try await Realm(configuration: config)
```

## ObjectBox

```dart
// Dart/Flutter
import 'package:objectbox/objectbox.dart';

@Entity()
class Order {
  @Id()
  int id = 0;

  String customerName;
  double amount;
  String status;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  // Embedded vector for similarity search
  @HnswIndex(dimensions: 128, distanceType: VectorDistanceType.cosine)
  Float32List? embedding;

  Order(this.customerName, this.amount, {this.status = 'pending', DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
}

// Usage
final store = await openStore();
final box = store.box<Order>();

// Put
final order = Order('Alice', 99.99);
box.put(order);

// Query
final pending = box.query(Order_.status.equals('pending'))
    .order(Order_.createdAt, flags: Order.descending)
    .build()
    .find();

// Vector similarity search (embedded)
final similar = box.query(Order_.embedding.nearestNeighborsF32(queryVector, 10))
    .build()
    .find();
```

## libSQL (Turso's SQLite Fork)

```bash
# libSQL: SQLite fork with server mode, HTTP API, and vector search
# Install Turso CLI
curl -sSfL https://get.tur.so/install.sh | bash

# Create database (local or cloud)
turso db create my-app
turso db shell my-app

# Embedded replicas (sync from primary to local SQLite file)
turso db create my-app --group default
```

```typescript
// TypeScript with @libsql/client
import { createClient } from '@libsql/client';

// Embedded replica (local reads, sync from remote)
const client = createClient({
  url: 'file:local.db',
  syncUrl: 'libsql://my-app-user.turso.io',
  authToken: 'eyJ...',
  syncInterval: 60,  // sync every 60 seconds
});

await client.sync();  // manual sync

// Standard SQL
await client.execute('INSERT INTO orders (customer, amount) VALUES (?, ?)', ['Alice', 99.99]);
const result = await client.execute('SELECT * FROM orders WHERE amount > ?', [50]);

// Vector search (libSQL extension)
await client.execute(`
  CREATE TABLE documents (
    id INTEGER PRIMARY KEY,
    content TEXT,
    embedding F32_BLOB(384)
  )
`);

await client.execute(`
  CREATE INDEX documents_idx ON documents (
    libsql_vector_idx(embedding, 'metric=cosine')
  )
`);

const similar = await client.execute(`
  SELECT id, content, vector_distance_cos(embedding, vector(?)) AS distance
  FROM vector_top_k('documents_idx', vector(?), 10)
  JOIN documents ON documents.rowid = id
`, [queryEmbedding, queryEmbedding]);
```

## H2 Database

```java
// H2: Java embedded SQL database (widely used for Spring Boot testing)
import java.sql.*;

// In-memory mode (fastest, data lost on close)
Connection conn = DriverManager.getConnection("jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1");

// File mode (persistent)
Connection conn = DriverManager.getConnection("jdbc:h2:file:./data/mydb");

// PostgreSQL compatibility mode (for testing PG-specific SQL)
Connection conn = DriverManager.getConnection("jdbc:h2:mem:testdb;MODE=PostgreSQL");

// Spring Boot test configuration (application-test.yml)
// spring:
//   datasource:
//     url: jdbc:h2:mem:testdb;MODE=PostgreSQL
//     driver-class-name: org.h2.Driver
//   jpa:
//     hibernate:
//       ddl-auto: create-drop
//   h2:
//     console:
//       enabled: true  # access at /h2-console
```

## HSQLDB

```java
// HSQLDB: Java embedded SQL with strong SQL standard compliance
// Modes: in-memory, file, server (hybrid)

// In-memory
Connection conn = DriverManager.getConnection("jdbc:hsqldb:mem:testdb", "SA", "");

// File-based
Connection conn = DriverManager.getConnection("jdbc:hsqldb:file:/path/to/db;shutdown=true");

// HSQLDB supports:
// - Full SQL:2016 standard compliance
// - Stored procedures in Java
// - Triggers
// - MVCC isolation
// - Text tables (CSV files as tables)

// Text table (query CSV directly)
Statement stmt = conn.createStatement();
stmt.execute("CREATE TEXT TABLE csv_data (id INT, name VARCHAR(100), amount DECIMAL(10,2))");
stmt.execute("SET TABLE csv_data SOURCE 'data.csv;fs=,;ignore_first=true'");
// Now query CSV as SQL: SELECT * FROM csv_data WHERE amount > 100
```

## Operational Best Practices

### SQLite Production Checklist

1. Enable WAL mode (`PRAGMA journal_mode=WAL`)
2. Set busy timeout (`PRAGMA busy_timeout=5000`)
3. Enable foreign keys (`PRAGMA foreign_keys=ON`)
4. Use `PRAGMA synchronous=NORMAL` (not OFF in production)
5. Set appropriate cache size based on working set
6. Run `PRAGMA optimize` periodically
7. Backup with `.backup` command or `VACUUM INTO` (safe online backup)
8. Monitor database size and WAL file growth
9. Use parameterized queries (prevent SQL injection)
10. Use strict tables (SQLite 3.37+) for type safety

### RocksDB Production Checklist

1. Tune write buffer size based on write throughput
2. Configure compaction style (Level for balanced, Universal for write-heavy)
3. Set appropriate block cache size (typically 30-50% of available RAM)
4. Enable Bloom filters for point lookups
5. Use column families to separate hot and cold data
6. Monitor write stalls and compaction pending bytes
7. Configure compression per level (LZ4 for hot, ZSTD for cold)
8. Set rate limiter to prevent I/O spikes during compaction
9. Backup with `CreateCheckpoint()` (consistent snapshot)
10. Enable statistics for monitoring

### Backup Strategies

```bash
# SQLite: online backup
sqlite3 mydb.db ".backup backup.db"
# Or atomic copy with VACUUM INTO (3.27+)
sqlite3 mydb.db "VACUUM INTO 'backup.db';"

# RocksDB: checkpoint (hard links, instant)
# In code: db->CreateCheckpoint("/path/to/checkpoint")

# BoltDB/bbolt: safe copy during read transaction
db.View(func(tx *bbolt.Tx) error {
    return tx.CopyFile("/path/to/backup.db", 0600)
})

# LMDB: copy environment
mdb_env_copy2(env, "/path/to/backup", MDB_CP_COMPACT);
```

For cross-references, see:
- DuckDB details in the data-warehouse-olap skill
- libSQL/Turso details in the serverless-databases skill
