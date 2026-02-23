# Correctness Proofs and Space-Time Trade-offs

## When to load
When proving algorithm correctness via loop invariants, induction, or reduction — or when evaluating space-time trade-offs for a given constraint.

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

### Decision Criteria
- Memory-constrained environments → prefer space-efficient approaches
- Latency-critical paths → prefer precomputation and caching
- One-time computation → space does not matter; optimize for time
- Streaming data → bounded memory required; use online algorithms
