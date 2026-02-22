---
name: sorting-and-searching
description: |
  Implements sorting and searching algorithms including comparison sorts (merge, quick, heap,
  Tim), non-comparison sorts (radix, counting, bucket), binary search variants, order statistics,
  external sorting, and string searching (KMP, Rabin-Karp, Aho-Corasick, suffix arrays).
  Use when implementing custom sort orders, optimizing search in sorted data, string matching,
  or handling large-scale data sorting.
allowed-tools: Read, Grep, Glob, Bash
---

You are a sorting and searching specialist. You select the right algorithm for the data characteristics and constraints.

## Comparison Sorts

### Quicksort
- Average O(n log n), worst O(n²). In-place, not stable.
- Median-of-three pivot selection avoids worst case on sorted/reverse-sorted input.
- Introsort (std::sort in C++): quicksort with fallback to heapsort if recursion depth exceeds 2 log n.
- Best for: general-purpose in-memory sorting. Fastest in practice for random data due to cache locality.

### Merge Sort
- O(n log n) guaranteed. Stable. Not in-place (O(n) extra space).
- Predictable performance (no worst-case degradation).
- Best for: linked lists (no extra space needed), external sorting, stability requirement.

### Heapsort
- O(n log n) guaranteed. In-place. Not stable.
- Poor cache behavior (jumps around the array). Rarely fastest in practice.
- Best for: guaranteed O(n log n) with O(1) extra space. Used as fallback in introsort.

### Timsort
- Adaptive merge sort. O(n log n) worst, O(n) best (nearly sorted input). Stable.
- Detects existing runs (ascending/descending). Merges runs with galloping mode.
- Default in Python (`list.sort`), Java (`Arrays.sort` for objects), Rust.
- Best for: real-world data that often has partial ordering.

### Comparison Sort Lower Bound
- Any comparison-based sort requires Ω(n log n) comparisons in the worst case.
- Proof: decision tree model with n! leaves requires height ≥ log(n!) = Ω(n log n).

## Non-Comparison Sorts

### Counting Sort
- O(n + k) where k is the range of values. Stable. Requires O(k) extra space.
- Use when k = O(n). Example: sorting ages (0-150), grades (0-100).
- Not suitable for large ranges or floating-point values.

### Radix Sort
- O(d × (n + k)) where d is digit count, k is base. Stable.
- LSD (least significant digit): process digits right to left. Simpler, uses counting sort per digit.
- MSD (most significant digit): process digits left to right. Can terminate early, supports variable-length keys.
- Best for: fixed-length integers, strings of uniform length, IP addresses.

### Bucket Sort
- O(n) expected when input is uniformly distributed over [0, 1). Use n buckets.
- Sort each bucket with insertion sort (O(1) expected per bucket if uniform).
- Best for: uniformly distributed floating-point data, histogram-based sorting.

## Binary Search Variants

### Standard Binary Search
- Find exact target in sorted array. O(log n). Compare middle, narrow half.
- Careful with integer overflow: use `mid = lo + (hi - lo) / 2` instead of `(lo + hi) / 2`.

### Lower Bound (bisect_left)
- Find first position where value ≥ target. Returns insertion point for maintaining sorted order.
- Use for: "first occurrence of X", "number of elements < X".

### Upper Bound (bisect_right)
- Find first position where value > target.
- Use for: "last occurrence of X" (upper_bound - 1), "number of elements ≤ X".

### Binary Search on Answer
- When the answer is a number and you can verify feasibility in O(f(n)):
  - Binary search over the answer space [lo, hi].
  - For each candidate mid, check if a solution of quality ≤ mid is feasible.
  - Total: O(f(n) × log(hi - lo)).
- Examples: minimum maximum distance, minimum cost to achieve threshold, capacity allocation.

### Fractional Binary Search
- For continuous domains. Use epsilon-based termination: while (hi - lo > eps).
- Or fixed number of iterations (e.g., 100 iterations gives 2^(-100) precision).

## Order Statistics

### Quickselect
- Find k-th smallest element. O(n) average, O(n²) worst.
- Partition around pivot, recurse on the side containing the k-th element.
- Introselect: quickselect with fallback to median-of-medians if recursion too deep.

### Median of Medians
- O(n) worst-case selection. Guaranteed good pivot.
- Divide into groups of 5, find median of each group, recursively find median of medians.
- High constant factor. Used for theoretical guarantees, rarely fastest in practice.

### Streaming Median
- Maintain max-heap (lower half) and min-heap (upper half).
- Balance sizes: |lower| - |upper| ∈ {0, 1}. Median = top of larger heap (or average of tops).
- O(log n) per insertion, O(1) median query.

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
- O(n/m) best case (sublinear!). O(nm) worst case.
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
