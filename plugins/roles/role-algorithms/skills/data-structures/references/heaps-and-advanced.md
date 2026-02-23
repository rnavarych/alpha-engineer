# Heaps, Priority Queues, and Advanced Structures

## When to load
When selecting a priority queue implementation, implementing tries, segment trees, Fenwick trees, or skip lists, or when choosing between advanced data structures for range queries and prefix operations.

## Heaps and Priority Queues

### Binary Heap
- Array-based. Insert: O(log n). Extract-min: O(log n). Build: O(n).
- Cache-friendly due to array layout. Default choice for most priority queue needs.

### D-ary Heap
- Shallower tree (log_d n height). Faster decrease-key (fewer comparisons per level).
- Trade-off: more comparisons per sift-down. Optimal d depends on workload.

### Fibonacci Heap
- Insert: O(1). Decrease-key: O(1) amortized. Extract-min: O(log n) amortized.
- Best theoretical bounds for Dijkstra and Prim (O(E + V log V)).
- Complex implementation, high constant factors. Rarely faster in practice for small graphs.

### Pairing Heap
- Simpler alternative to Fibonacci heap. Same amortized bounds conjectured.
- Practical choice when decrease-key performance matters.

## Advanced Structures

### Tries and Radix Trees
- Prefix-based lookup in O(key length), independent of collection size.
- Radix tree (compressed trie): Merge single-child paths. Reduces memory overhead.
- Use for: autocomplete, IP routing tables, dictionary lookups, prefix matching.

### Segment Trees
- Range query + point update in O(log n). Build in O(n).
- Supports: range sum, range min/max, range GCD, lazy propagation for range updates.
- Use when queries and updates are interleaved on array ranges.

### Fenwick Trees (Binary Indexed Trees)
- Simpler than segment trees. Prefix sum query + point update in O(log n).
- Lower constant factor than segment trees. Use when only prefix operations are needed.
- Cannot handle arbitrary range queries without two prefix queries (range = prefix(r) - prefix(l-1)).

### Skip Lists
- Probabilistic alternative to balanced BSTs. O(log n) expected for search/insert/delete.
- Simpler to implement than Red-Black trees. Easy to make concurrent (lock-free variants).
- Used in Redis sorted sets, LevelDB/RocksDB memtables.
