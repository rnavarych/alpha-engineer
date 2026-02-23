# SQLite

## When to load
Load when configuring SQLite for production use: PRAGMA tuning, WAL mode, FTS5 full-text search, JSON1/R*Tree/strict tables, multi-threaded access patterns, connection pooling.

## PRAGMA Tuning

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;
PRAGMA cache_size = -64000;        -- 64MB page cache (negative = KB)
PRAGMA foreign_keys = ON;
PRAGMA auto_vacuum = INCREMENTAL;
PRAGMA temp_store = MEMORY;
PRAGMA mmap_size = 268435456;      -- memory-map 256MB
PRAGMA page_size = 4096;           -- must set before creating DB

PRAGMA wal_autocheckpoint = 1000;
PRAGMA wal_checkpoint(TRUNCATE);
ANALYZE;
PRAGMA optimize;
```

## WAL Mode

```
WAL (Write-Ahead Log) Mode:
- Writes go to WAL file, not directly to database
- Multiple concurrent readers + single writer
- Checkpoints transfer WAL changes to database

+ Concurrent reads during writes
+ Faster writes (sequential WAL appends)
- WAL file can grow under heavy writes
- Not suitable for NFS
```

```bash
ls -la mydb.db mydb.db-wal mydb.db-shm
sqlite3 mydb.db "PRAGMA wal_checkpoint(TRUNCATE);"
```

## FTS5 Full-Text Search

```sql
CREATE VIRTUAL TABLE articles_fts USING fts5(
    title, body, tags,
    content='articles', content_rowid='id',
    tokenize='porter unicode61'
);
INSERT INTO articles_fts(articles_fts) VALUES('rebuild');

CREATE TRIGGER articles_ai AFTER INSERT ON articles BEGIN
    INSERT INTO articles_fts(rowid, title, body, tags)
    VALUES (new.id, new.title, new.body, new.tags);
END;
CREATE TRIGGER articles_ad AFTER DELETE ON articles BEGIN
    INSERT INTO articles_fts(articles_fts, rowid, title, body, tags)
    VALUES ('delete', old.id, old.title, old.body, old.tags);
END;

SELECT * FROM articles_fts WHERE articles_fts MATCH 'database AND optimization';
SELECT *, rank FROM articles_fts WHERE articles_fts MATCH 'streaming' ORDER BY rank;
SELECT snippet(articles_fts, 1, '<b>', '</b>', '...', 20) FROM articles_fts WHERE articles_fts MATCH 'query';
```

## JSON1, R*Tree, and Strict Tables

```sql
-- Generated column for JSON indexing
ALTER TABLE events ADD COLUMN event_type TEXT
    GENERATED ALWAYS AS (json_extract(data, '$.type')) STORED;
CREATE INDEX idx_event_type ON events(event_type);

-- JSON path operators (3.38+)
SELECT data->>'$.user.name' AS user_name FROM events;

-- R*Tree (spatial)
CREATE VIRTUAL TABLE locations USING rtree(id, min_lat, max_lat, min_lon, max_lon);
SELECT * FROM locations WHERE min_lat >= 40.0 AND max_lat <= 41.0 AND min_lon >= -74.5 AND max_lon <= -73.5;

-- Strict tables (3.37+)
CREATE TABLE orders (
    id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL,
    amount REAL NOT NULL, status TEXT NOT NULL
) STRICT;
```

## Multi-Threaded Access

```c
sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
sqlite3_open_v2("mydb.db", &db,
    SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX, NULL);
```

```python
class SQLitePool:
    def __init__(self, db_path, pool_size=5):
        self.pool = Queue(maxsize=pool_size)
        for _ in range(pool_size):
            conn = sqlite3.connect(db_path, check_same_thread=False)
            conn.execute("PRAGMA journal_mode=WAL")
            conn.execute("PRAGMA synchronous=NORMAL")
            conn.execute("PRAGMA busy_timeout=5000")
            self.pool.put(conn)
```

## Production Checklist

1. Enable WAL mode (`PRAGMA journal_mode=WAL`)
2. Set busy timeout (`PRAGMA busy_timeout=5000`)
3. Enable foreign keys (`PRAGMA foreign_keys=ON`)
4. Use `PRAGMA synchronous=NORMAL` (not OFF)
5. Run `PRAGMA optimize` periodically
6. Backup with `VACUUM INTO 'backup.db'` (safe online backup)
7. Use parameterized queries (prevent SQL injection)
8. Use strict tables (SQLite 3.37+) for type safety
