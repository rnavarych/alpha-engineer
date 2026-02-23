---
name: sorting-and-searching
description: Implements sorting and searching algorithms — comparison sorts (quicksort/introsort, merge sort, heapsort, Timsort), non-comparison sorts (radix, counting, bucket), binary search variants (lower/upper bound, answer-space search), order statistics (quickselect, streaming median), string searching (KMP, Rabin-Karp, Boyer-Moore, Aho-Corasick, suffix arrays), and external sorting. Use when implementing sort orders, optimizing search in sorted data, multi-pattern string matching, or sorting data larger than memory.
allowed-tools: Read, Grep, Glob, Bash
---

# Sorting and Searching

## When to use
- Selecting a sorting algorithm based on stability, memory, key type, or data distribution
- Implementing lower/upper bound binary search or binary search on an answer space
- Finding the k-th smallest element or maintaining a streaming median
- Implementing single-pattern (KMP, Boyer-Moore) or multi-pattern (Aho-Corasick) string matching
- Building suffix arrays for repeated substring queries on large texts
- Sorting datasets that exceed available memory (external k-way merge sort)

## Core principles
1. **Timsort wins on real-world data** — natural runs and partial ordering are the norm, not the exception
2. **Radix sort beats comparison sorts when key range is bounded** — O(dn) < O(n log n) when d is small
3. **Binary search on the answer, not just the array** — if you can check feasibility in O(f(n)), you can binary search the answer space
4. **Boyer-Moore is sublinear on average** — for single-pattern search on natural text it reads fewer characters than the input length
5. **Aho-Corasick when patterns > 1** — one pass over the text regardless of how many patterns you search for

## Reference Files
- `references/comparison-and-noncomparison-sorts.md` — quicksort (introsort fallback), merge sort, heapsort, Timsort (galloping mode), comparison lower bound, counting sort, radix sort (LSD/MSD), bucket sort with selection guide
- `references/binary-search-and-order-statistics.md` — standard search, lower/upper bound (bisect_left/right), binary search on answer space, fractional binary search, quickselect, median-of-medians, streaming median with two heaps
- `references/string-searching-and-external.md` — KMP failure function, Rabin-Karp rolling hash, Boyer-Moore bad-character and good-suffix rules, Aho-Corasick automaton, suffix arrays with LCP, external k-way merge sort, I/O optimization strategies
