---
name: connection-management
description: |
  Connection pooling and management across all engines. PgBouncer (transaction/session/statement mode), pgcat (Rust-based, load balancing, sharding), ProxySQL (MySQL query routing, caching), HikariCP (Java), application-level pooling (Prisma, SQLAlchemy, GORM, database/sql). Serverless connection strategies (Prisma Accelerate, RDS Proxy, Neon pooler). Connection limits, pool sizing, leak detection. Use when configuring connection pools, optimizing connection usage, or troubleshooting connection issues.
allowed-tools: Read, Grep, Glob, Bash
---

# Connection Management

## Why Connection Pooling

### The Problem
- Database connections are expensive to create (TCP handshake + auth + memory allocation)
- PostgreSQL: ~10 MB per connection (per-process model)
- MySQL: ~1-4 MB per connection (per-thread model)
- Without pooling: N application instances × M connections each = N×M database connections
- Most connections sit idle most of the time

### The Solution
- Pool reuses a small number of persistent connections
- Application checks out connection → uses it → returns it
- Typical ratio: 100 application requests served by 20 database connections

## PostgreSQL Connection Pooling

### PgBouncer

**Pool Modes:**
| Mode | Description | Use Case | Limitations |
|------|-------------|----------|-------------|
| **Transaction** | Connection returned after each transaction | Most web apps (recommended) | No SET, PREPARE, LISTEN, advisory locks across transactions |
| **Session** | Connection held for entire client session | Apps using session-level features | Less connection sharing |
| **Statement** | Connection returned after each statement | Simple queries, autocommit | No multi-statement transactions |

**Configuration:**
```ini
# pgbouncer.ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_port = 6432
listen_addr = 0.0.0.0
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

# Pool sizing
pool_mode = transaction
default_pool_size = 20          # server connections per user/db
min_pool_size = 5               # keep this many connections warm
reserve_pool_size = 5           # burst capacity
reserve_pool_timeout = 3        # seconds before using reserve

# Limits
max_client_conn = 1000          # total client connections
max_db_connections = 50         # max server connections per database

# Timeouts
server_idle_timeout = 300       # close idle server connections
client_idle_timeout = 0         # 0 = disabled
query_timeout = 0               # 0 = disabled
server_connect_timeout = 15     # timeout for connecting to PostgreSQL

# Logging
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
stats_period = 60
```

**Monitoring PgBouncer:**
```sql
-- Connect to PgBouncer admin console
psql -p 6432 -U pgbouncer pgbouncer

SHOW POOLS;       -- pool statistics
SHOW CLIENTS;     -- client connections
SHOW SERVERS;     -- server connections
SHOW STATS;       -- aggregate statistics
SHOW CONFIG;      -- current configuration
```

### pgcat (Rust-Based Alternative)

**Features over PgBouncer:**
- Multi-threaded (PgBouncer is single-threaded)
- Built-in load balancing across replicas
- Query-based routing (read/write splitting)
- Sharding support
- Prometheus metrics endpoint
- Connection mirroring

**Configuration:**
```toml
# pgcat.toml
[general]
host = "0.0.0.0"
port = 6432
admin_username = "admin"
admin_password = "admin"
worker_threads = 4

[pools.mydb]
pool_mode = "transaction"
default_role = "primary"
query_parser_enabled = true       # enables read/write splitting

[pools.mydb.shards.0]
servers = [
    ["primary-host", 5432, "primary"],
    ["replica-host", 5432, "replica"]
]
database = "mydb"
```

### AWS RDS Proxy
- Managed connection pooling for RDS/Aurora
- IAM authentication support
- Automatic failover handling
- Pin connections for prepared statements
- Multiplexes thousands of application connections to fewer DB connections

## MySQL Connection Pooling

### ProxySQL

**Key Features:**
- Query routing (read/write splitting)
- Query caching
- Connection multiplexing
- Query rewriting
- Monitoring and alerting

**Configuration:**
```sql
-- Add servers
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight)
VALUES (10, 'primary', 3306, 1000),   -- writer hostgroup
       (20, 'replica1', 3306, 500),    -- reader hostgroup
       (20, 'replica2', 3306, 500);

-- Query routing rules
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup)
VALUES (1, 1, '^SELECT.*FOR UPDATE', 10),     -- SELECT FOR UPDATE → writer
       (2, 1, '^SELECT', 20),                  -- SELECT → reader
       (3, 1, '.*', 10);                       -- everything else → writer

-- Connection pool settings
UPDATE mysql_servers SET max_connections=100, max_replication_lag=5;

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

## Application-Level Pooling

### Node.js / TypeScript

**Prisma:**
```typescript
// Prisma manages pool internally
// Configure via connection string
// DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10"

// Or use Prisma Accelerate for serverless
// DATABASE_URL="prisma://accelerate.prisma-data.net/?api_key=..."
```

**node-postgres (pg):**
```typescript
import { Pool } from 'pg';

const pool = new Pool({
    host: 'localhost',
    port: 5432,
    database: 'mydb',
    user: 'app',
    password: 'secret',
    max: 20,                    // max connections in pool
    idleTimeoutMillis: 30000,   // close idle connections after 30s
    connectionTimeoutMillis: 5000, // timeout waiting for connection
});

// Use pool (automatically checks out and returns)
const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
```

### Python

**SQLAlchemy:**
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

### Java

**HikariCP (Fastest JVM Pool):**
```java
HikariConfig config = new HikariConfig();
config.setJdbcUrl("jdbc:postgresql://host:5432/db");
config.setUsername("app");
config.setPassword("secret");

// Pool sizing (formula: connections = (core_count * 2) + spindle_count)
config.setMaximumPoolSize(20);
config.setMinimumIdle(5);

// Timeouts
config.setConnectionTimeout(30000);   // 30s wait for connection
config.setIdleTimeout(600000);        // 10min idle before close
config.setMaxLifetime(1800000);       // 30min max connection lifetime

// Leak detection
config.setLeakDetectionThreshold(60000); // warn if connection held > 60s

HikariDataSource ds = new HikariDataSource(config);
```

### Go

**database/sql (Built-in):**
```go
db, err := sql.Open("postgres", "postgresql://user:pass@host:5432/db?sslmode=require")

db.SetMaxOpenConns(20)           // max total connections
db.SetMaxIdleConns(5)            // max idle connections
db.SetConnMaxLifetime(30 * time.Minute) // max connection lifetime
db.SetConnMaxIdleTime(5 * time.Minute)  // max idle time
```

## Serverless Connection Strategies

| Strategy | Provider | How It Works |
|----------|----------|-------------|
| **Prisma Accelerate** | Prisma | Global edge cache + connection pooling proxy |
| **RDS Proxy** | AWS | Managed proxy, IAM auth, failover handling |
| **Neon Pooler** | Neon | Built-in PgBouncer, scale-to-zero |
| **Supabase Pooler** | Supabase | PgBouncer via Supavisor, transaction mode |
| **PlanetScale** | PlanetScale | HTTP-based connections, no persistent pool needed |
| **Upstash** | Upstash | REST API for Redis/Kafka, no TCP connections |
| **Cloudflare Hyperdrive** | Cloudflare | Connection pooling for Workers |

## Connection Leak Detection

### Symptoms
- Connection count grows over time without releasing
- "too many connections" errors
- Pool exhaustion (all connections checked out, none returned)

### Detection
```sql
-- PostgreSQL: Find long-idle connections
SELECT pid, usename, application_name, state, query,
       age(clock_timestamp(), state_change) AS idle_duration
FROM pg_stat_activity
WHERE state = 'idle' AND age(clock_timestamp(), state_change) > interval '5 minutes';

-- MySQL: Find sleeping connections
SELECT id, user, host, db, command, time, state
FROM information_schema.processlist
WHERE command = 'Sleep' AND time > 300;
```

### Prevention
1. **Always use try/finally or using/with** to return connections
2. **Set connection timeouts** in the pool configuration
3. **Enable leak detection** (HikariCP leakDetectionThreshold, PgBouncer server_idle_timeout)
4. **Monitor pool metrics**: active, idle, waiting counts
5. **Kill long-idle connections**: PgBouncer client_idle_timeout, MySQL wait_timeout

## Pool Sizing Formula

```
Optimal pool size = (core_count * 2) + effective_spindle_count

For SSD: spindle_count ≈ 1 (SSD handles concurrent I/O well)
For HDD: spindle_count = number of disk spindles

Example (8-core, SSD):
  Pool size = (8 * 2) + 1 = 17 ≈ 20 (round up)

Total across app instances:
  max_connections = pool_size × instances + admin_reserve
  Example: 20 × 5 + 10 = 110
```

## Quick Reference

1. **Use PgBouncer in transaction mode** for PostgreSQL web applications
2. **Use ProxySQL** for MySQL read/write splitting and query routing
3. **Pool size = (cores × 2) + 1** for SSD-backed databases
4. **Monitor pool utilization** — if consistently > 80%, increase pool or optimize queries
5. **Set timeouts** on both pool and database level
6. **Enable leak detection** in production
7. **Serverless**: Use HTTP-based connections or managed proxy (RDS Proxy, Neon pooler)
