# RocksDB and LevelDB

## When to load
Load when working with LSM-tree embedded stores: RocksDB compaction tuning, column families, write stalls, statistics monitoring; LevelDB basic operations and iteration.

## RocksDB LSM-Tree Architecture

```
Write Path:
  Write -> MemTable (in-memory sorted) -> Immutable MemTable -> SST files (L0)
           |
           v WAL (Write-Ahead Log) for crash recovery

Compaction Styles:
  Level (default): L0->L1->L2, size-ratio between levels
  Universal: merge similar-sized files, lower write amplification
  FIFO: time-based expiry (time-series/cache workloads)
```

## RocksDB Configuration

```cpp
#include <rocksdb/db.h>

rocksdb::Options options;
options.create_if_missing = true;
options.IncreaseParallelism(4);
options.OptimizeLevelStyleCompaction();

// MemTable tuning
options.write_buffer_size = 128 * 1024 * 1024;
options.max_write_buffer_number = 4;
options.min_write_buffer_number_to_merge = 2;

// Compaction thresholds
options.level0_file_num_compaction_trigger = 4;
options.level0_slowdown_writes_trigger = 20;
options.level0_stop_writes_trigger = 36;        // write stall!
options.max_bytes_for_level_base = 512 * 1024 * 1024;

// Block cache + Bloom filter
auto cache = rocksdb::NewLRUCache(1 * 1024 * 1024 * 1024); // 1GB
rocksdb::BlockBasedTableOptions table_options;
table_options.block_cache = cache;
table_options.filter_policy.reset(rocksdb::NewBloomFilterPolicy(10));
options.table_factory.reset(rocksdb::NewBlockBasedTableFactory(table_options));

// Compression per level
options.compression = rocksdb::kLZ4Compression;
options.bottommost_compression = rocksdb::kZSTD;
```

## Column Families and Write Stalls

```cpp
std::vector<rocksdb::ColumnFamilyDescriptor> cf_descs;
cf_descs.push_back({"default", rocksdb::ColumnFamilyOptions()});
cf_descs.push_back({"metadata", metadata_options});  // small, read-heavy
cf_descs.push_back({"events", events_options});       // large, write-heavy

std::vector<rocksdb::ColumnFamilyHandle*> handles;
rocksdb::DB* db;
rocksdb::DB::Open(options, "/path/to/db", cf_descs, &handles, &db);
db->Put(write_options, handles[1], "key", "value");

// Write stall causes (check LOG file for "Stalling writes"):
// 1. L0 files exceed level0_slowdown_writes_trigger
// 2. Too many pending compaction bytes
// 3. MemTable count exceeds max_write_buffer_number
// Fix: increase compaction parallelism, use faster storage
```

## RocksDB Monitoring

```cpp
options.statistics = rocksdb::CreateDBStatistics();

std::string stats;
db->GetProperty("rocksdb.stats", &stats);
// Key metrics:
// rocksdb.stall.micros: total write stall time
// rocksdb.block.cache.hit/miss: cache hit rate
// rocksdb.estimate-pending-compaction-bytes: compaction backlog
```

## Production Checklist

1. Tune write buffer size based on write throughput
2. Use column families to separate hot and cold data
3. Set block cache size (typically 30-50% of available RAM)
4. Enable Bloom filters for point lookups
5. Monitor write stalls and pending compaction bytes
6. Configure compression: LZ4 hot levels, ZSTD cold
7. Backup with `CreateCheckpoint()` (consistent snapshot)

## LevelDB

```go
import "github.com/syndtr/goleveldb/leveldb"

db, err := leveldb.OpenFile("/path/to/db", nil)
defer db.Close()

db.Put([]byte("key"), []byte("value"), nil)
data, _ := db.Get([]byte("key"), nil)

// Ordered iteration (keys are sorted)
iter := db.NewIterator(nil, nil)
for iter.Next() { fmt.Printf("%s: %s\n", iter.Key(), iter.Value()) }
iter.Release()

// Range scan
iter = db.NewIterator(&util.Range{Start: []byte("a"), Limit: []byte("z")}, nil)

// Atomic batch writes
batch := new(leveldb.Batch)
batch.Put([]byte("key1"), []byte("value1"))
batch.Delete([]byte("old-key"))
db.Write(batch, nil)
```
