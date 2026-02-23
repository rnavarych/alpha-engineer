# Application-Level Pooling and Pool Sizing

## When to load
Load when configuring connection pools inside Node.js, Python, Java, or Go applications, detecting and preventing connection leaks, or calculating the correct pool size for a given server.

## Application-Level Pooling

### Node.js — node-postgres (pg)
```typescript
import { Pool } from 'pg';

const pool = new Pool({
    host: 'localhost',
    port: 5432,
    database: 'mydb',
    user: 'app',
    password: 'secret',
    max: 20,                       // max connections in pool
    idleTimeoutMillis: 30000,      // close idle connections after 30s
    connectionTimeoutMillis: 5000, // timeout waiting for connection
});

const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
```

### Node.js — Prisma
```typescript
// Configure via connection string parameters
// DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10"

// Prisma Accelerate for serverless
// DATABASE_URL="prisma://accelerate.prisma-data.net/?api_key=..."
```

### Python — SQLAlchemy
```python
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://user:pass@host:5432/db",
    pool_size=20,            # persistent connections
    max_overflow=10,         # temporary extra connections
    pool_timeout=30,         # wait for available connection
    pool_recycle=1800,       # recycle connections after 30 min
    pool_pre_ping=True,      # verify connection before use
)
```

### Java — HikariCP
```java
HikariConfig config = new HikariConfig();
config.setJdbcUrl("jdbc:postgresql://host:5432/db");
config.setUsername("app");
config.setPassword("secret");

config.setMaximumPoolSize(20);
config.setMinimumIdle(5);

config.setConnectionTimeout(30000);      // 30s wait for connection
config.setIdleTimeout(600000);           // 10min idle before close
config.setMaxLifetime(1800000);          // 30min max connection lifetime
config.setLeakDetectionThreshold(60000); // warn if connection held > 60s

HikariDataSource ds = new HikariDataSource(config);
```

### Go — database/sql
```go
db, err := sql.Open("postgres", "postgresql://user:pass@host:5432/db?sslmode=require")

db.SetMaxOpenConns(20)
db.SetMaxIdleConns(5)
db.SetConnMaxLifetime(30 * time.Minute)
db.SetConnMaxIdleTime(5 * time.Minute)
```

## Pool Sizing Formula

```
Optimal pool size = (core_count * 2) + effective_spindle_count

For SSD: spindle_count ≈ 1
For HDD: spindle_count = number of disk spindles

Example (8-core, SSD):
  Pool size = (8 * 2) + 1 = 17 ≈ 20 (round up)

Total connections across app instances:
  max_connections = pool_size × instances + admin_reserve
  Example: 20 × 5 + 10 = 110
```

## Connection Leak Detection and Prevention

### Detect Leaks
```sql
-- PostgreSQL: long-idle connections
SELECT pid, usename, application_name, state, query,
       age(clock_timestamp(), state_change) AS idle_duration
FROM pg_stat_activity
WHERE state = 'idle' AND age(clock_timestamp(), state_change) > interval '5 minutes';

-- MySQL: sleeping connections
SELECT id, user, host, db, command, time, state
FROM information_schema.processlist
WHERE command = 'Sleep' AND time > 300;
```

### Prevention Checklist
1. Always use try/finally or using/with to return connections
2. Set connection timeouts in pool configuration
3. Enable leak detection (HikariCP leakDetectionThreshold, PgBouncer server_idle_timeout)
4. Monitor pool metrics: active, idle, waiting counts
5. Kill long-idle connections: PgBouncer client_idle_timeout, MySQL wait_timeout
