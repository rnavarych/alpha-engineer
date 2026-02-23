# MySQL — Vitess, ProxySQL, MariaDB, Backup, Security

## When to load
Load when sharding MySQL with Vitess/PlanetScale, configuring ProxySQL query routing, using MariaDB Galera/ColumnStore/MaxScale, or running XtraBackup and TDE.

## Vitess Architecture and VSchema

```json
{
  "sharded": true,
  "vindexes": {
    "hash": { "type": "hash" },
    "lookup_unique": {
      "type": "lookup_unique",
      "params": { "table": "user_email_idx", "from": "email", "to": "user_id" }
    }
  },
  "tables": {
    "users": { "column_vindexes": [{ "column": "id", "name": "hash" }] },
    "orders": { "column_vindexes": [{ "column": "user_id", "name": "hash" }] }
  }
}
```

```bash
# MoveTables (zero-downtime migration between keyspaces)
vtctldclient MoveTables --target-keyspace=commerce --workflow=move_orders create \
    --source-keyspace=main --tables=orders
vtctldclient MoveTables --target-keyspace=commerce --workflow=move_orders switchtraffic
vtctldclient MoveTables --target-keyspace=commerce --workflow=move_orders complete

# Reshard 2 -> 4 shards
vtctldclient Reshard --target-keyspace=commerce --workflow=reshard_4 create \
    --source-shards='-80,80-' --target-shards='-40,40-80,80-c0,c0-'
```

## ProxySQL

```sql
-- Query routing (admin interface port 6032)
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES
    (1, 1, '^SELECT .* FOR UPDATE', 0, 1),
    (2, 1, '^SELECT', 1, 1),
    (3, 1, '.*', 0, 1);

INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight)
VALUES (0, 'primary.mysql.local', 3306, 1000),
       (1, 'replica1.mysql.local', 3306, 1000);

-- Query caching
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, cache_ttl, apply)
VALUES (10, 1, '^SELECT .* FROM config_table', 60000, 1);

LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL QUERY RULES TO RUNTIME; SAVE MYSQL QUERY RULES TO DISK;
```

## MariaDB Galera Cluster

```ini
[galera]
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name = "my_galera"
wsrep_cluster_address = "gcomm://node1,node2,node3"
wsrep_node_address = "10.0.0.1"
wsrep_sst_method = mariabackup
wsrep_slave_threads = 4
binlog_format = ROW
innodb_autoinc_lock_mode = 2
```

## MariaDB System Versioning

```sql
CREATE TABLE products (id INT PRIMARY KEY, name VARCHAR(255), price DECIMAL(10,2))
WITH SYSTEM VERSIONING;

SELECT * FROM products FOR SYSTEM_TIME AS OF '2024-01-15 10:00:00';
SELECT * FROM products FOR SYSTEM_TIME ALL;
```

## Backup

```bash
# XtraBackup (Percona hot backup)
xtrabackup --backup --target-dir=/backups/full --user=backup --password=secret
xtrabackup --prepare --target-dir=/backups/full
xtrabackup --backup --target-dir=/backups/inc1 --incremental-basedir=/backups/full
xtrabackup --copy-back --target-dir=/backups/full --datadir=/var/lib/mysql

# MySQL Shell parallel dump
mysqlsh -- util.dumpInstance('/backups/dump', {threads: 8, compression: 'zstd'})
mysqlsh -- util.loadDump('/backups/dump', {threads: 8, deferTableIndexes: 'all'})

# Clone Plugin (MySQL 8.0.17+)
INSTALL PLUGIN clone SONAME 'mysql_clone.so';
CLONE INSTANCE FROM 'donor_user'@'donor_host':3306 IDENTIFIED BY 'password';
SELECT * FROM performance_schema.clone_progress;
```

## TDE and Audit

```ini
early-plugin-load = keyring_file.so
keyring_file_data = /var/lib/mysql-keyring/keyring
```

```sql
ALTER TABLE sensitive_data ENCRYPTION = 'Y';
ALTER INSTANCE ROTATE INNODB MASTER KEY;

INSTALL PLUGIN audit_log SONAME 'audit_log.so';
SET GLOBAL audit_log_policy = 'QUERIES';
SET GLOBAL audit_log_format = 'JSON';
```

## Managed Options Comparison

| Feature | Aurora MySQL | PlanetScale | Cloud SQL |
|---------|-------------|-------------|-----------|
| MySQL Version | 8.0 | 8.0 (Vitess) | 8.0/8.4 |
| Max Storage | 128 TB | Unlimited (sharded) | 64 TB |
| Sharding | No | Built-in (Vitess) | No |
| Online DDL | Limited | Non-blocking | Limited |
| Branching | No | Yes (schema only) | No |
