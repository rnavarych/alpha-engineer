# String Searching and External Sorting

## When to load
When implementing single or multi-pattern string matching (KMP, Rabin-Karp, Boyer-Moore, Aho-Corasick, suffix arrays) or sorting data that exceeds available memory.

## String Searching

### KMP (Knuth-Morris-Pratt)
- O(n + m) single-pattern search. Precomputes failure function from pattern.
- Failure function: for each position, longest proper prefix that is also a suffix.
- No backtracking on text. Processes each text character exactly once.

### Rabin-Karp
- O(n + m) expected with rolling hash. O(nm) worst case (hash collisions).
- Rolling hash: add new character, remove old character in O(1).
- Best for: multi-pattern search (hash all patterns, check text window against hash set).

### Boyer-Moore
- O(n/m) best case (sublinear). O(nm) worst case.
- Bad character rule + good suffix rule. Starts matching from end of pattern.
- Fastest single-pattern search in practice for natural language text.

### Aho-Corasick
- O(n + m + z) multi-pattern search (z = number of matches). Based on trie + failure links.
- Build automaton from all patterns. Process text in single pass.
- Use for: dictionary matching, multi-keyword filtering, intrusion detection.

### Suffix Arrays
- Array of all suffixes sorted lexicographically. Build in O(n log n) or O(n) with SA-IS.
- With LCP (Longest Common Prefix) array: substring search in O(m log n).
- Use for: repeated substring queries, longest repeated substring, string matching on large texts.
- More space-efficient than suffix trees (array of integers vs. tree of pointers).

## External Sorting

### K-Way Merge
- Split data into chunks fitting in memory. Sort each chunk. Merge k sorted chunks with min-heap.
- I/O complexity: O((N/B) × log_{M/B}(N/B)) where N = data size, M = memory, B = block size.

### Replacement Selection
- Build initial runs longer than memory using a tournament tree (heap).
- Average run length: 2 × memory size (better than simple in-memory sort + write).

### Practical Considerations
- Maximize sequential I/O (read/write large blocks, not random access).
- Use buffer pool: double-buffer reads and writes for I/O overlap.
- Compress intermediate runs to reduce I/O.
- SSD vs HDD: SSDs tolerate more random access but sequential is still faster.

## Selection Guide

| Scenario | Best Algorithm |
|---|---|
| General-purpose in-memory sort | Quicksort (introsort) or Timsort |
| Stability required | Merge sort or Timsort |
| Nearly sorted data | Timsort or insertion sort |
| Small range of integer keys | Counting sort |
| Fixed-length integers/strings | Radix sort |
| Single pattern matching | Boyer-Moore or KMP |
| Multiple pattern matching | Aho-Corasick |
| Data larger than memory | External merge sort |
| Find k-th element | Quickselect |
| Streaming median | Two heaps |
