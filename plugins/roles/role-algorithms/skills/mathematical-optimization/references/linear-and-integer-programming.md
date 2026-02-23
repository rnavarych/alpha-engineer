# Linear Programming and Integer Programming

## When to load
When formulating LP or MIP problems, selecting between simplex and interior point methods, working with duality/shadow prices, or applying branch-and-bound with cutting planes.

## Linear Programming

### Problem Formulation
- Minimize c^T × x subject to Ax ≤ b, x ≥ 0.
- Decision variables: what you control (quantities, allocations, flows).
- Objective function: what you optimize (cost, profit, time).
- Constraints: limitations (capacity, budget, demand, supply).

### Simplex Method
- Moves along vertices of the feasible polytope. Exponential worst case but fast in practice.
- Degeneracy (cycling): use Bland's rule or lexicographic pivoting.
- Typically the fastest for moderate-size problems (thousands of variables/constraints).

### Interior Point Methods
- Traverse the interior of the feasible region. Polynomial time guaranteed.
- Better than simplex for very large, sparse problems (millions of variables).
- Warm-starting is harder than with simplex (disadvantage for iterative re-solving).

### Duality
- Every LP has a dual problem. Strong duality: optimal values are equal.
- Dual variables give sensitivity information (shadow prices): value of relaxing each constraint by one unit.
- Complementary slackness: at optimality, either constraint is tight or dual variable is zero.

### Tools and Libraries
- **Python**: PuLP (modeling), SciPy linprog, CVXPY (convex modeling)
- **Specialized**: Google OR-Tools, Gurobi, CPLEX (commercial, fastest)
- **Julia**: JuMP (algebraic modeling language)
- Model in a high-level language, solve with optimized backend.

## Integer Programming

### Mixed-Integer Programming (MIP)
- Some or all variables restricted to integers. Much harder than LP (NP-hard).
- Branch and bound: solve LP relaxation, branch on fractional variables.
- Cutting planes: add constraints to tighten LP relaxation (Gomory cuts, cover cuts).

### Formulation Tricks
- **Binary indicator**: x ∈ {0,1} to represent yes/no decisions.
- **Big-M method**: Link binary indicators to continuous variables with large constant M.
- **SOS constraints (Special Ordered Sets)**: Model piecewise linear functions, exclusive choices.
- **Symmetry breaking**: Add constraints to eliminate equivalent solutions (reduce search space).

### Practical Tips
- Tighten the LP relaxation as much as possible (better bounds → faster solving).
- Set optimality gap tolerance (e.g., 1% gap acceptable for faster termination).
- Provide a good initial feasible solution (warm start) to accelerate branch and bound.
- MIP solving time is highly variable: small formulation changes can dramatically affect performance.
