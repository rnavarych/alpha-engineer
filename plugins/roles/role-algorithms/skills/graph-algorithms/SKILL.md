---
name: role-algorithms:graph-algorithms
description: Implements graph algorithms — BFS/DFS traversal, shortest paths (Dijkstra, Bellman-Ford, Floyd-Warshall, A*, Johnson's), minimum spanning trees (Kruskal, Prim), topological sort, strongly connected components (Tarjan, Kosaraju), maximum flow (Ford-Fulkerson, Dinic), and bipartite matching (Hopcroft-Karp, Hungarian). Use when solving traversal, shortest path, network flow, connectivity, or scheduling problems.
allowed-tools: Read, Grep, Glob, Bash
---

# Graph Algorithms

## When to use
- Modeling a problem as a graph and selecting the right traversal or optimization algorithm
- Finding shortest paths with positive weights (Dijkstra), negative weights (Bellman-Ford), or all pairs (Floyd-Warshall)
- Building minimum spanning trees for network design problems
- Resolving task dependency order via topological sort
- Finding strongly connected components for 2-SAT or condensation graphs
- Computing max flow / min cut or bipartite matching for allocation problems
- Pathfinding in grids or maps with a heuristic (A*)

## Core principles
1. **Representation determines complexity** — adjacency list for sparse, matrix for dense; wrong choice costs orders of magnitude
2. **Negative weights break Dijkstra** — if any edge weight is negative, use Bellman-Ford; don't assume inputs are clean
3. **Max-flow = min-cut** — network flow problems often hide as cut problems; recognize the dual
4. **Topological sort = DP on a DAG** — if you can sort topologically, you can compute DP in one pass
5. **Kruskal needs Union-Find; Prim needs a heap** — pick based on graph density, not familiarity

## Reference Files
- `references/representations-and-traversal.md` — adjacency list/matrix/edge list selection criteria, BFS (unweighted shortest path, bipartite check), DFS (cycle detection, articulation points), DFS edge classification
- `references/shortest-paths-and-mst.md` — Dijkstra, Bellman-Ford, Floyd-Warshall, A* (admissible heuristics), Johnson's algorithm, algorithm selection table, Kruskal and Prim with cut/cycle properties
- `references/advanced-graph.md` — topological sort (Kahn's BFS + DFS post-order), SCCs (Tarjan and Kosaraju), Dinic's max flow, bipartite matching (Hopcroft-Karp, Hungarian, Kuhn's), flow application patterns
