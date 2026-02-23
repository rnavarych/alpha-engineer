# Probabilistic Structures and Disjoint Sets

## When to load
When implementing Bloom filters, Count-Min Sketch, HyperLogLog for approximate queries, or Union-Find for dynamic connectivity and graph algorithms.

## Probabilistic Structures

### Bloom Filters
- Membership test with false positives (no false negatives). Space-efficient.
- Optimal: k = (m/n) × ln(2) hash functions for m bits and n elements.
- Use for: cache filtering, duplicate detection, spell checking, network routing.
- Counting Bloom filters support deletion (use counters instead of bits).

### Count-Min Sketch
- Frequency estimation with overcount (no undercount). Sub-linear space.
- Use for: heavy hitter detection, frequency counting in streaming data.

### HyperLogLog
- Cardinality estimation (count distinct) using O(log log n) space.
- Standard error ~1.04/√m for m registers. 12KB for ~2% error on billions of elements.
- Use for: unique visitor counting, database query planning (estimated distinct values).

## Disjoint Sets (Union-Find)

### Optimizations
- **Path compression**: Point every node directly to root during Find. Flattens tree.
- **Union by rank**: Attach smaller tree under root of larger tree. Keeps trees shallow.
- Combined: O(α(n)) amortized per operation (inverse Ackermann, effectively constant).

### Applications
- Connected components in undirected graphs
- Kruskal's MST algorithm (cycle detection)
- Image segmentation (pixel connectivity)
- Equivalence class tracking (compiler optimizations)

## Selection Decision Matrix

| Need | Best Structure |
|---|---|
| Fast key-value lookup | Hash table |
| Ordered iteration | Balanced BST or skip list |
| Priority queue (simple) | Binary heap |
| Priority queue (decrease-key) | Fibonacci/pairing heap |
| Range queries on array | Segment tree or Fenwick tree |
| Prefix matching | Trie or radix tree |
| Membership test (approx.) | Bloom filter |
| Cardinality estimation | HyperLogLog |
| Dynamic connectivity | Union-Find |
| Disk-based sorted data | B+ tree |
