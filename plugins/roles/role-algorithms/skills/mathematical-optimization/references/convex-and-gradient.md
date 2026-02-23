# Convex Optimization and Gradient Methods

## When to load
When checking convexity of a problem, selecting a gradient descent variant, applying second-order methods, or using CVXPY/SciPy/JAX for optimization.

## Convexity

- A function f is convex if f(λx + (1-λ)y) ≤ λf(x) + (1-λ)f(y) for all λ ∈ [0,1].
- Convex problems have no local minima that are not global minima. Polynomial-time solvable.
- Verify convexity: check that the Hessian is positive semidefinite.

## Gradient Descent

- x_{k+1} = x_k - α∇f(x_k). Learning rate α controls step size.
- Convergence: O(1/k) for convex, O(ρ^k) for strongly convex (linear convergence).
- Step size selection: constant (requires knowledge of Lipschitz constant), backtracking line search, exact line search.

## Gradient Descent Variants

- **Stochastic GD (SGD)**: Use random subset of data for gradient estimate. Faster per iteration, noisier.
- **Mini-batch SGD**: Balance between full GD and SGD. Batch size 32-256 is common.
- **Momentum**: Accumulate gradient history to dampen oscillation. Nesterov momentum for acceleration.
- **Adam**: Adaptive learning rates per parameter. Combines momentum and RMSProp. Default for deep learning.
- **L-BFGS**: Quasi-Newton method using limited memory. Best for smooth convex problems with moderate dimension.

## Second-Order Methods

- **Newton's method**: x_{k+1} = x_k - H^(-1)∇f(x_k). Quadratic convergence near optimum.
- Cost: O(n³) per iteration (Hessian inversion). Use when n is small (< 1000).
- **Conjugate gradient**: Avoids explicit Hessian. O(n) per iteration. Good for large sparse systems.

## Tools

- **CVXPY** (Python): Disciplined convex programming. Automatically verifies convexity.
- **SciPy optimize**: minimize, least_squares, linear_sum_assignment.
- **JAX/PyTorch**: Automatic differentiation for gradient computation.
