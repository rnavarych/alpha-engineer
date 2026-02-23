# Advanced DP Techniques and Space Optimization

## When to load
When applying bitmask DP, tree DP, rerooting, convex hull trick, divide-and-conquer optimization, or reducing space via rolling arrays and dimension reduction.

## Bitmask DP

- State includes a bitmask representing a subset of n elements (n ≤ 20).
- dp[mask][i] = optimal value considering the subset `mask` with last element i.
- **TSP**: dp[mask][i] = shortest path visiting cities in `mask`, ending at city i. O(2^n × n²).
- **Assignment problem**: dp[mask] = min cost assigning first popcount(mask) tasks using workers in mask.

## Tree DP

- DFS-based computation. dp[v] depends on dp values of children of v.
- **Examples**: Longest path in tree, max independent set, tree diameter, subtree queries.
- **Rerooting technique**: Compute dp for all nodes as root in O(n) total (two DFS passes).

## DP on DAGs

- Topological sort, then process in order. Shortest/longest path, counting paths.
- Any DP can be viewed as a DAG of states with transitions as edges.

## Convex Hull Trick

- Optimizes DP of the form dp[i] = min(dp[j] + b[j] × a[i]) over j < i.
- Maintain a convex hull of linear functions. Query minimum at point a[i].
- Reduces O(n²) to O(n log n) or O(n) if queries are monotone.
- Li Chao tree: alternative for non-monotone queries in O(n log C).

## Divide and Conquer Optimization

- For dp[i][j] = min over k (dp[i-1][k] + cost(k+1, j)) when optimal k is monotone.
- Reduces O(n × m × n) to O(n × m × log n).

## Space Optimization

### Rolling Array
- When dp[i] depends only on dp[i-1], keep only two rows. O(n) space instead of O(n²).
- 0/1 Knapsack: single row, iterate capacity in reverse to avoid using updated values.

### Dimension Reduction
- If dp[i][j] depends only on dp[i-1][j] and dp[i-1][j-1], reduce to 1D array with careful iteration order.
- LCS space optimization: O(min(m,n)) space with Hirschberg's algorithm for reconstruction.

### State-Space Pruning
- Skip unreachable states. In top-down, this is automatic. In bottom-up, track reachable set.
- Prune states that cannot lead to improvement over the current best known solution.

## Implementation Checklist

1. Define the state clearly (what does dp[...] represent?)
2. Write the recurrence relation with all transitions
3. Identify base cases
4. Determine computation order (dependencies must be computed before dependents)
5. Implement and verify with small examples
6. Optimize space if needed (rolling array, dimension reduction)
7. Test edge cases: empty input, single element, all same values, maximum constraints
