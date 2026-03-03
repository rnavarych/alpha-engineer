---
name: role-algorithms:computational-complexity
description: Analyzes computational complexity — P vs NP classification, NP-completeness proofs and reductions, approximation algorithms (PTAS, FPTAS) with provable guarantees, parameterized complexity (FPT, kernelization), randomized algorithms (Las Vegas, Monte Carlo), and practical heuristics for intractable problems. Use when classifying hardness, proving reductions, or selecting between exact and heuristic approaches.
allowed-tools: Read, Grep, Glob, Bash
---

# Computational Complexity

## When to use
- Classifying a problem as P, NP-complete, or NP-hard before choosing an algorithm
- Proving a problem is NP-complete via polynomial-time reduction
- Selecting between exact, approximation, FPT, or heuristic approaches
- Designing approximation algorithms with provable guarantees (PTAS, FPTAS)
- Deciding when randomized algorithms (Las Vegas vs Monte Carlo) are appropriate
- Identifying when a parameter makes an otherwise hard problem tractable (FPT)

## Core principles
1. **Classify before solving** — knowing a problem is NP-hard changes the entire strategy
2. **Reduction direction matters** — reduce FROM a known hard problem TO yours to prove hardness
3. **Approximation ratio is a guarantee, not a hope** — an unproven heuristic is not an approximation algorithm
4. **Small parameter = FPT opportunity** — exponential in k is fine when k ≤ 20
5. **Amplify randomized correctness** — repeat Monte Carlo k times to push error below 2^(-k)

## Reference Files
- `references/complexity-classes.md` — P, NP, NP-complete, NP-hard, PSPACE definitions; common NPC problems; reduction technique step-by-step; recognizing NP-hard problems in practice
- `references/approximation-and-fpt.md` — approximation ratios, classic results table, PTAS/FPTAS definitions, inapproximability bounds, FPT algorithms, kernelization, treewidth parameter
- `references/randomized-and-heuristics.md` — Las Vegas vs Monte Carlo, amplification, MCMC, local search, simulated annealing, genetic algorithms, when-to-use decision table
