---
name: role-algorithms:mathematical-optimization
description: Applies mathematical optimization — linear programming (simplex, interior point, duality), integer/mixed-integer programming (branch-and-bound, cutting planes), convex optimization (gradient descent variants, Adam, L-BFGS, Newton), constraint satisfaction (backtracking, AC-3, SAT/SMT solvers), and combinatorial optimization (VRP, scheduling, assignment, bin packing). Use when formulating optimization problems, selecting solvers, or solving scheduling/allocation/routing problems.
allowed-tools: Read, Grep, Glob, Bash
---

# Mathematical Optimization

## When to use
- Formulating a real-world problem as a mathematical optimization model
- Choosing between LP, MIP, convex, CSP, or combinatorial approaches
- Selecting the right gradient descent variant for a machine learning or fitting problem
- Solving scheduling, assignment, routing, or bin packing problems
- Applying SAT/SMT solvers or constraint programming for logical constraint problems
- Evaluating solver options (PuLP, CVXPY, OR-Tools, Gurobi, Z3)

## Core principles
1. **Formulate before you code** — identify variables, objective, and constraints explicitly before touching a solver
2. **Tight LP relaxation = faster MIP** — every improvement to the relaxation bound shrinks the branch-and-bound tree
3. **Convexity is the dividing line** — convex problems are reliably solvable; non-convex require restarts and heuristics
4. **Adam is not always the answer** — L-BFGS beats Adam on smooth well-conditioned problems with moderate dimension
5. **CP-SAT over custom backtracking** — Google OR-Tools CP-SAT handles constraint propagation and search orders better than hand-rolled solvers

## Reference Files
- `references/linear-and-integer-programming.md` — LP formulation, simplex vs interior point, duality and shadow prices, MIP branch-and-bound, Big-M method, symmetry breaking, solver library options
- `references/convex-and-gradient.md` — convexity verification (Hessian PSD), gradient descent variants (SGD, Adam, L-BFGS), Newton/conjugate gradient second-order methods, CVXPY/SciPy/JAX tooling
- `references/constraint-and-combinatorial.md` — CSP formulation, backtracking + constraint propagation, SAT/SMT solvers (Z3, CDCL), VRP/scheduling/assignment/bin packing patterns, problem classification guide
