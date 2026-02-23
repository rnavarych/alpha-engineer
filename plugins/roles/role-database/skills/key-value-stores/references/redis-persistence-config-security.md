# Redis / Valkey — Persistence, Configuration Tuning, Security, Latency Diagnostics

## When to load
Load when configuring RDB snapshots, AOF persistence, eviction policies, IO threads, memory thresholds, ACLs, TLS, or diagnosing latency with SLOWLOG and LATENCY commands.

## RDB Snapshots

```
save 3600 1
save 300 100
save 60 10000
dbfilename dump.rdb
dir /data/redis
rdbcompression yes
rdbchecksum yes
stop-writes-on-bgsave-error yes
```

```bash
redis-cli BGSAVE
redis-cli LASTSAVE
```

## AOF (Append-Only File)

```
appendonly yes
appendfilename "appendonly.aof"
appenddirname "appendonlydir"     # Redis 7.0+ multi-part AOF

appendfsync everysec              # Recommended (always=safest, no=fastest)

auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-use-rdb-preamble yes          # Hybrid persistence (Redis 7.0+)
```

```bash
redis-cli BGREWRITEAOF
```

**Fork overhead:** BGSAVE/BGREWRITEAOF uses fork() with copy-on-write — peak memory can double under high write rate. Monitor `latest_fork_usec` in INFO stats.

## Memory Configuration and Eviction

```
maxmemory 8gb
maxmemory-policy allkeys-lfu     # Recommended for cache workloads

# Eviction policies:
# noeviction       - Return errors when limit reached
# allkeys-lru      - Evict any key using LRU
# allkeys-lfu      - Evict any key using LFU (recommended for cache)
# volatile-lru     - Evict keys with TTL using LRU
# volatile-ttl     - Evict keys with shortest TTL

lfu-log-factor 10
lfu-decay-time 1

# Compact encodings for small structures
hash-max-listpack-entries 128
hash-max-listpack-value 64
set-max-intset-entries 512
zset-max-listpack-entries 128
zset-max-listpack-value 64
```

## Performance Tuning

```
io-threads 4                  # Redis 6.0+
io-threads-do-reads yes
hz 10
dynamic-hz yes
timeout 300
tcp-keepalive 300
tcp-backlog 511
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
lazyfree-lazy-user-del yes
```

## Latency Diagnostics

```bash
redis-cli --latency
redis-cli --latency-history --interval 15
redis-cli --latency-dist

CONFIG SET latency-monitor-threshold 100
LATENCY LATEST
LATENCY HISTORY command
LATENCY RESET

CONFIG SET slowlog-log-slower-than 10000
CONFIG SET slowlog-max-len 128
SLOWLOG GET 25
SLOWLOG RESET

INFO memory
MEMORY USAGE key_name SAMPLES 5
MEMORY DOCTOR
redis-cli --bigkeys
redis-cli --memkeys
CLIENT LIST
```

## ACL (Access Control Lists)

```bash
ACL SETUSER appuser on >strongpassword ~app:* +@read +@write -@admin
ACL SETUSER readonly on >readpass ~* +@read -@write -@admin +ping
ACL SETUSER user1 ~cache:* ~session:* &channel:*  # Key + pub/sub patterns

ACL LIST
ACL GETUSER appuser
ACL DELUSER appuser
ACL SAVE
ACL LOAD
ACL LOG 25

aclfile /etc/redis/users.acl
```

## TLS Configuration

```
tls-port 6380
port 0
tls-cert-file /path/redis.crt
tls-key-file /path/redis.key
tls-ca-cert-file /path/ca.crt
tls-auth-clients optional
tls-protocols "TLSv1.2 TLSv1.3"
tls-replication yes
tls-cluster yes
```

## Dangerous Command Handling

```
protected-mode yes
# Prefer ACL over rename-command (legacy)
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG "CONFIG_SECRET_CMD"
```
