# Redis / Valkey — Streams, Lua Scripting, Redis Stack Modules

## When to load
Load when implementing Redis Streams consumer groups, writing Lua scripts or Functions, or using Redis Stack modules (RediSearch, RedisJSON, RedisTimeSeries, RedisBloom).

## Redis Streams

```bash
# Producing
XADD mystream * field1 value1 field2 value2
XADD mystream MAXLEN ~ 100000 * field1 value1   # Trimmed stream

# Direct consumption
XRANGE mystream - + COUNT 10
XREVRANGE mystream + - COUNT 10
XREAD COUNT 10 BLOCK 5000 STREAMS mystream $

# Consumer groups
XGROUP CREATE mystream mygroup $ MKSTREAM
XREADGROUP GROUP mygroup consumer1 COUNT 10 BLOCK 2000 STREAMS mystream >
XACK mystream mygroup 1710000000000-0

# Pending / recovery
XPENDING mystream mygroup - + 10
XPENDING mystream mygroup IDLE 60000 - + 10
XAUTOCLAIM mystream mygroup consumer2 60000 0-0 COUNT 10

# Introspection
XINFO STREAM mystream
XINFO GROUPS mystream
XINFO CONSUMERS mystream mygroup
```

| Feature | Streams | Pub/Sub |
|---------|---------|---------|
| Persistence | Yes | No (fire-and-forget) |
| Consumer groups | Yes | No |
| Acknowledgment | Yes (XACK) | No |
| Replay/history | Yes | No |
| Use case | Event sourcing, task queues | Real-time notifications |

## Lua Scripting

```bash
# Atomic conditional counter
EVAL "
  local current = redis.call('GET', KEYS[1])
  if current and tonumber(current) >= tonumber(ARGV[1]) then
    return redis.error_reply('Limit exceeded')
  end
  return redis.call('INCR', KEYS[1])
" 1 rate:user:1001 100

# Load script (EVALSHA for repeat calls)
redis-cli SCRIPT LOAD "return redis.call('GET', KEYS[1])"
EVALSHA <sha> 1 mykey
SCRIPT EXISTS <sha1>
SCRIPT FLUSH ASYNC

# Functions (Redis 7.0+, persistent named functions)
FUNCTION LOAD "#!lua name=mylib\nredis.register_function('myfunc', function(keys, args) return redis.call('GET', keys[1]) end)"
FCALL myfunc 1 mykey
```

**Scripting rules:** scripts are atomic; access only keys via KEYS[] for cluster compatibility; avoid long-running scripts (blocks server); `lua-time-limit` default 5s.

## RediSearch

```bash
FT.CREATE idx:products ON HASH PREFIX 1 product: SCHEMA
  name TEXT WEIGHT 2.0 description TEXT
  price NUMERIC SORTABLE category TAG
  embedding VECTOR FLAT 6 TYPE FLOAT32 DIM 768 DISTANCE_METRIC COSINE

FT.SEARCH idx:products "@name:laptop @price:[500 1500]" SORTBY price ASC LIMIT 0 10
FT.SEARCH idx:products "(@name:laptop) => [KNN 5 @embedding $vec AS score]" PARAMS 2 vec <blob> DIALECT 2

FT.AGGREGATE idx:products "*"
  GROUPBY 1 @category
  REDUCE COUNT 0 AS count
  REDUCE AVG 1 @price AS avg_price
  SORTBY 2 @count DESC LIMIT 0 10
```

## RedisJSON

```bash
JSON.SET user:1001 $ '{"name":"Alice","age":30,"tags":["admin","vip"]}'
JSON.GET user:1001 $.name $.age
JSON.SET user:1001 $.age 31
JSON.NUMINCRBY user:1001 $.age 1
JSON.ARRAPPEND user:1001 $.tags '"editor"'
JSON.DEL user:1001 $.address.city
JSON.MGET user:1001 user:1002 $.name
```

## RedisTimeSeries

```bash
TS.CREATE sensor:temp:1 RETENTION 86400000 LABELS location "datacenter1" type "temperature"
TS.ADD sensor:temp:1 * 23.5
TS.RANGE sensor:temp:1 - + AGGREGATION avg 60000    # 1-min averages
TS.MRANGE - + FILTER location=datacenter1
TS.CREATERULE sensor:temp:1 sensor:temp:1:hourly AGGREGATION avg 3600000
```

## RedisBloom

```bash
# Bloom filter (probabilistic membership, no deletion)
BF.RESERVE filter:ips 0.001 1000000           # 0.1% error rate, 1M capacity
BF.ADD filter:emails "user@example.com"
BF.EXISTS filter:emails "user@example.com"

# Cuckoo filter (supports deletion)
CF.ADD cuckoo:sessions "session123"
CF.DEL cuckoo:sessions "session123"

# Count-Min Sketch (frequency estimation)
CMS.INITBYDIM sketch:pageviews 2000 5
CMS.INCRBY sketch:pageviews "/home" 1
CMS.QUERY sketch:pageviews "/home"

# Top-K
TOPK.RESERVE popular:pages 10
TOPK.ADD popular:pages "/home" "/about"
TOPK.LIST popular:pages
```
