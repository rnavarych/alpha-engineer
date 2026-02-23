# Constraint Satisfaction and Combinatorial Optimization

## When to load
When modeling scheduling, routing, assignment, or bin packing problems, applying constraint programming or SAT solvers, or following the step-by-step problem formulation process.

## Constraint Satisfaction

### CSP Formulation
- Variables with domains, constraints between variables.
- Examples: Sudoku, scheduling, timetabling, register allocation, map coloring.

### Solving Techniques
- **Backtracking**: Assign variables one by one, backtrack on constraint violation.
- **Constraint propagation**: Reduce domains before search (arc consistency, AC-3 algorithm).
- **Forward checking**: After assignment, eliminate inconsistent values from unassigned variables.
- **Variable/value ordering**: Most constrained variable first (fail-first heuristic). Least constraining value first.

### SAT Solvers
- Encode CSP as Boolean satisfiability. Modern SAT solvers (MiniSat, CryptoMiniSat, Z3) are highly optimized.
- DPLL algorithm + conflict-driven clause learning (CDCL).
- Can solve instances with millions of variables in practice.
- SMT (Satisfiability Modulo Theories): SAT with theory reasoning (integers, reals, arrays, bit vectors).

## Combinatorial Optimization

### Vehicle Routing Problem (VRP)
- Extension of TSP with multiple vehicles, capacity constraints, time windows.
- Clarke-Wright savings heuristic for initial solution. Improve with local search (2-opt, or-opt).
- Use OR-Tools routing library for production implementations.

### Scheduling
- **Job shop scheduling**: Assign operations to machines, minimize makespan. NP-hard.
- **Priority rules**: SPT (shortest processing time), EDD (earliest due date), critical ratio.
- **Constraint programming**: Model with CP-SAT (Google OR-Tools) for small-medium instances.

### Assignment Problem
- Assign n workers to n tasks minimizing total cost. Solved in O(n³) by Hungarian algorithm.
- Bottleneck assignment: Minimize maximum cost. Solvable with binary search + bipartite matching.

### Bin Packing
- Pack items into minimum number of bins with capacity C.
- **First Fit Decreasing (FFD)**: Sort items descending, assign to first bin that fits. ≤ (11/9)OPT + 6/9.
- For 2D/3D packing: use shelf algorithms, guillotine cuts, or constraint programming.

## Problem Formulation Guide

### Step-by-Step Process
1. **Identify decision variables**: What do you control?
2. **Define objective**: What do you optimize (minimize cost, maximize profit)?
3. **List constraints**: What are the limitations (capacity, time, budget)?
4. **Classify problem type**: LP, IP, convex, combinatorial?
5. **Check convexity/tractability**: Is the problem polynomial-time solvable?
6. **Select solver/algorithm**: Based on problem type, size, and required quality.

### Classification Guide

| Characteristics | Problem Type | Approach |
|---|---|---|
| Linear objective + constraints, continuous vars | LP | Simplex / interior point |
| Linear objective + constraints, integer vars | MIP | Branch and bound + cuts |
| Convex objective, convex constraints | Convex | Gradient methods / interior point |
| Combinatorial (discrete choices) | Combinatorial | Exact (small) or heuristic (large) |
| Non-convex, continuous | Non-convex | Local search + multi-start / global solvers |
| Logical constraints + discrete | CSP | Constraint programming / SAT |
