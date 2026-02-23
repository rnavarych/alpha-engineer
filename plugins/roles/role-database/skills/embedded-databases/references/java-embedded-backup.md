# Java Embedded Databases and Backup Strategies

## When to load
Load when using H2 or HSQLDB for Java/Spring Boot testing or embedded SQL, or when implementing online backup strategies for any embedded database.

## H2 Database

```java
// H2: widely used for Spring Boot testing
import java.sql.*;

// In-memory (fastest, data lost on close)
Connection conn = DriverManager.getConnection("jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1");

// File mode (persistent)
Connection conn = DriverManager.getConnection("jdbc:h2:file:./data/mydb");

// PostgreSQL compatibility mode
Connection conn = DriverManager.getConnection("jdbc:h2:mem:testdb;MODE=PostgreSQL");
```

```yaml
# application-test.yml for Spring Boot
spring:
  datasource:
    url: jdbc:h2:mem:testdb;MODE=PostgreSQL
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
  h2:
    console:
      enabled: true  # access at /h2-console
```

**Use H2 when**: Java/Spring Boot testing, CI in-memory database, PG-compatible SQL validation.

## HSQLDB

```java
// HSQLDB: full SQL:2016 compliance, stored procedures in Java

// In-memory
Connection conn = DriverManager.getConnection("jdbc:hsqldb:mem:testdb", "SA", "");

// File-based
Connection conn = DriverManager.getConnection("jdbc:hsqldb:file:/path/to/db;shutdown=true");

// Text table (query CSV as SQL)
Statement stmt = conn.createStatement();
stmt.execute("CREATE TEXT TABLE csv_data (id INT, name VARCHAR(100), amount DECIMAL(10,2))");
stmt.execute("SET TABLE csv_data SOURCE 'data.csv;fs=,;ignore_first=true'");
// SELECT * FROM csv_data WHERE amount > 100
```

**HSQLDB features**: triggers, MVCC isolation, stored procedures in Java, text tables (CSV as SQL).

**Use HSQLDB when**: strict SQL standard compliance required, text tables for CSV queries.

## Backup Strategies

```bash
# SQLite: online backup
sqlite3 mydb.db ".backup backup.db"
# Atomic copy (3.27+)
sqlite3 mydb.db "VACUUM INTO 'backup.db';"
```

```go
// BoltDB/bbolt: safe copy inside read transaction
db.View(func(tx *bbolt.Tx) error {
    return tx.CopyFile("/path/to/backup.db", 0600)
})
```

```c
// LMDB: compact copy
mdb_env_copy2(env, "/path/to/backup", MDB_CP_COMPACT);
```

```cpp
// RocksDB: checkpoint (hard links, instant, consistent)
// In code: db->CreateCheckpoint("/path/to/checkpoint")
```

## Backup Strategy Summary

| Database | Method | Notes |
|----------|--------|-------|
| SQLite | `VACUUM INTO` | Safe online, atomic, 3.27+ |
| RocksDB | `CreateCheckpoint()` | Hard links, instant, consistent snapshot |
| LMDB | `mdb_env_copy2` | `MDB_CP_COMPACT` reduces size |
| BoltDB | `tx.CopyFile()` | Must run inside View transaction |
| BadgerDB | `db.Backup()` | Streaming backup to writer |
