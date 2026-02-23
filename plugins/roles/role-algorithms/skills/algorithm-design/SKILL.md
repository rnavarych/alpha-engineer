---
name: algorithm-design
description: Designs algorithms with formal analysis — Big-O/Theta/Omega, amortized analysis, recurrence relations (Master theorem), correctness proofs (loop invariants, induction, reduction), and paradigm selection (greedy, divide-and-conquer, dynamic programming, backtracking). Use when analyzing efficiency, proving correctness, comparing approaches, or selecting optimal algorithms for given constraints.
allowed-tools: Read, Grep, Glob, Bash
---

# Algorithm Design

## When to use
- Analyzing algorithm efficiency and comparing time/space bounds
- Selecting the right paradigm: greedy, divide-and-conquer, DP, or backtracking
- Proving algorithm correctness with loop invariants or induction
- Solving recurrence relations and applying the Master theorem
- Evaluating space-time trade-offs under memory or latency constraints
- Explaining why a greedy choice is (or is not) valid

## Core principles
1. **Prove before you code** — choose a paradigm and establish correctness argument before implementation
2. **Tight bounds over loose bounds** — Big-Theta tells the truth; Big-O alone can mislead
3. **Constants matter at small n** — O(n log n) with large constants can lose to O(n²) for n < 10,000
4. **Amortized cost is not average cost** — a single expensive operation does not break O(1) amortized
5. **Greedy requires proof** — exchange argument or cut property; intuition is not a proof

## Reference Files
- `references/asymptotic-analysis.md` — notation (O/Ω/Θ/o), practical interpretation, amortized methods (aggregate, accounting, potential), recurrence relations and Master theorem
- `references/design-paradigms.md` — greedy (exchange argument, classic examples), divide-and-conquer (split/merge decisions), dynamic programming (when DP beats greedy), backtracking (pruning strategies)
- `references/correctness-and-tradeoffs.md` — loop invariants, structural induction, reduction proofs, space-time trade-off decision matrix
