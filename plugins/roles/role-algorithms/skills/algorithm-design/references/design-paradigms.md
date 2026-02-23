# Algorithm Design Paradigms

## When to load
When selecting an algorithm strategy — greedy, divide-and-conquer, dynamic programming, or backtracking — or when proving why a chosen paradigm is correct.

## Greedy

- **When to use**: Optimal substructure + greedy choice property. Local optimal → global optimal.
- **Proof technique**: Exchange argument (swapping a non-greedy choice for greedy does not worsen solution).
- **Classic examples**: Activity selection, Huffman coding, Kruskal's MST, fractional knapsack, interval scheduling.
- **Red flag**: If you cannot prove the greedy choice property, consider DP instead.

## Divide and Conquer

- **When to use**: Problem splits into independent subproblems of the same type.
- **Key decisions**: How to divide, how to merge, base case size.
- **Classic examples**: Merge sort, quicksort, closest pair of points, Strassen's matrix multiplication, FFT.
- **Optimization**: Choose base case size to switch to simpler algorithm (e.g., insertion sort for n < 16).

## Dynamic Programming

- **When to use**: Overlapping subproblems + optimal substructure. Greedy fails.
- **Design steps**: Define state → define transitions → identify base cases → determine computation order.
- **Classic examples**: Knapsack, LCS, edit distance, matrix chain multiplication, shortest paths (Bellman-Ford).
- **See**: `dynamic-programming` skill for comprehensive DP patterns.

## Backtracking

- **When to use**: Search for solutions in a combinatorial space with pruning.
- **Key optimization**: Prune early with constraint propagation. Fail fast on invalid partial solutions.
- **Classic examples**: N-Queens, Sudoku solver, graph coloring, subset sum.
- **Enhancement**: Add memoization to convert backtracking → DP when subproblems overlap.
