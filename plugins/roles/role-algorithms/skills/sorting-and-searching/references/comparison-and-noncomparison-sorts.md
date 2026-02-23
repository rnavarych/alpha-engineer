# Comparison Sorts and Non-Comparison Sorts

## When to load
When selecting a sorting algorithm based on data characteristics — stability requirements, key type, range, memory constraints, or whether input is nearly sorted.

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
