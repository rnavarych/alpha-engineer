# Hash Tables and Balanced Trees

## When to load
When implementing or selecting hash tables, choosing collision resolution strategies, or picking between AVL trees, Red-Black trees, and B-trees for ordered data.

## Hash Tables

### Collision Resolution
- **Chaining**: Linked list per bucket. Simple, degrades gracefully. Load factor can exceed 1.
- **Open addressing (linear probing)**: Cache-friendly, but clustering at high load factors. Keep load factor < 0.7.
- **Robin Hood hashing**: Steal from rich (short probe distance) to give to poor (long probe distance). Reduces variance in probe length.
- **Cuckoo hashing**: Two hash functions, two tables. O(1) worst-case lookup. Amortized O(1) insert.

### Design Decisions
- Hash function: Use high-quality hash (xxHash, SipHash for security) not simple modulo.
- Load factor threshold: 0.5-0.75 for open addressing, 1.0-2.0 for chaining.
- Resize strategy: Double capacity on threshold breach. Rehash all entries (amortized O(1) per insert).
- For fixed key sets: Perfect hashing (CMPH, gperf) → O(1) worst-case with no collisions.

## Balanced Trees

### AVL Trees
- Strictly balanced (height difference ≤ 1). Faster lookups than Red-Black (lower height).
- More rotations on insert/delete. Prefer when reads dominate writes.

### Red-Black Trees
- Relaxed balance (no path more than 2x longest). Fewer rotations on insert/delete.
- Used in most standard library implementations (C++ std::map, Java TreeMap).
- Prefer when insert/delete frequency is comparable to lookups.

### B-Trees / B+ Trees
- Multi-way trees optimized for disk/page-based storage. Minimize I/O operations.
- B+ trees: All data in leaves, internal nodes are index-only. Sequential scan via leaf linked list.
- Used in databases (indexes) and file systems. Node size = disk page size (4KB-16KB).
- Choose degree based on key size and page size: maximize keys per node.

### Selection Criteria

| Criterion | AVL | Red-Black | B-Tree |
|---|---|---|---|
| Read-heavy | Best | Good | Best (disk) |
| Write-heavy | Slower | Better | Best (disk) |
| In-memory | Good | Good | Overkill |
| Disk-based | Poor | Poor | Best |
| Ordered iteration | Yes | Yes | Yes (B+) |
