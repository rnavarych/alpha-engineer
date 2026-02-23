# Approximation Algorithms and Parameterized Complexity

## When to load
When designing or selecting approximation algorithms for NP-hard problems, working with PTAS/FPTAS, understanding inapproximability bounds, or applying fixed-parameter tractability.

## Approximation Algorithms

### Approximation Ratios
- An α-approximation produces a solution within factor α of optimal.
- Minimization: ALG ≤ α × OPT (α ≥ 1).
- Maximization: ALG ≥ OPT / α (α ≥ 1).

### Classic Approximation Results

| Problem | Algorithm | Ratio | Approach |
|---|---|---|---|
| Vertex Cover | Greedy edge matching | 2 | Take both endpoints of maximal matching |
| Set Cover | Greedy (largest uncovered) | O(log n) | Greedy by coverage ratio |
| Metric TSP | Christofides | 1.5 | MST + minimum weight perfect matching |
| MAX-SAT | Randomized rounding | 3/4 | LP relaxation + rounding |
| Knapsack | FPTAS | (1+ε) | DP with scaled profits |
| Bin Packing | First Fit Decreasing | ~1.22 | Sort descending, fit greedily |

### PTAS and FPTAS
- **PTAS (Polynomial-Time Approximation Scheme)**: (1+ε)-approximation in time polynomial in n for any fixed ε.
- **FPTAS (Fully PTAS)**: Polynomial in both n and 1/ε. Strongest form of approximation.
- Knapsack has an FPTAS: O(n²/ε) time.
- Unless P = NP, Set Cover has no constant-factor approximation better than O(log n).

### Inapproximability
- Some problems cannot be approximated below certain thresholds unless P = NP.
- TSP (general): No constant-factor approximation.
- Clique: No n^(1-ε) approximation for any ε > 0.
- Set Cover: No (1-ε)ln(n) approximation.

## Parameterized Complexity

### Fixed-Parameter Tractability (FPT)
- Time f(k) × poly(n) where k is a parameter (not input size).
- Problem is hard in general but tractable when parameter k is small.
- Example: Vertex Cover parameterized by solution size k: O(2^k × n) — exponential in k but polynomial in n.

### Common Parameters
- **Solution size k**: Vertex cover (2^k × n), k-clique (n^k but FPT with faster algorithms).
- **Treewidth w**: Many NP-hard problems solvable in O(f(w) × n) on bounded-treewidth graphs.
- **Maximum degree Δ**: Some problems become tractable on bounded-degree graphs.

### Kernelization
- Polynomial-time preprocessing that reduces instance to size f(k) (kernel).
- If a good kernel exists, the problem is FPT.
- Vertex Cover: kernel of size 2k (remove degree-0/1 vertices, apply crown decomposition).

### When to Use FPT
- When the parameter k is expected to be small in practice (e.g., k ≤ 20).
- When exact solutions are needed but the problem is NP-hard in general.
- Prefer FPT over brute force: 2^k × n beats n^k for small k.
