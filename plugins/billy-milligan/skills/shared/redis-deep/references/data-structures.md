# Redis Data Structures

## When to load
Load when choosing between Redis data types or designing data models in Redis.

## Core Data Types

| Type | Use Case | Commands | Time Complexity |
|------|----------|----------|-----------------|
| String | Cache, counters, flags | GET/SET/INCR | O(1) |
| Hash | Object storage, user profiles | HGET/HSET/HGETALL | O(1) per field |
| List | Queues, activity feeds, recent items | LPUSH/RPOP/LRANGE | O(1) push/pop |
| Set | Tags, unique visitors, relationships | SADD/SMEMBERS/SINTER | O(1) add/remove |
| Sorted Set | Leaderboards, rate limiting, scheduling | ZADD/ZRANGE/ZRANGEBYSCORE | O(log N) |
| Stream | Event sourcing, message queue | XADD/XREAD/XREADGROUP | O(1) per entry |
| HyperLogLog | Cardinality estimation (unique counts) | PFADD/PFCOUNT | O(1), ~0.81% error |
| Bitmap | Flags per user, feature toggles | SETBIT/GETBIT/BITCOUNT | O(1) per bit |

## Strings — Beyond Simple Key-Value

```redis
# Counter with atomic increment
INCR page:views:homepage         # → 1
INCRBY page:views:homepage 10    # → 11

# Distributed lock (SET with NX + EX)
SET lock:order:123 "worker-1" NX EX 30  # acquire, 30s TTL
# NX = only if not exists, EX = expire in seconds

# JSON-like storage (use RedisJSON module or serialize)
SET user:42 '{"name":"Alice","role":"admin"}' EX 3600
```

## Hashes — Object Storage

```redis
# User profile
HSET user:42 name "Alice" email "alice@co.com" role "admin"
HGET user:42 name           # → "Alice"
HGETALL user:42             # → all fields
HINCRBY user:42 login_count 1  # atomic field increment

# Memory efficient: hashes with <128 fields use ziplist encoding
# Configure: hash-max-ziplist-entries 128
```

## Sorted Sets — Leaderboards & Scheduling

```redis
# Leaderboard
ZADD leaderboard 1500 "player:1" 2300 "player:2" 1800 "player:3"
ZREVRANGE leaderboard 0 9 WITHSCORES  # top 10
ZRANK leaderboard "player:1"           # rank (0-indexed)

# Sliding window rate limiter
ZADD ratelimit:user:42 1708000001 "req:uuid1"
ZADD ratelimit:user:42 1708000002 "req:uuid2"
ZREMRANGEBYSCORE ratelimit:user:42 0 1707999900  # remove old
ZCARD ratelimit:user:42                           # count in window
```

## Streams — Event Log

```redis
# Append event
XADD orders * action "created" order_id "123" total "99.99"
# → "1708000001234-0" (auto-generated ID)

# Consumer group (exactly-once delivery per group)
XGROUP CREATE orders processor-group 0
XREADGROUP GROUP processor-group worker-1 COUNT 10 BLOCK 5000 STREAMS orders >

# Acknowledge processed
XACK orders processor-group "1708000001234-0"

# Check pending (unacknowledged)
XPENDING orders processor-group
```

## Anti-patterns
- Using KEYS in production → blocks entire server, use SCAN instead
- Large hashes (10K+ fields) → split into multiple keys
- Unbounded lists/streams → always set MAXLEN or trim periodically
- Storing large blobs (>1MB) → use object storage, store URL in Redis

## Quick reference
```
Strings: simple values, counters, locks (SET NX EX)
Hashes: objects with fields, memory-efficient under 128 fields
Lists: queues (LPUSH/RPOP), bounded with LTRIM
Sets: unique collections, intersections, unions
Sorted Sets: ranked data, rate limiting, scheduling
Streams: event log with consumer groups, exactly-once per group
HyperLogLog: unique counts with 0.81% error, 12KB fixed
Bitmap: per-entity flags, daily active users tracking
```
