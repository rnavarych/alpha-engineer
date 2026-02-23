# Topological Sort, SCCs, Network Flow, and Bipartite Matching

## When to load
When implementing topological sort, finding strongly connected components (Tarjan/Kosaraju), computing maximum network flow (Dinic/Edmonds-Karp), or solving bipartite matching problems.

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
