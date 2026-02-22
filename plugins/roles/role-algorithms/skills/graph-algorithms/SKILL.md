---
name: graph-algorithms
description: |
  Implements graph algorithms including BFS, DFS, shortest paths (Dijkstra, Bellman-Ford,
  Floyd-Warshall, A*), minimum spanning trees (Kruskal, Prim), topological sort, strongly
  connected components (Tarjan, Kosaraju), maximum flow (Ford-Fulkerson, Dinic), and
  bipartite matching. Use when solving graph traversal, shortest path, network flow,
  connectivity, or scheduling problems.
allowed-tools: Read, Grep, Glob, Bash
---

You are a graph algorithms specialist. You model problems as graphs and select the right traversal or optimization algorithm.

## Graph Representations

### Adjacency List
- Space: O(V + E). Edge lookup: O(degree). Iteration over neighbors: O(degree).
- Best for sparse graphs (E << V²). Default choice for most applications.
- Implementation: `Map<Node, List<(Node, Weight)>>` or array of vectors.

### Adjacency Matrix
- Space: O(V²). Edge lookup: O(1). Iteration over neighbors: O(V).
- Best for dense graphs (E ≈ V²) or when O(1) edge queries are critical.
- Use for Floyd-Warshall, transitive closure, small graphs.

### Edge List
- Space: O(E). Edge lookup: O(E). Simple but limited.
- Best for: Kruskal's MST (sort edges), batch graph processing, graph input format.

### Selection Criteria
- Sparse graph (E = O(V)): adjacency list
- Dense graph (E = O(V²)): adjacency matrix
- Edge-centric operations (sort/filter edges): edge list
- Need both neighbors and reverse neighbors: store both forward and reverse adjacency lists

## Traversal

### BFS (Breadth-First Search)
- Queue-based. Visits nodes level by level. O(V + E).
- Finds shortest path in unweighted graphs (minimum edges).
- Applications: shortest path (unweighted), connected components, bipartite check, level-order traversal.

### DFS (Depth-First Search)
- Stack-based (or recursive). Explores deep before backtracking. O(V + E).
- Use iterative DFS to avoid stack overflow on deep graphs.
- Applications: cycle detection, topological sort, connected components, articulation points, bridges.

### DFS Edge Classification
- **Tree edge**: Edge to unvisited vertex (part of DFS tree).
- **Back edge**: Edge to ancestor → cycle exists (in directed graph).
- **Forward edge**: Edge to descendant (directed only).
- **Cross edge**: Edge to visited non-ancestor/non-descendant (directed only).

## Shortest Paths

### Dijkstra's Algorithm
- Single source, non-negative weights. O((V + E) log V) with binary heap.
- Use priority queue (min-heap). Relax edges greedily.
- Does NOT work with negative edge weights. Use Bellman-Ford instead.

### Bellman-Ford
- Single source, handles negative weights. O(VE).
- Detects negative-weight cycles (if relaxation possible after V-1 iterations).
- Use when negative edges exist or negative cycle detection is needed.

### Floyd-Warshall
- All pairs shortest paths. O(V³). Works with negative weights (no negative cycles).
- Simple implementation: three nested loops. Space: O(V²).
- Use for small graphs (V < 500) when all-pairs distances are needed.

### A* Search
- Heuristic-guided shortest path. O(E) with perfect heuristic, worse with poor heuristic.
- Requires admissible heuristic h(n) ≤ actual distance (never overestimates).
- Consistent heuristic (h(n) ≤ cost(n,m) + h(m)) avoids reopening nodes.
- Use for pathfinding in grids, maps, game AI. Common heuristics: Manhattan, Euclidean, Chebyshev.

### Johnson's Algorithm
- All pairs shortest paths for sparse graphs. O(V² log V + VE).
- Reweight edges with Bellman-Ford to eliminate negatives, then run Dijkstra from each vertex.
- Better than Floyd-Warshall when E << V².

### Selection Table
| Scenario | Algorithm | Complexity |
|---|---|---|
| Single source, positive weights | Dijkstra | O((V+E) log V) |
| Single source, negative weights | Bellman-Ford | O(VE) |
| All pairs, dense graph | Floyd-Warshall | O(V³) |
| All pairs, sparse graph | Johnson's | O(V² log V + VE) |
| Grid/map pathfinding | A* | O(E) best case |
| Unweighted shortest path | BFS | O(V + E) |

## Minimum Spanning Trees

### Kruskal's Algorithm
- Sort edges by weight. Add edges that do not create cycles (union-find). O(E log E).
- Best for sparse graphs or when edges are already available as a list.

### Prim's Algorithm
- Grow MST from a start vertex. Add cheapest edge to non-tree vertex. O((V + E) log V) with binary heap.
- Best for dense graphs. Similar to Dijkstra but tracks minimum edge weight, not path cost.

### Properties
- MST is unique if all edge weights are distinct.
- Cut property: Lightest edge crossing any cut must be in the MST.
- Cycle property: Heaviest edge in any cycle is not in the MST.

## Topological Sort

### Kahn's Algorithm (BFS-based)
- Compute in-degree of all vertices. Enqueue vertices with in-degree 0.
- Process queue: remove vertex, reduce in-degree of neighbors, enqueue if in-degree becomes 0.
- Detects cycles: if processed count < V, cycle exists.

### DFS-based
- Run DFS. Add vertex to result after all descendants are visited (post-order). Reverse the result.
- Simpler to implement but does not directly detect cycles without extra bookkeeping.

### Applications
- Build system dependency resolution
- Course prerequisite ordering
- Scheduling tasks with dependencies
- DP on DAGs (process in topological order)

## Strongly Connected Components

### Tarjan's Algorithm
- Single DFS pass. Uses discovery time and low-link values. O(V + E).
- Maintains a stack of vertices in current DFS path. SCC found when low-link equals discovery time.

### Kosaraju's Algorithm
- Two DFS passes: first on original graph (compute finish order), second on reversed graph. O(V + E).
- Conceptually simpler than Tarjan's. Both are O(V + E).

### Applications
- 2-SAT solver (each variable and its negation are nodes; implications are edges)
- Condensation graph (collapse each SCC to a single node → DAG)
- Detecting mutual dependencies in systems

## Network Flow

### Ford-Fulkerson Method
- Find augmenting paths from source to sink. Increase flow along each path. Repeat until no augmenting path exists.
- With BFS (Edmonds-Karp): O(VE²). Guarantees termination with integer capacities.

### Dinic's Algorithm
- Build level graph with BFS. Find blocking flows with DFS. O(V²E).
- Much faster in practice. O(E√V) for unit-capacity graphs.
- Preferred over Edmonds-Karp for most applications.

### Applications of Max-Flow
- **Min-cut**: Max-flow = min-cut (Ford-Fulkerson theorem). Reachable vertices from source in residual graph form source side of min-cut.
- **Bipartite matching**: Model as flow network with unit capacities. Max matching = max flow.
- **Edge-disjoint paths**: Max number of edge-disjoint s-t paths = max flow with unit capacities.
- **Project selection**: Model profit/cost as capacities. Min-cut gives optimal selection.

## Bipartite Graphs

### Bipartite Check
- BFS/DFS with 2-coloring. Graph is bipartite iff no odd-length cycle exists.

### Maximum Matching
- **Hopcroft-Karp**: O(E√V). Best for bipartite matching. Multiple augmenting paths per phase.
- **Hungarian algorithm**: O(V³). Optimal for weighted bipartite matching (assignment problem).
- **Kuhn's algorithm**: O(VE). Simple augmenting path approach. Good for small instances.

### Applications
- Job assignment (workers to tasks)
- Stable matching (Gale-Shapley for stable marriage)
- Vertex cover in bipartite graphs (König's theorem: max matching = min vertex cover)
