---
name: data-structures
description: Implements and selects optimal data structures — hash tables (chaining, open addressing, Robin Hood, cuckoo), balanced BSTs (AVL, Red-Black, B-trees), heaps (binary, Fibonacci, pairing), tries, skip lists, segment trees, Fenwick trees, Bloom filters, Count-Min Sketch, HyperLogLog, and Union-Find. Use when choosing structures for performance constraints, implementing custom collections, or optimizing memory access patterns.
allowed-tools: Read, Grep, Glob, Bash
---

# Data Structures

## When to use
- Choosing the right data structure before writing a collection or lookup mechanism
- Implementing custom hash tables, trees, or heaps with specific performance requirements
- Selecting between approximate data structures (Bloom filter, HyperLogLog, Count-Min Sketch)
- Optimizing range queries or prefix operations on arrays
- Implementing dynamic connectivity or equivalence class tracking
- Moving from in-memory to disk-based storage structures

## Core principles
1. **Access pattern first** — select for how the structure is queried, not what is most familiar
2. **Load factor controls hash table performance** — keep below 0.75 for open addressing
3. **B-trees exist because disks exist** — in-memory trees should not use disk-page logic
4. **Segment tree when updates + queries interleave; Fenwick tree for prefix-only** — do not overengineer
5. **Union-Find is underused** — path compression + union by rank gives near-O(1) for connectivity

## Reference Files
- `references/hash-and-trees.md` — hash collision strategies (chaining, open addressing, Robin Hood, cuckoo), perfect hashing, AVL vs Red-Black vs B-tree selection matrix
- `references/heaps-and-advanced.md` — binary/d-ary/Fibonacci/pairing heap trade-offs, tries, radix trees, segment trees with lazy propagation, Fenwick trees, skip lists
- `references/probabilistic-and-unionfind.md` — Bloom filters (optimal k formula, counting variant), Count-Min Sketch, HyperLogLog, Union-Find with path compression and union by rank, full selection decision matrix
