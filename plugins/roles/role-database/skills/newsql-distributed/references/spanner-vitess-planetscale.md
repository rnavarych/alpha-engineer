# Google Spanner, Vitess, and PlanetScale — TrueTime, VSchema Sharding, Database Branching

## When to load
Load when configuring Google Spanner TrueTime/external consistency, designing Vitess VSchema with vindexes, running MoveTables/Reshard workflows, or using PlanetScale database branching and deploy requests.

## Google Spanner — TrueTime and External Consistency

```sql
-- TrueTime (GPS + atomic clocks) guarantees external consistency:
-- if T1 commits before T2 starts, T1 timestamp < T2 timestamp

-- Connect using pgAdapter proxy (PostgreSQL interface)
CREATE TABLE users (
    user_id TEXT NOT NULL,
    email TEXT NOT NULL,
    name TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) PRIMARY KEY (user_id);

-- Interleaved tables: parent-child co-location for efficient joins
CREATE TABLE orders (
    user_id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    total NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending'
) PRIMARY KEY (user_id, order_id),
INTERLEAVE IN PARENT users ON DELETE CASCADE;
-- Ensures all orders for a user are stored on the same split as the user row
```

## Spanner — Change Streams and Operations

```sql
-- Change streams (CDC)
CREATE CHANGE STREAM user_changes FOR users, orders
OPTIONS (retention_period = '7d', value_capture_type = 'NEW_AND_OLD_VALUES');

-- Bounded staleness reads via client library:
-- .singleUse(TimestampBound.ofMaxStaleness(15, TimeUnit.SECONDS))

-- Multi-region configuration via Google Cloud Console or Terraform
-- Instance configs: nam6 (US), eur6 (Europe), nam-eur-asia1 (global)
```

```bash
# Managed automatic backups + on-demand
gcloud spanner backups create mydb-backup --instance=myinstance --database=mydb --retention-period=30d
```

## Vitess — VSchema and Sharding Topology

```json
// VSchema: defines sharding strategy
{
  "sharded": true,
  "vindexes": {
    "hash_user_id": {
      "type": "hash"
    },
    "lookup_email": {
      "type": "consistent_lookup_unique",
      "params": {
        "table": "email_user_id_lookup",
        "from": "email",
        "to": "user_id"
      },
      "owner": "users"
    }
  },
  "tables": {
    "users": {
      "column_vindexes": [
        { "column": "user_id", "name": "hash_user_id" }
      ]
    },
    "orders": {
      "column_vindexes": [
        { "column": "user_id", "name": "hash_user_id" }
      ]
    }
  }
}
```

## Vitess — Components and Workflows

```bash
# Components:
# vtgate: stateless query router (clients connect here)
# vttablet: per-MySQL shard process (manages replication, schema)
# vtctld: cluster management daemon

# MoveTables: migrate tables between keyspaces (zero-downtime)
vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users create \
    --source-keyspaces=unsharded_ks --tables=users,orders

vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users show
vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users switchtraffic
vtctldclient MoveTables --target-keyspace=sharded_ks --workflow=move_users complete

# Reshard: split or merge shards
vtctldclient Reshard --target-keyspace=sharded_ks --workflow=reshard_4_to_8 create \
    --source-shards='-80,80-' --target-shards='-40,40-80,80-c0,c0-'

# Online DDL (non-blocking via gh-ost or Vitess native strategy)
vtctldclient ApplySchema --sql="ALTER TABLE users ADD COLUMN phone VARCHAR(20)" \
    --ddl-strategy="vitess" --keyspace=sharded_ks
```

## PlanetScale — Database Branching

```bash
# PlanetScale CLI (pscale)
pscale database create myapp --region us-east

# Branch workflow (git-like branching for schema changes)
pscale branch create myapp add-phone-column
pscale shell myapp add-phone-column
# > ALTER TABLE users ADD COLUMN phone VARCHAR(20);

# Deploy request (like a PR for schema changes)
pscale deploy-request create myapp add-phone-column
pscale deploy-request deploy myapp 1

# Non-blocking DDL: uses Vitess Online DDL under the hood
# No table locks — safe in production

# Local development connection
pscale connect myapp main --port 3306

# PlanetScale Boost (query caching at edge)
# Configured per-query via dashboard or API
# Auto-caches SELECT results, invalidates on writes
```
