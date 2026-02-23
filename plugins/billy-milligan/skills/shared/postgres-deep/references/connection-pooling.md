# PostgreSQL Connection Pooling

## When to Load
Load when configuring PgBouncer, sizing connection pools, or choosing between pool modes.

## Why Connection Pooling Is Non-Negotiable

```
PostgreSQL creates a process per connection (fork-based, not thread-based).
Each connection uses ~5-10MB of shared memory + backend process overhead.

Without pooling:
  100 Node.js instances × 10 connections each = 1000 PostgreSQL connections
  1000 × 7MB = 7GB just for connections
  PostgreSQL becomes unresponsive before running out of memory

With PgBouncer (transaction mode):
  100 Node.js instances × 10 connections = 1000 client connections to PgBouncer
  PgBouncer → PostgreSQL: 20-50 actual server connections
  PostgreSQL sees 20-50 connections; handles 10-50× more application throughput
```

## PgBouncer Pool Modes

```
Session mode:   client holds server connection for entire session
                Safest but no benefit for short-lived app connections
                Use when: SET LOCAL, advisory locks, LISTEN/NOTIFY, PREPARE STATEMENT

Transaction mode: server connection assigned per transaction
                  Released immediately after COMMIT/ROLLBACK
                  Best for OLTP applications (most web backends)
                  Limitation: cannot use session-level features (SET, advisory locks)
                  This is the mode you almost always want

Statement mode: server connection released after each statement
                Cannot use multi-statement transactions
                Rarely useful; most apps use transactions
```

## PgBouncer Configuration

```ini
; /etc/pgbouncer/pgbouncer.ini

[databases]
orderdb    = host=postgres-primary.internal port=5432 dbname=orderdb
orderdb_ro = host=postgres-replica.internal port=5432 dbname=orderdb

[pgbouncer]
listen_addr = *
listen_port = 5432
pool_mode   = transaction

default_pool_size    = 20     ; Connections per database-user pair
max_client_conn      = 10000  ; Total client connections PgBouncer accepts
reserve_pool_size    = 5      ; Extra connections for bursts
reserve_pool_timeout = 3

server_lifetime        = 3600  ; Close idle server connection after 1 hour
server_idle_timeout    = 600
server_connect_timeout = 15
query_wait_timeout     = 120

auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

log_connections    = 0
log_disconnections = 0
log_pooler_errors  = 1
stats_period       = 60
```

## Pool Size Formula

```
# OLTP starting point (transaction mode):
default_pool_size = (num_cpu_cores × 2) + effective_spindle_count
# db.t4g.medium (2 vCPU, SSD): (2 × 2) + 1 = ~10-15 connections

# Real formula based on max_connections:
# max_connections = 200; reserve 5 for admin; PgBouncer gets 195
# With 3 app environments: default_pool_size = 195 / 3 = ~65

# Application pool per process (Prisma/Drizzle/pg):
DATABASE_URL="postgresql://user:pass@pgbouncer:5432/orderdb?connection_limit=5"
```

## Application Configuration

```typescript
// node-postgres (pg)
import { Pool } from 'pg';
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  // Do NOT use: SET, advisory locks, LISTEN/NOTIFY, named PREPARE STATEMENT
});

// Drizzle ORM with postgres.js
import postgres from 'postgres';
const sql = postgres(process.env.DATABASE_URL!, {
  max: 5,
  idle_timeout: 30,
  connect_timeout: 5,
  prepare: false,  // CRITICAL: disable prepared statements in transaction mode
});
```

## Anti-Patterns

### Using Session Mode with Web Applications
Session mode holds the PostgreSQL connection for the entire HTTP session lifecycle. 1000 concurrent users = 1000 PostgreSQL connections. Eliminates the entire benefit of pooling.

### Prepared Statements in Transaction Mode
PgBouncer transaction mode cannot guarantee the same PostgreSQL backend handles a prepared statement and its execution. Use `prepare: false` in postgres.js or `disablePreparedStatements: true` in Prisma.

### max_connections Too High Without Pooler
Setting `max_connections = 2000` means 2000 × 7MB = 14GB reserved just for connections. Keep max_connections low (200-500), let PgBouncer handle the fan-out.

## Quick Reference

```
pool_mode: transaction for web apps; session only for SET/advisory locks/LISTEN
default_pool_size formula: (cores × 2) + 1 as starting point; tune up
max_connections: keep low (200-500); PgBouncer multiplexes
prepare: false in ORMs when using transaction mode
Application pool to PgBouncer: 2-5 connections per process (not 20-50)
```
