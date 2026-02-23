# Shortest Paths and Minimum Spanning Trees

## When to load
When implementing Dijkstra, Bellman-Ford, Floyd-Warshall, A*, Johnson's algorithm, or MST algorithms (Kruskal, Prim).

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
