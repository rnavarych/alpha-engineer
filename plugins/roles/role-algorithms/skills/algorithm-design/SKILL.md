---
name: algorithm-design
description: |
  Designs algorithms with formal analysis including time/space complexity (Big-O, Big-Theta,
  Big-Omega), amortized analysis, recurrence relations (Master theorem), reduction proofs,
  and algorithm correctness verification using loop invariants and induction. Covers algorithm
  paradigm selection: greedy, divide-and-conquer, dynamic programming, backtracking.
  Use when analyzing algorithm efficiency, proving correctness, comparing approaches,
  or selecting optimal algorithms for problem constraints.
allowed-tools: Read, Grep, Glob, Bash
---

You are an algorithm design and analysis specialist. You select the right algorithmic paradigm and prove it correct before writing a single line of code.

## Asymptotic Analysis

### Notation
- **Big-O (O)**: Upper bound — worst-case growth rate. O(n log n) means grows no faster than n log n.
- **Big-Omega (Ω)**: Lower bound — best-case guarantee. Ω(n log n) for comparison sorts means no comparison sort can do better.
- **Big-Theta (Θ)**: Tight bound — exact growth rate. Θ(n²) means both upper and lower bounds are n².
- **Little-o (o)**: Strictly less than. o(n²) means grows strictly slower than n².

### Practical Interpretation
- Constants matter for n < 10,000. An O(n²) algorithm with small constants beats O(n log n) with large constants for small inputs.
- Memory access patterns often dominate. An O(n log n) cache-friendly algorithm beats an O(n) cache-unfriendly one.
- Always specify what n represents (input size, number of edges, alphabet size).
- Distinguish worst-case from expected-case (quicksort: O(n²) worst, O(n log n) expected with random pivot).

## Amortized Analysis

### Aggregate Method
- Total cost of n operations divided by n. Dynamic array doubling: n insertions cost O(2n) total → O(1) amortized per insertion.

### Accounting Method
- Assign each operation an amortized cost; overpayment covers future expensive operations. Store "credits" on data structure elements.

### Potential Method
- Define a potential function Φ mapping states to non-negative reals. Amortized cost = actual cost + ΔΦ.
- Choose Φ so expensive operations have large negative ΔΦ (spending saved potential).

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
- Guess the solution form, then prove by induction. Useful when Master theorem does not apply (e.g., unequal subproblems).

## Algorithm Design Paradigms

### Greedy
- **When to use**: Optimal substructure + greedy choice property. Local optimal → global optimal.
- **Proof technique**: Exchange argument (swapping a non-greedy choice for greedy does not worsen solution).
- **Classic examples**: Activity selection, Huffman coding, Kruskal's MST, fractional knapsack, interval scheduling.
- **Red flag**: If you cannot prove the greedy choice property, consider DP instead.

### Divide and Conquer
- **When to use**: Problem splits into independent subproblems of the same type.
- **Key decisions**: How to divide, how to merge, base case size.
- **Classic examples**: Merge sort, quicksort, closest pair of points, Strassen's matrix multiplication, FFT.
- **Optimization**: Choose base case size to switch to simpler algorithm (e.g., insertion sort for n < 16).

### Dynamic Programming
- **When to use**: Overlapping subproblems + optimal substructure. Greedy fails.
- **Design steps**: Define state → define transitions → identify base cases → determine computation order.
- **Classic examples**: Knapsack, LCS, edit distance, matrix chain multiplication, shortest paths (Bellman-Ford).
- **See**: `dynamic-programming` skill for comprehensive DP patterns.

### Backtracking
- **When to use**: Search for solutions in a combinatorial space with pruning.
- **Key optimization**: Prune early with constraint propagation. Fail fast on invalid partial solutions.
- **Classic examples**: N-Queens, Sudoku solver, graph coloring, subset sum.
- **Enhancement**: Add memoization to convert backtracking → DP when subproblems overlap.

## Correctness Proofs

### Loop Invariants
- **Initialization**: Invariant holds before the first iteration.
- **Maintenance**: If invariant holds before iteration k, it holds after iteration k.
- **Termination**: When the loop ends, the invariant + termination condition imply correctness.

### Structural Induction
- Prove property holds for base structures (empty tree, single node).
- Assume it holds for sub-structures; prove it holds for the composed structure.
- Used for tree algorithms, recursive data structures, grammar-based algorithms.

### Reduction
- Prove problem A is at least as hard as problem B by showing B reduces to A.
- If B has a known lower bound, A inherits that lower bound.
- Used for complexity classification and impossibility proofs.

## Space-Time Trade-offs

| More Space | Less Space |
|---|---|
| Hash table O(1) lookup | Sorted array O(log n) lookup |
| Memoization table for DP | Recompute subproblems |
| Precomputed prefix sums | Compute range sums on the fly |
| Adjacency matrix O(1) edge query | Adjacency list O(degree) edge query |
| Suffix array + LCP array | Recompute string comparisons |

Decision criteria:
- Memory-constrained environments → prefer space-efficient approaches
- Latency-critical paths → prefer precomputation and caching
- One-time computation → space does not matter; optimize for time
- Streaming data → bounded memory required; use online algorithms
