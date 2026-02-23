# Binary Search Variants and Order Statistics

## When to load
When implementing binary search (standard, lower/upper bound, answer-space), quickselect, median-of-medians, or a streaming median with two heaps.

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
