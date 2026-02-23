# Graph Representations and Traversal

## When to load
When choosing a graph representation, implementing BFS or DFS, classifying DFS edges, or applying traversal-based algorithms (connected components, bipartite check, cycle detection).

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

## BFS (Breadth-First Search)
- Queue-based. Visits nodes level by level. O(V + E).
- Finds shortest path in unweighted graphs (minimum edges).
- Applications: shortest path (unweighted), connected components, bipartite check, level-order traversal.

## DFS (Depth-First Search)
- Stack-based (or recursive). Explores deep before backtracking. O(V + E).
- Use iterative DFS to avoid stack overflow on deep graphs.
- Applications: cycle detection, topological sort, connected components, articulation points, bridges.

### DFS Edge Classification
- **Tree edge**: Edge to unvisited vertex (part of DFS tree).
- **Back edge**: Edge to ancestor → cycle exists (in directed graph).
- **Forward edge**: Edge to descendant (directed only).
- **Cross edge**: Edge to visited non-ancestor/non-descendant (directed only).
