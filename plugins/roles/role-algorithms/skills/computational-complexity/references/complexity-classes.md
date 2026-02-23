# Complexity Classes and NP-Completeness

## When to load
When classifying a problem's difficulty, proving NP-completeness via reduction, or determining whether a polynomial-time solution can exist.

## Core Classes

- **P**: Problems solvable in polynomial time. Efficiently solvable. Examples: sorting, shortest path, matching.
- **NP**: Problems verifiable in polynomial time. Solution can be checked fast, but finding it may be hard.
- **co-NP**: Complement of NP. "No" answers verifiable in polynomial time.
- **NP-hard**: At least as hard as every NP problem. May not be in NP (may not be decision problems).
- **NP-complete**: In NP AND NP-hard. Hardest problems in NP. If any NPC problem has a poly-time solution, then P = NP.

## Extended Classes

- **PSPACE**: Solvable with polynomial space. Includes NP. Example: quantified Boolean formulas (QBF).
- **EXP**: Solvable in exponential time. Includes PSPACE.
- **BPP**: Solvable by randomized algorithm with bounded error probability. Believed to equal P.

## Practical Implication

- If your problem is in P → implement an efficient algorithm.
- If NP-complete → no polynomial algorithm known. Use approximation, heuristics, or parameterized algorithms.
- If NP-hard but not NP-complete → may be even harder (optimization version of NPC problems).

## Common NP-Complete Problems

- **SAT**: Boolean satisfiability. Cook's theorem: first proven NPC.
- **3-SAT**: SAT restricted to 3 literals per clause. Still NPC.
- **Vertex Cover**: Find minimum set of vertices covering all edges.
- **Independent Set**: Find maximum set of non-adjacent vertices.
- **Clique**: Find maximum complete subgraph.
- **Hamiltonian Path/Cycle**: Visit every vertex exactly once.
- **TSP (decision version)**: Is there a tour of cost ≤ k?
- **Subset Sum**: Is there a subset summing to a target value?
- **Graph Coloring (k ≥ 3)**: Color vertices with k colors, no adjacent same color.
- **Knapsack (decision version)**: Can we achieve value ≥ V with weight ≤ W?
- **Set Cover**: Cover a universe with minimum number of sets.

## Reduction Technique

1. Start with a known NPC problem A.
2. Show a polynomial-time transformation from any instance of A to an instance of your problem B.
3. Prove that A has a "yes" answer iff B has a "yes" answer.
4. Prove B is in NP (provide polynomial-time verifier).
5. Conclude: B is NP-complete.

## Recognizing NP-Hard Problems in Practice

- "Find the optimal assignment/schedule/route" → likely NP-hard.
- Problem involves selecting a subset with constraints → check if it reduces to knapsack, set cover, or subset sum.
- Problem on general graphs asking for Hamiltonian properties → NP-hard.
- If a special case of your problem is NP-complete, your problem is NP-hard.
