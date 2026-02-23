---
name: dynamic-programming
description: Solves optimization problems using dynamic programming — top-down memoization, bottom-up tabulation, state space design, dimension reduction, bitmask DP, interval DP, tree DP (with rerooting), DP on DAGs, and convex hull trick / divide-and-conquer optimizations. Use when solving optimization problems with overlapping subproblems, implementing memoized solutions, or converting recursive solutions to iterative DP.
allowed-tools: Read, Grep, Glob, Bash
---

# Dynamic Programming

## When to use
- Recognizing whether a problem has overlapping subproblems and optimal substructure
- Choosing between top-down memoization and bottom-up tabulation
- Designing state variables and minimizing state space dimensions
- Implementing knapsack, sequence (LCS, LIS, edit distance), interval, or grid DP patterns
- Applying bitmask DP for small subset enumeration (n ≤ 20)
- Optimizing O(n²) DP transitions with convex hull trick or D&C optimization

## Core principles
1. **State captures everything** — if future decisions need more information, the state is incomplete
2. **Bottom-up for production** — no stack overflow, easier space optimization, predictable memory access
3. **Rolling array before adding a dimension** — space optimization is almost always possible
4. **Bitmask DP is exact exponential, not a hack** — O(2^n × n) is acceptable for n ≤ 20
5. **Identify the DAG** — every DP is a shortest/longest path on a state DAG; if you can draw it, you can implement it

## Reference Files
- `references/identification-and-approach.md` — DP recognition heuristics, top-down vs bottom-up trade-offs, state variable design, state compression, redundant state elimination
- `references/classic-patterns.md` — knapsack variants (0/1, unbounded, bounded, multi-dimensional), sequence DP (LCS, LIS, edit distance), interval DP, grid/path DP
- `references/advanced-techniques.md` — bitmask DP (TSP, assignment), tree DP with rerooting, DP on DAGs, convex hull trick, D&C optimization, rolling arrays, dimension reduction, implementation checklist
