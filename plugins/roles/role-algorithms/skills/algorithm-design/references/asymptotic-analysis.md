# Asymptotic Analysis

## When to load
When analyzing algorithm efficiency, comparing time/space bounds, working through recurrence relations, or applying the Master theorem.

## Notation

- **Big-O (O)**: Upper bound — worst-case growth rate. O(n log n) means grows no faster than n log n.
- **Big-Omega (Ω)**: Lower bound — best-case guarantee. Ω(n log n) for comparison sorts means no comparison sort can do better.
- **Big-Theta (Θ)**: Tight bound — exact growth rate. Θ(n²) means both upper and lower bounds are n².
- **Little-o (o)**: Strictly less than. o(n²) means grows strictly slower than n².

## Practical Interpretation

- Constants matter for n < 10,000. An O(n²) algorithm with small constants beats O(n log n) with large constants for small inputs.
- Memory access patterns often dominate. An O(n log n) cache-friendly algorithm beats an O(n) cache-unfriendly one.
- Always specify what n represents (input size, number of edges, alphabet size).
- Distinguish worst-case from expected-case (quicksort: O(n²) worst, O(n log n) expected with random pivot).

## Amortized Analysis

### Aggregate Method
Total cost of n operations divided by n. Dynamic array doubling: n insertions cost O(2n) total → O(1) amortized per insertion.

### Accounting Method
Assign each operation an amortized cost; overpayment covers future expensive operations. Store "credits" on data structure elements.

### Potential Method
Define a potential function Φ mapping states to non-negative reals. Amortized cost = actual cost + ΔΦ.
Choose Φ so expensive operations have large negative ΔΦ (spending saved potential).

### Common Amortized Results
- Dynamic array append: O(1) amortized
- Union-Find with path compression + rank: O(α(n)) amortized (inverse Ackermann)
- Splay tree operations: O(log n) amortized
- Fibonacci heap decrease-key: O(1) amortized

## Recurrence Relations

### Master Theorem
For T(n) = aT(n/b) + O(n^d):
- If d < log_b(a): T(n) = O(n^(log_b(a)))
- If d = log_b(a): T(n) = O(n^d log n)
- If d > log_b(a): T(n) = O(n^d)

### Common Recurrences
- T(n) = 2T(n/2) + O(n) → O(n log n) — merge sort
- T(n) = T(n/2) + O(1) → O(log n) — binary search
- T(n) = 2T(n/2) + O(1) → O(n) — tree traversal
- T(n) = T(n-1) + O(n) → O(n²) — selection sort
- T(n) = 2T(n-1) + O(1) → O(2^n) — naive Fibonacci

### Substitution Method
Guess the solution form, then prove by induction. Useful when Master theorem does not apply (e.g., unequal subproblems).
