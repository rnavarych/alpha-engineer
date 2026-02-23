# LMDB, BoltDB/bbolt, and BadgerDB

## When to load
Load when choosing between mmap B+tree (LMDB), Go copy-on-write B+tree (bbolt/BoltDB), or Go LSM+value-log (BadgerDB) for embedded key-value storage.

## LMDB — Memory-Mapped B+Tree

```c
// Zero-copy reads, MVCC-like concurrency, single writer
#include <lmdb.h>

MDB_env *env;
mdb_env_create(&env);
mdb_env_set_mapsize(env, 1024UL * 1024 * 1024 * 10); // 10GB max
mdb_env_set_maxdbs(env, 10);
mdb_env_open(env, "/path/to/db", MDB_NORDAHEAD, 0664);

// Read transaction (zero-copy: data.mv_data points to mapped memory)
MDB_txn *txn; MDB_dbi dbi;
mdb_txn_begin(env, NULL, MDB_RDONLY, &txn);
mdb_dbi_open(txn, "mydb", 0, &dbi);
MDB_val key = {3, "foo"}, data;
mdb_get(txn, dbi, &key, &data);
mdb_txn_abort(txn);

// Write transaction
mdb_txn_begin(env, NULL, 0, &txn);
MDB_val value = {5, "hello"};
mdb_put(txn, dbi, &key, &value, 0);
mdb_txn_commit(txn);

// Cursor iteration
MDB_cursor *cursor;
mdb_cursor_open(txn, dbi, &cursor);
while (mdb_cursor_get(cursor, &key, &data, MDB_NEXT) == 0) { /* process */ }
mdb_cursor_close(cursor);
```

**Use LMDB when**: zero-copy reads matter, read-heavy workload, predictable memory-mapped access pattern.

## BoltDB / bbolt

```go
// Pure Go B+tree, copy-on-write, ACID, single writer
// Used by etcd for metadata
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
    v := tx.Bucket([]byte("users")).Get([]byte("user:123"))
    fmt.Println(string(v))
    return nil
})

// Prefix cursor scan
db.View(func(tx *bbolt.Tx) error {
    c := tx.Bucket([]byte("users")).Cursor()
    prefix := []byte("user:")
    for k, v := c.Seek(prefix); k != nil && bytes.HasPrefix(k, prefix); k, v = c.Next() {
        fmt.Printf("key=%s, value=%s\n", k, v)
    }
    return nil
})

```

**Use BoltDB when**: Go app, low-write workload, need nested namespacing, etcd-style metadata.

## BadgerDB

```go
// Go LSM + value log separation (SSD-optimized), used by Dgraph
import "github.com/dgraph-io/badger/v4"

opts := badger.DefaultOptions("/path/to/db").
    WithValueLogFileSize(256 << 20).
    WithNumCompactors(4).
    WithBlockCacheSize(256 << 20).
    WithCompression(options.ZSTD)
db, err := badger.Open(opts)
defer db.Close()

// Write with TTL
db.Update(func(txn *badger.Txn) error {
    entry := badger.NewEntry([]byte("key"), []byte("value")).WithTTL(24 * time.Hour)
    return txn.SetEntry(entry)
})

// Read
db.View(func(txn *badger.Txn) error {
    item, _ := txn.Get([]byte("key"))
    return item.Value(func(val []byte) error { fmt.Println(string(val)); return nil })
})

// Prefix iteration
db.View(func(txn *badger.Txn) error {
    opts := badger.DefaultIteratorOptions
    opts.Prefix = []byte("user:")
    it := txn.NewIterator(opts)
    defer it.Close()
    for it.Rewind(); it.Valid(); it.Next() { fmt.Printf("key=%s\n", it.Item().Key()) }
    return nil
})

// GC: reclaim value log space (run every 5 minutes)
for db.RunValueLogGC(0.5) == nil {}
```

**Use BadgerDB when**: Go app, high write throughput, large values, TTL needed.
