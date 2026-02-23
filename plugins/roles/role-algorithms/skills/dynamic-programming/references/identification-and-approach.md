# Identifying DP Problems and Choosing an Approach

## When to load
When deciding whether a problem is a DP candidate, choosing between top-down memoization and bottom-up tabulation, or designing the state space.

## Identifying DP Problems

A problem is a DP candidate when:
- **Optimal substructure**: Optimal solution contains optimal solutions to subproblems.
- **Overlapping subproblems**: Same subproblems are solved multiple times in a naive recursion.
- **Decision at each step**: At each stage, you make a choice that affects future states.

Red flags that DP applies:
- "Find the minimum/maximum cost to..."
- "Count the number of ways to..."
- "Is it possible to..." (often a subset/reachability DP)
- Naive recursive solution has exponential time with repeated states

## Top-Down vs Bottom-Up

### Top-Down (Memoization)
- Start from the target state and recurse to base cases. Cache computed results.
- Pros: Only computes reachable states. Natural to write from recursive formulation.
- Cons: Recursion stack overhead. Harder to optimize space. Cache lookup overhead.
- Use `@functools.cache` (Python), `Map`/`HashMap` memoization (JS/Java).

### Bottom-Up (Tabulation)
- Fill table from base cases to target state in dependency order.
- Pros: No recursion overhead. Easier to optimize space (rolling arrays). Predictable memory access.
- Cons: Must determine computation order. May compute unreachable states.
- Prefer for production code and when space optimization is needed.

## State Design

### Defining State Variables
- The state must capture all information needed to make future decisions.
- Minimize the number of state dimensions (each dimension multiplies state space).
- Ask: "What do I need to know at this point to make the optimal remaining decisions?"

### State Compression
- Represent sets as bitmasks (up to ~20 elements): state includes `mask` instead of explicit set.
- Encode multi-dimensional state as a single integer: `state = i * W + j`.
- Use coordinate compression when values are sparse but indices matter.

### Eliminating Redundant State
- If a state variable can be derived from others, remove it.
- Example: In knapsack, if you track items and weight, value is derivable — do not store it separately.
