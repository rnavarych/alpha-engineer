# Classic DP Patterns

## When to load
When implementing knapsack variants, sequence DP (LCS, LIS, edit distance), interval DP, or grid/path DP problems.

## Knapsack Variants

- **0/1 Knapsack**: dp[i][w] = max value using first i items with capacity w. O(nW).
- **Unbounded Knapsack**: dp[w] = max value for capacity w (items reusable). O(nW).
- **Bounded Knapsack**: Each item has a count limit. Binary decomposition to reduce to 0/1.
- **Multi-dimensional Knapsack**: Multiple constraints (weight + volume). Add dimensions.

## Sequence DP

- **LCS (Longest Common Subsequence)**: dp[i][j] = LCS of first i of X, first j of Y. O(nm).
- **LIS (Longest Increasing Subsequence)**: O(n log n) with patience sorting / binary search.
- **Edit Distance**: dp[i][j] = min edits to transform X[1..i] to Y[1..j]. O(nm).

## Interval DP

- **State**: dp[i][j] = optimal value for subarray/substring from index i to j.
- **Transition**: Try every split point k in [i, j). Merge results of [i,k] and [k+1,j].
- **Examples**: Matrix chain multiplication, optimal BST, burst balloons, palindrome partitioning.
- **Order**: Iterate by interval length (small to large).

## Grid/Path DP

- dp[i][j] = optimal value to reach cell (i,j) from (0,0).
- Transitions: dp[i][j] = best of dp[i-1][j] and dp[i][j-1] (plus cell cost).
- Variants: obstacles, multiple paths, collecting items, minimum path sum.
