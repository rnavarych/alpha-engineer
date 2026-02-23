# PgBouncer, pgcat, and ProxySQL

## When to load
Load when configuring connection pooling proxies for PostgreSQL (PgBouncer, pgcat, AWS RDS Proxy) or MySQL (ProxySQL). Covers pool modes, configuration, monitoring, and read/write splitting.

## PostgreSQL: PgBouncer

### Pool Modes
| Mode | Description | Use Case | Limitations |
|------|-------------|----------|-------------|
| **Transaction** | Connection returned after each transaction | Most web apps (recommended) | No SET, PREPARE, LISTEN, advisory locks across transactions |
| **Session** | Connection held for entire client session | Apps using session-level features | Less connection sharing |
| **Statement** | Connection returned after each statement | Simple queries, autocommit | No multi-statement transactions |

### Configuration
```ini
# pgbouncer.ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_port = 6432
listen_addr = 0.0.0.0
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

pool_mode = transaction
default_pool_size = 20          # server connections per user/db
min_pool_size = 5
reserve_pool_size = 5           # burst capacity
reserve_pool_timeout = 3

max_client_conn = 1000          # total client connections
max_db_connections = 50         # max server connections per database

server_idle_timeout = 300       # close idle server connections
server_connect_timeout = 15

log_connections = 1
log_disconnections = 1
stats_period = 60
```

### Monitoring PgBouncer
```sql
psql -p 6432 -U pgbouncer pgbouncer
SHOW POOLS;     -- pool statistics
SHOW CLIENTS;   -- client connections
SHOW SERVERS;   -- server connections
SHOW STATS;     -- aggregate statistics
SHOW CONFIG;    -- current configuration
```

## PostgreSQL: pgcat (Rust-Based)

Features over PgBouncer: multi-threaded, built-in load balancing across replicas, query-based read/write routing, sharding, Prometheus metrics, connection mirroring.

```toml
# pgcat.toml
[general]
host = "0.0.0.0"
port = 6432
worker_threads = 4

[pools.mydb]
pool_mode = "transaction"
default_role = "primary"
query_parser_enabled = true     # enables read/write splitting

[pools.mydb.shards.0]
servers = [
    ["primary-host", 5432, "primary"],
    ["replica-host", 5432, "replica"]
]
database = "mydb"
```

## AWS RDS Proxy
- Managed connection pooling for RDS/Aurora
- IAM authentication support
- Automatic failover handling
- Pins connections for prepared statements
- Multiplexes thousands of app connections to fewer DB connections

## MySQL: ProxySQL

### Read/Write Splitting Configuration
```sql
-- Add servers
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight)
VALUES (10, 'primary', 3306, 1000),    -- writer hostgroup
       (20, 'replica1', 3306, 500),    -- reader hostgroup
       (20, 'replica2', 3306, 500);

-- Query routing rules
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup)
VALUES (1, 1, '^SELECT.*FOR UPDATE', 10),  -- SELECT FOR UPDATE → writer
       (2, 1, '^SELECT', 20),               -- SELECT → reader
       (3, 1, '.*', 10);                    -- everything else → writer

UPDATE mysql_servers SET max_connections=100, max_replication_lag=5;

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Serverless Connection Strategies

| Strategy | Provider | How It Works |
|----------|----------|-------------|
| Prisma Accelerate | Prisma | Global edge cache + connection pooling proxy |
| RDS Proxy | AWS | Managed proxy, IAM auth, failover handling |
| Neon Pooler | Neon | Built-in PgBouncer, scale-to-zero |
| Supabase Pooler | Supabase | PgBouncer via Supavisor, transaction mode |
| Cloudflare Hyperdrive | Cloudflare | Connection pooling for Workers |
