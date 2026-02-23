# Randomized Algorithms and Practical Heuristics

## When to load
When selecting between Las Vegas and Monte Carlo algorithms, applying randomized techniques, or choosing a heuristic strategy (local search, simulated annealing, genetic algorithms) for intractable problems.

## Randomized Algorithms

### Las Vegas Algorithms
- Always produce correct output. Running time is random (expected polynomial).
- Example: Randomized quicksort. Expected O(n log n), worst O(n²) with probability 0.

### Monte Carlo Algorithms
- May produce incorrect output with bounded probability. Running time is deterministic.
- One-sided error: Miller-Rabin primality test (if "prime", might be wrong with probability < 4^(-k)).
- Two-sided error: BPP algorithms (error on both "yes" and "no" with probability < 1/3).
- Amplification: Repeat k times to reduce error to 2^(-k).

### Key Randomized Techniques
- **Random sampling**: Select random subset for estimation (random pivot in quicksort).
- **Hashing**: Randomized hash functions for universal hashing, fingerprinting.
- **Random walks**: Estimate graph properties, satisfiability (Schöning's algorithm for 3-SAT).
- **Markov Chain Monte Carlo (MCMC)**: Sample from complex distributions (Metropolis-Hastings, Gibbs sampling).

## Practical Heuristics for Intractable Problems

### Local Search
- Start with any feasible solution. Improve by making local changes (swap, move, insert).
- Terminate when no improving move exists (local optimum).
- Risk: stuck in local optima. Mitigate with restarts or metaheuristics.

### Simulated Annealing
- Accept worse solutions with probability exp(-ΔE/T) where T decreases over time.
- High temperature → exploratory (accepts bad moves). Low temperature → exploitative.
- Theoretical guarantee: converges to global optimum with slow enough cooling (impractical).

### Genetic Algorithms
- Population of candidate solutions. Selection, crossover, mutation, replacement.
- Good for multi-objective optimization and large search spaces.
- Requires careful encoding of solutions and fitness function design.

### When to Use What

| Problem Size / Quality Need | Approach |
|---|---|
| Small (n < 20) | Exact (brute force / FPT) |
| Medium, need optimality proof | Branch and bound / ILP |
| Large, need good solution fast | Greedy + local search |
| Large, need near-optimal | Approximation algorithm with guarantee |
| Very large, no quality guarantee needed | Metaheuristics (SA, GA) |
